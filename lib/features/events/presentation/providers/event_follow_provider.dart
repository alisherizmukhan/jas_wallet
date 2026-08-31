import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/event_follow_store.dart';
import '../../domain/entities/event.dart';

final eventFollowStoreProvider = Provider<EventFollowStore>(
  (ref) => EventFollowStore(),
);

class EventFollowNotifier extends StateNotifier<Set<String>> {
  EventFollowNotifier(this._store) : super(const {}) {
    _init();
  }

  final EventFollowStore _store;

  Future<void> _init() async {
    final loaded = await _store.load();
    if (!mounted) return;
    state = loaded;
  }

  bool isFollowed(NuEvent event) => state.contains(event.reminderKey);

  /// Persists first, then updates UI state so [EventReminderScheduler]
  /// (which reads SharedPreferences) sees the new set on the subsequent
  /// resync triggered by this state change.
  Future<bool> toggle(NuEvent event) async {
    final result = await _store.toggle(event);
    if (!mounted) return result.followed;
    state = result.keys;
    return result.followed;
  }
}

final eventFollowProvider =
    StateNotifierProvider<EventFollowNotifier, Set<String>>(
  (ref) => EventFollowNotifier(ref.watch(eventFollowStoreProvider)),
);
