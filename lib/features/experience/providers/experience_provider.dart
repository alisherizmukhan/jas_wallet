import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_repository_provider.dart';
import '../data/repositories/experience_repository_impl.dart';
import '../domain/entities/experience_entity.dart';

/// Provider for experience repository. Typed to the concrete impl (rather
/// than the domain interface) so [ExperienceListNotifier] can reach the
/// cache-only [ExperienceRepositoryImpl.getCachedEntry] SWR helper.
final experienceRepositoryProvider = Provider<ExperienceRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExperienceRepositoryImpl(apiClient: apiClient);
});

/// Provider for user's experience list
final experienceListProvider = StateNotifierProvider<ExperienceListNotifier, AsyncValue<List<ExperienceEntity>>>((ref) {
  return ExperienceListNotifier(ref.watch(experienceRepositoryProvider));
});

/// Provider for other user's experience list
final userExperienceProvider = FutureProvider.family<List<ExperienceEntity>, String>((ref, userId) async {
  final repository = ref.watch(experienceRepositoryProvider);
  return repository.getExperienceByUserId(userId);
});

class ExperienceListNotifier extends StateNotifier<AsyncValue<List<ExperienceEntity>>> {
  ExperienceListNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadData();
  }

  final ExperienceRepositoryImpl _repository;

  /// Cancels the previous [refresh] call's request when a new one
  /// supersedes it (e.g. rapid retry-button taps) — otherwise both requests
  /// complete independently and whichever response arrives last silently
  /// wins, regardless of which tap came first.
  CancelToken? _refreshCancelToken;

  @override
  void dispose() {
    _refreshCancelToken?.cancel('ExperienceListNotifier disposed');
    super.dispose();
  }

  /// Stale-while-revalidate initial load: fresh cache skips the network
  /// call entirely; stale/missing cache paints instantly then revalidates
  /// in the background — cuts redundant `/profile-resume` calls on repeat
  /// profile-tab visits.
  Future<void> _loadData() async {
    final cached = await _repository.getCachedEntry();
    if (cached != null && mounted) {
      state = AsyncValue.data(cached.items);
      if (cached.isFresh) return;
    }
    try {
      final data = await _repository.getExperienceList();
      if (mounted) state = AsyncValue.data(data);
    } catch (e, st) {
      if (cached == null && mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _refreshCancelToken?.cancel('superseded by a newer refresh() call');
    final cancelToken = CancelToken();
    _refreshCancelToken = cancelToken;

    state = const AsyncValue.loading();
    try {
      final data = await _repository.getExperienceList(cancelToken: cancelToken);
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (cancelToken.isCancelled) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _syncListAfterMutation() async {
    try {
      final data = await _repository.getExperienceList();
      state = AsyncValue.data(data);
    } catch (_) {
      // Keep optimistic state from the successful mutation.
    }
  }

  Future<void> add(ExperienceEntity experience) async {
    final prev = state.valueOrNull ?? [];
    state = AsyncValue.data([...prev, experience]);
    try {
      await _repository.addExperience(experience);
      await _syncListAfterMutation();
    } catch (e, st) {
      state = AsyncValue.data(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> update(ExperienceEntity experience) async {
    final prev = state.valueOrNull ?? [];
    state = AsyncValue.data(
      prev.map((e) => e.id == experience.id ? experience : e).toList(),
    );
    try {
      await _repository.updateExperience(experience);
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
      await _repository.deleteExperience(id);
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
