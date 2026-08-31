import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';


import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/reward.dart';
import '../providers/orientation_rewards_provider.dart';
import '../widgets/orientation_confetti.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/redeem_flow.dart';
import '../widgets/reward_availability_badge.dart';
import '../widgets/reward_price_tag.dart';
import '../widgets/reward_visuals.dart';
import '../theme/orientation_brand.dart';

/// Reward detail — a large product header, the brief, reward facts, terms,
/// how-to-redeem steps, and a bottom Redeem bar. The bar shows the price
/// when affordable, or an "earn more" nudge with a shortcut when not.
class RewardDetailPage extends ConsumerWidget {
  const RewardDetailPage({super.key, required this.reward});

  final Reward reward;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(orientationRewardsProvider);
    final live = state.rewards.where((r) => r.id == reward.id).firstOrNull ?? reward;
    final tint = RewardVisuals.tint(live.image);
    final canAfford = state.tokens >= live.priceTokens;
    final isRedeeming = state.redeemingRewardId == live.id;
    final shortfall = live.priceTokens - state.tokens;
    final canRedeem = live.isRedeemable && canAfford && !state.furtherRedeemsBlocked;

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(title: l10n.orientation_rw_details, showTokens: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FeaturePageBody(
                children: [
                  FeatureFadeIn(child: _Header(reward: live, tint: tint)),
                  // Title, badge and description are one unit — the section
                  // gap belongs after them, not between them.
                  FeatureFadeIn(
                    delay: const Duration(milliseconds: 45),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(live.title, style: FeatureStyle.sectionTitle.copyWith(fontSize: 18)),
                            ),
                            const SizedBox(width: FeatureStyle.s8),
                            RewardAvailabilityBadge(reward: live),
                          ],
                        ),
                        const SizedBox(height: FeatureStyle.s8),
                        Text(
                          live.description,
                          style: FeatureStyle.body.copyWith(color: FeatureStyle.mute),
                        ),
                      ],
                    ),
                  ),
                  FeatureFadeIn(
                    delay: const Duration(milliseconds: 135),
                    child: _FactsRow(reward: live, l10n: l10n),
                  ),
                  if (live.redemptionSteps.isNotEmpty)
                    FeatureFadeIn(
                      delay: const Duration(milliseconds: 180),
                      child: _StepsCard(title: l10n.orientation_rw_how_to_redeem, steps: live.redemptionSteps),
                    ),
                  if (live.terms.isNotEmpty)
                    FeatureFadeIn(
                      delay: const Duration(milliseconds: 225),
                      child: _TermsCard(title: l10n.orientation_rw_terms, terms: live.terms),
                    ),
                ],
              ),
            ),
            _RedeemBar(
              reward: live,
              canAfford: canAfford,
              canRedeem: canRedeem,
              alreadyRedeemed: live.alreadyRedeemed,
              furtherBlocked: state.furtherRedeemsBlocked && !live.alreadyRedeemed,
              isRedeeming: isRedeeming,
              shortfall: shortfall,
              onRedeem: () => _redeem(context, ref, live),
              onEarnMore: () => context.go(AppRoutes.orientationBingo),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _redeem(BuildContext context, WidgetRef ref, Reward live) async {
    final tokens = ref.read(orientationRewardsProvider).tokens;
    final confirmed = await showRedeemConfirmSheet(context, live, tokens);
    if (!context.mounted || confirmed != true) return;

    final result = await ref.read(orientationRewardsProvider.notifier).redeem(live.id);
    if (!context.mounted) return;

    if (!result.isSuccess) {
      if (result.errorMessage != null) AppToast.showError(context, result.errorMessage!);
      return;
    }

    AnalyticsService.instance.trackOrientationRewardRedeemed(rewardId: live.id);
    refreshOrientationBalances(ref);
    OrientationConfetti.play(context);

    await showRedeemSuccessSheet(
      context,
      live,
      onViewHistory: () {
        if (context.mounted) context.push(AppRoutes.orientationRewardHistory);
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.reward, required this.tint});

  final Reward reward;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FeatureStyle.rCard),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          // Flat product panel — the render itself carries the depth.
          color: tint.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Image.asset(RewardVisuals.photo(reward), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.reward, required this.l10n});

  final Reward reward;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Fact(
              label: l10n.orientation_reward_label,
              child: RewardPriceTag(tokens: reward.priceTokens, iconSize: 16, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Fact(
              label: l10n.orientation_rw_availability,
              child: RewardAvailabilityBadge(reward: reward),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FeatureStyle.tiny.copyWith(color: FeatureStyle.stone, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: child),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: OrientationBrand.accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: FeatureStyle.tiny.copyWith(color: OrientationBrand.accent, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[i],
                    style: FeatureStyle.body.copyWith(color: FeatureStyle.bodyInk, fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({required this.title, required this.terms});

  final String title;
  final List<String> terms;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < terms.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: CircleAvatar(radius: 2, backgroundColor: FeatureStyle.stone),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    terms[i],
                    style: FeatureStyle.body.copyWith(color: FeatureStyle.mute, fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FeatureStyle.cardFill,
        borderRadius: BorderRadius.circular(FeatureStyle.rCard),
        border: FeatureStyle.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FeatureStyle.cardTitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// The pinned bottom bar. When the student can afford the reward it is a
/// Redeem button; otherwise it shows how many tokens short they are and a
/// shortcut to earn more.
class _RedeemBar extends StatelessWidget {
  const _RedeemBar({
    required this.reward,
    required this.canAfford,
    required this.canRedeem,
    required this.alreadyRedeemed,
    required this.furtherBlocked,
    required this.isRedeeming,
    required this.shortfall,
    required this.onRedeem,
    required this.onEarnMore,
  });

  final Reward reward;
  final bool canAfford;
  final bool canRedeem;
  final bool alreadyRedeemed;
  final bool furtherBlocked;
  final bool isRedeeming;
  final int shortfall;
  final VoidCallback onRedeem;
  final VoidCallback onEarnMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String blockedLabel() {
      if (alreadyRedeemed) return l10n.orientation_challenge_done;
      if (furtherBlocked) return l10n.orientation_rw_exclusive_claimed_title;
      if (!reward.isRedeemable) return l10n.orientation_rw_out_of_stock;
      return l10n.orientation_rw_need_more(formatTokens(shortfall));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: FeatureStyle.cardFill,
        border: Border(top: BorderSide(color: FeatureStyle.hairline)),
      ),
      child: canRedeem
          ? FeatureCtaButton(accent: OrientationBrand.accent, 
              label: l10n.orientation_rw_redeem,
              isLoading: isRedeeming,
              onTap: onRedeem,
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    blockedLabel(),
                    style: FeatureStyle.cardTitle.copyWith(fontSize: 14),
                  ),
                ),
                if (!alreadyRedeemed && !furtherBlocked && reward.isRedeemable && !canAfford) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: FeatureCtaButton(accent: OrientationBrand.accent, 
                      label: l10n.orientation_rw_earn_more,
                      onTap: onEarnMore,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
