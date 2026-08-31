import 'bingo_board.dart';
import 'bingo_tile.dart';
import 'photo_mission.dart';
import 'reward.dart';

/// Result wrappers for the repository's mutating calls — mirrors the
/// `ScanResult` success/error pattern used by the Social Meal Program
/// (`lib/features/social_meal/presentation/providers/svc_meal_provider.dart`),
/// so callers branch on `isSuccess` instead of catching exceptions.

/// Outcome of submitting a photo for one mission, including the mission's
/// own tokens and the one-time all-missions bonus if this submission
/// finished the quest.
class PhotoMissionSubmitResult {
  const PhotoMissionSubmitResult._({
    required this.isSuccess,
    this.mission,
    this.reward = PhotoQuestReward.none,
    this.errorMessage,
    this.userMessage,
  });

  factory PhotoMissionSubmitResult.success({
    required PhotoMission mission,
    required PhotoQuestReward reward,
    String? userMessage,
  }) {
    return PhotoMissionSubmitResult._(
      isSuccess: true,
      mission: mission,
      reward: reward,
      userMessage: userMessage,
    );
  }

  factory PhotoMissionSubmitResult.error(String message) {
    return PhotoMissionSubmitResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final PhotoMission? mission;
  final PhotoQuestReward reward;
  final String? errorMessage;

  /// CV / backend message for the student (`message_ru`), even on a successful HTTP submit.
  final String? userMessage;

  int get tokensAwarded => reward.totalTokens;
}

/// Outcome of completing one Bingo tile, including everything the tile
/// completion paid out (tile tokens, any line bonuses it triggered, and the
/// one-time grand bonus).
class BingoTileResult {
  const BingoTileResult._({
    required this.isSuccess,
    this.tile,
    this.reward = BingoReward.none,
    this.errorMessage,
  });

  factory BingoTileResult.success({required BingoTile tile, required BingoReward reward}) {
    return BingoTileResult._(isSuccess: true, tile: tile, reward: reward);
  }

  factory BingoTileResult.error(String message) {
    return BingoTileResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final BingoTile? tile;
  final BingoReward reward;
  final String? errorMessage;

  int get tokensAwarded => reward.totalTokens;
}

/// Outcome of scanning a Club Fair stand QR.
class ClubScanResult {
  const ClubScanResult({
    required this.clubId,
    required this.clubName,
    required this.tokensAwarded,
    required this.bingoLineTokens,
    required this.bingoGrandTokens,
    required this.alreadyCompleted,
    required this.tokensBalance,
  });

  final String clubId;
  final String clubName;
  final int tokensAwarded;
  final int bingoLineTokens;
  final int bingoGrandTokens;
  final bool alreadyCompleted;
  final int tokensBalance;

  int get totalTokens => tokensAwarded + bingoLineTokens + bingoGrandTokens;
}

class RedeemRewardResult {
  const RedeemRewardResult._({
    required this.isSuccess,
    this.reward,
    this.remainingTokens = 0,
    this.errorMessage,
  });

  factory RedeemRewardResult.success({
    required Reward reward,
    required int remainingTokens,
  }) {
    return RedeemRewardResult._(
      isSuccess: true,
      reward: reward,
      remainingTokens: remainingTokens,
    );
  }

  factory RedeemRewardResult.error(String message) {
    return RedeemRewardResult._(isSuccess: false, errorMessage: message);
  }

  final bool isSuccess;
  final Reward? reward;
  final int remainingTokens;
  final String? errorMessage;
}
