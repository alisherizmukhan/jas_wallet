import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

/// Personal data consent page — scrollable page with consent text.
/// Navigated to from the consent checkbox on the registration page.
class PersonalDataConsentPage extends StatelessWidget {
  const PersonalDataConsentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        showBackButton: true,
        showDivider: false,
        title: l10n.auth_personalDataConsent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            l10n.auth_personalDataConsentBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isLight ? AppColors.textColor : AppColors.textColorDark,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
