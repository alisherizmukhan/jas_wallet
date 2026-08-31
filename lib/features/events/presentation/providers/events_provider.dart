import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/home_cache_service.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../notifications/presentation/providers/notification_provider.dart'
    show notificationSettingsProvider;
import '../../data/event_reminder_scheduler.dart';
import '../../data/events_service.dart';
import '../../domain/entities/event.dart';
import 'event_follow_provider.dart';

// ─── Testable service providers ───────────────────────────────────────────────

final eventsServiceProvider = Provider<EventsService>(
  (ref) => EventsService.instance,
);

final eventReminderSchedulerProvider = Provider<EventReminderScheduler>(
  (ref) => EventReminderScheduler(
    notifications: LocalNotificationService.instance,
  ),
);

// ─── State ────────────────────────────────────────────────────────────────────

class EventsListState {
  const EventsListState({
    this.events,
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  final List<NuEvent>? events;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;

  bool get hasData => events != null && events!.isNotEmpty;

  EventsListState copyWith({
    List<NuEvent>? events,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
  }) =>
      EventsListState(
        events: events ?? this.events,
        isInitialLoading: isInitialLoading ?? this.isInitialLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class EventsNotifier extends StateNotifier<EventsListState> {
  EventsNotifier(this._service, this._reminderScheduler)
      : super(const EventsListState()) {
    _init();
  }

  final EventsService _service;
  final EventReminderScheduler _reminderScheduler;
  bool _isFetching = false;
  bool _isLoadingMore = false;

  /// Rebuild the day-before event reminders whenever the list changes
  /// (cache restore, refresh, pagination). Fire-and-forget: scheduling is a
  /// best-effort side effect and never blocks or fails the events flow.
  ///
  /// TODO(student-clubs): when student club events are parsed (planned),
  /// merge them into the list passed here so they get the same reminders.
  void _resyncReminders(List<NuEvent> events) {
    unawaited(_reminderScheduler.resync(events));
  }

  /// Re-runs reminder scheduling against the current list without refetching.
  /// Called when notification settings change so toggling Events (or master
  /// push) takes effect immediately instead of on the next refresh.
  void resyncRemindersNow() {
    if (!mounted) return; // deferred callers may outlive this notifier
    final events = state.events;
    if (events != null) _resyncReminders(events);
  }

  Future<void> _init() async {
    final json = await HomeCacheService.loadEventsJson();
    if (!mounted) return;
    if (json != null) {
      try {
        final list = (jsonDecode(json) as List<dynamic>)
            .map((e) => _fromJson(e as Map<String, dynamic>))
            .toList();
        state = EventsListState(
          events: list,
          isInitialLoading: false,
          hasMore: true,
        );
        _resyncReminders(list);
      } catch (_) {
        // Corrupt cache — ignore and fall back to the network fetch below.
      }
    }

    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final events = await _service.refresh();
      if (!mounted) return;
      await HomeCacheService.saveEventsJson(
        jsonEncode(events.map(_toJson).toList()),
      );
      state = EventsListState(
        events: events,
        isInitialLoading: false,
        hasMore: _service.hasMore,
      );
      _resyncReminders(events);
    } catch (e) {
      if (!mounted) return;
      // No cached data and the network failed: stop the shimmer instead of
      // spinning forever. The section collapses and retries on pull-to-refresh.
      if (!state.hasData) {
        state = state.copyWith(
          events: const <NuEvent>[],
          isInitialLoading: false,
          hasMore: false,
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !state.hasMore) return;
    _isLoadingMore = true;
    state = state.copyWith(isLoadingMore: true);
    try {
      final (all, hasMore) = await _service.fetchNextPage();
      if (!mounted) return;
      state = state.copyWith(
        events: all,
        isLoadingMore: false,
        hasMore: hasMore,
      );
      _resyncReminders(all);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, hasMore: false);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Explicit refresh — called by pull-to-refresh.
  Future<void> refresh() => _fetch();

  // ─── JSON helpers ──────────────────────────────────────────────────────

  static Map<String, dynamic> _toJson(NuEvent e) => {
        'title': e.title,
        'date': e.date,
        'venue': e.venue,
        if (e.time != null) 'time': e.time,
        if (e.imageUrl != null) 'imageUrl': e.imageUrl,
        if (e.link != null) 'link': e.link,
        if (e.category != null) 'category': e.category,
        if (e.audience != null) 'audience': e.audience,
      };

  static NuEvent _fromJson(Map<String, dynamic> j) => NuEvent(
        title: j['title'] as String,
        date: j['date'] as String,
        venue: j['venue'] as String,
        time: j['time'] as String?,
        imageUrl: j['imageUrl'] as String?,
        link: j['link'] as String?,
        category: j['category'] as String?,
        audience: j['audience'] as String?,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final eventsProvider =
    StateNotifierProvider<EventsNotifier, EventsListState>(
  (ref) {
    final notifier = EventsNotifier(
      ref.watch(eventsServiceProvider),
      ref.watch(eventReminderSchedulerProvider),
    );
    // Reschedule reminders as soon as notification settings change (Events
    // toggle → mute/unmute, master push → on/off). Deferred by one event-loop
    // task so the settings notifier finishes persisting to SharedPreferences
    // first (setBool updates the in-memory cache synchronously, and event
    // tasks always run after the pending microtask chain).
    ref.listen(notificationSettingsProvider, (prev, next) {
      Future(() => notifier.resyncRemindersNow());
    });
    // Follow/unfollow must rebuild the pending set immediately — otherwise
    // the user would wait until the next events refresh for the bell tap
    // to take effect.
    ref.listen(eventFollowProvider, (prev, next) {
      Future(() => notifier.resyncRemindersNow());
    });
    return notifier;
  },
);
