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

Story _makeStory({required String id, DateTime? expiresAt}) {
  final now = DateTime.now();
  return Story(
    id: id,
    authorId: 'org-1',
    authorName: 'Test Org',
    mediaUrl: 'https://example.com/$id.jpg',
    mediaType: StoryMediaType.image,
    createdAt: now,
    expiresAt: expiresAt ?? now.add(const Duration(days: 7)),
  );
}

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeStoryRepository extends StoryRepositoryImpl {
  _FakeStoryRepository()
      : super(apiClient: ApiClient(authStorage: FakeAuthStorageService()));

  List<Story> feedToReturn = [];
  bool throwOnFetch = false;

  @override
  Future<List<Story>> getFeed({CancelToken? cancelToken}) async {
    if (throwOnFetch) throw Exception('network error');
    return List<Story>.from(feedToReturn);
  }
}

/// Movable test clock for stepping past the stories refresh TTL.
class _TestClock {
  DateTime current = DateTime(2026, 7, 7, 12);

  void advance(Duration d) => current = current.add(d);
}

StoriesNotifier _makeNotifier(
  _FakeStoryRepository repo, {
  Map<String, Object> initialPrefs = const {},
  _TestClock? clock,
}) {
  SharedPreferences.setMockInitialValues(initialPrefs);
  return StoriesNotifier(
    repo,
    StoryStorageService.instance,
    null,
    now: clock == null ? null : () => clock.current,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoriesNotifier — persistent cache', () {
    test('shows cached stories on init when network fails', () async {
      final story = _makeStory(id: 's-cached');
      final cachedJson = Story.encodeList([story]);
      final repo = _FakeStoryRepository()..throwOnFetch = true;
      final notifier = _makeNotifier(repo, initialPrefs: {
        'home_cache_stories_json': cachedJson,
        'home_cache_stories_at': DateTime.now().toIso8601String(),
      });
      addTearDown(notifier.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.valueOrNull?.first.id, equals('s-cached'));
    });

    test('does not show error state when cache exists and network fails', () async {
      final story = _makeStory(id: 's-1');
      final cachedJson = Story.encodeList([story]);
      final repo = _FakeStoryRepository()..throwOnFetch = true;
      final notifier = _makeNotifier(repo, initialPrefs: {
        'home_cache_stories_json': cachedJson,
        'home_cache_stories_at': DateTime.now().toIso8601String(),
      });
      addTearDown(notifier.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifier.state.hasError, isFalse);
      expect(notifier.state.hasValue, isTrue);
    });

    test('saves network data to cache after successful fetch', () async {
      final story = _makeStory(id: 's-net');
      final repo = _FakeStoryRepository()..feedToReturn = [story];
      final notifier = _makeNotifier(repo);
      addTearDown(notifier.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final saved = await HomeCacheService.loadStoriesJson();
      expect(saved, isNotNull);
      final decoded = Story.decodeList(saved!);
      expect(decoded.first.id, equals('s-net'));
    });

    test('filters expired stories from cache on load', () async {
      final expired = _makeStory(
        id: 's-expired',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final cachedJson = Story.encodeList([expired]);
      final repo = _FakeStoryRepository()..throwOnFetch = true;
      final notifier = _makeNotifier(repo, initialPrefs: {
        'home_cache_stories_json': cachedJson,
        'home_cache_stories_at': DateTime.now().toIso8601String(),
      });
      addTearDown(notifier.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final stories = notifier.state.valueOrNull ?? [];
      expect(stories.any((s) => s.id == 's-expired'), isFalse);
    });

    test('autoCheck saves updated stories to cache', () async {
      final s1 = _makeStory(id: 's-1');
      final repo = _FakeStoryRepository()..feedToReturn = [s1];
      final clock = _TestClock();
      final notifier = _makeNotifier(repo, clock: clock);
      addTearDown(notifier.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      // Step past the refresh TTL so the silent check actually fetches.
      clock.advance(HomeCacheService.storiesTtl + const Duration(minutes: 1));

      final s2 = _makeStory(id: 's-2');
      repo.feedToReturn = [s1, s2];
      notifier.checkForUpdates();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final saved = await HomeCacheService.loadStoriesJson();
      expect(saved, isNotNull);
      final decoded = Story.decodeList(saved!);
      expect(decoded.any((s) => s.id == 's-2'), isTrue);
    });

    test('explicit refresh updates cache with new data', () async {
      final s1 = _makeStory(id: 's-1');
      final repo = _FakeStoryRepository()..feedToReturn = [s1];
      final notifier = _makeNotifier(repo);
      addTearDown(notifier.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final s2 = _makeStory(id: 's-2');
      repo.feedToReturn = [s1, s2];
      await notifier.refresh(showLoading: false);

      final saved = await HomeCacheService.loadStoriesJson();
      expect(saved, isNotNull);
      final decoded = Story.decodeList(saved!);
      expect(decoded.length, equals(2));
    });
  });
}
