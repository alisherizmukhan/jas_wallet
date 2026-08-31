import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/local_notification_service.dart';
import 'package:jaswallet_app/core/services/notification_storage_service.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';
import 'package:jaswallet_app/features/social_meal/data/meal_reminder_scheduler.dart';
import 'package:jaswallet_app/features/social_meal/domain/entities/meal_entry.dart';
import 'package:jaswallet_app/features/social_meal/domain/entities/meal_schedule.dart';
import 'package:jaswallet_app/features/social_meal/domain/entities/meal_slot.dart';
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

// Campus dining hours are scheduled in Asia/Almaty (UTC+5) — see
// MealReminderScheduler._campusTimeZone. "now" is a real UTC instant that
// [MealReminderScheduler] re-labels into that zone for wall-clock
// comparisons, so express it as the UTC instant of the intended Almaty
// moment rather than as raw matching digits.
// 07:00 Almaty, before breakfast opens == 02:00 UTC.
final _fixedNow = DateTime.utc(2026, 7, 6, 2, 0);

MealEntry _entry(DateTime date, MealSlot slot, {MealStatus status = MealStatus.scheduled}) =>
    MealEntry(id: MealEntry.makeId(date, slot), date: date, slot: slot, status: status);

MealSchedule _schedule(
  DateTime date, {
  MealStatus breakfast = MealStatus.scheduled,
  MealStatus lunch = MealStatus.scheduled,
  MealStatus dinner = MealStatus.scheduled,
}) =>
    MealSchedule(date: date, meals: [
      _entry(date, MealSlot.breakfast, status: breakfast),
      _entry(date, MealSlot.lunch, status: lunch),
      _entry(date, MealSlot.dinner, status: dinner),
    ]);

MealReminderScheduler _makeScheduler(_FakeNotificationService fake) =>
    MealReminderScheduler(notifications: fake, now: () => _fixedNow);

final _today = DateTime.utc(2026, 7, 6);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeNotificationService fake;
  late MealReminderScheduler scheduler;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = _FakeNotificationService();
    scheduler = _makeScheduler(fake);
  });

  group('stage timing', () {
    test('breakfast schedules opens at 08:15 and closingSoon at 11:30', () async {
      await scheduler.resync([_schedule(_today, lunch: MealStatus.cancelled, dinner: MealStatus.cancelled)]);

      expect(fake.scheduled, hasLength(2));
      final byTime = [...fake.scheduled]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      expect(byTime[0].scheduledAt.hour, 8);
      expect(byTime[0].scheduledAt.minute, 15);
      expect(byTime[1].scheduledAt.hour, 11);
      expect(byTime[1].scheduledAt.minute, 30);
      for (final call in fake.scheduled) {
        expect(call.channelId, 'jaswallet_meals');
        expect(call.payload, '/svc');
      }
    });

    test('lunch schedules opens at 12:15 and closingSoon at 16:30', () async {
      await scheduler.resync([_schedule(_today, breakfast: MealStatus.cancelled, dinner: MealStatus.cancelled)]);

      final byTime = [...fake.scheduled]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      expect(byTime[0].scheduledAt.hour, 12);
      expect(byTime[0].scheduledAt.minute, 15);
      expect(byTime[1].scheduledAt.hour, 16);
      expect(byTime[1].scheduledAt.minute, 30);
    });

    test('dinner schedules opens at 17:15 and closingSoon at 23:30', () async {
      await scheduler.resync([_schedule(_today, breakfast: MealStatus.cancelled, lunch: MealStatus.cancelled)]);

      final byTime = [...fake.scheduled]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      expect(byTime[0].scheduledAt.hour, 17);
      expect(byTime[0].scheduledAt.minute, 15);
      expect(byTime[1].scheduledAt.hour, 23);
      expect(byTime[1].scheduledAt.minute, 30);
    });

    test('bodies name the meal and match the open/closing wording', () async {
      await scheduler.resync([_schedule(_today, lunch: MealStatus.cancelled, dinner: MealStatus.cancelled)]);

      final bodies = fake.scheduled.map((c) => c.body).toSet();
      expect(bodies, {
        "Breakfast is ready — don't forget to grab it!",
        "Only 30 minutes left to get your Breakfast — don't miss it!",
      });
      expect(fake.scheduled.every((c) => c.title == 'Breakfast reminder'), isTrue);
    });
  });

  group('skips non-scheduled slots', () {
    test('cancelled, received, and no-show slots get no reminders', () async {
      await scheduler.resync([
        _schedule(
          _today,
          breakfast: MealStatus.cancelled,
          lunch: MealStatus.received,
          dinner: MealStatus.noShow,
        ),
      ]);

      expect(fake.scheduled, isEmpty);
    });
  });

  group('deterministic IDs', () {
    test('same date/slot/stage always maps to the same ID', () {
      final a = _entry(_today, MealSlot.breakfast);
      expect(
        MealReminderScheduler.notificationIdFor(a, MealReminderStage.opens),
        MealReminderScheduler.notificationIdFor(a, MealReminderStage.opens),
      );
    });

    test('different slots on the same day have different IDs', () {
      expect(
        MealReminderScheduler.notificationIdFor(_entry(_today, MealSlot.breakfast), MealReminderStage.opens),
        isNot(MealReminderScheduler.notificationIdFor(_entry(_today, MealSlot.lunch), MealReminderStage.opens)),
      );
    });

    test('the two stages of one slot have different IDs', () {
      final e = _entry(_today, MealSlot.breakfast);
      expect(
        MealReminderScheduler.notificationIdFor(e, MealReminderStage.opens),
        isNot(MealReminderScheduler.notificationIdFor(e, MealReminderStage.closingSoon)),
      );
    });

    test('IDs are valid positive 32-bit notification IDs', () {
      final e = _entry(_today, MealSlot.breakfast);
      for (final stage in MealReminderStage.values) {
        final id = MealReminderScheduler.notificationIdFor(e, stage);
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThanOrEqualTo(0x7fffffff));
      }
    });

    test('resyncing the same schedule twice re-schedules with identical IDs, '
        'nothing cancelled', () async {
      final schedules = [_schedule(_today, lunch: MealStatus.cancelled, dinner: MealStatus.cancelled)];
      await scheduler.resync(schedules);
      await scheduler.resync(schedules);

      expect(fake.scheduled, hasLength(4));
      expect(
        fake.scheduled.take(2).map((c) => c.id).toSet(),
        fake.scheduled.skip(2).map((c) => c.id).toSet(),
      );
      expect(fake.cancelled, isEmpty);
    });
  });

  group('settings', () {
    test('master push toggle off cancels everything and schedules nothing', () async {
      await scheduler.resync([_schedule(_today, lunch: MealStatus.cancelled, dinner: MealStatus.cancelled)]);
      final ids = fake.scheduled.map((c) => c.id).toList();
      expect(ids, hasLength(2));

      SharedPreferences.setMockInitialValues({
        'notif_setting_push': false,
        'meal_reminder_scheduled_ids': ids.map((id) => '$id').toList(),
      });
      final fake2 = _FakeNotificationService();
      final scheduler2 = _makeScheduler(fake2);

      await scheduler2.resync([_schedule(_today, lunch: MealStatus.cancelled, dinner: MealStatus.cancelled)]);

      expect(fake2.scheduled, isEmpty);
      expect(fake2.cancelled, unorderedEquals(ids));
    });

    test('Meal Pass toggle off = mute mode: cancels scheduled reminders and '
        'schedules nothing', () async {
      await scheduler.resync([_schedule(_today, lunch: MealStatus.cancelled, dinner: MealStatus.cancelled)]);
      final ids = fake.scheduled.map((c) => c.id).toList();
      expect(ids, hasLength(2));

      SharedPreferences.setMockInitialValues({
        'notif_setting_svc': false,
        'meal_reminder_scheduled_ids': ids.map((id) => '$id').toList(),
      });
      final fake2 = _FakeNotificationService();
      final scheduler2 = _makeScheduler(fake2);

      await scheduler2.resync([_schedule(_today, lunch: MealStatus.cancelled, dinner: MealStatus.cancelled)]);

      expect(fake2.scheduled, isEmpty);
      expect(fake2.cancelled, unorderedEquals(ids));
    });
  });

  group('feed delivery', () {
    // now = 07:00. Move "now" to 09:20 (past breakfast opens@08:15, but the
    // slot itself — ends 12:00 — is still open) via a scheduler with that now.
    MealReminderScheduler schedulerAt(DateTime now, _FakeNotificationService f) =>
        MealReminderScheduler(notifications: f, now: () => now);

    test('a past-due opens reminder for a still-open slot lands in the feed', () async {
      final lateFake = _FakeNotificationService();
      // 09:20 Almaty == 04:20 UTC.
      final lateScheduler = schedulerAt(DateTime.utc(2026, 7, 6, 4, 20), lateFake);

      await lateScheduler.resync([_schedule(_today, lunch: MealStatus.cancelled, dinner: MealStatus.cancelled)]);

      // opens (08:15) is past-due → feed; closingSoon (11:30) still ahead → scheduled.
      expect(lateFake.scheduled, hasLength(1));
      expect(lateFake.scheduled.single.scheduledAt.hour, 11);
      expect(lateFake.scheduled.single.scheduledAt.minute, 30);

      final feed = await NotificationStorageService.instance.getAll();
      expect(feed, hasLength(1));
      expect(feed.single.category, NotificationCategory.svc);
      expect(feed.single.message, "Breakfast is ready — don't forget to grab it!");
    });

    test('a slot whose window has fully closed still delivers both its '
        'past-due reminders to the feed', () async {
      // A closed slot's reminders already fired as real system
      // notifications via native alarms scheduled before the slot closed —
      // the feed must match that, not silently disagree with what the user
      // actually received.
      final lateFake = _FakeNotificationService();
      // 13:00 Almaty (breakfast, which ends 12:00, is entirely over) == 08:00 UTC.
      final lateScheduler = schedulerAt(DateTime.utc(2026, 7, 6, 8, 0), lateFake);

      await lateScheduler.resync([_schedule(_today, lunch: MealStatus.cancelled, dinner: MealStatus.cancelled)]);

      expect(lateFake.scheduled, isEmpty);
      final feed = await NotificationStorageService.instance.getAll();
      final messages = feed.map((n) => n.message).toSet();
      expect(messages, {
        "Breakfast is ready — don't forget to grab it!",
        "Only 30 minutes left to get your Breakfast — don't miss it!",
      });
    });

    test('master push off blocks feed delivery entirely', () async {
      SharedPreferences.setMockInitialValues({'notif_setting_push': false});
      final lateFake = _FakeNotificationService();
      // 09:20 Almaty == 04:20 UTC.
      final lateScheduler = schedulerAt(DateTime.utc(2026, 7, 6, 4, 20), lateFake);

      await lateScheduler.resync([_schedule(_today, lunch: MealStatus.cancelled, dinner: MealStatus.cancelled)]);

      final feed = await NotificationStorageService.instance.getAll();
      expect(feed, isEmpty);
    });
  });
}
