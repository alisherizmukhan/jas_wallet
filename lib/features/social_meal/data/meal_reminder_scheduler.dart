import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/local_notification_service.dart';
import '../../../core/services/notification_channel_config.dart';
import '../../../core/services/notification_storage_service.dart';
import '../../../core/services/timezone_initializer.dart';
import '../../notifications/domain/entities/notification_item.dart';
import '../domain/entities/meal_entry.dart';
import '../domain/entities/meal_schedule.dart';
import '../domain/entities/meal_slot.dart';

/// The two reminders fired for each still-scheduled meal slot, in firing
/// order.
enum MealReminderStage {
  /// Fires shortly after the slot opens — "it's ready, go get it".
  opens,

  /// Fires shortly before the slot closes — "last call".
  closingSoon,
}

/// Schedules local reminders for SVC meal slots at two points per slot:
/// 15 minutes after it opens, and 30 minutes before it closes (see
/// [MealReminderStage]). Architecturally the same shape as
/// [EventReminderScheduler] (`lib/features/events/data/event_reminder_scheduler.dart`)
/// — read that file for the fuller rationale behind the pattern this mirrors.
///
/// Works fully offline — no backend involvement. Every time the meal
/// schedule changes (today's load, pull-to-refresh, a cancel/undo/receive
/// mutation) the owning notifier calls [resync] with the currently-known
/// schedules (today plus a short forward window) and the scheduler rebuilds
/// the pending reminders:
///
///  • Reminder time = slot start + 15min (`opens`) or slot end − 30min
///    (`closingSoon`), skipped if already in the past.
///  • Only [MealStatus.scheduled] entries get reminders — a cancelled,
///    received, or no-show meal has nothing to remind about.
///  • Notification IDs are deterministic (FNV-1a hash of date + slot +
///    stage), so rescheduling the same day/slot replaces its pending
///    notifications on both platforms instead of duplicating them.
///  • IDs scheduled in the previous sync are persisted in SharedPreferences;
///    slots that disappeared (cancelled) or fell off the window get their
///    reminders cancelled.
///  • Meal times are campus dining-hall hours (Astana/Almaty time, same as
///    event listings — see [_campusTimeZone]), not device-local wall-clock
///    time, so a reminder fires at the right campus moment regardless of
///    which timezone the student's phone is set to.
///
/// Settings semantics mirror [EventReminderScheduler] exactly:
///  • Master push toggle OFF → no system notifications and no feed entries.
///  • Meal Pass category toggle OFF ([NotificationCategory.svc]) = mute mode
///    ("silent subscription"): no system notifications, but reminders still
///    appear in the in-app notifications feed.
///  • Reminders whose time has passed (fired while the app was closed, or
///    suppressed by mute mode) are written to the feed on the next resync
///    via [NotificationStorageService], deduplicated by a persisted
///    delivered-ID list so deleting one from the feed doesn't resurrect it.
///
/// Failures never propagate: notifications are a best-effort side effect and
/// must not break the meal flow.
class MealReminderScheduler {
  MealReminderScheduler({
    required LocalNotificationService notifications,
    NotificationStorageService? storage,
    DateTime Function()? now,
  })  : _notifications = notifications,
        _storage = storage ?? NotificationStorageService.instance,
        _now = now ?? DateTime.now;

  final LocalNotificationService _notifications;
  final NotificationStorageService _storage;
  final DateTime Function() _now;

  /// How long after a slot opens the "it's ready" reminder fires.
  static const Duration _opensLead = Duration(minutes: 15);

  /// How long before a slot closes the "last call" reminder fires.
  static const Duration _closingLead = Duration(minutes: 30);

  /// iOS caps pending local notifications at 64 per app; leave headroom
  /// alongside event reminders by only scheduling the soonest ones.
  /// 24 pending = 4 days fully covered at 3 slots × 2 stages each.
  static const int maxScheduledReminders = 24;

  /// Cap for the delivered-feed-ID history (prevents unbounded pref growth).
  static const int _maxDeliveredIds = 100;

  static const String _kScheduledIdsKey = 'meal_reminder_scheduled_ids';
  static const String _kDeliveredIdsKey = 'meal_reminder_delivered_ids';
  static const String _kPushSettingKey = 'notif_setting_push';
  static const String _kMealsToggleKey = 'notif_setting_svc';
  static const String _kLocaleKey = 'app_locale';

  /// GoRouter location of the SVC dashboard (AppRoutes.svcDashboard). Kept
  /// as a local constant so this data-layer file does not import the router.
  static const String _svcDashboardPath = '/svc';

  /// Campus dining-hall hours are published in Astana/Almaty time (matches
  /// [EventReminderScheduler.campusTimeZone] — kept as a local constant here
  /// too so this file stays independent of the events feature).
  static const String _campusTimeZone = 'Asia/Almaty';

  Future<void>? _running;
  List<MealSchedule>? _queued;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Rebuilds all meal reminders from [schedules] (today plus whatever
  /// forward window the caller currently knows about).
  ///
  /// Concurrent calls are coalesced: while a sync is running the latest list
  /// is queued and applied once the current pass finishes, so two overlapping
  /// refreshes can never interleave their cancel/schedule operations.
  Future<void> resync(List<MealSchedule> schedules) {
    final running = _running;
    if (running != null) {
      _queued = schedules;
      return running;
    }
    final future = _doResync(schedules).whenComplete(() {
      _running = null;
      final queued = _queued;
      _queued = null;
      if (queued != null) unawaited(resync(queued));
    });
    _running = future;
    return future;
  }

  /// Deterministic 31-bit notification ID for [entry] at [stage].
  static int notificationIdFor(MealEntry entry, MealReminderStage stage) {
    final d = entry.date;
    final dateKey =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return _fnv1a('$dateKey|${entry.slot.name}|${stage.name}') & 0x7fffffff;
  }

  // ── Sync pass ──────────────────────────────────────────────────────────────

  Future<void> _doResync(List<MealSchedule> schedules) async {
    try {
      ensureTimeZonesInitialized();
      final prefs = await SharedPreferences.getInstance();
      final previousIds = (prefs.getStringList(_kScheduledIdsKey) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toList();

      // Master push toggle off → fully blocked: tear everything down, no
      // system notifications and no feed entries.
      final pushEnabled = prefs.getBool(_kPushSettingKey) ?? true;
      if (!pushEnabled) {
        await _cancelIds(previousIds);
        await prefs.remove(_kScheduledIdsKey);
        return;
      }

      final location = tz.getLocation(_campusTimeZone);
      final now = tz.TZDateTime.from(_now(), location);

      // Partition stage reminders into future ones (to schedule) and
      // past-due ones (to deliver into the feed). Every non-future reminder
      // goes to the feed regardless of whether its own slot has since fully
      // closed — the real system notification already fired independently
      // via a native alarm at its scheduled instant, so a slot-still-open
      // gate here only meant the in-app history silently disagreed with what
      // the user actually received (e.g. jumping/resuming past dinner's
      // close made breakfast and lunch's already-fired reminders vanish from
      // the feed, leaving only dinner). The per-item delivered-ID ledger
      // (see _deliverPastDueToFeed) is what prevents duplicate spam, not
      // this partition — so nothing is lost here by dropping that gate.
      final candidates = <_ReminderCandidate>[];
      final pastDue = <_ReminderCandidate>[];
      final seenIds = <int>{};
      for (final schedule in schedules) {
        for (final entry in schedule.meals) {
          // Only a still-attending slot has anything to remind about.
          if (entry.status != MealStatus.scheduled) continue;
          for (final stage in MealReminderStage.values) {
            final reminderAt = _reminderAt(entry, stage, location);
            final id = notificationIdFor(entry, stage);
            if (!seenIds.add(id)) continue;
            final candidate = _ReminderCandidate(
              id: id,
              entry: entry,
              stage: stage,
              reminderAt: reminderAt,
            );
            if (reminderAt.isAfter(now)) {
              candidates.add(candidate);
            } else {
              pastDue.add(candidate);
            }
          }
        }
      }
      candidates.sort((a, b) => a.reminderAt.compareTo(b.reminderAt));
      final toSchedule = candidates.take(maxScheduledReminders).toList();

      final l10n = _localizations(prefs);

      // Feed delivery happens in BOTH banner mode and mute mode — a muted
      // category still records reminders silently, like a kept subscription.
      await _deliverPastDueToFeed(pastDue, prefs, l10n);

      // Meal Pass toggle off = mute mode: no system notifications at all.
      final mealsEnabled = prefs.getBool(_kMealsToggleKey) ?? true;
      if (!mealsEnabled) {
        await _cancelIds(previousIds);
        await prefs.setStringList(_kScheduledIdsKey, const []);
        return;
      }

      // Cancel reminders whose slots were cancelled or fell off the window.
      final newIds = toSchedule.map((c) => c.id).toSet();
      await _cancelIds(
        previousIds.where((id) => !newIds.contains(id)).toList(),
      );

      // Schedule (same-ID schedules atomically replace pending ones, so
      // re-syncing an unchanged slot never duplicates its reminder).
      final scheduledIds = <String>[];
      for (final candidate in toSchedule) {
        try {
          await _notifications.scheduleNotification(
            id: candidate.id,
            title: _titleFor(candidate.entry.slot, l10n),
            body: _bodyFor(candidate, l10n),
            scheduledAt: candidate.reminderAt,
            channelId: NotificationChannels.meals,
            channelName: 'Meals',
            payload: _svcDashboardPath,
          );
          scheduledIds.add('${candidate.id}');
        } catch (e) {
          debugPrint('MealReminderScheduler: schedule failed for '
              '${candidate.entry.slot.name}: $e');
        }
      }

      await prefs.setStringList(_kScheduledIdsKey, scheduledIds);

      if (kDebugMode) {
        debugPrint('MealReminderScheduler: ${scheduledIds.length} '
            'reminder(s) scheduled, ${pastDue.length} past-due → feed '
            '(next: ${toSchedule.isEmpty ? 'none' : toSchedule.first.reminderAt})');
      }
    } catch (e) {
      debugPrint('MealReminderScheduler.resync failed: $e');
    }
  }

  /// Writes past-due reminders into the in-app notifications feed.
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
      final feedId = 'meal_reminder_${candidate.id}';
      if (deliveredSet.contains(feedId)) continue;
      try {
        await _storage.add(NotificationItem(
          id: feedId,
          title: _titleFor(candidate.entry.slot, l10n),
          message: _bodyFor(candidate, l10n),
          category: NotificationCategory.svc,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            candidate.reminderAt.millisecondsSinceEpoch,
          ),
          actionRoute: _svcDashboardPath,
        ));
        updated.add(feedId);
      } catch (e) {
        debugPrint('MealReminderScheduler: feed delivery failed for '
            '${candidate.entry.slot.name}: $e');
      }
    }

    final capped = updated.length > _maxDeliveredIds
        ? updated.sublist(updated.length - _maxDeliveredIds)
        : updated;
    await prefs.setStringList(_kDeliveredIdsKey, capped);
  }

  String _titleFor(MealSlot slot, AppLocalizations l10n) => switch (slot) {
        MealSlot.breakfast => l10n.svc_reminderBreakfast,
        MealSlot.lunch => l10n.svc_reminderLunch,
        MealSlot.dinner => l10n.svc_reminderDinner,
      };

  String _mealNameFor(MealSlot slot, AppLocalizations l10n) => switch (slot) {
        MealSlot.breakfast => l10n.svc_breakfast,
        MealSlot.lunch => l10n.svc_lunch,
        MealSlot.dinner => l10n.svc_dinner,
      };

  String _bodyFor(_ReminderCandidate candidate, AppLocalizations l10n) {
    final mealName = _mealNameFor(candidate.entry.slot, l10n);
    return switch (candidate.stage) {
      MealReminderStage.opens => l10n.svc_meal_reminder_open(mealName),
      MealReminderStage.closingSoon => l10n.svc_meal_reminder_closing(mealName),
    };
  }

  Future<void> _cancelIds(List<int> ids) async {
    for (final id in ids) {
      try {
        await _notifications.cancelNotification(id);
      } catch (e) {
        debugPrint('MealReminderScheduler: cancel($id) failed: $e');
      }
    }
  }

  // ── Time math ──────────────────────────────────────────────────────────────

  // Built directly from raw components rather than going through
  // MealSlot.startDateTime/endDateTime (a *local* DateTime) — converting a
  // local DateTime into a tz.TZDateTime via .from() reads the host machine's
  // real timezone offset, which would make this depend on where the app
  // happens to be running. Constructing the TZDateTime directly from
  // date/hour/minute keeps it purely a function of [location], exactly like
  // EventReminderScheduler does.
  tz.TZDateTime _slotStart(MealEntry entry, tz.Location location) {
    final (h, m) = entry.slot.startTime;
    return tz.TZDateTime(location, entry.date.year, entry.date.month, entry.date.day, h, m);
  }

  // Dinner's endTime is (0, 0) — midnight of the *next* day, not the start
  // of entry.date. Roll it forward the same way MealSlot.endDateTime does.
  tz.TZDateTime _slotEnd(MealEntry entry, tz.Location location) {
    final (h, m) = entry.slot.endTime;
    final end = tz.TZDateTime(location, entry.date.year, entry.date.month, entry.date.day, h, m);
    return (h == 0 && m == 0) ? end.add(const Duration(days: 1)) : end;
  }

  tz.TZDateTime _reminderAt(MealEntry entry, MealReminderStage stage, tz.Location location) {
    return switch (stage) {
      MealReminderStage.opens => _slotStart(entry, location).add(_opensLead),
      MealReminderStage.closingSoon => _slotEnd(entry, location).subtract(_closingLead),
    };
  }

  // ── Localization ───────────────────────────────────────────────────────────

  /// Resolves strings in the user's saved app locale. Notification text is
  /// baked at scheduling time, so a locale switch takes effect on the next
  /// resync — an acceptable trade-off for local scheduling.
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
    required this.entry,
    required this.stage,
    required this.reminderAt,
  });

  final int id;
  final MealEntry entry;
  final MealReminderStage stage;
  final tz.TZDateTime reminderAt;
}
