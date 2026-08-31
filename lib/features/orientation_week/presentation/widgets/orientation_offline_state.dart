import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import '../theme/orientation_brand.dart';


class OrientationOfflineState extends StatelessWidget {
  const OrientationOfflineState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.fieldBackground, shape: BoxShape.circle),
            child: const AppIcon(AppIcons.wifiOff, size: 28, color: AppColors.grey),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.orientation_offline_title,
            style: AppTextStyles.titleMedium.copyWith(
              color: isLight ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.orientation_offline_message,
            style: AppTextStyles.bodySmall.copyWith(color: FeatureStyle.mute),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FeatureCtaButton(accent: OrientationBrand.accent, label: l10n.common_retry, onTap: onRetry),
        ],
      ),
    );
  }
}
