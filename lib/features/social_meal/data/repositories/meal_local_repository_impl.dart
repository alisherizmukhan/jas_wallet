import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/meal_schedule.dart';
import '../../domain/entities/meal_slot.dart';
import '../../domain/entities/meal_streak.dart';

/// Local-first implementation of meal scheduling.
///
/// Generates daily meal plans (breakfast/lunch/dinner) automatically.
/// Cancellations and received meals are persisted in SharedPreferences.
/// No-show status is derived at read-time based on the meal time window.
///
/// Keys use the `svc2_` prefix to avoid collision with old svc_ keys.
class MealLocalRepositoryImpl {
  static final MealLocalRepositoryImpl _instance =
      MealLocalRepositoryImpl._internal();

  factory MealLocalRepositoryImpl() => _instance;

  MealLocalRepositoryImpl._internal();

  // ─── SharedPreferences key helpers ──────────────────────────────────────────

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _cancelKey(DateTime d, MealSlot s) =>
      'svc2_cancelled_${_fmtDate(d)}_${s.key}';

  static String _receivedKey(DateTime d, MealSlot s) =>
      'svc2_received_${_fmtDate(d)}_${s.key}';

  static String _streakCurrentKey(String userId) =>
      'svc2_streak_current_$userId';

  static String _streakBestKey(String userId) => 'svc2_streak_best_$userId';

  static String _milestoneKey(String userId, int days) =>
      'svc2_milestone_${userId}_$days';

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  // ─── Schedule generation ─────────────────────────────────────────────────────

  Future<MealEntry> _buildEntry(
    SharedPreferences prefs,
    DateTime date,
    MealSlot slot,
  ) async {
    final d = _dateOnly(date);
    final id = MealEntry.makeId(d, slot);
    final now = DateTime.now();

    // Check cancelled
    final cancelledStr = prefs.getString(_cancelKey(d, slot));
    if (cancelledStr != null) {
      return MealEntry(
        id: id,
        date: d,
        slot: slot,
        status: MealStatus.cancelled,
        cancelledAt: DateTime.tryParse(cancelledStr),
      );
    }

    // Check received
    final receivedStr = prefs.getString(_receivedKey(d, slot));
    if (receivedStr != null) {
      return MealEntry(
        id: id,
        date: d,
        slot: slot,
        status: MealStatus.received,
        receivedAt: DateTime.tryParse(receivedStr),
      );
    }

    // If meal window has passed without any action → no_show
    if (now.isAfter(slot.endDateTime(d))) {
      return MealEntry(
        id: id,
        date: d,
        slot: slot,
        status: MealStatus.noShow,
      );
    }

    // Default: scheduled
    return MealEntry(
      id: id,
      date: d,
      slot: slot,
      status: MealStatus.scheduled,
    );
  }

  // ─── Public schedule API ─────────────────────────────────────────────────────

  Future<MealSchedule> getScheduleForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final d = _dateOnly(date);

    final meals = await Future.wait([
      _buildEntry(prefs, d, MealSlot.breakfast),
      _buildEntry(prefs, d, MealSlot.lunch),
      _buildEntry(prefs, d, MealSlot.dinner),
    ]);

    return MealSchedule(date: d, meals: meals);
  }

  Future<List<MealSchedule>> getSchedulesForRange(
    DateTime start,
    DateTime end,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final schedules = <MealSchedule>[];
    var current = _dateOnly(start);
    final endDate = _dateOnly(end);

    while (!current.isAfter(endDate)) {
      final meals = await Future.wait([
        _buildEntry(prefs, current, MealSlot.breakfast),
        _buildEntry(prefs, current, MealSlot.lunch),
        _buildEntry(prefs, current, MealSlot.dinner),
      ]);
      schedules.add(MealSchedule(date: current, meals: meals));
      current = current.add(const Duration(days: 1));
    }

    return schedules;
  }

  Future<List<MealSchedule>> getMonthSchedule(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return getSchedulesForRange(firstDay, lastDay);
  }

  Future<List<MealSchedule>> getHistory({int limit = 30}) {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: limit - 1));
    return getSchedulesForRange(start, today);
  }

  // ─── Cancellation ────────────────────────────────────────────────────────────

  /// Cancels a meal. Throws if cancellation is past the deadline.
  Future<MealEntry> cancelMeal(DateTime date, MealSlot slot) async {
    final d = _dateOnly(date);
    final entry = MealEntry(
      id: MealEntry.makeId(d, slot),
      date: d,
      slot: slot,
      status: MealStatus.scheduled,
    );

    if (!entry.canCancel) {
      throw Exception('Cancellation window has closed');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cancelKey(d, slot),
      DateTime.now().toIso8601String(),
    );

    return entry.copyWith(
      status: MealStatus.cancelled,
      cancelledAt: DateTime.now(),
    );
  }

  /// Restores a cancelled meal back to scheduled status.
  /// Only allowed while the 24-hour cancellation window is still open.
  Future<MealEntry> undoCancellation(DateTime date, MealSlot slot) async {
    final d = _dateOnly(date);
    final prefs = await SharedPreferences.getInstance();

    final cancelTimestamp = prefs.getString(_cancelKey(d, slot));
    if (cancelTimestamp == null) {
      throw Exception('Meal was not cancelled — cannot undo');
    }

    final cancelledEntry = MealEntry(
      id: MealEntry.makeId(d, slot),
      date: d,
      slot: slot,
      status: MealStatus.cancelled,
      cancelledAt: DateTime.tryParse(cancelTimestamp),
    );

    if (!cancelledEntry.canUndoCancel) {
      throw Exception('Cancellation deadline has passed — cannot undo');
    }

    await prefs.remove(_cancelKey(d, slot));

    return MealEntry(
      id: MealEntry.makeId(d, slot),
      date: d,
      slot: slot,
      status: MealStatus.scheduled,
    );
  }

  // ─── QR / Receive ────────────────────────────────────────────────────────────

  /// Marks the meal for [date] and [slot] as received (called after QR scan).
  Future<MealEntry> markAsReceived(DateTime date, MealSlot slot) async {
    final d = _dateOnly(date);
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(_receivedKey(d, slot), now.toIso8601String());

    return MealEntry(
      id: MealEntry.makeId(d, slot),
      date: d,
      slot: slot,
      status: MealStatus.received,
      receivedAt: now,
    );
  }

  // ─── Streak computation ──────────────────────────────────────────────────────

  /// Computes streak from scratch by iterating backwards through history.
  ///
  /// Rules:
  ///   received meal   → streak increments
  ///   all-cancelled   → streak preserved (no increment, no reset)
  ///   any no_show     → streak resets
  Future<MealStreak> computeStreak({String userId = 'default'}) async {
    final today = _dateOnly(DateTime.now());
    int currentStreak = 0;
    int bestStreak = 0;
    int totalReceived = 0;
    int totalCancelled = 0;
    int totalNoShows = 0;
    bool streakActive = true;
    DateTime? lastActivity;

    // Look at today first (partial day), then go back up to 365 days
    for (int i = 0; i <= 365; i++) {
      final day = today.subtract(Duration(days: i));
      final schedule = await getScheduleForDate(day);

      // Accumulate totals regardless of streak state
      totalReceived += schedule.receivedCount;
      totalCancelled += schedule.cancelledCount;
      totalNoShows += schedule.noShowCount;

      if (!streakActive) continue;

      if (i == 0) {
        // Today: only scheduled/received; future slots aren't no-shows yet
        if (schedule.hasReceived) {
          currentStreak = 1;
          lastActivity = day;
          bestStreak = max(bestStreak, currentStreak);
        }
        continue;
      }

      // Past day — all slots have been resolved
      if (schedule.hasNoShow) {
        // No-show on this day → streak is broken; stop extending backward
        streakActive = false;
      } else if (schedule.hasReceived) {
        currentStreak++;
        lastActivity ??= day;
        bestStreak = max(bestStreak, currentStreak);
      }
      // allCancelled or no meals: no increment, no break → continue
    }

    // Persist for quick-read in providers
    await _persistStreak(userId, currentStreak, bestStreak);

    return MealStreak(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalReceived: totalReceived,
      totalCancelled: totalCancelled,
      totalNoShows: totalNoShows,
      lastActivityDate: lastActivity,
    );
  }

  Future<void> _persistStreak(
      String userId, int current, int best) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_streakCurrentKey(userId), current);
      await prefs.setInt(_streakBestKey(userId), best);
    } catch (_) {}
  }

  /// Returns a quickly cached streak (may lag one update cycle).
  Future<MealStreak> getCachedStreak({String userId = 'default'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_streakCurrentKey(userId)) ?? 0;
      final best = prefs.getInt(_streakBestKey(userId)) ?? 0;
      return MealStreak(
        currentStreak: current,
        bestStreak: best,
        totalReceived: 0,
        totalCancelled: 0,
        totalNoShows: 0,
      );
    } catch (_) {
      return MealStreak.zero;
    }
  }

  // ─── Milestone tracking ──────────────────────────────────────────────────────

  Future<bool> isMilestoneAwarded(String userId, int days) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_milestoneKey(userId, days)) ?? false;
  }

  Future<void> markMilestoneAwarded(String userId, int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_milestoneKey(userId, days), true);
  }
}
