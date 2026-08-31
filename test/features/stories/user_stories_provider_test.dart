import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/api/api_client.dart';
import 'package:jaswallet_app/features/stories/data/repositories/story_repository_impl.dart';
import 'package:jaswallet_app/features/stories/data/story_service.dart';
import 'package:jaswallet_app/features/stories/domain/entities/story.dart';
import 'package:jaswallet_app/features/stories/presentation/providers/stories_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_storage.dart';

// ── Fake storage ───────────────────────────────────────────────────────────

class _FakeStoryStorage implements StoryStorageService {
  final Set<String> _viewed;

  _FakeStoryStorage({Set<String>? viewedIds})
      : _viewed = viewedIds ?? {};

  @override
  Future<void> init({String? viewerId}) async {}

  @override
  Future<void> setViewerScope(String? viewerId) async {}

  @override
  Future<void> markViewed(String storyId) async => _viewed.add(storyId);

  @override
  Future<void> removeViewed(String storyId) async => _viewed.remove(storyId);

  @override
  bool isViewed(String storyId) => _viewed.contains(storyId);

  @override
  bool areAllViewed(String authorId, List<Story> stories) {
    final relevant = stories.where((s) => s.authorId == authorId && !s.isExpired);
    return relevant.every((s) => _viewed.contains(s.id));
  }

  @override
  int getFirstUnviewedIndex(String authorId, List<Story> stories) {
    for (int i = 0; i < stories.length; i++) {
      if (!_viewed.contains(stories[i].id)) return i;
    }
    return 0;
  }

  @override
  Future<void> clearAll() async => _viewed.clear();
}

// ── Fake repository ────────────────────────────────────────────────────────

class _FakeStoryRepositoryImpl extends StoryRepositoryImpl {
  final List<Story> _stories;
  final bool _shouldThrow;

  _FakeStoryRepositoryImpl(this._stories, {bool shouldThrow = false})
      : _shouldThrow = shouldThrow,
        super(
          apiClient: ApiClient(
            authStorage: FakeAuthStorageService(),
            dio: Dio(),
          ),
        );

  @override
  Future<List<Story>> getFeed({CancelToken? cancelToken}) async {
    if (_shouldThrow) throw Exception('Network error');
    return _stories;
  }

  @override
  Future<List<StoryPublisherOrganization>> getMyOrganizations() async => [];
}

// ── Story factory ──────────────────────────────────────────────────────────

Story _makeStory({
  required String id,
  required String authorId,
  String authorName = 'Author',
  DateTime? createdAt,
  bool expired = false,
}) {
  final now = DateTime.now();
  return Story(
    id: id,
    authorId: authorId,
    authorName: authorName,
    mediaUrl: 'url',
    mediaType: StoryMediaType.image,
    createdAt: createdAt ?? now.subtract(const Duration(hours: 2)),
    expiresAt: expired
        ? now.subtract(const Duration(hours: 1))
        : now.add(const Duration(hours: 22)),
  );
}

// ── Container builder ──────────────────────────────────────────────────────

Future<ProviderContainer> _makeContainer({
  required List<Story> stories,
  Set<String> viewedIds = const {},
  bool throwOnFeed = false,
}) async {
  SharedPreferences.setMockInitialValues({});

  final fakeStorage = _FakeStoryStorage(viewedIds: Set.from(viewedIds));
  final fakeRepo = _FakeStoryRepositoryImpl(stories, shouldThrow: throwOnFeed);

  final container = ProviderContainer(
    overrides: [
      storyStorageProvider.overrideWithValue(fakeStorage),
      storyRepositoryProvider.overrideWithValue(fakeRepo),
      currentUserIdProvider.overrideWithValue('test-viewer'),
    ],
  );

  // Pre-warm storiesProvider AND its notifier sub-provider so that
  // userStoriesProvider can safely do ref.read(storiesProvider.notifier).
  container.read(storiesProvider);
  container.read(storiesProvider.notifier);
  // Wait for StoriesNotifier._load() to complete
  await Future<void>.delayed(const Duration(milliseconds: 50));

  return container;
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  // ── userStoriesProvider: basic grouping ───────────────────────────────────

  group('userStoriesProvider — grouping', () {
    test('groups stories by authorId into UserStory entries', () async {
      final stories = [
        _makeStory(id: 's1', authorId: 'author-A', authorName: 'Alice'),
        _makeStory(id: 's2', authorId: 'author-A', authorName: 'Alice'),
        _makeStory(id: 's3', authorId: 'author-B', authorName: 'Bob'),
      ];

      final container = await _makeContainer(stories: stories);
      addTearDown(container.dispose);

      final userStories = container.read(userStoriesProvider);

      expect(userStories.length, 2);
      final authors = userStories.map((us) => us.userId).toSet();
      expect(authors, containsAll(['author-A', 'author-B']));
    });

    test('each UserStory contains correct story count for that author', () async {
      final stories = [
        _makeStory(id: 's1', authorId: 'author-A'),
        _makeStory(id: 's2', authorId: 'author-A'),
        _makeStory(id: 's3', authorId: 'author-B'),
      ];

      final container = await _makeContainer(stories: stories);
      addTearDown(container.dispose);

      final userStories = container.read(userStoriesProvider);
      final authorA = userStories.firstWhere((us) => us.userId == 'author-A');
      final authorB = userStories.firstWhere((us) => us.userId == 'author-B');

      expect(authorA.stories.length, 2);
      expect(authorB.stories.length, 1);
    });
  });

  // ── userStoriesProvider: expired stories ─────────────────────────────────

  group('userStoriesProvider — expired stories filtered out', () {
    test('expired stories are not included', () async {
      final stories = [
        _makeStory(id: 'live', authorId: 'author-A'),
        _makeStory(id: 'expired', authorId: 'author-A', expired: true),
      ];

      final container = await _makeContainer(stories: stories);
      addTearDown(container.dispose);

      final userStories = container.read(userStoriesProvider);
      final authorA = userStories.firstWhere(
        (us) => us.userId == 'author-A',
        orElse: () => const UserStory(
          userId: '', userName: '', stories: [], hasUnviewedStories: false,
        ),
      );

      expect(authorA.stories.every((s) => !s.isExpired), isTrue);
    });

    test('author with only expired stories does not appear', () async {
      final stories = [
        _makeStory(id: 'expired1', authorId: 'ghost', expired: true),
        _makeStory(id: 'live1', authorId: 'real-author'),
      ];

      final container = await _makeContainer(stories: stories);
      addTearDown(container.dispose);

      final userStories = container.read(userStoriesProvider);
      expect(userStories.any((us) => us.userId == 'ghost'), isFalse);
      expect(userStories.any((us) => us.userId == 'real-author'), isTrue);
    });
  });

  // ── userStoriesProvider: sort order ──────────────────────────────────────

  group('userStoriesProvider — sort order', () {
    test('unviewed authors appear before fully viewed authors', () async {
      final stories = [
        _makeStory(id: 's1', authorId: 'viewed-author'),
        _makeStory(id: 's2', authorId: 'unviewed-author'),
      ];

      final container = await _makeContainer(
        stories: stories,
        viewedIds: {'s1'}, // viewed-author is fully viewed
      );
      addTearDown(container.dispose);

      final userStories = container.read(userStoriesProvider);

      expect(userStories.first.userId, 'unviewed-author');
      expect(userStories.last.userId, 'viewed-author');
    });

    test('hasUnviewedStories is true when some stories not viewed', () async {
      final stories = [
        _makeStory(id: 's1', authorId: 'author-A'),
        _makeStory(id: 's2', authorId: 'author-A'),
      ];

      final container = await _makeContainer(
        stories: stories,
        viewedIds: {'s1'}, // only s1 viewed
      );
      addTearDown(container.dispose);

      final userStories = container.read(userStoriesProvider);
      final authorA = userStories.firstWhere((us) => us.userId == 'author-A');

      expect(authorA.hasUnviewedStories, isTrue);
    });

    test('hasUnviewedStories is false when all stories are viewed', () async {
      final stories = [
        _makeStory(id: 's1', authorId: 'author-A'),
        _makeStory(id: 's2', authorId: 'author-A'),
      ];

      final container = await _makeContainer(
        stories: stories,
        viewedIds: {'s1', 's2'}, // both viewed
      );
      addTearDown(container.dispose);

      final userStories = container.read(userStoriesProvider);
      final authorA = userStories.firstWhere((us) => us.userId == 'author-A');

      expect(authorA.hasUnviewedStories, isFalse);
    });
  });

  // ── userStoriesProvider: stories sorted by createdAt ─────────────────────

  group('userStoriesProvider — stories sorted chronologically', () {
    test('stories within a UserStory are sorted oldest-first', () async {
      final now = DateTime.now();
      final stories = [
        _makeStory(
          id: 's-newer',
          authorId: 'author-A',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        _makeStory(
          id: 's-older',
          authorId: 'author-A',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
      ];

      final container = await _makeContainer(stories: stories);
      addTearDown(container.dispose);

      final userStories = container.read(userStoriesProvider);
      final authorA = userStories.firstWhere((us) => us.userId == 'author-A');

      expect(authorA.stories.first.id, 's-older');
      expect(authorA.stories.last.id, 's-newer');
    });
  });

  // ── userStoriesProvider: empty feed ──────────────────────────────────────

  group('userStoriesProvider — empty feed', () {
    test('returns empty list when no stories', () async {
      final container = await _makeContainer(stories: []);
      addTearDown(container.dispose);

      expect(container.read(userStoriesProvider), isEmpty);
    });
  });

  // ── storiesProvider: error handling ──────────────────────────────────────

  group('StoriesNotifier — error handling', () {
    test('sets error state when feed fetch fails', () async {
      final container = await _makeContainer(
        stories: [],
        throwOnFeed: true,
      );
      addTearDown(container.dispose);

      final state = container.read(storiesProvider);
      expect(state.hasError, isTrue);
    });
  });
}
