import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// Help page with Telegram and Email options.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const String _telegramUrl = 'https://t.me/bflabnu/17';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: l10n.help_title,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            
            // Header image/illustration
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  AppIcons.call,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Center(
              child: Text(
                l10n.help_title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.help_subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
              ),
            ),
            SizedBox(height: 32),

            // Help options
            _buildHelpOption(
              context: context,
              icon: AppIcons.users,
              title: l10n.help_telegramTitle,
              subtitle: l10n.help_telegramSubtitle,
              color: AppColors.primary,
              onTap: () => _openTelegramGroup(context),
            ),
            const SizedBox(height: 10),

            _buildHelpOption(
              context: context,
              icon: AppIcons.email,
              title: l10n.help_email,
              subtitle: l10n.help_supportEmail,
              color: const Color(0xFFFF9500), // Orange accent
              onTap: () => _sendEmail(context, l10n.help_supportEmail),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption({
    required BuildContext context,
    required AppIconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Material(
      color: isLight ? AppColors.white : const Color(0xFF242424),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcon(
                AppIcons.chevronRight,
                color: AppColors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTelegramGroup(BuildContext context) async {
    final uri = Uri.parse(_telegramUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (context.mounted) {
      AppToast.showError(context, AppLocalizations.of(context)!.help_telegramOpenFailed);
    }
  }

  void _sendEmail(BuildContext context, String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': AppLocalizations.of(context)!.help_emailSubject,
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        AppToast.showError(
          context,
          AppLocalizations.of(context)!.help_emailSendFailed(email),
        );
      }
    }
  }
}
