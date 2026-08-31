import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Service that handles device biometric authentication (Face ID / fingerprint)
/// and secure credential storage. Acts as the single source of truth for all
/// biometric-related operations throughout the app.
class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  }) : _localAuth = localAuth ?? LocalAuthentication(),
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
             iOptions: IOSOptions(
               // Scoped to this device only — see AuthStorageService for why.
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  // ─── Storage keys ────────────────────────────────────────────────────
  static const _keyUsername = 'biometric_username';
  static const _keyPassword = 'biometric_password';
  static const _keyFingerprintEnabled = 'fingerprint_enabled';
  static const _keyFaceIdEnabled = 'face_id_enabled';
  static const _keyRememberMe = 'remember_me';
  static const _keyBiometricEnabled = 'auth_biometric_enabled';

  // ─── Device capability checks ────────────────────────────────────────

  /// Whether the device hardware supports biometric authentication.
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Whether biometrics (fingerprint / face) are enrolled on the device.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types on this device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Whether the device has fingerprint capability.
  Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong) ||
        (defaultTargetPlatform == TargetPlatform.android &&
            biometrics.isNotEmpty);
  }

  /// Whether the device has Face ID capability.
  Future<bool> hasFaceId() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Whether *any* biometric is available and enrolled.
  Future<bool> isBiometricAvailable() async {
    final supported = await isDeviceSupported();
    final canCheck = await canCheckBiometrics();
    return supported && canCheck;
  }

  // ─── Authentication ──────────────────────────────────────────────────

  /// Prompt the user for biometric authentication.
  /// Returns `true` if authentication succeeded.
  Future<bool> authenticate({
    String reason = 'Authenticate to continue',
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  // ─── Credential storage ──────────────────────────────────────────────

  /// Legacy API kept for compatibility.
  ///
  /// Bank-style auth must not persist login passwords on device. This method
  /// now acts as a no-op migration guard and removes any previously stored
  /// credential cache.
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await clearCredentials();
  }

  /// Legacy API kept for compatibility.
  ///
  /// Password-based local login is disabled; always returns no credentials.
  Future<({String? username, String? password})> getCredentials() async {
    return (username: null, password: null);
  }

  /// Legacy API kept for compatibility.
  ///
  /// Always false because password credential storage is disabled.
  Future<bool> hasStoredCredentials() async {
    return false;
  }

  /// Clear stored credentials.
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _keyUsername);
    await _secureStorage.delete(key: _keyPassword);
  }

  // ─── Fingerprint preference ──────────────────────────────────────────

  Future<bool> isFingerprintEnabled() async {
    final value = await _secureStorage.read(key: _keyFingerprintEnabled);
    return value == 'true';
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyFingerprintEnabled,
      value: enabled.toString(),
    );
    final hasFaceEnabled = await isFaceIdEnabled();
    final anyEnabled = enabled || hasFaceEnabled;
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: anyEnabled.toString(),
    );
    if (!anyEnabled) {
      await clearCredentials();
    }
  }

  // ─── Face ID preference ──────────────────────────────────────────────

  Future<bool> isFaceIdEnabled() async {
    final value = await _secureStorage.read(key: _keyFaceIdEnabled);
    return value == 'true';
  }

  Future<void> setFaceIdEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyFaceIdEnabled,
      value: enabled.toString(),
    );
    final hasFingerprintEnabled = await isFingerprintEnabled();
    final anyEnabled = enabled || hasFingerprintEnabled;
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: anyEnabled.toString(),
    );
    if (!anyEnabled) {
      await clearCredentials();
    }
  }

  // ─── Remember me ────────────────────────────────────────────────────

  Future<bool> isRememberMeEnabled() async {
    final value = await _secureStorage.read(key: _keyRememberMe);
    return value == 'true';
  }

  Future<void> setRememberMeEnabled(bool enabled) async {
    await _secureStorage.write(key: _keyRememberMe, value: enabled.toString());
  }

  // ─── Biometric invalidation (CASE 14) ────────────────────────────────

  /// Disable all biometric methods (called when OS invalidates biometric key).
  /// Used in CASE 14 when device biometric changes (new face/fingerprint).
  Future<void> disableBiometric() async {
    await setFingerprintEnabled(false);
    await setFaceIdEnabled(false);
  }

  // ─── Combined helpers ────────────────────────────────────────────────

  /// Whether any biometric login method is enabled by the user.
  Future<bool> isAnyBiometricEnabled() async {
    final globalEnabled =
        (await _secureStorage.read(key: _keyBiometricEnabled)) == 'true';
    final fp = await isFingerprintEnabled();
    final face = await isFaceIdEnabled();
    return globalEnabled || fp || face;
  }

  /// Clear all biometric data (preferences + credentials). Call on logout.
  Future<void> clearAll() async {
    await clearCredentials();
    await _secureStorage.delete(key: _keyFingerprintEnabled);
    await _secureStorage.delete(key: _keyFaceIdEnabled);
    await _secureStorage.delete(key: _keyRememberMe);
    await _secureStorage.delete(key: _keyBiometricEnabled);
  }
}
