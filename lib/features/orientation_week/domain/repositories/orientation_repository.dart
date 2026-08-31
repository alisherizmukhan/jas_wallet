import '../entities/bingo_board.dart';
import '../entities/club_fair_club_rank.dart';
import '../entities/club_fair_stand_qr.dart';
import '../entities/leaderboard_entry.dart';
import '../entities/orientation_challenge.dart';
import '../entities/orientation_dashboard.dart';
import '../entities/orientation_identity.dart';
import '../entities/orientation_progress.dart';
import '../entities/orientation_results.dart';
import '../entities/orientation_schedule.dart';
import '../entities/photo_mission.dart';
import '../entities/reward.dart';

/// Contract for all Orientation Week data access.
///
/// Photo Quest list/submit, token balance, and the token leaderboard are live
/// via [OrientationRepositoryHybridImpl]. Other surfaces still use the local
/// mock until their APIs ship — swap the provider at
/// `presentation/providers/orientation_repository_provider.dart`.
abstract class OrientationRepository {
  Future<OrientationDashboard> getDashboard();

  Future<BingoBoard> getBingoBoard();

  /// Sends a photo in for [missionId], awarding the mission's tokens plus
  /// the one-time all-missions bonus if it was the last one.
  Future<PhotoMissionSubmitResult> submitMissionPhoto(String missionId, String localFilePath);

  /// Removes the photo submitted for [missionId], reopening the mission and
  /// taking back whatever that submission paid out.
  Future<PhotoMissionSubmitResult> deleteMissionPhoto(String missionId);

  /// Marks one Bingo tile complete, awarding its tokens plus any line and
  /// grand bonuses it unlocks. Bonuses are paid at most once each.
  Future<BingoTileResult> completeBingoTile(String tileId);

  Future<List<LeaderboardEntry>> getLeaderboard({LeaderboardScope scope});

  Future<List<Reward>> getRewards();

  Future<RedeemRewardResult> redeemReward(String rewardId);

  /// Rewards the student has already redeemed, newest first.
  Future<List<RewardRedemption>> getRewardHistory();

  /// The token milestone timeline shown at the bottom of the Rewards page.
  Future<List<RewardMilestone>> getRewardMilestones();

  /// Lifetime tokens earned (not the spendable balance) — drives milestone
  /// progress, which must not fall when tokens are spent.
  Future<int> getTokensEarnedTotal();

  Future<OrientationProgress> getProgress();

  Future<List<PhotoMission>> getPhotoMissions();

  /// Missions plus the one-time "finish every mission" bonus this student's
  /// board actually pays, sourced live where the backend reports it, so the
  /// progress card never shows a locally-guessed number that can drift from
  /// what the server is really configured to pay.
  Future<({List<PhotoMission> missions, int bonusTokens})> getPhotoQuestBoard();

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// The week's timetable, both tracks. Filtering is the caller's job.
  Future<OrientationSchedule> getSchedule();

  /// Which programme the student is on, or null before they have said.
  ///
  /// The timetable runs two parallel columns every day, so this is not a
  /// display preference — without it, half of what a student is shown does
  /// not apply to them.
  Future<StudentTrack?> getTrack();

  Future<void> setTrack(StudentTrack track);

  // ── Identity (peer QR) ────────────────────────────────────────────────────

  /// This student's own code payload, or null until they have declared a
  /// school. [studentId] and [displayName] come from the signed-in profile;
  /// only the school is stored by Orientation Week.
  Future<OrientationIdentity?> getIdentity({
    required String studentId,
    required String displayName,
  });

  Future<void> setSchool(NuSchool school);

  Future<NuSchool?> getSchool();

  // ── Challenges ────────────────────────────────────────────────────────────

  /// Every challenge, with this student's stored answers overlaid.
  Future<List<OrientationChallenge>> getChallenges();

  /// Records a typed answer, paying the reward the first time.
  ///
  /// Returns the tokens awarded — 0 when the challenge was already answered,
  /// so editing an answer never pays twice.
  Future<int> answerChallenge(String challengeId, String answer);

  /// Clears an answer, reopening the challenge. Tokens already paid are kept.
  Future<void> clearChallengeAnswer(String challengeId);

  /// Evaluates a scanned payload against a QR challenge's rule and, if it
  /// passes, records it and pays out.
  ///
  /// The whole decision runs on the two payloads — no network.
  Future<ScanOutcome> submitChallengeScan({
    required String challengeId,
    required OrientationIdentity me,
    required String scannedRaw,
  });

  /// Everyone already scanned for [challengeId], so the same person cannot
  /// complete it twice.
  Future<List<OrientationIdentity>> getChallengeScans(String challengeId);

  /// Scan a Club Fair stand QR (`jasaim-club:…`). Club id is read from the payload.
  Future<ClubScanResult> scanClubQr(String scannedPayload);

  /// Rotating stand QR(s) for this account, or [ClubFairStandQrBundle.isRep]
  /// false when the student is not a listed representative.
  Future<ClubFairStandQrBundle> getClubStandQrs();

  /// Quest clubs ranked by unique student scans.
  Future<ClubFairClubRanking> getClubRanking();
}
