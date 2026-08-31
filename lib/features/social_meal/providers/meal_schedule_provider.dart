import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/local_notification_service.dart';
import '../../auth/presentation/providers/auth_repository_provider.dart';
import '../../notifications/presentation/providers/notification_provider.dart'
    show notificationSettingsProvider;
import '../data/meal_reminder_scheduler.dart';
import '../data/repositories/meal_remote_repository_impl.dart';
import '../domain/entities/meal_entry.dart';
import '../domain/entities/meal_schedule.dart';
import '../domain/entities/meal_slot.dart';
import '../domain/entities/meal_streak.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

final mealRemoteRepositoryProvider = Provider<MealRemoteRepositoryImpl>(
  (ref) => MealRemoteRepositoryImpl(apiClient: ref.watch(apiClientProvider)),
);

// ─── Reminders ────────────────────────────────────────────────────────────────

final mealReminderSchedulerProvider = Provider<MealReminderScheduler>(
  (ref) => MealReminderScheduler(notifications: LocalNotificationService.instance),
);

// ─── Today schedule ───────────────────────────────────────────────────────────

class MealScheduleNotifier extends StateNotifier<AsyncValue<MealSchedule>> {
  MealScheduleNotifier(this._repo, this._ref)
      : super(const AsyncValue.loading()) {
    load();
  }

  final MealRemoteRepositoryImpl _repo;
  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final schedule = await _repo.getScheduleForDate(DateTime.now());
      state = AsyncValue.data(schedule);
      unawaited(_resyncReminders());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Cancel today's meal for [slot].
  Future<void> cancelMeal(MealSlot slot) async {
    await cancelMealForDate(DateTime.now(), slot);
  }

  /// Cancel a meal for any [date] and [slot]. Refreshes today's state if
  /// the date is today; invalidates the month and per-date providers.
  Future<void> cancelMealForDate(DateTime date, MealSlot slot) async {
    await _repo.cancelMeal(date, slot);
    _invalidateDate(date);
    if (_isToday(date)) await load();
    unawaited(_resyncReminders());
  }

  /// Mark a meal as received (called after QR scan confirms receipt).
  Future<void> markReceived(DateTime date, MealSlot slot) async {
    await _repo.markAsReceived(date, slot);
    _invalidateDate(date);
    if (_isToday(date)) await load();
    unawaited(_resyncReminders());
  }

  /// Undo a cancellation for any [date] and [slot].
  Future<void> undoCancelForDate(DateTime date, MealSlot slot) async {
    await _repo.undoCancellation(date, slot);
    _invalidateDate(date);
    if (_isToday(date)) await load();
    unawaited(_resyncReminders());
  }

  void _invalidateDate(DateTime date) {
    final month = DateTime(date.year, date.month);
    _ref.invalidate(mealMonthScheduleProvider(month));
    _ref.invalidate(mealScheduleForDateProvider(date));
    _ref.invalidate(mealHistoryProvider);
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// Rebuilds meal reminders from a short forward window (today + 6 days).
  /// Fire-and-forget: scheduling is a best-effort side effect and never
  /// blocks or fails the meal flow.
  Future<void> _resyncReminders() async {
    try {
      final today = DateTime.now();
      final schedules = await _repo.getSchedulesForRange(
        today,
        today.add(const Duration(days: 6)),
      );
      await _ref.read(mealReminderSchedulerProvider).resync(schedules);
    } catch (_) {
      // Best-effort — a reminder-sync failure must never surface here.
    }
  }

  /// Re-runs reminder scheduling against the current window without
  /// refetching today's schedule. Called when notification settings change
  /// so toggling Meal Pass (or master push) takes effect immediately.
  void resyncRemindersNow() {
    if (!mounted) return; // deferred callers may outlive this notifier
    unawaited(_resyncReminders());
  }
}

final mealScheduleProvider =
    StateNotifierProvider<MealScheduleNotifier, AsyncValue<MealSchedule>>(
  (ref) {
    final notifier = MealScheduleNotifier(ref.read(mealRemoteRepositoryProvider), ref);
    // Reschedule reminders as soon as notification settings change (Meal
    // Pass toggle → mute/unmute, master push → on/off). Deferred by one
    // event-loop task so the settings notifier finishes persisting to
    // SharedPreferences first.
    ref.listen(notificationSettingsProvider, (prev, next) {
      Future(() => notifier.resyncRemindersNow());
    });
    return notifier;
  },
);

// ─── Per-date schedule (for day detail sheet and calendar) ───────────────────

final mealScheduleForDateProvider =
    FutureProvider.autoDispose.family<MealSchedule, DateTime>((ref, date) async {
  final repo = ref.read(mealRemoteRepositoryProvider);
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel('mealScheduleForDateProvider disposed'));
  return repo.getScheduleForDate(date, cancelToken: cancelToken);
});

// ─── Month schedule (for calendar) ───────────────────────────────────────────

final mealMonthScheduleProvider =
    FutureProvider.autoDispose.family<List<MealSchedule>, DateTime>((ref, month) async {
  final repo = ref.read(mealRemoteRepositoryProvider);
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel('mealMonthScheduleProvider disposed'));
  return repo.getMonthSchedule(month, cancelToken: cancelToken);
});

// ─── History (simple — used for calendar invalidation) ───────────────────────

final mealHistoryProvider = FutureProvider<List<MealSchedule>>((ref) async {
  final repo = ref.read(mealRemoteRepositoryProvider);
  return repo.getHistory(limit: 60);
});

// ─── Paginated History ────────────────────────────────────────────────────────

class MealHistoryState {
  const MealHistoryState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.daysLoaded,
    this.error,
  });

  const MealHistoryState.initial()
      : items = const [],
        isLoading = true,
        isLoadingMore = false,
        hasMore = true,
        daysLoaded = 0,
        error = null;

  final List<MealSchedule> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int daysLoaded;
  final Object? error;

  MealHistoryState copyWith({
    List<MealSchedule>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? daysLoaded,
    Object? error,
    bool clearError = false,
  }) {
    return MealHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      daysLoaded: daysLoaded ?? this.daysLoaded,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MealHistoryNotifier extends StateNotifier<MealHistoryState> {
  MealHistoryNotifier(this._repo) : super(const MealHistoryState.initial()) {
    _loadInitial();
  }

  static const _pageSize = 5;
  final MealRemoteRepositoryImpl _repo;

  Future<void> _loadInitial() async {
    try {
      final schedules = await _repo.getHistory(limit: _pageSize);
      final past = _filterAndSort(schedules);
      state = MealHistoryState(
        items: past,
        isLoading: false,
        isLoadingMore: false,
        hasMore: past.length >= _pageSize,
        daysLoaded: _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() async {
    state = const MealHistoryState.initial();
    await _loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final today = DateTime.now();
      final rangeEnd =
          today.subtract(Duration(days: state.daysLoaded));
      final rangeStart =
          today.subtract(Duration(days: state.daysLoaded + _pageSize - 1));
      final schedules = await _repo.getSchedulesForRange(rangeStart, rangeEnd);
      final past = _filterAndSort(schedules);
      state = state.copyWith(
        items: [...state.items, ...past],
        isLoadingMore: false,
        hasMore: past.length >= _pageSize,
        daysLoaded: state.daysLoaded + _pageSize,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  static List<MealSchedule> _filterAndSort(List<MealSchedule> schedules) {
    return schedules
        .where((s) => s.meals.any((m) => m.isPast))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}

/// autoDispose: the paged notifier accumulates every page the user scrolls
/// through, so it must be torn down when the history page closes — otherwise
/// reopening it resumes at whatever depth (e.g. 200 days) was last scrolled
/// to instead of starting fresh at the first page.
final mealHistoryPagedProvider =
    StateNotifierProvider.autoDispose<MealHistoryNotifier, MealHistoryState>(
  (ref) => MealHistoryNotifier(ref.read(mealRemoteRepositoryProvider)),
);

// ─── Streak ──────────────────────────────────────────────────────────────────

class MealStreakNotifier extends StateNotifier<AsyncValue<MealStreak>> {
  MealStreakNotifier(this._repo)
      : super(const AsyncValue.loading()) {
    load();
  }

  final MealRemoteRepositoryImpl _repo;

  Future<void> load({bool full = false}) async {
    if (full) {
      state = const AsyncValue.loading();
    } else {
      final cached = await _repo.getCachedStreak();
      if (state is! AsyncData) {
        state = AsyncValue.data(cached);
      }
    }
    try {
      final streak = await _repo.computeStreak();

      state = AsyncValue.data(streak);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

}

final mealStreakProvider =
    StateNotifierProvider<MealStreakNotifier, AsyncValue<MealStreak>>(
  (ref) => MealStreakNotifier(ref.read(mealRemoteRepositoryProvider)),
);

// ─── Convenience derived providers ───────────────────────────────────────────

/// Today's per-slot status map (fast read from watched today schedule).
final todayMealStatusProvider = Provider<Map<MealSlot, MealStatus>>((ref) {
  final scheduleAsync = ref.watch(mealScheduleProvider);
  return scheduleAsync.whenOrNull(
        data: (s) => {
          MealSlot.breakfast: s.breakfast.status,
          MealSlot.lunch: s.lunch.status,
          MealSlot.dinner: s.dinner.status,
        },
      ) ??
      {};
});
