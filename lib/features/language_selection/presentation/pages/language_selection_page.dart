import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/supported_locales.dart';
import '../../../../core/providers/auth_provider.dart';

/// Language selection page — shown only on first launch.
class LanguageSelectionPage extends ConsumerWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Logo — absolutely centered
          Center(
            child: AppIcon(AppIcons.logo, size: 140),
          ),

          // Language buttons
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Russian
                  _LanguageButton(
                    flag: '🇷🇺',
                    label: AppLocalizations.of(context)!.splash_russian,
                    onTap: () {
                      AnalyticsService.instance.trackLanguageSelected('ru');
                      ref.read(localeProvider.notifier).setLocale(SupportedLocales.russian);
                      ref.read(authProvider.notifier).completeLanguageSelection();
                    },
                  ),
                  const SizedBox(height: 12),
                  // English
                  _LanguageButton(
                    flag: '🇺🇸',
                    label: AppLocalizations.of(context)!.splash_english,
                    onTap: () {
                      AnalyticsService.instance.trackLanguageSelected('en');
                      ref.read(localeProvider.notifier).setLocale(SupportedLocales.english);
                      ref.read(authProvider.notifier).completeLanguageSelection();
                    },
                  ),
                  const SizedBox(height: 12),
                  // Kazakh
                  _LanguageButton(
                    flag: '🇰🇿',
                    label: AppLocalizations.of(context)!.splash_kazakh,
                    onTap: () {
                      AnalyticsService.instance.trackLanguageSelected('kk');
                      ref.read(localeProvider.notifier).setLocale(SupportedLocales.kazakh);
                      ref.read(authProvider.notifier).completeLanguageSelection();
                    },
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }
}

/// Language selection button matching the design.
class _LanguageButton extends StatelessWidget {
  final String flag;
  final String label;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.flag,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
