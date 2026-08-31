import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/api/api_client.dart';
import 'package:jaswallet_app/core/services/home_cache_service.dart';
import 'package:jaswallet_app/features/stories/data/repositories/story_repository_impl.dart';
import 'package:jaswallet_app/features/stories/data/story_service.dart';
import 'package:jaswallet_app/features/stories/domain/entities/story.dart';
import 'package:jaswallet_app/features/stories/presentation/providers/stories_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_storage.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Story _makeStory({
  required String id,
  String authorId = 'org-1',
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.now();
  return Story(
    id: id,
    authorId: authorId,
    authorName: 'Test Org',
    mediaUrl: 'https://example.com/$id.jpg',
    mediaType: StoryMediaType.image,
    createdAt: now,
    expiresAt: now.add(const Duration(days: 7)),
  );
}

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeStoryRepository extends StoryRepositoryImpl {
  _FakeStoryRepository()
      : super(
          apiClient: ApiClient(authStorage: FakeAuthStorageService()),
        );

  List<Story> feedToReturn = [];
  int getFeedCallCount = 0;
  bool throwOnFetch = false;

  @override
  Future<List<Story>> getFeed({CancelToken? cancelToken}) async {
    getFeedCallCount++;
    if (throwOnFetch) throw Exception('network error');
    return List<Story>.from(feedToReturn);
  }
}

/// Movable test clock: advance [_TestClock.current] to step past the
/// stories TTL and unlock the gated background checks.
class _TestClock {
  DateTime current = DateTime(2026, 7, 7, 12);

  void advance(Duration d) => current = current.add(d);
}

StoriesNotifier _makeNotifier(_FakeStoryRepository repo, {_TestClock? clock}) {
  SharedPreferences.setMockInitialValues({});
  return StoriesNotifier(
    repo,
    StoryStorageService.instance,
    null,
    now: clock == null ? null : () => clock.current,
  );
}

/// One tick past the refresh TTL — makes the next checkForUpdates eligible.
final _pastTtl = HomeCacheService.storiesTtl + const Duration(minutes: 1);

// ── hasNewContent ─────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoriesNotifier.hasNewContent', () {
    late _FakeStoryRepository repo;
    late StoriesNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = _FakeStoryRepository();
      notifier = _makeNotifier(repo);
      // Let _load() complete so state is not AsyncLoading.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() => notifier.dispose());

    test('false when incoming matches current stories exactly', () async {
      final story = _makeStory(id: 's-1');
      repo.feedToReturn = [story];
      // Reload so state becomes AsyncData([story]).
      await notifier.refresh(showLoading: false);
      expect(notifier.hasNewContent([story]), isFalse);
    });

    test('true when incoming has an additional story', () async {
      final s1 = _makeStory(id: 's-1');
      final s2 = _makeStory(id: 's-2');
      repo.feedToReturn = [s1];
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.hasNewContent([s1, s2]), isTrue);
    });

    test('true when incoming replaces a story with a different id', () async {
      final s1 = _makeStory(id: 's-1');
      final s2 = _makeStory(id: 's-2');
      repo.feedToReturn = [s1];
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.hasNewContent([s2]), isTrue);
    });

    test('false when incoming is identical (same ids, same count)', () async {
      final s1 = _makeStory(id: 's-1');
      repo.feedToReturn = [s1];
      await notifier.refresh(showLoading: false);

      expect(notifier.hasNewContent([s1]), isFalse);
    });

    test('true when count drops (story expired / deleted on server)', () async {
      final s1 = _makeStory(id: 's-1');
      final s2 = _makeStory(id: 's-2');
      repo.feedToReturn = [s1, s2];
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.hasNewContent([s1]), isTrue);
    });

    test('false when current state has no data yet', () {
      // Brand-new notifier — state = AsyncLoading, valueOrNull == null.
      SharedPreferences.setMockInitialValues({});
      final freshRepo = _FakeStoryRepository()..feedToReturn = [];
      final freshNotifier = StoriesNotifier(
        freshRepo,
        StoryStorageService.instance,
        null,
      );
      addTearDown(freshNotifier.dispose);

      // No data yet — incoming empty means nothing changed.
      expect(freshNotifier.hasNewContent([]), isFalse);
    });

    test('true when current state has no data and incoming is non-empty', () {
      SharedPreferences.setMockInitialValues({});
      final freshRepo = _FakeStoryRepository()..feedToReturn = [];
      final freshNotifier = StoriesNotifier(
        freshRepo,
        StoryStorageService.instance,
        null,
      );
      addTearDown(freshNotifier.dispose);

      expect(freshNotifier.hasNewContent([_makeStory(id: 's-new')]), isTrue);
    });
  });

  // ── checkForUpdates ───────────────────────────────────────────────────────

  group('StoriesNotifier.checkForUpdates', () {
    late _FakeStoryRepository repo;
    late _TestClock clock;
    late StoriesNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = _FakeStoryRepository()..feedToReturn = [_makeStory(id: 's-1')];
      clock = _TestClock();
      notifier = _makeNotifier(repo, clock: clock);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // The initial load just synced — step past the TTL so background
      // checks in these tests are eligible to hit the network.
      clock.advance(_pastTtl);
    });

    tearDown(() => notifier.dispose());

    test('updates state silently when new stories arrive', () async {
      final s2 = _makeStory(id: 's-2');
      repo.feedToReturn = [_makeStory(id: 's-1'), s2];

      notifier.checkForUpdates();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final stories = notifier.state.valueOrNull ?? [];
      expect(stories.any((s) => s.id == 's-2'), isTrue);
    });

    test('does NOT set state to loading during background check', () async {
      repo.feedToReturn = [_makeStory(id: 's-1'), _makeStory(id: 's-new')];

      // State before check is data.
      expect(notifier.state.hasValue, isTrue);

      notifier.checkForUpdates();
      // Synchronously after the call — must still have data, not loading.
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.hasValue, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('keeps state unchanged when incoming stories are identical', () async {
      final before = notifier.state.valueOrNull;
      repo.feedToReturn = [_makeStory(id: 's-1')]; // same as initial

      final callsBefore = repo.getFeedCallCount;
      notifier.checkForUpdates();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.getFeedCallCount, greaterThan(callsBefore));
      // State list reference may differ but ids should be the same.
      expect(
        notifier.state.valueOrNull?.map((s) => s.id).toList(),
        equals(before?.map((s) => s.id).toList()),
      );
    });

    test('silently ignores network errors', () async {
      repo.throwOnFetch = true;
      final before = notifier.state.valueOrNull;

      notifier.checkForUpdates();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // State must still be data (not error).
      expect(notifier.state.hasValue, isTrue);
      expect(
        notifier.state.valueOrNull?.map((s) => s.id),
        equals(before?.map((s) => s.id)),
      );
    });

    test('does not run when an explicit refresh is in progress', () async {
      // Capture count before refresh — getFeed() increments synchronously.
      final countBefore = repo.getFeedCallCount;
      final refreshFuture = notifier.refresh(showLoading: false);

      notifier.checkForUpdates();

      // Allow both futures to resolve.
      await refreshFuture;
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // checkForUpdates was a no-op because _isRefreshing was true.
      // Only the manual refresh should have run.
      expect(repo.getFeedCallCount, equals(countBefore + 1));
    });
  });

  // ── TTL gating (stale-while-revalidate) ───────────────────────────────────

  group('StoriesNotifier TTL gating', () {
    test('checkForUpdates is a no-op while the feed is fresh', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeStoryRepository()
        ..feedToReturn = [_makeStory(id: 's-1')];
      final clock = _TestClock();
      final notifier = _makeNotifier(repo, clock: clock);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final callsAfterLoad = repo.getFeedCallCount;

      // Still within the TTL — the silent check must not hit the network.
      notifier.checkForUpdates();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.getFeedCallCount, equals(callsAfterLoad));

      notifier.dispose();
    });

    test('checkForUpdates fetches once the TTL has lapsed', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeStoryRepository()
        ..feedToReturn = [_makeStory(id: 's-1')];
      final clock = _TestClock();
      final notifier = _makeNotifier(repo, clock: clock);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final callsAfterLoad = repo.getFeedCallCount;
      clock.advance(_pastTtl);

      notifier.checkForUpdates();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.getFeedCallCount, equals(callsAfterLoad + 1));

      // And the successful check re-arms the gate: an immediate second
      // check is a no-op again.
      notifier.checkForUpdates();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.getFeedCallCount, equals(callsAfterLoad + 1));

      notifier.dispose();
    });
  });

  // ── Manual refresh integration ────────────────────────────────────────────

  group('StoriesNotifier.refresh (compatibility)', () {
    test('shows loading state when showLoading=true', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeStoryRepository()
        ..feedToReturn = [_makeStory(id: 's-1')];
      final notifier = _makeNotifier(repo);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Kick off but do not await.
      final future = notifier.refresh();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.hasValue, isTrue);

      notifier.dispose();
    });

    test('does NOT show loading state when showLoading=false', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeStoryRepository()
        ..feedToReturn = [_makeStory(id: 's-1')];
      final notifier = _makeNotifier(repo);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final future = notifier.refresh(showLoading: false);
      // State must remain as data, not loading.
      expect(notifier.state.hasValue, isTrue);
      await future;

      notifier.dispose();
    });

    test('keeps stale data on error when showLoading=false', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeStoryRepository()
        ..feedToReturn = [_makeStory(id: 's-1')];
      final notifier = _makeNotifier(repo);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      repo.throwOnFetch = true;
      await notifier.refresh(showLoading: false);

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.valueOrNull?.first.id, equals('s-1'));

      notifier.dispose();
    });
  });

  // ── Provider integration ──────────────────────────────────────────────────

  group('storiesProvider Riverpod integration', () {
    test('state is initially AsyncLoading', () {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeStoryRepository()..feedToReturn = [];
      final container = ProviderContainer(
        overrides: [
          storyRepositoryProvider.overrideWithValue(repo),
          storyStorageProvider.overrideWithValue(StoryStorageService.instance),
          currentUserIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(storiesProvider);
      expect(state.isLoading, isTrue);
    });

    test('state becomes AsyncData after load', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeStoryRepository()
        ..feedToReturn = [_makeStory(id: 's-1')];
      final container = ProviderContainer(
        overrides: [
          storyRepositoryProvider.overrideWithValue(repo),
          storyStorageProvider.overrideWithValue(StoryStorageService.instance),
          currentUserIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      container.read(storiesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(storiesProvider);
      expect(state.hasValue, isTrue);
      expect(state.valueOrNull?.first.id, equals('s-1'));
    });
  });
}
