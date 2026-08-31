import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

/// Bottom sheet dialog asking the user if they want to enable biometric login.
/// Shown once after a successful manual login when biometric is not yet enabled.
class BiometricPromptDialog extends StatelessWidget {
  const BiometricPromptDialog({
    super.key,
    required this.onEnable,
    required this.onSkip,
  });

  final VoidCallback onEnable;
  final VoidCallback onSkip;

  /// Show this dialog as a modal bottom sheet. Returns `true` if user enabled.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BiometricPromptDialog(
        onEnable: () => Navigator.of(context).pop(true),
        onSkip: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppIcon(
                AppIcons.faceId,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              l10n.auth_biometricLoginTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isLight ? AppColors.textColor : AppColors.textColorDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              l10n.auth_biometricLoginDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Enable button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onEnable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.auth_biometricEnable,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Skip button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.auth_biometricMaybeLater,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
