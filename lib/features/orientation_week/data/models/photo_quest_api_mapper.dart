/// JSON mappers for Orientation Week Photo Quest API responses.
library;

import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/orientation_results.dart';
import '../../domain/entities/photo_mission.dart';
import '../../domain/entities/student_profile.dart';

PhotoMission photoMissionFromApi(Map<String, dynamic> json) {
  return PhotoMission(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    difficulty: _difficultyFromApi(json['difficulty'] as String?),
    category: _categoryFromApi(json['category'] as String?),
    icon: _iconFromApi(json['icon'] as String?),
    rewardTokens: (json['reward_tokens'] as num?)?.toInt() ?? 0,
    status: _missionStatusFromApi(json['status'] as String?),
    requirements: (json['requirements'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList(growable: false),
    location: json['location'] as String?,
    submissionCount: (json['submission_count'] as num?)?.toInt() ?? 0,
    // Remote URL — the detail header accepts http(s) as well as local files.
    photoPath: json['photo_url'] as String?,
    completedAt: _parseDate(json['completed_at']),
  );
}

PhotoQuestProgress photoQuestProgressFromApi(Map<String, dynamic> json) {
  return PhotoQuestProgress(
    completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
    totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    bonusTokens: (json['bonus_tokens'] as num?)?.toInt() ?? 0,
  );
}

/// Balance + rank from `GET /orientation/photo-quests/me/tokens`.
class OrientationTokensSnapshot {
  const OrientationTokensSnapshot({
    required this.balance,
    required this.earned,
    required this.rank,
    required this.totalParticipants,
  });

  final int balance;
  final int earned;
  final int rank;
  final int totalParticipants;
}

OrientationTokensSnapshot orientationTokensFromApi(Map<String, dynamic> json) {
  return OrientationTokensSnapshot(
    balance: (json['balance'] as num?)?.toInt() ?? 0,
    earned: (json['earned'] as num?)?.toInt() ?? 0,
    rank: (json['rank'] as num?)?.toInt() ?? 1,
    totalParticipants: (json['total_participants'] as num?)?.toInt() ?? 1,
  );
}

LeaderboardEntry orientationLeaderboardEntryFromApi(Map<String, dynamic> json) {
  final id = json['student_id']?.toString() ?? '';
  final isCurrent = json['is_current_user'] as bool? ?? false;
  // The real name, even for the current student's own row — the leaderboard
  // provider overwrites this row with the signed-in profile right after, but
  // it shouldn't have to fall back to a placeholder in the meantime (e.g. a
  // student who isn't signed in yet, or a future caller of this mapper that
  // skips that overlay).
  final displayName = json['display_name'] as String? ?? 'Student';
  return LeaderboardEntry(
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    tokens: (json['tokens'] as num?)?.toInt() ?? 0,
    isCurrentUser: isCurrent,
    student: StudentProfile(
      id: id,
      fullName: displayName,
      initials: _initialsFromDisplayName(displayName, isCurrent: isCurrent),
      avatarColorIndex: id.hashCode.abs() % 5,
      faculty: '',
      isFoundationYear: false,
      country: '',
      interests: const [],
      photoUrl: json['avatar_url'] as String?,
    ),
  );
}

/// Merges top-N rows with [current_user] so the page always has "you".
List<LeaderboardEntry> orientationLeaderboardFromApi(Map<String, dynamic> json) {
  final rawEntries = json['entries'] as List<dynamic>? ?? const [];
  final entries = rawEntries
      .whereType<Map>()
      .map((e) => orientationLeaderboardEntryFromApi(Map<String, dynamic>.from(e)))
      .toList();
  final currentJson = json['current_user'];
  if (currentJson is Map) {
    final current = orientationLeaderboardEntryFromApi(
      Map<String, dynamic>.from(currentJson),
    );
    if (!entries.any((e) => e.isCurrentUser)) {
      entries.add(current);
    }
  }
  return entries;
}

String _initialsFromDisplayName(String name, {required bool isCurrent}) {
  if (isCurrent) return 'ME';
  final parts = name
      .replaceAll('.', ' ')
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

PhotoMissionSubmitResult photoMissionSubmitResultFromApi(Map<String, dynamic> json) {
  final missionJson = json['mission'] as Map<String, dynamic>? ?? const {};
  final submission = json['submission'] as Map<String, dynamic>? ?? const {};
  final mission = photoMissionFromApi(missionJson);
  final tokens = (json['tokens_awarded'] as num?)?.toInt() ??
      (submission['tokens_awarded'] as num?)?.toInt() ??
      0;
  final bonus = (json['bonus_tokens_awarded'] as num?)?.toInt() ??
      (submission['bonus_tokens_awarded'] as num?)?.toInt() ??
      0;
  final questCompleted = json['quest_completed'] as bool? ?? false;
  final message = submission['message_ru'] as String?;

  return PhotoMissionSubmitResult.success(
    mission: mission,
    reward: PhotoQuestReward(
      missionTokens: tokens,
      bonusTokens: bonus,
      questCompleted: questCompleted,
    ),
    userMessage: message,
  );
}

MissionStatus _missionStatusFromApi(String? raw) {
  return switch ((raw ?? '').toLowerCase()) {
    'completed' => MissionStatus.completed,
    'pending_review' || 'pending' || 'uploading' => MissionStatus.pendingReview,
    'rejected' => MissionStatus.rejected,
    'locked' => MissionStatus.locked,
    'expired' => MissionStatus.expired,
    _ => MissionStatus.available,
  };
}

MissionDifficulty _difficultyFromApi(String? raw) {
  return switch ((raw ?? '').toLowerCase()) {
    'medium' => MissionDifficulty.medium,
    'hard' => MissionDifficulty.hard,
    _ => MissionDifficulty.easy,
  };
}

MissionCategory _categoryFromApi(String? raw) {
  return switch ((raw ?? '').toLowerCase()) {
    'architecture' => MissionCategory.architecture,
    'food' => MissionCategory.food,
    'nature' => MissionCategory.nature,
    'art' => MissionCategory.art,
    'event' => MissionCategory.event,
    'sky' => MissionCategory.sky,
    'study' => MissionCategory.study,
    'facility' => MissionCategory.facility,
    _ => MissionCategory.landmark,
  };
}

MissionIcon _iconFromApi(String? raw) {
  return switch ((raw ?? '').toLowerCase()) {
    'building' => MissionIcon.building,
    'coffee' => MissionIcon.coffee,
    'trees' => MissionIcon.trees,
    'palette' => MissionIcon.palette,
    'megaphone' => MissionIcon.megaphone,
    'sunset' => MissionIcon.sunset,
    'book' => MissionIcon.book,
    'utensils' => MissionIcon.utensils,
    'compass' => MissionIcon.compass,
    'camera' => MissionIcon.camera,
    _ => MissionIcon.landmark,
  };
}

DateTime? _parseDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
