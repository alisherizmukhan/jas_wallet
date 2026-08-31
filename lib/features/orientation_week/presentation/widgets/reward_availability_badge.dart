import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/reward.dart';
import '../theme/orientation_brand.dart';

/// The small rounded stock badge — "Unlimited", "Limited: 5 left", etc. Its
/// tint encodes urgency: neutral for unlimited, amber for limited, muted for
/// unavailable states.
class RewardAvailabilityBadge extends StatelessWidget {
  const RewardAvailabilityBadge({super.key, required this.reward, this.compact = false});

  final Reward reward;

  /// A tighter variant for dense list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (label, color) = switch (reward.availability) {
      RewardAvailability.unlimited => (l10n.orientation_rw_unlimited, OrientationBrand.accent),
      RewardAvailability.limited => (
          l10n.orientation_rw_limited(reward.stockRemaining ?? 0),
          OrientationBrand.accentOrange,
        ),
      RewardAvailability.outOfStock => (l10n.orientation_rw_out_of_stock, AppColors.grey),
      RewardAvailability.comingSoon => (l10n.orientation_rw_coming_soon, OrientationBrand.accentCobalt),
      RewardAvailability.expired => (l10n.orientation_rw_expired, AppColors.grey),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: FeatureStyle.tiny.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
