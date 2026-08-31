import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/stories/domain/entities/story.dart';

void main() {
  // ── Story.isExpired ───────────────────────────────────────────────────────

  group('Story.isExpired', () {
    test('returns true when expiresAt is in the past', () {
      final story = Story(
        id: '1',
        authorId: 'author',
        authorName: 'Author',
        mediaUrl: 'https://example.com/img.jpg',
        mediaType: StoryMediaType.image,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(story.isExpired, isTrue);
    });

    test('returns false when expiresAt is in the future', () {
      final story = Story(
        id: '1',
        authorId: 'author',
        authorName: 'Author',
        mediaUrl: 'https://example.com/img.jpg',
        mediaType: StoryMediaType.image,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
      expect(story.isExpired, isFalse);
    });
  });

  // ── Story.fromApi ─────────────────────────────────────────────────────────

  group('Story.fromApi', () {
    test('parses complete API response correctly', () {
      final json = <String, dynamic>{
        'id': 'abc123',
        'organization_id': 'org-1',
        'organization_name': 'Test Club',
        'organization_avatar_url': 'https://example.com/avatar.png',
        'media_url': 'https://example.com/story.jpg',
        'media_type': 'image',
        'created_at': '2024-01-15T10:00:00.000Z',
        'expires_at': '2024-01-16T10:00:00.000Z',
      };

      final story = Story.fromApi(json);

      expect(story.id, 'abc123');
      expect(story.authorId, 'org-1');
      expect(story.authorName, 'Test Club');
      expect(story.authorAvatar, 'https://example.com/avatar.png');
      expect(story.mediaUrl, 'https://example.com/story.jpg');
      expect(story.mediaType, StoryMediaType.image);
      expect(story.isAsset, isFalse);
    });

    test('parses video media_type correctly', () {
      final json = <String, dynamic>{
        'id': '1',
        'organization_id': 'org',
        'organization_name': 'Org',
        'media_url': 'https://example.com/video.mp4',
        'media_type': 'video',
        'created_at': '2024-01-15T10:00:00.000Z',
        'expires_at': '2024-01-16T10:00:00.000Z',
      };

      final story = Story.fromApi(json);
      expect(story.mediaType, StoryMediaType.video);
    });

    test('defaults to image for unknown media_type', () {
      final json = <String, dynamic>{
        'id': '1',
        'organization_id': 'org',
        'organization_name': 'Org',
        'media_url': 'url',
        'media_type': 'gif', // unknown
        'created_at': '2024-01-15T10:00:00.000Z',
        'expires_at': '2024-01-16T10:00:00.000Z',
      };

      final story = Story.fromApi(json);
      expect(story.mediaType, StoryMediaType.image);
    });

    test('handles null organization_avatar_url gracefully', () {
      final json = <String, dynamic>{
        'id': '1',
        'organization_id': 'org',
        'organization_name': 'Org',
        'organization_avatar_url': null,
        'media_url': 'url',
        'media_type': 'image',
        'created_at': '2024-01-15T10:00:00.000Z',
        'expires_at': '2024-01-16T10:00:00.000Z',
      };

      final story = Story.fromApi(json);
      expect(story.authorAvatar, isNull);
    });
  });

  // ── Story.fromJson / toJson round-trip ────────────────────────────────────

  group('Story.fromJson / toJson round-trip', () {
    Story makeStory({String id = '1', String authorId = 'author'}) {
      return Story(
        id: id,
        authorId: authorId,
        authorName: 'Author Name',
        authorAvatar: 'https://example.com/avatar.png',
        mediaUrl: 'https://example.com/img.jpg',
        mediaType: StoryMediaType.image,
        createdAt: DateTime(2024, 1, 15, 10),
        expiresAt: DateTime(2024, 1, 16, 10),
        isViewed: true,
        duration: const Duration(seconds: 5),
        caption: 'Test caption',
        isAsset: false,
      );
    }

    test('toJson / fromJson preserves all fields', () {
      final original = makeStory();
      final json = original.toJson();
      final decoded = Story.fromJson(json);

      expect(decoded.id, original.id);
      expect(decoded.authorId, original.authorId);
      expect(decoded.authorName, original.authorName);
      expect(decoded.authorAvatar, original.authorAvatar);
      expect(decoded.mediaUrl, original.mediaUrl);
      expect(decoded.mediaType, original.mediaType);
      expect(decoded.isViewed, original.isViewed);
      expect(decoded.duration, original.duration);
      expect(decoded.caption, original.caption);
      expect(decoded.isAsset, original.isAsset);
      expect(
        decoded.createdAt.toIso8601String(),
        original.createdAt.toIso8601String(),
      );
      expect(
        decoded.expiresAt.toIso8601String(),
        original.expiresAt.toIso8601String(),
      );
    });
  });

  // ── Story.encodeList / decodeList ─────────────────────────────────────────

  group('Story.encodeList / decodeList', () {
    test('encodes and decodes empty list', () {
      final encoded = Story.encodeList([]);
      final decoded = Story.decodeList(encoded);
      expect(decoded, isEmpty);
    });

    test('round-trips a list of stories', () {
      final stories = [
        Story(
          id: 'a',
          authorId: 'org-1',
          authorName: 'Club A',
          mediaUrl: 'url-a',
          mediaType: StoryMediaType.image,
          createdAt: DateTime(2024, 1, 1),
          expiresAt: DateTime(2024, 1, 2),
        ),
        Story(
          id: 'b',
          authorId: 'org-2',
          authorName: 'Club B',
          mediaUrl: 'url-b',
          mediaType: StoryMediaType.video,
          createdAt: DateTime(2024, 1, 3),
          expiresAt: DateTime(2024, 1, 4),
        ),
      ];

      final encoded = Story.encodeList(stories);
      final decoded = Story.decodeList(encoded);

      expect(decoded.length, 2);
      expect(decoded[0].id, 'a');
      expect(decoded[1].id, 'b');
      expect(decoded[0].mediaType, StoryMediaType.image);
      expect(decoded[1].mediaType, StoryMediaType.video);
    });
  });

  // ── Story.copyWith ────────────────────────────────────────────────────────

  group('Story.copyWith', () {
    test('copyWith updates specified fields only', () {
      final original = Story(
        id: '1',
        authorId: 'author',
        authorName: 'Author',
        mediaUrl: 'url',
        mediaType: StoryMediaType.image,
        createdAt: DateTime(2024, 1, 1),
        expiresAt: DateTime(2024, 1, 2),
        isViewed: false,
      );

      final copy = original.copyWith(isViewed: true, caption: 'hello');

      expect(copy.id, original.id);
      expect(copy.isViewed, isTrue);
      expect(copy.caption, 'hello');
      expect(copy.authorId, original.authorId);
    });
  });

  // ── StoryTextOverlay ─────────────────────────────────────────────────────

  group('StoryTextOverlay.fromJson / toJson', () {
    test('round-trips correctly', () {
      const overlay = StoryTextOverlay(
        text: 'Hello!',
        x: 0.3,
        y: 0.7,
        rotation: 45.0,
        scale: 1.5,
        color: 0xFF0000FF,
        fontSize: 32,
      );

      final json = overlay.toJson();
      final decoded = StoryTextOverlay.fromJson(json);

      expect(decoded.text, overlay.text);
      expect(decoded.x, overlay.x);
      expect(decoded.y, overlay.y);
      expect(decoded.rotation, overlay.rotation);
      expect(decoded.scale, overlay.scale);
      expect(decoded.color, overlay.color);
      expect(decoded.fontSize, overlay.fontSize);
    });
  });

  // ── UserStory ─────────────────────────────────────────────────────────────

  group('UserStory.copyWith', () {
    test('copyWith updates specified fields', () {
      final story = Story(
        id: '1',
        authorId: 'a',
        authorName: 'A',
        mediaUrl: 'url',
        mediaType: StoryMediaType.image,
        createdAt: DateTime(2024),
        expiresAt: DateTime(2025),
      );

      const original = UserStory(
        userId: 'u1',
        userName: 'User One',
        stories: [],
        hasUnviewedStories: true,
      );

      final copy = original.copyWith(
        hasUnviewedStories: false,
        stories: [story],
      );

      expect(copy.userId, original.userId);
      expect(copy.hasUnviewedStories, isFalse);
      expect(copy.stories.length, 1);
    });
  });
}
