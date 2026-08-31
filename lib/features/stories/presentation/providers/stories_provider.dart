import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/home_cache_service.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../data/repositories/story_repository_impl.dart';
import '../../data/story_service.dart';
import '../../domain/entities/story.dart';

final storyRepositoryProvider = Provider<StoryRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StoryRepositoryImpl(apiClient: apiClient);
});

/// Identity of the story viewer, used to scope viewed-markers and to rebuild
/// the story notifiers on a real account switch.
///
/// Sourced from the AUTH session (known before Home ever renders), NOT from
/// the profile fetch: deriving this from `userProvider` made the id flip
/// null → id when `/students/me` resolved after startup, which recreated
/// both story notifiers and double-fetched `/stories/feed` and
/// `/stories/my-organizations` on every cold start.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider.select((a) => a.userId));
});

final storyStorageProvider = Provider<StoryStorageService>((ref) {
  return StoryStorageService.instance;
});

class StoriesNotifier extends StateNotifier<AsyncValue<List<Story>>> {
  StoriesNotifier(
    this._repository,
    this._storage,
    this._viewerId, {
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const AsyncValue.loading()) {
    _load();
  }

  final StoryRepositoryImpl _repository;
  final StoryStorageService _storage;
  final String? _viewerId;
  final DateTime Function() _now;

  // ── Silent refresh (stale-while-revalidate) ─────────────────────────────────
  //
  // Stories are long-lived university announcements, not Instagram stories:
  // most stay unchanged for days and urgent ones are delivered via push.
  // There is therefore NO periodic polling. The network is touched only when
  // the local cache is older than [HomeCacheService.storiesTtl] (checked on
  // load and app resume) or when the user explicitly pulls to refresh.

  bool _isRefreshing = false;
  bool _isAutoChecking = false;

  /// Cancelled and replaced on every new [refresh] call, and cancelled in
  /// [dispose] — so a request nobody will read (superseded by a newer
  /// refresh, or the notifier torn down mid-flight) doesn't run to
  /// completion for no reason.
  CancelToken? _refreshCancelToken;

  @override
  void dispose() {
    _refreshCancelToken?.cancel('StoriesNotifier disposed');
    super.dispose();
  }

  /// When the feed was last confirmed against the backend (fetch completed
  /// or a fresh persistent cache was restored). Gates the silent checks.
  DateTime? _lastSyncedAt;

  bool get _isCacheFresh {
    final syncedAt = _lastSyncedAt;
    if (syncedAt == null) return false;
    return _now().difference(syncedAt) <= HomeCacheService.storiesTtl;
  }

  /// Triggers a background check when the cached feed has expired.
  /// Safe to call on app resume or tab focus — a no-op while data is fresh,
  /// so it costs nothing on ordinary Home visits.
  void checkForUpdates() => unawaited(_autoCheck());

  /// Silently refreshes stories from the backend when the cache is stale.
  /// Updates state only when content has changed; no loading indicator.
  Future<void> _autoCheck() async {
    if (_isRefreshing || _isAutoChecking) return;
    if (_isCacheFresh) return;

    // Skip when the app is not visible.
    final lifecycle = _currentLifecycleState();
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;

    _isAutoChecking = true;
    try {
      final incoming = await _repository.getFeed();
      if (!mounted) return;
      _lastSyncedAt = _now();
      await HomeCacheService.saveStoriesJson(Story.encodeList(incoming));
      if (!mounted) return;
      if (_hasNewContent(incoming)) {
        state = AsyncValue.data(incoming);
      }
    } catch (_) {
      // Silent failure — keep current data intact.
    } finally {
      _isAutoChecking = false;
    }
  }

  /// Returns true when [incoming] contains stories not present in the current
  /// state, or when the story count has changed.
  @visibleForTesting
  bool hasNewContent(List<Story> incoming) => _hasNewContent(incoming);

  bool _hasNewContent(List<Story> incoming) {
    final current = state.valueOrNull;
    if (current == null) return incoming.isNotEmpty;
    if (incoming.length != current.length) return true;
    final currentIds = {for (final s in current) s.id};
    return incoming.any((s) => !currentIds.contains(s.id));
  }

  AppLifecycleState? _currentLifecycleState() {
    try {
      return WidgetsBinding.instance.lifecycleState;
    } catch (_) {
      return null;
    }
  }

  // ── Core methods ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    await _storage.init(viewerId: _viewerId);

    // Load from persistent cache for instant UI render — stale entries
    // included, so opening Home never blocks on the network (offline too).
    var cacheIsFresh = false;
    final cached = await HomeCacheService.loadStoriesEntry();
    if (!mounted) return;
    if (cached != null) {
      try {
        final stories = Story.decodeList(cached.json)
            .where((s) => !s.isExpired)
            .toList(growable: false);
        if (stories.isNotEmpty) {
          state = AsyncValue.data(stories);
          cacheIsFresh = cached.isFresh;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    if (cacheIsFresh) {
      // Within TTL — no network on this launch. Urgent announcements arrive
      // via push; the user can always pull to refresh.
      _lastSyncedAt = _now();
      return;
    }

    // No cache or expired cache: silent background refresh — no spinner
    // when (stale) cache is already on screen.
    unawaited(refresh(showLoading: state.valueOrNull == null));
  }

  Future<void> refresh({bool showLoading = true}) async {
    // A new refresh supersedes any still-in-flight one — cancel it rather
    // than let two responses race to write `state`.
    _refreshCancelToken?.cancel('superseded by a newer refresh() call');
    final cancelToken = CancelToken();
    _refreshCancelToken = cancelToken;

    _isRefreshing = true;
    final previous = state.valueOrNull;
    if (showLoading || previous == null) {
      state = const AsyncValue.loading();
    }
    try {
      final data = await _repository.getFeed(cancelToken: cancelToken);
      if (!mounted || cancelToken.isCancelled) return;
      _lastSyncedAt = _now();
      await HomeCacheService.saveStoriesJson(Story.encodeList(data));
      if (!mounted) return;
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (!mounted || e is DioException && e.type == DioExceptionType.cancel) {
        // Deliberately abandoned (disposed or superseded) — not a real
        // failure, so no error state to show anyone.
        return;
      }
      if (previous != null && !showLoading) {
        state = AsyncValue.data(previous);
      } else {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> createStory({
    required String organizationId,
    required String filePath,
    void Function(double? progress)? onProgress,
  }) async {
    final prev = state.valueOrNull ?? const <Story>[];
    final created = await _repository.createStory(
      organizationId: organizationId,
      filePath: filePath,
      onProgress: onProgress,
    );
    final next = [created, ...prev];
    state = AsyncValue.data(next);
    // Keep the persistent cache in sync so a restart within the TTL
    // window still shows the just-published story.
    unawaited(HomeCacheService.saveStoriesJson(Story.encodeList(next)));
  }

  Future<void> deleteStory(String storyId) async {
    await _repository.deleteStory(storyId);
    await _storage.removeViewed(storyId);
    final prev = state.valueOrNull ?? const <Story>[];
    final next = prev.where((s) => s.id != storyId).toList();
    state = AsyncValue.data(next);
    unawaited(HomeCacheService.saveStoriesJson(Story.encodeList(next)));
  }

  Future<void> markViewed(String storyId) async {
    await _storage.markViewed(storyId);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(List<Story>.from(current));
    }
  }

  bool isViewed(String storyId) => _storage.isViewed(storyId);

  bool areAllViewed(String authorId, List<Story> stories) {
    return _storage.areAllViewed(authorId, stories);
  }

  int getFirstUnviewedIndex(String authorId, List<Story> stories) {
    return _storage.getFirstUnviewedIndex(authorId, stories);
  }
}

final storiesProvider =
    StateNotifierProvider<StoriesNotifier, AsyncValue<List<Story>>>((ref) {
      final repository = ref.watch(storyRepositoryProvider);
      final storage = ref.watch(storyStorageProvider);
      final viewerId = ref.watch(currentUserIdProvider);
      return StoriesNotifier(repository, storage, viewerId);
    });

class StoryOrganizationsNotifier
    extends StateNotifier<AsyncValue<List<StoryPublisherOrganization>>> {
  StoryOrganizationsNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final StoryRepositoryImpl _repository;

  /// Stale-while-revalidate: publisher membership changes rarely, so the
  /// cached list renders instantly and the network is only touched when the
  /// 24 h TTL has lapsed (or on pull-to-refresh via [refresh]).
  Future<void> _load() async {
    final cached = await HomeCacheService.loadStoryOrgsEntry();
    if (!mounted) return;
    if (cached != null) {
      try {
        state = AsyncValue.data(
          StoryPublisherOrganization.decodeList(cached.json),
        );
        if (cached.isFresh) return;
      } catch (_) {}
    }
    unawaited(refresh(showLoading: state.valueOrNull == null));
  }

  Future<void> refresh({bool showLoading = true}) async {
    final previous = state.valueOrNull;
    if (showLoading || previous == null) {
      state = const AsyncValue.loading();
    }
    try {
      final data = await _repository.getMyOrganizations();
      await HomeCacheService.saveStoryOrgsJson(
        StoryPublisherOrganization.encodeList(data),
      );
      if (!mounted) return;
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (!mounted) return;
      if (previous != null && !showLoading) {
        state = AsyncValue.data(previous);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final storyOrganizationsProvider = StateNotifierProvider<
  StoryOrganizationsNotifier,
  AsyncValue<List<StoryPublisherOrganization>>
>((ref) {
  ref.watch(currentUserIdProvider);
  return StoryOrganizationsNotifier(ref.watch(storyRepositoryProvider));
});

final storyPublisherOrganizationIdsProvider = Provider<Set<String>>((ref) {
  final orgs = ref.watch(storyOrganizationsProvider).valueOrNull ?? const [];
  return orgs.map((e) => e.id).toSet();
});

final storyCanPublishProvider = Provider<bool>((ref) {
  final orgs = ref.watch(storyOrganizationsProvider).valueOrNull ?? const [];
  return orgs.isNotEmpty;
});

final userStoriesProvider = Provider<List<UserStory>>((ref) {
  final stories = ref.watch(storiesProvider).valueOrNull ?? const <Story>[];
  final notifier = ref.read(storiesProvider.notifier);

  final map = <String, List<Story>>{};
  for (final s in stories) {
    if (s.isExpired) continue;
    map.putIfAbsent(s.authorId, () => []).add(s);
  }

  final result = <UserStory>[];
  for (final entry in map.entries) {
    final sorted = List<Story>.of(entry.value)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final first = sorted.first;
    final allViewed = notifier.areAllViewed(entry.key, sorted);
    result.add(
      UserStory(
        userId: entry.key,
        userName: first.authorName,
        userAvatar: first.authorAvatar,
        stories: sorted,
        hasUnviewedStories: !allViewed,
      ),
    );
  }

  result.sort((a, b) {
    if (a.hasUnviewedStories && !b.hasUnviewedStories) return -1;
    if (!a.hasUnviewedStories && b.hasUnviewedStories) return 1;
    return b.stories.last.createdAt.compareTo(a.stories.last.createdAt);
  });

  return result;
});
