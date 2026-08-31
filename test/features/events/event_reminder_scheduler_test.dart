import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/local_notification_service.dart';
import 'package:jaswallet_app/core/services/notification_storage_service.dart';
import 'package:jaswallet_app/features/events/data/event_follow_store.dart';
import 'package:jaswallet_app/features/events/data/event_reminder_scheduler.dart';
import 'package:jaswallet_app/features/events/domain/entities/event.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

// ── Fake notification service ─────────────────────────────────────────────────

class _ScheduledCall {
  _ScheduledCall({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.channelId,
    this.payload,
  });

  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledAt;
  final String channelId;
  final String? payload;
}

class _FakeNotificationService extends LocalNotificationService {
  _FakeNotificationService() : super.forTesting();

  final scheduled = <_ScheduledCall>[];
  final cancelled = <int>[];

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledAt,
    String channelId = 'jaswallet_reminders',
    String channelName = 'Reminders',
    String? payload,
  }) async {
    scheduled.add(_ScheduledCall(
      id: id,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      channelId: channelId,
      payload: payload,
    ));
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelled.add(id);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// Fixed "now": 2026-07-06 12:00 Asia/Almaty (UTC+5) == 07:00 UTC.
final _fixedNow = DateTime.utc(2026, 7, 6, 7);

NuEvent _event({
  String title = 'Orientation Day',
  String date = 'Fri, Jul 10, 2026',
  String? time = '06:00',
  String? link = 'https://nu.edu.kz/eventsm/orientation-day',
}) =>
    NuEvent(title: title, date: date, venue: 'Main Hall', time: time, link: link);

EventReminderScheduler _makeScheduler(_FakeNotificationService fake) =>
    EventReminderScheduler(notifications: fake, now: () => _fixedNow);

List<int> _allStageIds(NuEvent event) => [
      for (final stage in ReminderStage.values)
        EventReminderScheduler.notificationIdFor(event, stage),
    ];

Future<void> _follow(Iterable<NuEvent> events) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    EventFollowStore.prefsKey,
    events.map((e) => e.reminderKey).toList(),
  );
}

Future<void> _resyncFollowed(
  EventReminderScheduler scheduler,
  List<NuEvent> events,
) async {
  await _follow(events);
  await scheduler.resync(events);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeNotificationService fake;
  late EventReminderScheduler scheduler;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = _FakeNotificationService();
    scheduler = _makeScheduler(fake);
  });

  group('scheduling', () {
    test('schedules three reminders: 1 day, 12 hours, and 1 hour before start',
        () async {
      // Event: Jul 10, 06:00 Asia/Almaty.
      await _resyncFollowed(scheduler, [_event()]);

      expect(fake.scheduled, hasLength(3));
      for (final call in fake.scheduled) {
        expect(call.scheduledAt.location.name, 'Asia/Almaty');
        expect(call.channelId, 'jaswallet_events');
      }
      final byTime = [...fake.scheduled]
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      // 1 day before: Jul 9 06:00.
      expect(byTime[0].scheduledAt.day, 9);
      expect(byTime[0].scheduledAt.hour, 6);
      // 12 hours before: Jul 9 18:00.
      expect(byTime[1].scheduledAt.day, 9);
      expect(byTime[1].scheduledAt.hour, 18);
      // 1 hour before: Jul 10 05:00.
      expect(byTime[2].scheduledAt.day, 10);
      expect(byTime[2].scheduledAt.hour, 5);
    });

    test('bodies are stage-specific and use 24-hour times', () async {
      await _resyncFollowed(scheduler, [_event()]);

      final bodies = fake.scheduled.map((c) => c.body).toSet();
      expect(bodies, {
        'Tomorrow at 06:00 — Orientation Day',
        'In 12 hours at 06:00 — Orientation Day',
        'In 1 hour at 06:00 — Orientation Day',
      });
      expect(fake.scheduled.every((c) => c.title == 'Upcoming Event'), isTrue);
    });

    test('event without a time gets only the day-before all-day reminder',
        () async {
      await _resyncFollowed(scheduler, [_event(time: null)]);

      final call = fake.scheduled.single;
      expect(call.body, 'Tomorrow — Orientation Day');
      expect(call.scheduledAt.hour, 9); // assumed 09:00 start
    });

    test('stages whose reminder time already passed are not scheduled',
        () async {
      // Event tomorrow 06:00: day-before stage (today 06:00) already passed;
      // 12h (today 18:00) and 1h (tomorrow 05:00) are still ahead.
      await _resyncFollowed(scheduler, [_event(date: 'Tue, Jul 7, 2026')]);

      expect(fake.scheduled, hasLength(2));
      final hours = fake.scheduled.map((c) => c.scheduledAt.hour).toSet();
      expect(hours, {18, 5});
    });

    test('skips events with unparsable dates', () async {
      await scheduler.resync([_event(date: 'Sometime soon')]);

      expect(fake.scheduled, isEmpty);
    });

    test('date without a year that already passed rolls to next year',
        () async {
      // "Jan 5" parsed on 2026-07-06 must mean Jan 5, 2027.
      await _resyncFollowed(scheduler, [_event(date: 'Mon, Jan 5', time: '10:00')]);

      expect(fake.scheduled, hasLength(3));
      final dayBefore = fake.scheduled
          .map((c) => c.scheduledAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      expect(dayBefore.year, 2027);
      expect(dayBefore.month, 1);
      expect(dayBefore.day, 4);
      expect(dayBefore.hour, 10);
    });

    test('caps total pending notifications at maxScheduledReminders', () async {
      final events = List.generate(
        30,
        (i) => _event(
          title: 'Event $i',
          date: 'Aug ${(i % 28) + 1}, 2026',
          link: 'https://nu.edu.kz/eventsm/event-$i',
        ),
      );

      await _resyncFollowed(scheduler, events);

      expect(
        fake.scheduled,
        hasLength(EventReminderScheduler.maxScheduledReminders),
      );
    });

    test('unfollowed events are not scheduled', () async {
      await scheduler.resync([_event()]);

      expect(fake.scheduled, isEmpty);
    });

    test('only followed events among a mixed list are scheduled', () async {
      final followed = _event();
      final ignored = _event(
        title: 'Ignored',
        link: 'https://nu.edu.kz/eventsm/ignored',
      );
      await _follow([followed]);
      await scheduler.resync([followed, ignored]);

      expect(fake.scheduled, hasLength(3));
      expect(
        fake.scheduled.map((c) => c.id).toSet(),
        _allStageIds(followed).toSet(),
      );
    });

    test('unfollowing cancels previously scheduled reminders', () async {
      await _resyncFollowed(scheduler, [_event()]);
      expect(fake.scheduled, hasLength(3));

      await _follow(const []);
      await scheduler.resync([_event()]);

      expect(fake.cancelled, unorderedEquals(_allStageIds(_event())));
    });
  });

  group('deep links (tap → event details)', () {
    const expectedRoute = '/events/detail'
        '?link=https%3A%2F%2Fnu.edu.kz%2Feventsm%2Forientation-day';

    test('actionRouteFor encodes the event link into the details route', () {
      expect(EventReminderScheduler.actionRouteFor(_event()), expectedRoute);
    });

    test('actionRouteFor is null for events without a link', () {
      expect(EventReminderScheduler.actionRouteFor(_event(link: null)), isNull);
    });

    test('scheduled notifications carry the event-details payload', () async {
      await _resyncFollowed(scheduler, [_event()]);

      expect(fake.scheduled, hasLength(3));
      for (final call in fake.scheduled) {
        expect(call.payload, expectedRoute);
      }
    });

    test('events without a link schedule with a null payload', () async {
      await _resyncFollowed(scheduler, [_event(link: null)]);

      expect(fake.scheduled, isNotEmpty);
      expect(fake.scheduled.every((c) => c.payload == null), isTrue);
    });

    test('past-due feed entries carry the event-details actionRoute',
        () async {
      // Day-before stage already passed → delivered to the feed.
      await _resyncFollowed(scheduler, [_event(date: 'Tue, Jul 7, 2026')]);

      final feed = await NotificationStorageService.instance.getAll();
      expect(feed.single.actionRoute, expectedRoute);
    });
  });

  group('deterministic IDs and deduplication', () {
    test('same event and stage always map to the same ID', () {
      expect(
        EventReminderScheduler.notificationIdFor(
            _event(), ReminderStage.dayBefore),
        EventReminderScheduler.notificationIdFor(
            _event(), ReminderStage.dayBefore),
      );
    });

    test('each stage of one event has its own ID', () {
      final ids = _allStageIds(_event());
      expect(ids.toSet(), hasLength(3));
    });

    test('different links map to different IDs', () {
      expect(
        EventReminderScheduler.notificationIdFor(
            _event(link: 'https://nu.edu.kz/eventsm/a'),
            ReminderStage.dayBefore),
        isNot(EventReminderScheduler.notificationIdFor(
            _event(link: 'https://nu.edu.kz/eventsm/b'),
            ReminderStage.dayBefore)),
      );
    });

    test('IDs are valid positive 32-bit notification IDs', () {
      for (final id in _allStageIds(_event())) {
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThanOrEqualTo(0x7fffffff));
      }
    });

    test('duplicate events in one list schedule only once per stage',
        () async {
      await _resyncFollowed(scheduler, [_event(), _event()]);

      expect(fake.scheduled, hasLength(3));
    });

    test('resyncing the same list twice re-schedules with identical IDs '
        '(platform replaces pending notifications, no duplicates)', () async {
      await _resyncFollowed(scheduler, [_event()]);
      await _resyncFollowed(scheduler, [_event()]);

      expect(fake.scheduled, hasLength(6));
      expect(
        fake.scheduled.take(3).map((c) => c.id).toSet(),
        fake.scheduled.skip(3).map((c) => c.id).toSet(),
      );
      // The still-present event must not be cancelled.
      expect(fake.cancelled, isEmpty);
    });
  });

  group('rescheduling on list changes', () {
    test('cancels all stage reminders for events removed from the list',
        () async {
      final removed = _event(
        title: 'Removed',
        link: 'https://nu.edu.kz/eventsm/removed',
      );
      await _resyncFollowed(scheduler, [_event(), removed]);
      expect(fake.scheduled, hasLength(6));

      await _resyncFollowed(scheduler, [_event()]);

      expect(fake.cancelled, unorderedEquals(_allStageIds(removed)));
    });

    test('persists scheduled IDs across scheduler instances', () async {
      await _resyncFollowed(scheduler, [_event()]);

      // New instance (e.g. app restart) sees the previous IDs and cancels
      // stale ones.
      final fake2 = _FakeNotificationService();
      final scheduler2 = _makeScheduler(fake2);
      await scheduler2.resync([]);

      expect(fake2.cancelled, unorderedEquals(_allStageIds(_event())));
    });
  });

  group('settings', () {
    test('master push toggle off cancels everything and schedules nothing',
        () async {
      await _resyncFollowed(scheduler, [_event()]);
      expect(fake.scheduled, hasLength(3));

      SharedPreferences.setMockInitialValues({
        'notif_setting_push': false,
        'event_reminder_scheduled_ids':
            _allStageIds(_event()).map((id) => '$id').toList(),
      });
      final fake2 = _FakeNotificationService();
      final scheduler2 = _makeScheduler(fake2);

      await scheduler2.resync([_event()]);

      expect(fake2.scheduled, isEmpty);
      expect(fake2.cancelled, unorderedEquals(_allStageIds(_event())));
    });

    test('bodies use the saved app locale', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ru'});

      await _resyncFollowed(scheduler, [_event()]);

      expect(fake.scheduled.map((c) => c.title).toSet(), {'Скоро мероприятие'});
      expect(fake.scheduled.map((c) => c.body).toSet(), {
        'Завтра в 06:00 — Orientation Day',
        'Через 12 часов в 06:00 — Orientation Day',
        'Через час, в 06:00 — Orientation Day',
      });
    });

    test('events toggle off = mute mode: cancels scheduled reminders and '
        'schedules nothing', () async {
      await _resyncFollowed(scheduler, [_event()]);
      expect(fake.scheduled, hasLength(3));

      SharedPreferences.setMockInitialValues({
        'notif_setting_events': false,
        'event_reminder_scheduled_ids':
            _allStageIds(_event()).map((id) => '$id').toList(),
      });
      final fake2 = _FakeNotificationService();
      final scheduler2 = _makeScheduler(fake2);

      await scheduler2.resync([_event()]);

      expect(fake2.scheduled, isEmpty);
      expect(fake2.cancelled, unorderedEquals(_allStageIds(_event())));
    });
  });

  group('feed delivery', () {
    // Event starting tomorrow 06:00: the day-before reminder time (today
    // 06:00) has passed → feed; 12h and 1h stages are still schedulable.
    NuEvent dueEvent() => _event(date: 'Tue, Jul 7, 2026');

    test('unfollowed events do not land in the feed even if past-due', () async {
      await scheduler.resync([dueEvent()]);

      expect(fake.scheduled, isEmpty);
      final feed = await NotificationStorageService.instance.getAll();
      expect(feed, isEmpty);
    });

    test('past-due stage for an upcoming event lands in the feed', () async {
      await _resyncFollowed(scheduler, [dueEvent()]);

      expect(fake.scheduled, hasLength(2)); // 12h + 1h still ahead
      final feed = await NotificationStorageService.instance.getAll();
      expect(feed, hasLength(1));
      final item = feed.single;
      expect(item.category, NotificationCategory.events);
      expect(item.title, 'Upcoming Event');
      expect(item.message, 'Tomorrow at 06:00 — Orientation Day');
      expect(
        item.id,
        'event_reminder_${EventReminderScheduler.notificationIdFor(dueEvent(), ReminderStage.dayBefore)}',
      );
    });

    test('feed entry is delivered even in mute mode (toggle off)', () async {
      SharedPreferences.setMockInitialValues({
        'notif_setting_events': false,
        EventFollowStore.prefsKey: [dueEvent().reminderKey],
      });

      await _resyncFollowed(scheduler, [dueEvent()]);

      expect(fake.scheduled, isEmpty);
      final feed = await NotificationStorageService.instance.getAll();
      expect(feed, hasLength(1));
    });

    test('master push off blocks feed delivery entirely', () async {
      SharedPreferences.setMockInitialValues({'notif_setting_push': false});

      await _resyncFollowed(scheduler, [dueEvent()]);

      final feed = await NotificationStorageService.instance.getAll();
      expect(feed, isEmpty);
    });

    test('resyncing twice does not duplicate the feed entry', () async {
      await _resyncFollowed(scheduler, [dueEvent()]);
      await _resyncFollowed(scheduler, [dueEvent()]);

      final feed = await NotificationStorageService.instance.getAll();
      expect(feed, hasLength(1));
    });

    test('a feed entry the user deleted is not resurrected', () async {
      await _resyncFollowed(scheduler, [dueEvent()]);
      final delivered =
          (await NotificationStorageService.instance.getAll()).single;
      await NotificationStorageService.instance.delete(delivered.id);

      await _resyncFollowed(scheduler, [dueEvent()]);

      final feed = await NotificationStorageService.instance.getAll();
      expect(feed, isEmpty);
    });

    test('an event that already started still delivers every past-due '
        'stage to the feed', () async {
      // An already-started event's reminders already fired as real system
      // notifications via native alarms scheduled before the event started —
      // the feed must match that, not silently disagree with what the user
      // actually received.
      // Started 2026-07-06 06:00 — before "now" (12:00), so all three stages
      // (1 day / 12h / 1h before) are past-due.
      final startedEvent = _event(date: 'Mon, Jul 6, 2026');
      await _resyncFollowed(scheduler, [startedEvent]);

      expect(fake.scheduled, isEmpty);
      final feed = await NotificationStorageService.instance.getAll();
      expect(feed, hasLength(3));
      expect(
        feed.map((n) => n.id).toSet(),
        {
          for (final stage in ReminderStage.values)
            'event_reminder_${EventReminderScheduler.notificationIdFor(startedEvent, stage)}',
        },
      );
    });
  });
}
