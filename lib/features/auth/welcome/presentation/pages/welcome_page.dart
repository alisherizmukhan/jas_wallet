import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/routing/app_router.dart';

/// Welcome page with title on top, logo in center, Login/Register buttons.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authProvider.select((a) => a.status));

    if (authStatus == AuthStatus.appStarting ||
        authStatus == AuthStatus.unknown) {
      return const Scaffold(backgroundColor: AppColors.background);
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Title
                        Text(
                          l10n.welcome_title,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLight ? AppColors.textColor : AppColors.textColorDark,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Logo — centered, takes remaining space
                        const Spacer(),
                        AppIcon(AppIcons.logo, size: 140),
                        const Spacer(),

                        // Buttons pinned at bottom
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            key: const Key('welcomeLoginButton'),
                            onPressed: () => context.push(AppRoutes.login),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n.welcome_login,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            key: const Key('welcomeRegisterButton'),
                            onPressed: () => context.push(AppRoutes.registration),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n.welcome_register,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
