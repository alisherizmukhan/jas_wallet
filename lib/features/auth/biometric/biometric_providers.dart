import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/services/biometric_auth_service.dart';

// ─── Service provider ──────────────────────────────────────────────────

/// Singleton instance of [BiometricAuthService].
final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

// ─── Device capability providers ───────────────────────────────────────

/// Whether the device hardware supports biometric auth at all.
final biometricSupportedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricAuthServiceProvider);
  return service.isBiometricAvailable();
});

/// Whether device has fingerprint sensor.
final hasFingerprintProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricAuthServiceProvider);
  return service.hasFingerprint();
});

/// Whether device has Face ID.
final hasFaceIdProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricAuthServiceProvider);
  return service.hasFaceId();
});

/// List of enrolled biometric types on this device.
final availableBiometricsProvider =
    FutureProvider<List<BiometricType>>((ref) async {
  final service = ref.watch(biometricAuthServiceProvider);
  return service.getAvailableBiometrics();
});

// ─── Fingerprint preference ────────────────────────────────────────────

final fingerprintEnabledProvider =
    StateNotifierProvider<_BoolPrefNotifier, AsyncValue<bool>>((ref) {
  final service = ref.watch(biometricAuthServiceProvider);
  return _BoolPrefNotifier(
    service: service,
    load: () => service.isFingerprintEnabled(),
    save: (v) => service.setFingerprintEnabled(v),
    authReason: 'Verify your identity to enable Fingerprint',
  );
});

// ─── Face ID preference ────────────────────────────────────────────────

final faceIdEnabledProvider =
    StateNotifierProvider<_BoolPrefNotifier, AsyncValue<bool>>((ref) {
  final service = ref.watch(biometricAuthServiceProvider);
  return _BoolPrefNotifier(
    service: service,
    load: () => service.isFaceIdEnabled(),
    save: (v) => service.setFaceIdEnabled(v),
    authReason: 'Verify your identity to enable Face ID',
  );
});

// ─── Remember Me preference ───────────────────────────────────────────

final rememberMeEnabledProvider =
    StateNotifierProvider<_BoolPrefNotifier, AsyncValue<bool>>((ref) {
  final service = ref.watch(biometricAuthServiceProvider);
  return _BoolPrefNotifier(
    service: service,
    load: () => service.isRememberMeEnabled(),
    save: (v) => service.setRememberMeEnabled(v),
    requireAuth: false,
  );
});

// ─── Whether any biometric login method is currently enabled ──────────

final anyBiometricEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricAuthServiceProvider);
  return service.isAnyBiometricEnabled();
});

/// Whether credentials are currently stored in secure storage.
final hasStoredCredentialsProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricAuthServiceProvider);
  return service.hasStoredCredentials();
});

// ─── Shared notifier for bool preferences persisted in secure storage ──

class _BoolPrefNotifier extends StateNotifier<AsyncValue<bool>> {
  _BoolPrefNotifier({
    required this.service,
    required this.load,
    required this.save,
    this.authReason,
    this.requireAuth = true,
  }) : super(const AsyncValue.loading()) {
    _init();
  }

  final BiometricAuthService service;
  final Future<bool> Function() load;
  final Future<void> Function(bool) save;
  final String? authReason;
  final bool requireAuth;

  Future<void> _init() async {
    try {
      final v = await load();
      if (mounted) state = AsyncValue.data(v);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Toggle the preference. If [requireAuth] and enabling, verify biometric
  /// first. Returns true if the change was applied.
  Future<bool> setEnabled(bool enabled) async {
    if (requireAuth && enabled) {
      final ok = await service.authenticate(
        reason: authReason ?? 'Verify your identity',
      );
      if (!ok) return false;
    }
    await save(enabled);
    if (mounted) state = AsyncValue.data(enabled);
    return true;
  }

  /// Reload from storage.
  Future<void> refresh() async => _init();
}
