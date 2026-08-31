import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/orientation_results.dart';
import '../../domain/entities/reward.dart';
import '../../domain/repositories/orientation_repository.dart';
import 'orientation_dashboard_provider.dart';
import 'orientation_leaderboard_provider.dart';
import 'orientation_repository_provider.dart';

/// UI state for the Rewards tab — catalog + spendable balance. Milestones
/// were removed; the shop is the only prize surface.
class OrientationRewardsState {
  const OrientationRewardsState({
    required this.rewards,
    required this.tokens,
    required this.isLoading,
    required this.redeemingRewardId,
    this.furtherRedeemsBlocked = false,
    this.error,
  });

  const OrientationRewardsState.initial()
      : rewards = const [],
        tokens = 0,
        isLoading = true,
        redeemingRewardId = null,
        furtherRedeemsBlocked = false,
        error = null;

  final List<Reward> rewards;

  /// Spendable balance (live ledger).
  final int tokens;

  final bool isLoading;
  final String? redeemingRewardId;
  final bool furtherRedeemsBlocked;
  final Object? error;

  bool canAfford(Reward reward) => tokens >= reward.priceTokens;

  OrientationRewardsState copyWith({
    List<Reward>? rewards,
    int? tokens,
    bool? isLoading,
    String? redeemingRewardId,
    bool clearRedeeming = false,
    bool? furtherRedeemsBlocked,
    Object? error,
    bool clearError = false,
  }) {
    return OrientationRewardsState(
      rewards: rewards ?? this.rewards,
      tokens: tokens ?? this.tokens,
      isLoading: isLoading ?? this.isLoading,
      redeemingRewardId: clearRedeeming ? null : (redeemingRewardId ?? this.redeemingRewardId),
      furtherRedeemsBlocked: furtherRedeemsBlocked ?? this.furtherRedeemsBlocked,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrientationRewardsNotifier extends StateNotifier<OrientationRewardsState> {
  OrientationRewardsNotifier(this._repo) : super(const OrientationRewardsState.initial()) {
    load();
  }

  final OrientationRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rewards = await _repo.getRewards();
      final dashboard = await _repo.getDashboard();
      state = state.copyWith(
        rewards: rewards,
        tokens: dashboard.tokens,
        furtherRedeemsBlocked: rewards.any((r) => r.alreadyRedeemed && r.blocksFurtherRedeems),
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Keeps the spendable balance (and its `canAfford` gate) in step with the
  /// dashboard, which every earn action already reloads. Tokens are earned
  /// from Challenges, Photo Quest and Bingo — none of which touch this
  /// provider — so without this the balance shown here only ever moved on
  /// its own `load()`/`redeem()` and would sit stale for as long as this
  /// provider stayed alive (it is not `autoDispose`, so that's the rest of
  /// the session) while the student earned tokens on another tab.
  void syncTokens(int tokens) {
    if (!mounted || tokens == state.tokens) return;
    state = state.copyWith(tokens: tokens);
  }

  Future<RedeemRewardResult> redeem(String rewardId) async {
    if (state.redeemingRewardId != null) {
      return RedeemRewardResult.error('Another redemption is already in progress.');
    }
    state = state.copyWith(redeemingRewardId: rewardId, clearError: true);
    final result = await _repo.redeemReward(rewardId);
    if (result.isSuccess) {
      await load();
      state = state.copyWith(tokens: result.remainingTokens, clearRedeeming: true);
    } else {
      state = state.copyWith(clearRedeeming: true, error: result.errorMessage);
    }
    return result;
  }
}

final orientationRewardsProvider =
    StateNotifierProvider<OrientationRewardsNotifier, OrientationRewardsState>(
  (ref) {
    final notifier = OrientationRewardsNotifier(ref.watch(orientationRepositoryProvider));
    // See `syncTokens` — this is what actually keeps the Rewards balance
    // live while the student earns elsewhere in the feature.
    ref.listen(orientationDashboardProvider, (previous, next) {
      final tokens = next.dashboard?.tokens;
      if (tokens != null) notifier.syncTokens(tokens);
    });
    return notifier;
  },
);

/// After a successful redeem, refresh surfaces that show the token balance.
void refreshOrientationBalances(WidgetRef ref) {
  ref.read(orientationDashboardProvider.notifier).load();
  ref.read(orientationLeaderboardProvider.notifier).load();
}

final orientationRewardHistoryProvider =
    FutureProvider.autoDispose<List<RewardRedemption>>((ref) {
  return ref.watch(orientationRepositoryProvider).getRewardHistory();
});
