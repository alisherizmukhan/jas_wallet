import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jaswallet_app/features/stories/data/story_service.dart';
import 'package:jaswallet_app/features/stories/domain/entities/story.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

Story _makeStory({
  required String id,
  required String authorId,
  bool expired = false,
}) {
  final now = DateTime.now();
  return Story(
    id: id,
    authorId: authorId,
    authorName: 'Author',
    mediaUrl: 'url',
    mediaType: StoryMediaType.image,
    createdAt: now.subtract(const Duration(hours: 2)),
    expiresAt: expired
        ? now.subtract(const Duration(hours: 1))
        : now.add(const Duration(hours: 22)),
  );
}

void main() {
  late StoryStorageService service;

  setUpAll(() {
    // Provide a blank SharedPreferences mock for the entire suite.
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    service = StoryStorageService.instance;
    // Clear any state left over from previous tests.
    await service.clearAll();
    // Re-initialize to a known viewer scope.
    await service.init(viewerId: 'test-viewer');
  });

  // ── init / viewer scope ───────────────────────────────────────────────────

  group('StoryStorageService.init', () {
    test('init completes without error', () async {
      await expectLater(
        service.init(viewerId: 'user-1'),
        completes,
      );
    });

    test('changing viewerId via init scopes viewed IDs separately', () async {
      // Mark a story viewed for user-A
      await service.init(viewerId: 'user-A');
      await service.markViewed('story-1');
      expect(service.isViewed('story-1'), isTrue);

      // Switch to user-B — story-1 should not be visible
      await service.init(viewerId: 'user-B');
      expect(service.isViewed('story-1'), isFalse);
    });
  });

  // ── markViewed / isViewed ─────────────────────────────────────────────────

  group('StoryStorageService.markViewed and isViewed', () {
    test('isViewed returns false before marking', () {
      expect(service.isViewed('story-x'), isFalse);
    });

    test('isViewed returns true after marking', () async {
      await service.markViewed('story-1');
      expect(service.isViewed('story-1'), isTrue);
    });

    test('marking the same story twice is idempotent', () async {
      await service.markViewed('story-1');
      await service.markViewed('story-1');
      expect(service.isViewed('story-1'), isTrue);
    });

    test('marking one story does not affect others', () async {
      await service.markViewed('story-1');
      expect(service.isViewed('story-2'), isFalse);
    });
  });

  // ── removeViewed ──────────────────────────────────────────────────────────

  group('StoryStorageService.removeViewed', () {
    test('removes a previously marked story', () async {
      await service.markViewed('story-5');
      expect(service.isViewed('story-5'), isTrue);

      await service.removeViewed('story-5');
      expect(service.isViewed('story-5'), isFalse);
    });

    test('removing an unknown story is safe (no error)', () async {
      await expectLater(service.removeViewed('not-exists'), completes);
    });
  });

  // ── areAllViewed ──────────────────────────────────────────────────────────

  group('StoryStorageService.areAllViewed', () {
    test('returns true when all stories are viewed', () async {
      final stories = [
        _makeStory(id: 's1', authorId: 'author-1'),
        _makeStory(id: 's2', authorId: 'author-1'),
      ];
      await service.markViewed('s1');
      await service.markViewed('s2');
      expect(service.areAllViewed('author-1', stories), isTrue);
    });

    test('returns false when some stories are not viewed', () async {
      final stories = [
        _makeStory(id: 's1', authorId: 'author-1'),
        _makeStory(id: 's2', authorId: 'author-1'),
      ];
      await service.markViewed('s1'); // only s1
      expect(service.areAllViewed('author-1', stories), isFalse);
    });

    test('returns true when no non-expired stories exist', () async {
      final stories = [
        _makeStory(id: 's-expired', authorId: 'author-1', expired: true),
      ];
      // Expired stories are excluded by areAllViewed
      expect(service.areAllViewed('author-1', stories), isTrue);
    });

    test('ignores expired stories in the check', () async {
      final stories = [
        _makeStory(id: 's-live', authorId: 'author-1'),
        _makeStory(id: 's-expired', authorId: 'author-1', expired: true),
      ];
      await service.markViewed('s-live');
      // s-expired is expired → doesn't count; s-live is viewed → all viewed
      expect(service.areAllViewed('author-1', stories), isTrue);
    });

    test('considers only stories matching authorId', () async {
      final stories = [
        _makeStory(id: 'a1', authorId: 'author-A'),
        _makeStory(id: 'b1', authorId: 'author-B'),
      ];
      await service.markViewed('a1');
      // Only author-A stories: a1 is viewed → all viewed for author-A
      expect(service.areAllViewed('author-A', stories), isTrue);
      // Only author-B stories: b1 is not viewed → not all viewed
      expect(service.areAllViewed('author-B', stories), isFalse);
    });
  });

  // ── getFirstUnviewedIndex ─────────────────────────────────────────────────

  group('StoryStorageService.getFirstUnviewedIndex', () {
    test('returns 0 when no stories are viewed', () {
      final stories = [
        _makeStory(id: 's1', authorId: 'a'),
        _makeStory(id: 's2', authorId: 'a'),
        _makeStory(id: 's3', authorId: 'a'),
      ];
      expect(service.getFirstUnviewedIndex('a', stories), 0);
    });

    test('returns index of first unviewed story', () async {
      final stories = [
        _makeStory(id: 's1', authorId: 'a'),
        _makeStory(id: 's2', authorId: 'a'),
        _makeStory(id: 's3', authorId: 'a'),
      ];
      await service.markViewed('s1');
      await service.markViewed('s2');
      expect(service.getFirstUnviewedIndex('a', stories), 2);
    });

    test('returns 0 when all stories are viewed', () async {
      final stories = [
        _makeStory(id: 's1', authorId: 'a'),
        _makeStory(id: 's2', authorId: 'a'),
      ];
      await service.markViewed('s1');
      await service.markViewed('s2');
      // Per implementation: returns 0 when all viewed (rewind to start)
      expect(service.getFirstUnviewedIndex('a', stories), 0);
    });
  });

  // ── clearAll ──────────────────────────────────────────────────────────────

  group('StoryStorageService.clearAll', () {
    test('clears all marked story IDs', () async {
      await service.markViewed('story-A');
      await service.markViewed('story-B');

      await service.clearAll();

      expect(service.isViewed('story-A'), isFalse);
      expect(service.isViewed('story-B'), isFalse);
    });

    test('clearAll then init restores clean state', () async {
      await service.markViewed('story-A');
      await service.clearAll();
      await service.init(viewerId: 'test-viewer');

      expect(service.isViewed('story-A'), isFalse);
    });
  });
}
