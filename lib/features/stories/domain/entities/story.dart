import 'dart:convert';

/// Type of media in a story.
enum StoryMediaType { image, video }

/// Text overlay on a story.
class StoryTextOverlay {
  const StoryTextOverlay({
    required this.text,
    this.x = 0.5,
    this.y = 0.5,
    this.rotation = 0,
    this.scale = 1.0,
    this.color = 0xFFFFFFFF,
    this.fontSize = 24,
  });

  final String text;
  final double x; // 0..1 normalized
  final double y; // 0..1 normalized
  final double rotation;
  final double scale;
  final int color;
  final double fontSize;

  Map<String, dynamic> toJson() => {
    'text': text,
    'x': x,
    'y': y,
    'rotation': rotation,
    'scale': scale,
    'color': color,
    'fontSize': fontSize,
  };

  factory StoryTextOverlay.fromJson(Map<String, dynamic> json) {
    return StoryTextOverlay(
      text: json['text'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      color: json['color'] as int? ?? 0xFFFFFFFF,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24,
    );
  }
}

/// Drawing stroke point.
class DrawingPoint {
  const DrawingPoint({required this.x, required this.y});
  final double x;
  final double y;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// A freehand drawing stroke.
class DrawingStroke {
  const DrawingStroke({required this.points, this.color = 0xFFFFFFFF, this.width = 3.0});
  final List<DrawingPoint> points;
  final int color;
  final double width;

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'color': color,
    'width': width,
  };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List?)
              ?.map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      color: json['color'] as int? ?? 0xFFFFFFFF,
      width: (json['width'] as num?)?.toDouble() ?? 3.0,
    );
  }
}

/// Story model representing a single story item.
class Story {
  const Story({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    this.isViewed = false,
    this.textOverlays = const [],
    this.drawings = const [],
    this.duration = const Duration(seconds: 7),
    this.caption,
    this.isAsset = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isViewed;
  final List<StoryTextOverlay> textOverlays;
  final List<DrawingStroke> drawings;
  final Duration duration;
  final String? caption;
  /// Whether [mediaUrl] is a bundled asset path (true) or a device file path (false).
  final bool isAsset;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Story copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? mediaUrl,
    StoryMediaType? mediaType,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isViewed,
    List<StoryTextOverlay>? textOverlays,
    List<DrawingStroke>? drawings,
    Duration? duration,
    String? caption,
    bool? isAsset,
  }) {
    return Story(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isViewed: isViewed ?? this.isViewed,
      textOverlays: textOverlays ?? this.textOverlays,
      drawings: drawings ?? this.drawings,
      duration: duration ?? this.duration,
      caption: caption ?? this.caption,
      isAsset: isAsset ?? this.isAsset,
    );
  }

  factory Story.fromApi(Map<String, dynamic> json) {
    final mediaTypeRaw = (json['media_type'] ?? '').toString().trim().toLowerCase();
    return Story(
      id: (json['id'] ?? '').toString(),
      authorId: (json['organization_id'] ?? '').toString(),
      authorName: (json['organization_name'] ?? '').toString(),
      authorAvatar: (json['organization_avatar_url'] as String?)?.trim(),
      mediaUrl: (json['media_url'] ?? '').toString(),
      mediaType: mediaTypeRaw == 'video' ? StoryMediaType.video : StoryMediaType.image,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      expiresAt:
          DateTime.tryParse((json['expires_at'] ?? '').toString()) ??
          DateTime.now().add(const Duration(days: 7)),
      isAsset: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatar': authorAvatar,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType.name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'isViewed': isViewed,
    'textOverlays': textOverlays.map((t) => t.toJson()).toList(),
    'drawings': drawings.map((d) => d.toJson()).toList(),
    'duration': duration.inSeconds,
    'caption': caption,
    'isAsset': isAsset,
  };

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorAvatar: json['authorAvatar'] as String?,
      mediaUrl: json['mediaUrl'] as String? ?? '',
      mediaType: StoryMediaType.values.firstWhere(
        (e) => e.name == json['mediaType'],
        orElse: () => StoryMediaType.image,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      isViewed: json['isViewed'] as bool? ?? false,
      textOverlays: (json['textOverlays'] as List?)
              ?.map((t) => StoryTextOverlay.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      drawings: (json['drawings'] as List?)
              ?.map((d) => DrawingStroke.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      duration: Duration(seconds: json['duration'] as int? ?? 7),
      caption: json['caption'] as String?,
      isAsset: json['isAsset'] as bool? ?? false,
    );
  }

  static String encodeList(List<Story> stories) =>
      json.encode(stories.map((s) => s.toJson()).toList());

  static List<Story> decodeList(String data) {
    final list = json.decode(data) as List;
    return list.map((e) => Story.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// A user's story collection (grouped by author).
class UserStory {
  const UserStory({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.stories,
    this.hasUnviewedStories = true,
  });

  final String userId;
  final String userName;
  final String? userAvatar;
  final List<Story> stories;
  final bool hasUnviewedStories;

  UserStory copyWith({
    String? userId,
    String? userName,
    String? userAvatar,
    List<Story>? stories,
    bool? hasUnviewedStories,
  }) {
    return UserStory(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      stories: stories ?? this.stories,
      hasUnviewedStories: hasUnviewedStories ?? this.hasUnviewedStories,
    );
  }
}

class StoryPublisherOrganization {
  const StoryPublisherOrganization({
    required this.id,
    required this.slug,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String slug;
  final String name;
  final String role;
  final String? avatarUrl;

  factory StoryPublisherOrganization.fromApi(Map<String, dynamic> json) {
    return StoryPublisherOrganization(
      id: (json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'role': role,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };

  static String encodeList(List<StoryPublisherOrganization> orgs) =>
      json.encode(orgs.map((o) => o.toJson()).toList());

  static List<StoryPublisherOrganization> decodeList(String data) {
    final list = json.decode(data) as List<dynamic>;
    return list
        .map(
          (e) => StoryPublisherOrganization.fromApi(e as Map<String, dynamic>),
        )
        .toList();
  }
}
