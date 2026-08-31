import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/reward.dart';
import 'reward_price_tag.dart';
import 'reward_visuals.dart';
import '../theme/orientation_brand.dart';

/// Confirmation before spending tokens — a bottom-sheet modal whose balance
/// summary and action button are inset (not full-bleed), so it reads as a
/// compact card rather than an edge-to-edge form. Resolves `true` when the
/// student confirms.
Future<bool?> showRedeemConfirmSheet(BuildContext context, Reward reward, int currentTokens) {
  return AppBottomSheet.show<bool>(
    context: context,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: _RedeemConfirmContent(reward: reward, currentTokens: currentTokens),
    ),
  );
}

class _RedeemConfirmContent extends StatelessWidget {
  const _RedeemConfirmContent({required this.reward, required this.currentTokens});

  final Reward reward;
  final int currentTokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final after = currentTokens - reward.priceTokens;
    final tint = RewardVisuals.tint(reward.image);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Product hero — a flat tinted panel with the render centred.
        Center(
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(FeatureStyle.rHero),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Image.asset(RewardVisuals.photo(reward), fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          reward.title,
          textAlign: TextAlign.center,
          style: FeatureStyle.sectionTitle.copyWith(fontSize: 19),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: FeatureStyle.chipTint(OrientationBrand.accent),
              borderRadius: BorderRadius.circular(FeatureStyle.rPill),
            ),
            child: RewardPriceTag(tokens: reward.priceTokens, showSuffix: true, iconSize: 16, fontSize: 14),
          ),
        ),
        const SizedBox(height: 20),
        // Balance summary — an inset card, Apple-settings style.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FeatureStyle.surfaceSoft,
            borderRadius: BorderRadius.circular(FeatureStyle.rChip),
          ),
          child: Column(
            children: [
              _Line(label: l10n.orientation_rw_confirm_balance, tokens: currentTokens),
              const SizedBox(height: 12),
              _Line(label: l10n.orientation_rw_confirm_cost, tokens: -reward.priceTokens),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, thickness: 1, color: FeatureStyle.hairline),
              ),
              _Line(label: l10n.orientation_rw_confirm_after, tokens: after, emphasise: true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FeatureCtaButton(accent: OrientationBrand.accent, 
          label: l10n.orientation_rw_redeem,
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: FeatureStyle.s8),
        FeatureCtaButton(accent: OrientationBrand.accent, 
          label: l10n.orientation_rw_cancel,
          style: FeatureCtaStyle.quiet,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.tokens, this.emphasise = false});

  final String label;
  final int tokens;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final sign = tokens < 0 ? '−' : '';
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: FeatureStyle.body.copyWith(
              color: emphasise ? FeatureStyle.ink : FeatureStyle.mute,
              fontWeight: emphasise ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Token artwork keeps its own colours — never tinted.
            const AppIcon(AppIcons.tokenAdsl, size: 16),
            const SizedBox(width: 5),
            Text(
              '$sign${formatTokens(tokens.abs())}',
              style: TextStyle(
                fontSize: emphasise ? 16 : 14,
                fontWeight: FontWeight.w800,
                color: OrientationBrand.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Success modal shown after a redemption clears — a celebratory badge, the
/// reward and its price, and shortcuts to the history page or back to the
/// shop. A bottom-sheet modal whose content is inset (not full-bleed).
Future<void> showRedeemSuccessSheet(BuildContext context, Reward reward, {required VoidCallback onViewHistory}) {
  return AppBottomSheet.show<void>(
    context: context,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: _RedeemSuccessContent(reward: reward, onViewHistory: onViewHistory),
    ),
  );
}

class _RedeemSuccessContent extends StatelessWidget {
  const _RedeemSuccessContent({required this.reward, required this.onViewHistory});

  final Reward reward;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tint = RewardVisuals.tint(reward.image);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Product render inside a tinted disc, with an animated check badge.
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(RewardVisuals.photo(reward), fit: BoxFit.contain),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                      child: const AppIcon(AppIcons.checkCircle, size: 26, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.orientation_rw_success_title,
          textAlign: TextAlign.center,
          style: FeatureStyle.sectionTitle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.orientation_rw_success_body,
          textAlign: TextAlign.center,
          style: FeatureStyle.body.copyWith(color: FeatureStyle.mute, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: OrientationBrand.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reward.title, style: FeatureStyle.caption.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                // Token artwork keeps its own colours — never tinted.
                const AppIcon(AppIcons.tokenAdsl, size: 15),
                const SizedBox(width: 4),
                Text('−${formatTokens(reward.priceTokens)}',
                    style: FeatureStyle.caption.copyWith(color: OrientationBrand.accent, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FeatureCtaButton(accent: OrientationBrand.accent, 
          label: l10n.orientation_rw_view_history,
          onTap: () {
            Navigator.of(context).pop();
            onViewHistory();
          },
        ),
        const SizedBox(height: FeatureStyle.s8),
        FeatureCtaButton(accent: OrientationBrand.accent, 
          label: l10n.orientation_rw_done,
          style: FeatureCtaStyle.quiet,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
