import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../config/orientation_links.dart';
import '../theme/orientation_brand.dart';

/// "How to get your prize" — the instructions for turning a redeemed reward
/// into something the student actually holds.
///
/// Redeeming in the app is only half of it: prizes are handed over in person,
/// after a check on site. Without this on the page a student redeems, gets a
/// confirmation, and then has nobody to ask — so it sits on the Rewards page
/// itself rather than behind the redeem flow, where only someone who has
/// already spent their tokens would ever find it.
///
/// Folded shut by default, like the explainer on the Overview: three steps
/// and a phone number are the right amount of detail *once*, and dead weight
/// above the marketplace on every visit after that.
class RewardClaimCard extends StatefulWidget {
  const RewardClaimCard({super.key});

  @override
  State<RewardClaimCard> createState() => _RewardClaimCardState();
}

class _RewardClaimCardState extends State<RewardClaimCard> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FeatureHeaderCard(
      icon: AppIcons.gift,
      accent: OrientationBrand.accent,
      title: l10n.orientation_rw_claim_title,
      collapsed: _collapsed,
      onToggle: () => setState(() => _collapsed = !_collapsed),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orientation_rw_claim_intro,
            style: FeatureStyle.body.copyWith(color: FeatureStyle.mute),
          ),
          const SizedBox(height: FeatureStyle.s16),
          _Step(number: 1, label: l10n.orientation_rw_claim_step1),
          const SizedBox(height: FeatureStyle.s12),
          _Step(
            number: 2,
            label: l10n.orientation_rw_claim_step2(OrientationLinks.prizeWhatsAppNumber),
          ),
          const SizedBox(height: FeatureStyle.s12),
          _Step(number: 3, label: l10n.orientation_rw_claim_step3),
          const SizedBox(height: FeatureStyle.s16),
          FeatureCtaButton(accent: OrientationBrand.accent, 
            label: l10n.orientation_rw_claim_cta,
            icon: AppIcons.whatsapp,
            onTap: () => openOrientationLink(OrientationLinks.prizeWhatsApp),
          ),
        ],
      ),
    );
  }
}

/// One numbered instruction. The numeral sits in the same 28px chip the
/// About card's points use, so a numbered list and an icon list line up on
/// the same left column.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.label});

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: FeatureStyle.chipTint(OrientationBrand.accent),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              '$number',
              style: FeatureStyle.caption.copyWith(
                color: OrientationBrand.accent,
                fontWeight: FontWeight.w700,
                fontFeatures: FeatureStyle.tabular,
              ),
            ),
          ),
        ),
        const SizedBox(width: FeatureStyle.s12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              label,
              style: FeatureStyle.body.copyWith(color: FeatureStyle.bodyInk),
            ),
          ),
        ),
      ],
    );
  }
}

/// Technical support, folded shut by default — separate from prize pickup.
class RewardTechSupportCard extends StatefulWidget {
  const RewardTechSupportCard({super.key});

  @override
  State<RewardTechSupportCard> createState() => _RewardTechSupportCardState();
}

class _RewardTechSupportCardState extends State<RewardTechSupportCard> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FeatureHeaderCard(
      icon: AppIcons.telegram,
      accent: OrientationBrand.accent,
      title: l10n.orientation_rw_tech_cta,
      collapsed: _collapsed,
      onToggle: () => setState(() => _collapsed = !_collapsed),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orientation_rw_tech_body,
            style: FeatureStyle.body.copyWith(color: FeatureStyle.mute),
          ),
          const SizedBox(height: FeatureStyle.s16),
          FeatureCtaButton(
            accent: OrientationBrand.accent,
            label: l10n.orientation_rw_tech_open,
            icon: AppIcons.telegram,
            onTap: () => openOrientationLink(OrientationLinks.techSupportTelegram),
          ),
        ],
      ),
    );
  }
}
