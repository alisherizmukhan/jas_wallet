import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_repository_provider.dart';
import '../data/repositories/skills_repository_impl.dart';
import '../domain/entities/skill_entity.dart';

/// Provider for skills repository. Typed to the concrete impl (rather than
/// the domain interface) so [SkillsListNotifier] can reach the cache-only
/// [SkillsRepositoryImpl.getCachedEntry] SWR helper.
final skillsRepositoryProvider = Provider<SkillsRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SkillsRepositoryImpl(apiClient: apiClient);
});

/// Provider for user's skills list
final skillsListProvider = StateNotifierProvider<SkillsListNotifier, AsyncValue<List<SkillEntity>>>((ref) {
  return SkillsListNotifier(ref.watch(skillsRepositoryProvider));
});

/// Provider for other user's skills list
final userSkillsProvider = FutureProvider.autoDispose.family<List<SkillEntity>, String>((ref, userId) async {
  final repository = ref.watch(skillsRepositoryProvider);
  return repository.getSkillsByUserId(userId);
});

class SkillsListNotifier extends StateNotifier<AsyncValue<List<SkillEntity>>> {
  SkillsListNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadData();
  }

  final SkillsRepositoryImpl _repository;

  /// Cancels the previous [refresh] call's request when a new one
  /// supersedes it (e.g. rapid retry-button taps) — otherwise both requests
  /// complete independently and whichever response arrives last silently
  /// wins, regardless of which tap came first.
  CancelToken? _refreshCancelToken;

  @override
  void dispose() {
    _refreshCancelToken?.cancel('SkillsListNotifier disposed');
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
      final data = await _repository.getUserSkills();
      if (mounted) state = AsyncValue.data(data);
    } catch (e, st) {
      if (cached == null && mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Reload from API (pull-to-refresh, retry after error).
  Future<void> refresh() async {
    _refreshCancelToken?.cancel('superseded by a newer refresh() call');
    final cancelToken = CancelToken();
    _refreshCancelToken = cancelToken;

    state = const AsyncValue.loading();
    try {
      final data = await _repository.getUserSkills(cancelToken: cancelToken);
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (cancelToken.isCancelled) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _reloadFromApiSilently() async {
    try {
      final data = await _repository.getUserSkills();
      state = AsyncValue.data(data);
    } catch (_) {
      // Keep last known list after a successful mutation.
    }
  }

  Future<void> add(SkillEntity skill) async {
    final list = state.valueOrNull;
    if (list == null) return;
    final key = skill.name.trim().toLowerCase();
    if (key.isEmpty) return;
    if (list.any((s) => s.name.trim().toLowerCase() == key)) return;
    state = AsyncValue.data([...list, skill]);
    try {
      await _repository.addSkill(skill);
      await _reloadFromApiSilently();
    } catch (e, st) {
      state = AsyncValue.data(list);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> remove(String id) async {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncValue.data(list.where((s) => s.id != id).toList());
    try {
      await _repository.removeSkill(id);
      await _reloadFromApiSilently();
    } catch (e, st) {
      state = AsyncValue.data(list);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> setSkills(List<SkillEntity> skills) async {
    final prev = state.valueOrNull ?? [];
    state = AsyncValue.data(skills);
    try {
      await _repository.setSkills(skills);
      final data = await _repository.getUserSkills();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.data(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}
