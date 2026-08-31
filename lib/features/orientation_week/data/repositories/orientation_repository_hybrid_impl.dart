import '../../../../core/api/api_client.dart';
import '../../domain/entities/bingo_board.dart';
import '../../domain/entities/club_fair_club_rank.dart';
import '../../domain/entities/club_fair_stand_qr.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/orientation_challenge.dart';
import '../../domain/entities/orientation_dashboard.dart';
import '../../domain/entities/orientation_identity.dart';
import '../../domain/entities/orientation_schedule.dart';
import '../../domain/entities/orientation_progress.dart';
import '../../domain/entities/orientation_results.dart';
import '../../domain/entities/photo_mission.dart';
import '../../domain/entities/reward.dart';
import '../../domain/entities/streak.dart';
import '../../domain/repositories/orientation_repository.dart';
import 'orientation_photo_quest_remote.dart';
import 'orientation_repository_mock_impl.dart';
import 'orientation_rewards_remote.dart';
import 'orientation_tasks_remote.dart';

/// Hybrid Orientation Week repository.
///
/// Photo Quest, tokens, leaderboard, challenges, bingo and the prize shop go
/// to the live backend. The schedule (bundled asset) stays on the local mock
/// — by design, not just until an API ships (see the schedule/identity
/// section below).
class OrientationRepositoryHybridImpl implements OrientationRepository {
  OrientationRepositoryHybridImpl({
    required ApiClient apiClient,
    String Function()? languageCode,
    OrientationRepository? local,
    OrientationPhotoQuestRemote? photoRemote,
    OrientationTasksRemote? tasksRemote,
    OrientationRewardsRemote? rewardsRemote,
  })  : _local = local ?? OrientationRepositoryMockImpl(),
        _photo = photoRemote ?? OrientationPhotoQuestRemote(apiClient: apiClient),
        _tasks = tasksRemote ??
            OrientationTasksRemote(
              apiClient: apiClient,
              languageCode: languageCode ?? (() => 'en'),
            ),
        _rewards = rewardsRemote ??
            OrientationRewardsRemote(
              apiClient: apiClient,
              languageCode: languageCode ?? (() => 'en'),
            );

  final OrientationRepository _local;
  final OrientationPhotoQuestRemote _photo;
  final OrientationTasksRemote _tasks;
  final OrientationRewardsRemote _rewards;

  @override
  Future<List<PhotoMission>> getPhotoMissions() => _photo.getPhotoMissions();

  @override
  Future<({List<PhotoMission> missions, int bonusTokens})> getPhotoQuestBoard() async {
    final board = await _photo.fetchBoard();
    return (missions: board.missions, bonusTokens: board.progress.bonusTokens);
  }

  @override
  Future<PhotoMissionSubmitResult> submitMissionPhoto(
    String missionId,
    String localFilePath,
  ) =>
      _photo.submitMissionPhoto(missionId, localFilePath);

  @override
  Future<PhotoMissionSubmitResult> deleteMissionPhoto(String missionId) =>
      _photo.deleteMissionPhoto(missionId);

  @override
  Future<OrientationDashboard> getDashboard() => _tasks.fetchHome();

  @override
  Future<OrientationProgress> getProgress() async {
    final home = await _tasks.fetchHome();
    return OrientationProgress(
      visitedLocationsCount: 0,
      totalLocationsCount: 0,
      completedChallengesCount: home.tasksCompleted,
      totalChallengesCount: home.tasksTotal,
      completedTilesCount: home.clubsScanned,
      totalTilesCount: home.clubsTotal,
      placesDiscoveredCount: home.clubsScanned,
      tokensEarned: home.tokens,
      bingoCompletionPercent: 0,
      streak: const Streak(current: 0, longest: 0),
    );
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardScope scope = LeaderboardScope.global,
  }) {
    // Server board is campus-wide for now; friends/school scopes come later.
    return _photo.fetchLeaderboard();
  }

  @override
  Future<int> getTokensEarnedTotal() async {
    final home = await _tasks.fetchHome();
    return home.tokens;
  }

  // ── Bingo (live) ──────────────────────────────────────────────────────────

  @override
  Future<BingoBoard> getBingoBoard() => _tasks.fetchBingoBoard();

  @override
  Future<BingoTileResult> completeBingoTile(String tileId) async {
    // Server squares are never self-marked: each completes through its own
    // task flow (Challenges input, peer/venue scan, Photo Quest camera) and
    // the board only reflects it. Reachable only from stale UI.
    return BingoTileResult.error('Complete this task from its own flow.');
  }

  // ── Rewards (live) ────────────────────────────────────────────────────────

  @override
  Future<List<Reward>> getRewards() async {
    final snap = await _rewards.fetchRewards();
    return snap.rewards;
  }

  @override
  Future<RedeemRewardResult> redeemReward(String rewardId) =>
      _rewards.redeem(rewardId);

  @override
  Future<List<RewardRedemption>> getRewardHistory() =>
      _rewards.fetchRedemptions();

  @override
  Future<List<RewardMilestone>> getRewardMilestones() async => const [];

  // ── Schedule and identity ─────────────────────────────────────────────────
  //
  // Local by design, not just "until the API ships": the timetable is a
  // bundled asset and the declared school is a device-side preference.

  @override
  Future<OrientationSchedule> getSchedule() => _local.getSchedule();

  @override
  Future<StudentTrack?> getTrack() => _local.getTrack();

  @override
  Future<void> setTrack(StudentTrack track) => _local.setTrack(track);

  @override
  Future<OrientationIdentity?> getIdentity({
    required String studentId,
    required String displayName,
  }) =>
      _local.getIdentity(studentId: studentId, displayName: displayName);

  @override
  Future<void> setSchool(NuSchool school) => _local.setSchool(school);

  @override
  Future<NuSchool?> getSchool() => _local.getSchool();

  // ── Challenges (live) ─────────────────────────────────────────────────────

  @override
  Future<List<OrientationChallenge>> getChallenges() => _tasks.fetchChallenges();

  @override
  Future<int> answerChallenge(String challengeId, String answer) async {
    final result = await _tasks.completeTask(challengeId, answer: answer);
    return result.tokensAwarded + result.bingoLineTokens + result.bingoGrandTokens;
  }

  @override
  Future<void> clearChallengeAnswer(String challengeId) async {
    // A paid completion is final on the server; there is nothing to clear.
  }

  @override
  Future<ScanOutcome> submitChallengeScan({
    required String challengeId,
    required OrientationIdentity me,
    required String scannedRaw,
  }) async {
    // Decoded locally only for the confirmation card — every rule (schools
    // from the SALTO directory, venue secrets, self-scans) runs on the server.
    final them = OrientationIdentity.decode(scannedRaw);
    try {
      final result = await _tasks.completeTask(
        challengeId,
        scannedPayload: scannedRaw,
        mySchoolCode: me.school.code,
      );
      if (result.alreadyCompleted) {
        return them == null ? const ScanUnrecognised() : ScanDuplicate(them);
      }
      final counted = them ??
          OrientationIdentity(
            studentId: 'venue:$challengeId',
            displayName: '',
            school: me.school,
          );
      return ScanAccepted(
        counted,
        result.tokensAwarded + result.bingoLineTokens + result.bingoGrandTokens,
      );
    } on OrientationTaskRejected catch (e) {
      return switch (e.detail) {
        'cannot_scan_yourself' => const ScanSelf(),
        'same_school' when them != null =>
          ScanRejected(them, QrScanRule.differentSchool.rejectionReason(them)),
        'peer_not_nufyp' when them != null =>
          ScanRejected(them, QrScanRule.foundationYear.rejectionReason(them)),
        'different_birth_month' when them != null =>
          ScanRejected(them, QrScanRule.sameBirthMonth.rejectionReason(them)),
        'own_dob_unknown' when them != null => ScanRejected(
            them,
            'Your profile has no date of birth, so months cannot be compared. '
            'Add it in your profile and try again.',
          ),
        'peer_dob_unknown' when them != null => ScanRejected(
            them,
            '${them.displayName} has no date of birth in their profile, '
            'so months cannot be compared.',
          ),
        'no_connection' when them != null =>
          ScanRejected(them, 'No connection. Check your network and try again.'),
        _ => const ScanUnrecognised(),
      };
    }
  }

  @override
  Future<List<OrientationIdentity>> getChallengeScans(String challengeId) =>
      _local.getChallengeScans(challengeId);

  @override
  Future<ClubScanResult> scanClubQr(String scannedPayload) =>
      _tasks.scanClub(scannedPayload);

  @override
  Future<ClubFairStandQrBundle> getClubStandQrs() => _tasks.fetchClubStandQrs();

  @override
  Future<ClubFairClubRanking> getClubRanking() => _tasks.fetchClubRanking();
}
