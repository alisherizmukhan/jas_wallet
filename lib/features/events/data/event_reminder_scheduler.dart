import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/local_notification_service.dart';
import '../../../core/services/notification_channel_config.dart';
import '../../../core/services/notification_storage_service.dart';
import '../../../core/services/timezone_initializer.dart';
import '../../notifications/domain/entities/notification_item.dart';
import '../domain/entities/event.dart';
import 'event_follow_store.dart';

/// The three reminders fired for each upcoming event, in firing order.
///
/// Events without a parsed start time only get [dayBefore] — claiming
/// "in 1 hour" against an assumed 09:00 start would be confidently wrong.
enum ReminderStage {
  dayBefore(Duration(days: 1)),
  twelveHoursBefore(Duration(hours: 12)),
  oneHourBefore(Duration(hours: 1));

  const ReminderStage(this.lead);

  /// How long before the event start this stage fires.
  final Duration lead;
}

/// Schedules local reminders for upcoming NU events at three points:
/// 1 day, 12 hours, and 1 hour before the event starts (see [ReminderStage]).
///
/// Opt-in: only events the user has followed (see [EventFollowStore]) are
/// scheduled. An empty follow list means no event reminders at all.
///
/// Works fully offline — no backend involvement. Every time the events list
/// changes (cache restore on startup, network refresh, pull-to-refresh,
/// pagination, follow/unfollow) the owning notifier calls [resync] with the
/// full list and the scheduler rebuilds the pending reminders:
///
///  • Reminder time = event start − stage lead, skipped if already in the past.
///  • Notification IDs are deterministic (FNV-1a hash of the event link +
///    stage), so rescheduling the same event replaces its pending
///    notifications on both platforms instead of duplicating them.
///  • IDs scheduled in the previous sync are persisted in SharedPreferences;
///    events that disappeared from the list get their reminders cancelled.
///  • Event times are interpreted in the campus timezone ([campusTimeZone]) —
///    the NU site publishes wall-clock times for Astana, so the reminder
///    fires at the correct instant even if the device timezone differs.
///
/// Settings semantics mirror the FCM categories (see FCMService):
///  • Master push toggle OFF → no system notifications and no feed entries.
///  • Events category toggle OFF = mute mode ("silent subscription"): no
///    system notifications, but reminders still appear in the in-app
///    notifications feed.
///  • Reminders whose time has passed (fired while the app was closed, or
///    suppressed by mute mode) are written to the feed on the next resync
///    via [NotificationStorageService], deduplicated by a persisted
///    delivered-ID list so deleting one from the feed doesn't resurrect it.
///
/// TODO(student-clubs): student club events are planned as a second source.
/// The scheduler is source-agnostic — once club events are parsed with dates,
/// map them to [NuEvent]s (or a shared interface) and merge them into the
/// list passed to [resync]; IDs derive from the event link so the two
/// sources cannot collide.
///
/// Failures never propagate: notifications are a best-effort side effect and
/// must not break the events flow.
class EventReminderScheduler {
  EventReminderScheduler({
    required LocalNotificationService notifications,
    NotificationStorageService? storage,
    DateTime Function()? now,
  })  : _notifications = notifications,
        _storage = storage ?? NotificationStorageService.instance,
        _now = now ?? DateTime.now;

  final LocalNotificationService _notifications;
  final NotificationStorageService _storage;
  final DateTime Function() _now;

  /// IANA timezone the NU site's event times are published in.
  static const String campusTimeZone = 'Asia/Almaty';

  /// iOS caps pending local notifications at 64 per app; leave headroom for
  /// other reminder types by only scheduling the soonest reminders.
  /// 24 pending = the 8 soonest events fully covered at 3 stages each.
  static const int maxScheduledReminders = 24;

  /// Assumed start hour for events whose listing has no time.
  static const int _defaultStartHour = 9;

  /// Cap for the delivered-feed-ID history (prevents unbounded pref growth).
  static const int _maxDeliveredIds = 100;

  static const String _kScheduledIdsKey = 'event_reminder_scheduled_ids';
  static const String _kDeliveredIdsKey = 'event_reminder_delivered_ids';
  static const String _kPushSettingKey = 'notif_setting_push';
  static const String _kEventsToggleKey = 'notif_setting_events';
  static const String _kLocaleKey = 'app_locale';

  /// GoRouter location of the event details page (AppRoutes.eventDetails).
  /// Kept as a local constant so this data-layer file does not import the
  /// router (which pulls in the whole page tree).
  static const String _eventDetailsPath = '/events/detail';

  Future<void>? _running;
  List<NuEvent>? _queued;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Rebuilds all event reminders from [events].
  ///
  /// Concurrent calls are coalesced: while a sync is running the latest list
  /// is queued and applied once the current pass finishes, so two overlapping
  /// refreshes can never interleave their cancel/schedule operations.
  Future<void> resync(List<NuEvent> events) {
    final running = _running;
    if (running != null) {
      _queued = events;
      return running;
    }
    final future = _doResync(events).whenComplete(() {
      _running = null;
      final queued = _queued;
      _queued = null;
      if (queued != null) unawaited(resync(queued));
    });
    _running = future;
    return future;
  }

  /// Deterministic 31-bit notification ID for [event] at [stage].
  ///
  /// Derived from [NuEvent.reminderKey] (event link, or title+date), salted
  /// with the stage so each of the three reminders has its own stable ID.
  /// Positive 31-bit so it is a valid Android/iOS notification ID and stable
  /// across app restarts.
  static int notificationIdFor(NuEvent event, ReminderStage stage) {
    return _fnv1a('${event.reminderKey}#${stage.name}') & 0x7fffffff;
  }

  /// Deep-link route for [event]'s details page — used both as the OS
  /// notification payload (tap → navigate) and as the feed item's
  /// [NotificationItem.actionRoute].
  ///
  /// Returns null for events without a link: the details page loads its
  /// content from the event URL, so there is nothing to deep-link to.
  static String? actionRouteFor(NuEvent event) {
    final link = event.link;
    if (link == null || link.isEmpty) return null;
    return '$_eventDetailsPath?link=${Uri.encodeQueryComponent(link)}';
  }

  // ── Sync pass ──────────────────────────────────────────────────────────────

  Future<void> _doResync(List<NuEvent> events) async {
    try {
      ensureTimeZonesInitialized();
      final prefs = await SharedPreferences.getInstance();
      final previousIds = (prefs.getStringList(_kScheduledIdsKey) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toList();

      // Master push toggle off → fully blocked: tear everything down, no
      // system notifications and no feed entries (same as non-SVC FCM).
      final pushEnabled = prefs.getBool(_kPushSettingKey) ?? true;
      if (!pushEnabled) {
        await _cancelIds(previousIds);
        await prefs.remove(_kScheduledIdsKey);
        return;
      }

      final location = tz.getLocation(campusTimeZone);
      final now = tz.TZDateTime.from(_now(), location);
      final followed = (prefs.getStringList(EventFollowStore.prefsKey) ??
              const [])
          .toSet();

      // Partition stage reminders into future ones (to schedule) and
      // past-due ones (to deliver into the feed). Every non-future reminder
      // goes to the feed regardless of whether the event has since started —
      // see the matching note in MealReminderScheduler._doResync for why: the
      // real system notification already fired independently via a native
      // alarm, so gating feed delivery on "event hasn't started yet" only
      // meant the in-app history silently disagreed with what was actually
      // delivered. The per-item delivered-ID ledger is what prevents
      // duplicate spam, not this partition.
      //
      // Unfollowed events are skipped entirely (opt-in): no system
      // notification and no feed entry.
      final candidates = <_ReminderCandidate>[];
      final pastDue = <_ReminderCandidate>[];
      final seenIds = <int>{};
      for (final event in events) {
        if (!followed.contains(event.reminderKey)) continue;
        final start = _parseStart(event, location, now);
        if (start == null) continue;
        for (final stage in ReminderStage.values) {
          // Without a real start time, 12h/1h leads would be guesses.
          if (event.time == null && stage != ReminderStage.dayBefore) {
            continue;
          }
          final reminderAt = start.subtract(stage.lead);
          final id = notificationIdFor(event, stage);
          if (!seenIds.add(id)) continue;
          final candidate = _ReminderCandidate(
            id: id,
            event: event,
            stage: stage,
            start: start,
            reminderAt: reminderAt,
          );
          if (reminderAt.isAfter(now)) {
            candidates.add(candidate);
          } else {
            pastDue.add(candidate);
          }
        }
      }
      candidates.sort((a, b) => a.reminderAt.compareTo(b.reminderAt));
      final toSchedule = candidates.take(maxScheduledReminders).toList();

      final l10n = _localizations(prefs);

      // Feed delivery happens in BOTH banner mode and mute mode — a muted
      // category still records reminders silently, like a kept subscription.
      await _deliverPastDueToFeed(pastDue, prefs, l10n);

      // Events toggle off = mute mode: no system notifications at all.
      final eventsEnabled = prefs.getBool(_kEventsToggleKey) ?? true;
      if (!eventsEnabled) {
        await _cancelIds(previousIds);
        await prefs.setStringList(_kScheduledIdsKey, const []);
        return;
      }

      // Cancel reminders whose events disappeared or are no longer eligible.
      final newIds = toSchedule.map((c) => c.id).toSet();
      await _cancelIds(
        previousIds.where((id) => !newIds.contains(id)).toList(),
      );

      // Schedule (same-ID schedules atomically replace pending ones, so
      // re-syncing an unchanged event never duplicates its reminder).
      final scheduledIds = <String>[];
      for (final candidate in toSchedule) {
        try {
          await _notifications.scheduleNotification(
            id: candidate.id,
            title: l10n.events_reminderTitle,
            body: _bodyFor(candidate, l10n),
            scheduledAt: candidate.reminderAt,
            channelId: NotificationChannels.events,
            channelName: 'Events',
            payload: actionRouteFor(candidate.event),
          );
          scheduledIds.add('${candidate.id}');
        } catch (e) {
          debugPrint('EventReminderScheduler: schedule failed for '
              '"${candidate.event.title}": $e');
        }
      }

      await prefs.setStringList(_kScheduledIdsKey, scheduledIds);

      if (kDebugMode) {
        debugPrint('EventReminderScheduler: ${scheduledIds.length} '
            'reminder(s) scheduled, ${pastDue.length} past-due → feed '
            '(next: ${toSchedule.isEmpty ? 'none' : toSchedule.first.reminderAt})');
      }
    } catch (e) {
      debugPrint('EventReminderScheduler.resync failed: $e');
    }
  }

  /// Writes past-due reminders into the in-app notifications feed.
  ///
  /// This is what makes a reminder visible in the Notifications tab after
  /// the OS notification fired while the app was closed, and what keeps
  /// muted reminders flowing into the feed. A persisted delivered-ID list
  /// ensures each reminder enters the feed at most once, even if the user
  /// deletes it from the feed afterwards.
  Future<void> _deliverPastDueToFeed(
    List<_ReminderCandidate> pastDue,
    SharedPreferences prefs,
    AppLocalizations l10n,
  ) async {
    if (pastDue.isEmpty) return;

    final delivered = prefs.getStringList(_kDeliveredIdsKey) ?? const [];
    final deliveredSet = delivered.toSet();
    final updated = [...delivered];

    for (final candidate in pastDue) {
      final feedId = 'event_reminder_${candidate.id}';
      if (deliveredSet.contains(feedId)) continue;
      try {
        await _storage.add(NotificationItem(
          id: feedId,
          title: l10n.events_reminderTitle,
          message: _bodyFor(candidate, l10n),
          category: NotificationCategory.events,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            candidate.reminderAt.millisecondsSinceEpoch,
          ),
          actionRoute: actionRouteFor(candidate.event),
        ));
        updated.add(feedId);
      } catch (e) {
        debugPrint('EventReminderScheduler: feed delivery failed for '
            '"${candidate.event.title}": $e');
      }
    }

    final capped = updated.length > _maxDeliveredIds
        ? updated.sublist(updated.length - _maxDeliveredIds)
        : updated;
    await prefs.setStringList(_kDeliveredIdsKey, capped);
  }

  /// Stage-specific body. Times are always rendered 24-hour ("15:00"),
  /// matching the campus wall-clock the NU site publishes.
  String _bodyFor(_ReminderCandidate candidate, AppLocalizations l10n) {
    final title = candidate.event.title;
    if (candidate.event.time == null) {
      // No-time events only reach here as dayBefore reminders.
      return l10n.events_reminderBodyAllDay(title);
    }
    final time = _formatTime(candidate.start);
    return switch (candidate.stage) {
      ReminderStage.dayBefore => l10n.events_reminderBody(time, title),
      ReminderStage.twelveHoursBefore =>
        l10n.events_reminderBody12h(time, title),
      ReminderStage.oneHourBefore => l10n.events_reminderBody1h(time, title),
    };
  }

  Future<void> _cancelIds(List<int> ids) async {
    for (final id in ids) {
      try {
        await _notifications.cancelNotification(id);
      } catch (e) {
        debugPrint('EventReminderScheduler: cancel($id) failed: $e');
      }
    }
  }

  // ── Date/time parsing ──────────────────────────────────────────────────────

  /// Parses the listing's `date` ("Fri, Jun 12, 2026") and `time` ("09:00")
  /// into a start moment in [location]. Returns null when the date cannot be
  /// parsed. Events without a time are assumed to start at
  /// [_defaultStartHour] so the reminder still fires the morning before.
  tz.TZDateTime? _parseStart(
    NuEvent event,
    tz.Location location,
    tz.TZDateTime now,
  ) {
    final date = _parseDate(event.date, now);
    if (date == null) return null;
    final time = _parseTime(event.time);
    return tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      time?.hour ?? _defaultStartHour,
      time?.minute ?? 0,
    );
  }

  /// Mirrors EventsService._parseEventDate: strips the weekday prefix and a
  /// day-range suffix ("Jun 12–13, 2026" → first day). Dates without a year
  /// assume the current year, rolling to the next year when that would put
  /// the event more than a day in the past.
  DateTime? _parseDate(String raw, tz.TZDateTime now) {
    // Strip only real weekday prefixes — a bare `[A-Za-z]{3}` would also eat
    // a leading month in dates without a weekday ("Aug 1, 2026").
    var cleaned = raw
        .replaceFirst(
          RegExp(r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun),?\s*', caseSensitive: false),
          '',
        )
        .trim();
    cleaned = cleaned.replaceFirst(RegExp(r'[-–—]\s*\d+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    for (final fmt in ['MMM dd, yyyy', 'MMM d, yyyy', 'MMM dd yyyy', 'MMM d yyyy']) {
      try {
        return DateFormat(fmt, 'en_US').parseStrict(cleaned);
      } catch (_) {}
    }
    for (final fmt in ['MMM dd', 'MMM d']) {
      try {
        final d = DateFormat(fmt, 'en_US').parseStrict(cleaned);
        var candidate = DateTime(now.year, d.month, d.day);
        final today = DateTime(now.year, now.month, now.day);
        if (candidate.isBefore(today)) {
          candidate = DateTime(now.year + 1, d.month, d.day);
        }
        return candidate;
      } catch (_) {}
    }
    return null;
  }

  ({int hour, int minute})? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return (hour: hour, minute: minute);
  }

  String _formatTime(tz.TZDateTime start) =>
      '${start.hour.toString().padLeft(2, '0')}:'
      '${start.minute.toString().padLeft(2, '0')}';

  // ── Localization ───────────────────────────────────────────────────────────

  /// Resolves strings in the user's saved app locale. Notification text is
  /// baked at scheduling time, so a locale switch takes effect on the next
  /// resync (any events refresh) — an acceptable trade-off for local
  /// scheduling.
  AppLocalizations _localizations(SharedPreferences prefs) {
    final code = prefs.getString(_kLocaleKey) ?? 'en';
    try {
      return lookupAppLocalizations(Locale(code));
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  // ── Hashing ────────────────────────────────────────────────────────────────

  static int _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}

class _ReminderCandidate {
  const _ReminderCandidate({
    required this.id,
    required this.event,
    required this.stage,
    required this.start,
    required this.reminderAt,
  });

  final int id;
  final NuEvent event;
  final ReminderStage stage;
  final tz.TZDateTime start;
  final tz.TZDateTime reminderAt;
}
