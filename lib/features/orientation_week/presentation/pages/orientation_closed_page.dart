import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

/// Shown once Orientation Week has locked for the season — see
/// `OrientationConfig.isClosed`.
///
/// Deliberately a plain [StatelessWidget] with no Riverpod providers and no
/// repository calls of any kind: this page *is* the "make zero Orientation
/// Week network requests" state, so it must not accidentally create one by
/// watching something that loads. Just an app bar with a back button and
/// static, localized text.
class OrientationClosedPage extends StatelessWidget {
  const OrientationClosedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppAppBar(showBackButton: true),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: AppColors.fieldBackground, shape: BoxShape.circle),
                  child: const AppIcon(AppIcons.calendar, size: 32, color: AppColors.grey),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.orientation_closed_title,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isLight ? AppColors.textPrimary : AppColors.textPrimaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.orientation_closed_body,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
