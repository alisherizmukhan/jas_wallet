import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_client.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/meal_schedule.dart';
import '../../domain/entities/meal_slot.dart';
import '../../domain/entities/meal_streak.dart';

/// Backend-backed implementation of the social meal schedule / streak /
/// leaderboard. Mirrors the public surface of the old local repository so the
/// providers and UI stay unchanged, but every value is now synced with the
/// server (`/api/v1/social-meals/...`).
class MealRemoteRepositoryImpl {
  MealRemoteRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static MealSlot _slotFromApi(String value) =>
      MealSlot.values.firstWhere((s) => s.name == value,
          orElse: () => MealSlot.lunch);

  static MealStatus _statusFromApi(String value) => switch (value) {
        'received' => MealStatus.received,
        'cancelled' => MealStatus.cancelled,
        'no_show' => MealStatus.noShow,
        _ => MealStatus.scheduled,
      };

  static DateTime? _parseDateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  MealSchedule _scheduleFromJson(Map<String, dynamic> json) {
    final date = _dateOnly(DateTime.parse(json['meal_date'] as String));
    final slotsJson = (json['slots'] as List<dynamic>? ?? const []);

    final bySlot = <MealSlot, MealEntry>{};
    for (final raw in slotsJson) {
      final s = raw as Map<String, dynamic>;
      final slot = _slotFromApi(s['slot'] as String);
      bySlot[slot] = MealEntry(
        id: MealEntry.makeId(date, slot),
        date: date,
        slot: slot,
        status: _statusFromApi(s['status'] as String? ?? 'scheduled'),
        cancelledAt: _parseDateTime(s['cancelled_at']),
        receivedAt: _parseDateTime(s['received_at']),
      );
    }

    // Guarantee all three slots exist even if the backend omitted one.
    final meals = MealSlot.values
        .map((slot) =>
            bySlot[slot] ??
            MealEntry(
              id: MealEntry.makeId(date, slot),
              date: date,
              slot: slot,
              status: MealStatus.scheduled,
            ))
        .toList();

    return MealSchedule(date: date, meals: meals);
  }

  Exception _mapError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return Exception(detail);
      }
    }
    return Exception('Could not reach the social meal service. Please try again.');
  }

  // ─── Schedule reads ───────────────────────────────────────────────────────────

  /// [cancelToken] lets a caller (e.g. the autoDispose family provider this
  /// backs) abandon this request when the calendar/day-sheet widget that
  /// wanted it is torn down before the response arrives.
  Future<MealSchedule> getScheduleForDate(DateTime date, {CancelToken? cancelToken}) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/social-meals/schedule',
        queryParameters: {'date': _fmtDate(date)},
        cancelToken: cancelToken,
      );
      return _scheduleFromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// See [getScheduleForDate] for [cancelToken] semantics.
  Future<List<MealSchedule>> getMonthSchedule(DateTime month, {CancelToken? cancelToken}) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/social-meals/schedule/month',
        queryParameters: {'year': month.year, 'month': month.month},
        cancelToken: cancelToken,
      );
      final days = (response.data?['days'] as List<dynamic>? ?? const []);
      return days
          .map((d) => _scheduleFromJson(d as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<MealSchedule>> getSchedulesForRange(
    DateTime start,
    DateTime end,
  ) async {
    // Fetch the months spanning the range and clip to [start, end].
    final startDate = _dateOnly(start);
    final endDate = _dateOnly(end);
    final seen = <String>{};
    final result = <MealSchedule>[];

    var cursor = DateTime(startDate.year, startDate.month);
    final lastMonth = DateTime(endDate.year, endDate.month);
    while (!cursor.isAfter(lastMonth)) {
      final monthSchedules = await getMonthSchedule(cursor);
      for (final s in monthSchedules) {
        if (!s.date.isBefore(startDate) &&
            !s.date.isAfter(endDate) &&
            seen.add(_fmtDate(s.date))) {
          result.add(s);
        }
      }
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  Future<List<MealSchedule>> getHistory({int limit = 30}) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/social-meals/history',
        queryParameters: {'limit': limit},
      );
      final days = (response.data?['days'] as List<dynamic>? ?? const []);
      return days
          .map((d) => _scheduleFromJson(d as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── Mutations ──────────────────────────────────────────────────────────────

  Future<MealEntry> cancelMeal(DateTime date, MealSlot slot) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/social-meals/cancel',
        data: {'meal_date': _fmtDate(date), 'slot': slot.name},
      );
      final schedule = _scheduleFromJson(response.data!);
      return schedule.entryFor(slot);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<MealEntry> undoCancellation(DateTime date, MealSlot slot) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/social-meals/cancel/undo',
        data: {'meal_date': _fmtDate(date), 'slot': slot.name},
      );
      final schedule = _scheduleFromJson(response.data!);
      return schedule.entryFor(slot);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Receipt is recorded server-side by the QR redeem endpoint. Kept for API
  /// compatibility — simply returns the refreshed entry.
  Future<MealEntry> markAsReceived(DateTime date, MealSlot slot) async {
    final schedule = await getScheduleForDate(date);
    return schedule.entryFor(slot);
  }

  // ─── Streak ───────────────────────────────────────────────────────────────────

  static String _streakCurrentKey(String userId) => 'svc2_streak_current_$userId';
  static String _streakBestKey(String userId) => 'svc2_streak_best_$userId';
  static String _milestoneKey(String userId, int days) =>
      'svc2_milestone_${userId}_$days';

  Future<MealStreak> computeStreak({String userId = 'default'}) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/social-meals/streak',
      );
      final data = response.data!;
      final streak = MealStreak(
        currentStreak: data['current_streak'] as int? ?? 0,
        bestStreak: data['best_streak'] as int? ?? 0,
        totalReceived: data['total_received'] as int? ?? 0,
        totalCancelled: data['total_cancelled'] as int? ?? 0,
        totalNoShows: data['total_no_shows'] as int? ?? 0,
        lastActivityDate: _parseDateTime(data['last_activity_date']),
      );
      await _persistStreak(userId, streak.currentStreak, streak.bestStreak);
      return streak;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> _persistStreak(String userId, int current, int best) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_streakCurrentKey(userId), current);
      await prefs.setInt(_streakBestKey(userId), best);
    } catch (_) {}
  }

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

  Future<bool> isMilestoneAwarded(String userId, int days) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_milestoneKey(userId, days)) ?? false;
  }

  Future<void> markMilestoneAwarded(String userId, int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_milestoneKey(userId, days), true);
  }
}
