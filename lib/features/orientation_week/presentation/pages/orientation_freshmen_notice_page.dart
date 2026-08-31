import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../theme/orientation_brand.dart';

/// Shown once, the first time a student ever opens Orientation Week — see
/// the Hub tile's tap handler, which pushes this and waits for `true`
/// before continuing to the real shell.
///
/// Purely informational and self-contained: no providers, no repository
/// calls. The "seen" flag lives in SharedPreferences and is written by the
/// caller once this pops `true`, not by this page itself, so the flag and
/// the navigation stay in the same place (the Hub tap handler) rather than
/// split across two files.
class OrientationFreshmenNoticePage extends StatelessWidget {
  const OrientationFreshmenNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: FeatureStyle.pageBackground,
        appBar: AppAppBar(showBackButton: true, onBackPressed: () => Navigator.of(context).pop(false)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: FeatureStyle.chipTint(OrientationBrand.accent),
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(AppIcons.info, size: 32, color: OrientationBrand.accent),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.orientation_freshmen_title,
                  style: AppTextStyles.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.orientation_freshmen_body,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                FeatureCtaButton(
                  accent: OrientationBrand.accent,
                  label: l10n.orientation_freshmen_acknowledge,
                  onTap: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
