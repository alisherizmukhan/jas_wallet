import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/entities/reward.dart';
import '../providers/orientation_rewards_provider.dart';
import '../widgets/orientation_error_state.dart';
import '../widgets/orientation_skeletons.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/reward_claim_card.dart';
import '../widgets/reward_row.dart';
import '../theme/orientation_brand.dart';

/// Rewards — tab 4 of the Orientation Week shell.
///
/// Prize shop only: history entry, how-to-claim (WhatsApp), category chips,
/// and the token rewards list. Milestones were removed — claiming is redeem
/// against the live catalog on the backend.
class RewardsPage extends ConsumerWidget {
  const RewardsPage({super.key});

  void _openReward(BuildContext context, Reward reward) {
    context.push(AppRoutes.orientationRewardDetail, extra: reward);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(orientationRewardsProvider);

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(
        title: l10n.orientation_rewards,
        isShellRoot: true,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(orientationRewardsProvider.notifier).load(),
          child: _buildBody(context, ref, l10n, state),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    OrientationRewardsState state,
  ) {
    if (state.isLoading && state.rewards.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(padding: EdgeInsets.only(top: 20), child: OrientationDashboardSkeleton()),
      );
    }
    if (state.error != null && state.rewards.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: OrientationErrorState(
          onRetry: () => ref.read(orientationRewardsProvider.notifier).load(),
        ),
      );
    }

    final listed = state.rewards;
    const stagger = Duration(milliseconds: 45);

    return FeaturePageBody(
      children: [
        FeatureFadeIn(
          child: FeatureHeaderCard(
            icon: AppIcons.history,
            accent: OrientationBrand.accent,
            title: l10n.orientation_rw_history_title,
            onTap: () => context.push(AppRoutes.orientationRewardHistory),
          ),
        ),
        const FeatureFadeIn(child: RewardClaimCard()),
        const FeatureFadeIn(child: RewardTechSupportCard()),
        if (state.furtherRedeemsBlocked)
          FeatureFadeIn(
            delay: stagger,
            child: FeatureCard(
              child: FeatureListRow(
                icon: AppIcons.checkCircle,
                iconColor: OrientationBrand.accentTeal,
                title: l10n.orientation_rw_exclusive_claimed_title,
                subtitle: l10n.orientation_rw_exclusive_claimed_body,
              ),
            ),
          ),
        FeatureFadeIn(
          delay: stagger * 2,
          child: FeatureSection(
            title: l10n.orientation_rw_token_rewards,
            child: listed.isEmpty
                ? _EmptyCategory(label: l10n.orientation_rw_empty_category)
                : RewardListCard(
                    children: [
                      for (final reward in listed)
                        RewardRow(reward: reward, onTap: () => _openReward(context, reward)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: FeatureStyle.cardFill,
        borderRadius: BorderRadius.circular(FeatureStyle.rCard),
        border: FeatureStyle.cardBorder,
      ),
      child: Column(
        children: [
          AppIcon(AppIcons.gift, size: 28, color: FeatureStyle.mute),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: FeatureStyle.body.copyWith(color: FeatureStyle.mute, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
