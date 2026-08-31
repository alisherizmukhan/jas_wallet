import 'orientation_dashboard.dart' show kTokensPerLevel;
import 'streak.dart';

/// Aggregate stats for the Progress screen.
class OrientationProgress {
  const OrientationProgress({
    required this.visitedLocationsCount,
    required this.totalLocationsCount,
    required this.completedChallengesCount,
    required this.totalChallengesCount,
    required this.completedTilesCount,
    required this.totalTilesCount,
    required this.placesDiscoveredCount,
    required this.tokensEarned,
    required this.bingoCompletionPercent,
    required this.streak,
  });

  final int visitedLocationsCount;
  final int totalLocationsCount;

  /// Daily Challenges closed, and how many there are.
  final int completedChallengesCount;
  final int totalChallengesCount;

  /// Bingo squares closed, and how many the board holds. Tracked for the
  /// Bingo tab's own summary only — the board is a personal, random 16-tile
  /// subset of the same challenge/photo catalog, not a distinct task set, so
  /// it must not be added into [overallCompletionPercent] alongside them or
  /// completions get double-counted (and tasks that missed the board get
  /// dropped entirely).
  final int completedTilesCount;
  final int totalTilesCount;
  final int placesDiscoveredCount;
  final int tokensEarned;
  final double bingoCompletionPercent;
  final Streak streak;

  /// Every completable task across the week: Daily Challenges + Photo Quest.
  /// Bingo is deliberately excluded — see [completedTilesCount].
  double get overallCompletionPercent {
    final totalTasks = totalChallengesCount + totalLocationsCount;
    if (totalTasks == 0) return 0;
    final done = completedChallengesCount + visitedLocationsCount;
    return (done / totalTasks).clamp(0, 1).toDouble();
  }

  int get level => 1 + tokensEarned ~/ kTokensPerLevel;

  double get levelProgress => (tokensEarned % kTokensPerLevel) / kTokensPerLevel;
}
