import 'club_fair_schedule.dart';
import 'photo_mission.dart';
import 'reward.dart';
import 'streak.dart';

/// Tokens required per level — a flat curve, not XP-scaled.
const int kTokensPerLevel = 500;

/// Named levels (1-indexed) per the gamification spec — meaningful titles
/// instead of raw "Level N". Levels beyond the list fall back to "Level N".
const List<String> kOrientationLevelNames = [
  'Welcome',
  'Explorer',
  'Navigator',
  'Connector',
  'Campus Guide',
  'Ambassador',
  'Orientation Master',
];

/// Display name for a 1-indexed [level] — clamps to the named list, then
/// falls back to "Level N" for anything beyond it.
String orientationLevelName(int level) {
  if (level < 1) return kOrientationLevelNames.first;
  if (level <= kOrientationLevelNames.length) return kOrientationLevelNames[level - 1];
  return 'Level $level';
}

/// Aggregate for the Overview screen — one call (`getDashboard`) assembles
/// everything the hero card and the four highlight rows need, so the
/// dashboard page never has to fan out into separate loads.
class OrientationDashboard {
  const OrientationDashboard({
    required this.currentDay,
    required this.totalDays,
    required this.tokens,
    required this.rank,
    required this.totalParticipants,
    required this.timeRemaining,
    required this.bingoCompletedCount,
    required this.bingoTotalCount,
    required this.rewardsPreview,
    required this.photoQuestsPreview,
    required this.streak,
    this.clubsScanned = 0,
    this.clubsTotal = 0,
    this.clubScanTokens = 0,
    this.tasksCompleted = 0,
    this.tasksTotal = 0,
    this.isRep = false,
    this.slots = const [],
  });

  final int currentDay;
  final int totalDays;
  final int tokens;
  final int rank;
  final int totalParticipants;
  final Duration timeRemaining;
  final int bingoCompletedCount;
  final int bingoTotalCount;
  final List<Reward> rewardsPreview;
  final List<PhotoMission> photoQuestsPreview;
  final Streak streak;

  final int clubsScanned;
  final int clubsTotal;
  final int clubScanTokens;
  final int tasksCompleted;
  final int tasksTotal;
  final bool isRep;
  final List<ClubFairSlotGroup> slots;

  int get questCompleted => tasksCompleted + clubsScanned;
  int get questTotal => tasksTotal + clubsTotal;

  double get weekProgress =>
      totalDays == 0 ? 0 : (currentDay / totalDays).clamp(0, 1).toDouble();

  double get bingoProgress =>
      bingoTotalCount == 0 ? 0 : (bingoCompletedCount / bingoTotalCount).clamp(0, 1).toDouble();

  int get level => 1 + tokens ~/ kTokensPerLevel;

  double get levelProgress => (tokens % kTokensPerLevel) / kTokensPerLevel;

  int get photoQuestsRemaining => photoQuestsPreview.length;

  OrientationDashboard copyWith({
    int? tokens,
    int? rank,
    int? totalParticipants,
    int? bingoCompletedCount,
    int? bingoTotalCount,
    List<PhotoMission>? photoQuestsPreview,
    Streak? streak,
    int? clubsScanned,
    int? clubsTotal,
    int? clubScanTokens,
    int? tasksCompleted,
    int? tasksTotal,
    bool? isRep,
    List<ClubFairSlotGroup>? slots,
  }) {
    return OrientationDashboard(
      currentDay: currentDay,
      totalDays: totalDays,
      tokens: tokens ?? this.tokens,
      rank: rank ?? this.rank,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      timeRemaining: timeRemaining,
      bingoCompletedCount: bingoCompletedCount ?? this.bingoCompletedCount,
      bingoTotalCount: bingoTotalCount ?? this.bingoTotalCount,
      rewardsPreview: rewardsPreview,
      photoQuestsPreview: photoQuestsPreview ?? this.photoQuestsPreview,
      streak: streak ?? this.streak,
      clubsScanned: clubsScanned ?? this.clubsScanned,
      clubsTotal: clubsTotal ?? this.clubsTotal,
      clubScanTokens: clubScanTokens ?? this.clubScanTokens,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      tasksTotal: tasksTotal ?? this.tasksTotal,
      isRep: isRep ?? this.isRep,
      slots: slots ?? this.slots,
    );
  }
}
