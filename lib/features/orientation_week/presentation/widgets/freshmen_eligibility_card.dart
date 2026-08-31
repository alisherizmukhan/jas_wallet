import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../theme/orientation_brand.dart';

/// "Who can participate" — a permanent, always-available restatement of the
/// one-time freshmen-eligibility notice shown the first time a student opens
/// Orientation Week (see `OrientationFreshmenNoticePage`).
///
/// That notice is seen exactly once and then never again, so a student who
/// skimmed past it — or an upperclassman who wandered in from a friend's
/// phone — has nowhere left to check the rule once they're looking at real
/// prizes. Folded shut by default, same as [RewardClaimCard] right above it.
class FreshmenEligibilityCard extends StatefulWidget {
  const FreshmenEligibilityCard({super.key});

  @override
  State<FreshmenEligibilityCard> createState() => _FreshmenEligibilityCardState();
}

class _FreshmenEligibilityCardState extends State<FreshmenEligibilityCard> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FeatureHeaderCard(
      icon: AppIcons.info,
      accent: OrientationBrand.accent,
      title: l10n.orientation_freshmen_card_title,
      collapsed: _collapsed,
      onToggle: () => setState(() => _collapsed = !_collapsed),
      body: Text(
        l10n.orientation_freshmen_body,
        style: FeatureStyle.body.copyWith(color: FeatureStyle.mute),
      ),
    );
  }
}
