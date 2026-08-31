import 'student_profile.dart';

enum LeaderboardScope { global, friends, school }

/// A single leaderboard row. [previousRank] is the rank last time this scope
/// was loaded (`null` on the very first load) — the UI derives the movement
/// arrow from `previousRank - rank` rather than storing a direction enum, so
/// the repository only ever has to persist one number per student.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.student,
    required this.tokens,
    required this.isCurrentUser,
    this.previousRank,
  });

  final int rank;
  final StudentProfile student;
  final int tokens;
  final bool isCurrentUser;
  final int? previousRank;

  /// Positive = moved up (better rank, lower number), negative = moved down,
  /// zero = unchanged, null = no prior snapshot to compare against.
  int? get rankDelta => previousRank == null ? null : previousRank! - rank;

  LeaderboardEntry copyWith({StudentProfile? student}) {
    return LeaderboardEntry(
      rank: rank,
      student: student ?? this.student,
      tokens: tokens,
      isCurrentUser: isCurrentUser,
      previousRank: previousRank,
    );
  }
}
