import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_repository_provider.dart';
import '../data/repositories/activity_repository_impl.dart';
import '../domain/entities/user_activity_entity.dart';

/// Singleton repository provider.
final activityRepositoryProvider = Provider<ActivityRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ActivityRepositoryImpl(apiClient: apiClient);
});

/// Current-user profile activities.
///
/// Initialisation strategy:
///   1. Serve cached data immediately (cache-first, no blank flash).
///   2. Fetch fresh list from backend in background; update state on success.
///   3. If backend call fails and no cache exists, state stays empty
///      — the profile completion card shows activity as incomplete.
final userActivityListProvider =
    StateNotifierProvider<UserActivityListNotifier, List<UserActivityEntity>>(
        (ref) {
  final repository = ref.watch(activityRepositoryProvider);
  return UserActivityListNotifier(repository);
});

/// Activities count — used in profile dashboard summary boxes.
final userActivitiesCountProvider = Provider<int>((ref) {
  return ref.watch(userActivityListProvider).length;
});

/// Manages the current user's activity list.
class UserActivityListNotifier
    extends StateNotifier<List<UserActivityEntity>> {
  UserActivityListNotifier(this._repository) : super(const []) {
    _initializeActivities();
  }

  final ActivityRepositoryImpl _repository;
  bool _initialized = false;
  Future<void>? _inFlightInit;

  /// Cancelled and replaced on every [_reloadFromApi] call, and cancelled in
  /// [dispose] — abandons a fetch nobody will read instead of letting it run
  /// to completion.
  CancelToken? _reloadCancelToken;

  /// True while the initial cache+network load has not yet completed.
  /// Profile completion reads this to avoid showing stale 0-activity state.
  bool get isInitializing => !_initialized;

  @override
  void dispose() {
    _reloadCancelToken?.cancel('UserActivityListNotifier disposed');
    super.dispose();
  }

  Future<void> _initializeActivities() async {
    if (_initialized) return;
    if (_inFlightInit != null) return _inFlightInit!;

    _inFlightInit = _doInitialize();
    try {
      await _inFlightInit;
    } finally {
      _inFlightInit = null;
    }
  }

  Future<void> _doInitialize() async {
    // ── Phase 1: serve cached data immediately ─────────────────────────────
    var cacheIsFresh = false;
    try {
      final cached = await _repository.getCachedActivities();
      if (cached.isNotEmpty && mounted) {
        state = cached;
      }
      cacheIsFresh = cached.isNotEmpty && await _repository.isCacheFresh();
    } catch (_) {
      // Cache read failure is non-fatal; proceed to network fetch.
    }

    // Cache is within TTL — skip the network round-trip entirely.
    if (cacheIsFresh) {
      _initialized = true;
      return;
    }

    // ── Phase 2: fetch fresh list from backend ─────────────────────────────
    // Set _initialized BEFORE updating state so that any provider
    // re-run triggered by the state change sees isInitializing == false.
    try {
      final fresh = await _repository.getActivities();
      _initialized = true;
      if (mounted) state = fresh;
    } catch (_) {
      // Network error: keep whatever the cache gave us, but still signal
      // completion so that profile completion doesn't stay in loading state.
      _initialized = true;
      if (mounted) state = List.of(state);
    }
  }

  /// Reload activities from backend (pull-to-refresh, post-add, etc.).
  Future<void> _reloadFromApi() async {
    _reloadCancelToken?.cancel('superseded by a newer reload');
    final cancelToken = CancelToken();
    _reloadCancelToken = cancelToken;
    try {
      final fresh = await _repository.getActivities(cancelToken: cancelToken);
      if (mounted) state = fresh;
    } catch (_) {
      // Keep current state on transient network failure (including a
      // deliberate cancellation — nothing to show for either case).
    }
  }

  /// Add a new activity (optimistic: shows in list immediately, uploads in background).
  Future<void> add(UserActivityEntity activity) async {
    final prev = List<UserActivityEntity>.from(state);
    if (mounted) state = [activity, ...prev];
    try {
      await _repository.addActivity(activity);
      await _reloadFromApi();
    } catch (e, st) {
      if (mounted) state = prev;
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Update an activity (optimistic: reflects change immediately, syncs in background).
  Future<void> update(UserActivityEntity activity) async {
    final prev = List<UserActivityEntity>.from(state);
    if (mounted) {
      state = state.map((a) => a.id == activity.id ? activity : a).toList();
    }
    try {
      await _repository.updateActivity(activity);
      await _reloadFromApi();
    } catch (e, st) {
      if (mounted) state = prev;
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Remove an activity (optimistic: removes from list immediately, deletes in background).
  Future<void> remove(String id) async {
    final prev = List<UserActivityEntity>.from(state);
    if (mounted) state = state.where((a) => a.id != id).toList();
    try {
      await _repository.deleteActivity(id);
      await _reloadFromApi();
    } catch (e, st) {
      if (mounted) state = prev;
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Clear all activities on the server, then reset local state.
  Future<void> clear() async {
    await _repository.clearActivities();
    if (mounted) state = const [];
  }
}
