import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app_ui/app_ui.dart';
import '../../../../l10n/app_localizations.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(title: l10n.about_title, showBackButton: true),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isLight ? AppColors.white : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isLight
                              ? AppColors.borderGrey
                              : AppColors.borderDark,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(
                              alpha: isLight ? 0.08 : 0.25,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(child: AppIcon(AppIcons.logo, size: 56)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final info = snapshot.data;
                        final version = info == null
                            ? ''
                            : 'v${info.version} (${info.buildNumber})';
                        return Text(
                          '${l10n.about_version} $version',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.about_developedBy,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.about_supportedBy,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
