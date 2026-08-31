import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../auth/biometric/biometric_providers.dart';
import '../../../../core/providers/auth_provider.dart';

/// Biometric setup page.
///
/// Shown once after PIN creation. Prompts the user to enable
/// Face ID / Fingerprint for faster login on subsequent app opens.
class BiometricSetupPage extends ConsumerStatefulWidget {
  const BiometricSetupPage({super.key});

  @override
  ConsumerState<BiometricSetupPage> createState() => _BiometricSetupPageState();
}

class _BiometricSetupPageState extends ConsumerState<BiometricSetupPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check setup state synchronously in first frame for instant skip.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSkipSetup());
  }

  Future<void> _maybeSkipSetup() async {
    final authStorage = ref.read(authStorageServiceProvider);
    // Parallelize the two storage reads for speed.
    final results = await Future.wait([
      authStorage.isBiometricEnabled(),
      authStorage.isBiometricSetupCompleted(),
    ]);
    final alreadyEnabled = results[0];
    final setupCompleted = results[1];
    if (!mounted) return;
    if (alreadyEnabled || setupCompleted) {
      await ref.read(authProvider.notifier).completeBiometricSetup(
        biometricEnabled: alreadyEnabled,
      );
    }
  }

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);

    final biometricService = ref.read(biometricAuthServiceProvider);
    final authStorage = ref.read(authStorageServiceProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    final success = await biometricService.authenticate(
      reason: l10n.biometric_setupReason,
    );

    if (!mounted) return;

    if (success) {
      AnalyticsService.instance.trackBiometricEnabled();
      // Fire storage writes in background — don't block app open on them.
      unawaited(authStorage.setBiometricEnabled(true));
      unawaited(
        Future.wait([biometricService.hasFaceId(), biometricService.hasFingerprint()])
            .then((results) async {
          if (results[0]) await biometricService.setFaceIdEnabled(true);
          if (results[1]) await biometricService.setFingerprintEnabled(true);
        }),
      );
      // Open app immediately — biometricEnabled is known to be true.
      await authNotifier.completeBiometricSetup(biometricEnabled: true);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _skipBiometric() async {
    AnalyticsService.instance.trackBiometricSetupSkipped();
    final biometricService = ref.read(biometricAuthServiceProvider);
    final authStorage = ref.read(authStorageServiceProvider);
    // Fire cleanup in background — don't block navigation on writes.
    unawaited(biometricService.disableBiometric());
    unawaited(authStorage.setBiometricEnabled(false));
    await ref.read(authProvider.notifier).completeBiometricSetup(biometricEnabled: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Spacer(flex: 2),

              // Biometric icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: AppIcon(
                  AppIcons.faceId,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                l10n.biometric_setupTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLight ? AppColors.textColor : AppColors.textColorDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.biometric_setupDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 3),

              // Enable button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enableBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          l10n.biometric_setupEnable,
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
                height: 56,
                child: TextButton(
                  onPressed: _isLoading ? null : _skipBiometric,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.biometric_setupSkip,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
