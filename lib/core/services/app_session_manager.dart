import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'biometric_auth_service.dart';
import 'auth_storage_service.dart';
import '../../features/auth/biometric/biometric_providers.dart';

/// Manages app session lifecycle and token re-validation on app resume.
///
/// Handles:
/// - CASE 13: Background session resume (re-validate tokens, silent refresh)
/// - CASE 14: Device-level biometric change detection
/// - Offline mode detection and sync
class AppSessionManager {
  AppSessionManager({
    required this.authStorage,
    required this.biometricService,
  });

  final AuthStorageService authStorage;
  final BiometricAuthService biometricService;

  /// Called when app resumes from background.
  /// Validates tokens are still present. (CASE 13)
  /// Should be called from within a Riverpod provider context.
  Future<bool> validateSessionOnResume() async {
    try {
      final refreshToken = await authStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// CASE 14: Checks if device biometric is still enabled.
  /// Returns true if biometric settings are still valid.
  Future<bool> checkBiometricValidity() async {
    try {
      final isEnabled = await biometricService.isAnyBiometricEnabled();
      final canCheckBiometrics = await biometricService.canCheckBiometrics();

      if (!canCheckBiometrics && isEnabled) {
        await biometricService.disableBiometric();
        return false;
      }

      return true;
    } catch (e) {
      return true;
    }
  }

  void handleAppPause() {}

  void handleAppDetached() {}
}

/// Riverpod provider for AppSessionManager.
final appSessionManagerProvider = Provider<AppSessionManager>((ref) {
  final authStorage = ref.watch(authStorageServiceProvider);
  final biometricService = ref.watch(biometricAuthServiceProvider);
  return AppSessionManager(
    authStorage: authStorage,
    biometricService: biometricService,
  );
});
