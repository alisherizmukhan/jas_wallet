import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';

/// Screen shown when a user without SVC access tries to open
/// the Social Meal Program.
class SVCAccessDeniedPage extends StatelessWidget {
  const SVCAccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.svc_title),
        leading: IconButton(
          tooltip: l10n.common_back,
          icon: const AppIcon(AppIcons.back, size: 24),
          onPressed: () => context.go(AppRoutes.hub),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: isLight ? AppColors.errorLight : AppColors.red.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: AppIcon(
                      AppIcons.close,
                      size: 48,
                      color: AppColors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.svc_accessDenied,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.svc_accessDeniedHint,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.hub),
                    child: Text(l10n.common_back),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
