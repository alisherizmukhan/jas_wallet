/// How demanding a mission is. Drives the filter tabs and the accent colour
/// of the difficulty pill.
enum MissionDifficulty { easy, medium, hard }

/// What the mission is about. Semantic only — the presentation layer maps
/// each value to a pastel tint, so this entity never imports Flutter.
enum MissionCategory { landmark, architecture, food, nature, art, event, sky, study, facility }

/// The glyph a mission card shows. An enum for the same reason as
/// [MissionCategory] — `photo_mission_visuals.dart` maps these to `AppIcons`.
enum MissionIcon { landmark, building, coffee, trees, palette, megaphone, sunset, book, utensils, compass, camera }

/// Lifecycle of one mission.
///
/// [locked] is reserved for prerequisite-gated missions; [uploading] and
/// [pendingReview] are transient states while a submission is in flight or
/// awaiting moderation; [rejected] missions can be re-shot.
enum MissionStatus { locked, available, uploading, pendingReview, completed, rejected, expired }

/// One photo mission — a place, a thing or a moment on campus to capture.
class PhotoMission {
  const PhotoMission({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.icon,
    required this.rewardTokens,
    required this.status,
    this.requirements = const [],
    this.location,
    this.submissionCount = 0,
    this.photoPath,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final MissionDifficulty difficulty;
  final MissionCategory category;
  final MissionIcon icon;
  final int rewardTokens;
  final MissionStatus status;

  /// The checklist shown on the detail page — what a valid photo must show.
  final List<String> requirements;

  /// Where on campus the shot is taken ("NU Library, 2nd floor").
  ///
  /// Separate from [description], which says what to photograph: a student
  /// standing in the Atrium wondering whether they are in the right place
  /// needs the *place*, and burying it in prose means re-reading a paragraph
  /// to find it.
  final String? location;

  /// How many photos have been submitted for this mission so far.
  final int submissionCount;

  /// Local path of the most recent submission, if any.
  final String? photoPath;

  final DateTime? createdAt;
  final DateTime? completedAt;

  bool get isCompleted => status == MissionStatus.completed;

  bool get isLocked => status == MissionStatus.locked;

  /// Awaiting a moderation decision — no further submission allowed.
  bool get isPending => status == MissionStatus.uploading || status == MissionStatus.pendingReview;

  /// The student can shoot (or re-shoot) this one.
  bool get canSubmit => status == MissionStatus.available || status == MissionStatus.rejected;

  PhotoMission copyWith({
    MissionStatus? status,
    int? submissionCount,
    String? photoPath,
    DateTime? completedAt,
  }) {
    return PhotoMission(
      id: id,
      title: title,
      description: description,
      difficulty: difficulty,
      category: category,
      icon: icon,
      rewardTokens: rewardTokens,
      status: status ?? this.status,
      requirements: requirements,
      location: location,
      submissionCount: submissionCount ?? this.submissionCount,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// One photo sent in for a mission.
class PhotoSubmission {
  const PhotoSubmission({
    required this.missionId,
    required this.localPath,
    required this.submittedAt,
    required this.status,
  });

  final String missionId;
  final String localPath;
  final DateTime submittedAt;
  final MissionStatus status;
}

/// Aggregate counters for the progress card.
class PhotoQuestProgress {
  const PhotoQuestProgress({
    required this.completedCount,
    required this.totalCount,
    required this.bonusTokens,
  });

  final int completedCount;
  final int totalCount;

  /// One-time payout for finishing every mission.
  final int bonusTokens;

  /// 0–1, clamped, for the progress bar.
  double get percent => totalCount == 0 ? 0 : (completedCount / totalCount).clamp(0, 1).toDouble();

  bool get isComplete => totalCount > 0 && completedCount >= totalCount;
}

/// What a single accepted submission paid out.
class PhotoQuestReward {
  const PhotoQuestReward({
    required this.missionTokens,
    required this.bonusTokens,
    required this.questCompleted,
  });

  static const PhotoQuestReward none =
      PhotoQuestReward(missionTokens: 0, bonusTokens: 0, questCompleted: false);

  final int missionTokens;

  /// The all-missions bonus, paid at most once.
  final int bonusTokens;

  final bool questCompleted;

  int get totalTokens => missionTokens + bonusTokens;
}
