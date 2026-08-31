import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_repository_provider.dart';
import '../data/repositories/academy_repository_impl.dart';
import '../domain/entities/academy_entity.dart';

/// Provider for academy repository. Typed to the concrete impl (rather than
/// the domain interface) so [AcademyListNotifier] can reach the cache-only
/// [AcademyRepositoryImpl.getCachedEntry] SWR helper.
final academyRepositoryProvider = Provider<AcademyRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AcademyRepositoryImpl(apiClient: apiClient);
});

/// Provider for user's academy/education list
final academyListProvider = StateNotifierProvider<AcademyListNotifier, AsyncValue<List<AcademyEntity>>>((ref) {
  return AcademyListNotifier(ref.watch(academyRepositoryProvider));
});

/// Provider for other user's academy/education list
final userAcademyProvider = FutureProvider.family<List<AcademyEntity>, String>((ref, userId) async {
  final repository = ref.watch(academyRepositoryProvider);
  return repository.getAcademyByUserId(userId);
});

class AcademyListNotifier extends StateNotifier<AsyncValue<List<AcademyEntity>>> {
  AcademyListNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadData();
  }

  final AcademyRepositoryImpl _repository;

  /// Cancels the previous [refresh] call's request when a new one
  /// supersedes it (e.g. rapid retry-button taps) — otherwise both requests
  /// complete independently and whichever response arrives last silently
  /// wins, regardless of which tap came first.
  CancelToken? _refreshCancelToken;

  @override
  void dispose() {
    _refreshCancelToken?.cancel('AcademyListNotifier disposed');
    super.dispose();
  }

  /// Stale-while-revalidate initial load: fresh cache skips the network
  /// call entirely; stale/missing cache paints instantly then revalidates
  /// in the background — same instant-render pattern as [HomeCacheService]
  /// consumers, cutting redundant `/profile-resume` calls on repeat visits.
  Future<void> _loadData() async {
    final cached = await _repository.getCachedEntry();
    if (cached != null && mounted) {
      state = AsyncValue.data(cached.items);
      if (cached.isFresh) return;
    }
    try {
      final data = await _repository.getAcademyList();
      if (mounted) state = AsyncValue.data(data);
    } catch (e, st) {
      if (cached == null && mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Pull latest list from API (e.g. pull-to-refresh). Errors stay on screen.
  Future<void> refresh() async {
    _refreshCancelToken?.cancel('superseded by a newer refresh() call');
    final cancelToken = CancelToken();
    _refreshCancelToken = cancelToken;

    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAcademyList(cancelToken: cancelToken);
      state = AsyncValue.data(data);
    } catch (e, st) {
      // A cancellation means a newer refresh() call already took over —
      // that call owns updating state, so this superseded one stays quiet.
      if (cancelToken.isCancelled) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _syncListAfterMutation() async {
    try {
      final data = await _repository.getAcademyList();
      state = AsyncValue.data(data);
    } catch (_) {
      // Keep optimistic state from the successful mutation.
    }
  }

  Future<void> add(AcademyEntity academy) async {
    final prev = state.valueOrNull ?? [];
    state = AsyncValue.data([...prev, academy]);
    try {
      await _repository.addAcademy(academy);
      await _syncListAfterMutation();
    } catch (e, st) {
      state = AsyncValue.data(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> update(AcademyEntity academy) async {
    final prev = state.valueOrNull ?? [];
    state = AsyncValue.data(
      prev.map((e) => e.id == academy.id ? academy : e).toList(),
    );
    try {
      await _repository.updateAcademy(academy);
      await _syncListAfterMutation();
    } catch (e, st) {
      state = AsyncValue.data(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> remove(String id) async {
    final prev = state.valueOrNull ?? [];
    state = AsyncValue.data(prev.where((e) => e.id != id).toList());
    try {
      await _repository.deleteAcademy(id);
      await _syncListAfterMutation();
    } catch (e, st) {
      state = AsyncValue.data(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}
