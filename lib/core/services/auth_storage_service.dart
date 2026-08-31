import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/salto/data/repositories/access_log_repository.dart';
import 'profile_cache_service.dart';
import 'profile_pending_edit_service.dart';
import 'package:uuid/uuid.dart';

/// Persistent auth storage service.
///
/// Uses [FlutterSecureStorage] for sensitive data (tokens, credentials, PIN)
/// and [SharedPreferences] for non-sensitive flags (onboarding completion).
///
/// This is the single source of truth for persisted auth / session state.
///
/// Call [init] once at app startup to prime the [SharedPreferences] cache.
class AuthStorageService {
  AuthStorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              // Scoped to this device only — Keychain items are excluded from
              // encrypted device backups, so tokens/PIN/SALTO key can't be
              // restored onto a different physical device.
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _secureStorage;

  /// Cached [SharedPreferences] instance — avoids repeated async lookups.
  SharedPreferences? _prefs;

  /// Get or create the cached [SharedPreferences] instance.
  Future<SharedPreferences> get _sharedPrefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Pre-load caches. Call once from main() before runApp or from
  /// [AuthNotifier._init] to ensure storage is ready.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Batch read for fast auth state resolution ───────────────────────
  
  /// Read all auth-related secure storage keys in ONE call.
  /// This is MUCH faster than multiple individual reads during cold start.
  /// Returns a map with all auth keys - missing keys will be null.
  Future<Map<String, String?>> readAllAuthKeys() async {
    try {
      final all = await _secureStorage.readAll();
      return {
        'isLoggedIn': all[_keyIsLoggedIn],
        'userId': all[_keyUserId],
        'refreshToken': all[_keyRefreshToken],
        'hasPin': all[_keyHasPin],
        'biometricEnabled': all[_keyBiometricEnabled],
        'biometricSetupCompleted': all[_keyBiometricSetupCompleted],
        'pinFailedAttempts': all[_keyPinFailedAttempts],
      };
    } catch (e) {
      return {};
    }
  }

  // ─── Secure storage keys ─────────────────────────────────────────────
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyIsLoggedIn = 'auth_is_logged_in';
  static const _keyPinHash = 'auth_pin_hash';
  static const _keyPinSalt = 'auth_pin_salt';
  static const _keyHasPin = 'auth_has_pin';
  static const _keyBiometricEnabled = 'auth_biometric_enabled';
  static const _keyBiometricSetupCompleted = 'auth_biometric_setup_completed';
  static const _keyPinFailedAttempts = 'auth_pin_failed_attempts';
  static const _keyPinLockUntil = 'auth_pin_lock_until';
  static const _keySaltoMobilePhoneId = 'salto_mobile_phone_id';
  static const _keySaltoDigitalKey = 'salto_digital_key_hex';
  static const _keySaltoDigitalKeyAt = 'salto_digital_key_stored_at';
  static const _keySaltoMobileStatus = 'salto_mobile_status_json';
  static const _keySaltoMobileStatusAt = 'salto_mobile_status_stored_at';
  static const _keyFcmToken = 'fcm_device_token';

  /// The token value that was last successfully PUT to the backend — distinct
  /// from [_keyFcmToken] (the device's current token), so [FcmTokenSyncService]
  /// can skip a redundant PUT when nothing has actually changed since the last
  /// successful sync (multiple independent triggers — token rotation, every
  /// auth-state transition to authenticated — otherwise each fire their own
  /// unconditional PUT of an unchanged value).
  static const _keyFcmTokenSyncedValue = 'fcm_device_token_synced_value';

  // ─── SharedPreferences keys ──────────────────────────────────────────
  static const _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const _keyHasSelectedLanguage = 'has_selected_language';
  static const _keyIsOfflineMode = 'auth_is_offline_mode';
  static const _saltoDesignKeyPrefix = 'salto_student_card_design_';
  static const _saltoCustomImageKeyPrefix = 'salto_student_card_custom_image_';

  /// Non-sensitive backup flag in SharedPreferences for hasPin.
  /// The actual PIN hash stays in secure storage — this is only a boolean
  /// so we can survive Android Keystore cold-start failures.
  static const _keyHasPinBackup = 'has_pin_backup';
  static const _keySessionExistsBackup = 'session_exists_backup';
  static const _keyUserIdBackup = 'user_id_backup';

  /// Marks that an OTP-verified registration is in progress but the profile
  /// (and password) has not been completed yet. Used to avoid treating an
  /// abandoned registration as a valid returning session on cold start.
  static const _keyRegistrationPending = 'registration_pending';

  // ─── Login state ─────────────────────────────────────────────────────

  /// Persist login session. Call after successful authentication.
  ///
  /// [userId] — the authenticated user's ID.
  /// [accessToken] — JWT or API token (optional until backend is ready).
  /// [refreshToken] — refresh token (optional until backend is ready).
  Future<void> saveSession({
    required String userId,
    String? accessToken,
    String? refreshToken,
  }) async {
    await _secureStorage.write(key: _keyUserId, value: userId);
    await _secureStorage.write(key: _keyIsLoggedIn, value: 'true');
    if (accessToken != null) {
      await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    }
    if (refreshToken != null) {
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    }
    // Backup session flags in SharedPreferences so cold-start secure
    // storage timeouts don't falsely log the user out.
    final prefs = await _sharedPrefs;
    await prefs.setBool(_keySessionExistsBackup, true);
    await prefs.setString(_keyUserIdBackup, userId);
  }

  /// Mark whether an OTP-verified registration is still incomplete.
  ///
  /// Set to `true` right after OTP verification (session tokens are stored so
  /// the complete-profile call can authenticate) and cleared once the profile
  /// is successfully completed. If the app is killed in between, cold-start
  /// resolution uses this flag to discard the half-created session instead of
  /// silently logging the user in without a password / profile.
  Future<void> setRegistrationPending(bool pending) async {
    final prefs = await _sharedPrefs;
    if (pending) {
      await prefs.setBool(_keyRegistrationPending, true);
    } else {
      await prefs.remove(_keyRegistrationPending);
    }
  }

  /// Whether an OTP-verified registration is still incomplete.
  Future<bool> isRegistrationPending() async {
    try {
      final prefs = await _sharedPrefs;
      return prefs.getBool(_keyRegistrationPending) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Whether the user has an active persisted session.
  Future<bool> isLoggedIn() async {
    try {
      final value = await _secureStorage.read(key: _keyIsLoggedIn);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Retrieve persisted user ID (null if not logged in).
  Future<String?> getUserId() async {
    return _secureStorage.read(key: _keyUserId);
  }

  /// Retrieve the stored access token.
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _keyAccessToken);
  }

  /// Retrieve the stored refresh token.
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _keyRefreshToken);
  }

  /// Set the access token.
  Future<void> setAccessToken(String token) async {
    await _secureStorage.write(key: _keyAccessToken, value: token);
  }

  /// Set the refresh token.
  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: _keyRefreshToken, value: token);
  }

  /// Clear the access token.
  Future<void> clearAccessToken() async {
    await _secureStorage.delete(key: _keyAccessToken);
  }

  /// Clear the refresh token.
  Future<void> clearRefreshToken() async {
    await _secureStorage.delete(key: _keyRefreshToken);
  }

  /// Delete a key from secure storage (generic method).
  Future<void> delete({required String key}) async {
    await _secureStorage.delete(key: key);
  }

  /// In-flight read-or-create, de-duplicating concurrent callers.
  ///
  /// Without this, two callers racing on a fresh install/first SALTO use
  /// (typically the status fetch and the activation request, both fired
  /// within moments of the activation page mounting) could each read an
  /// empty secure-storage value before either write lands, each generate a
  /// *different* UUID via [Uuid.v4], and each persist their own — leaving
  /// the status check and the activation POST using inconsistent device
  /// IDs on the very first attempt. The backend then reasonably treats
  /// that as "a different device" and the activation is rejected, which
  /// looks to the user like "it didn't work the first time" even though a
  /// stable ID exists on every retry afterward.
  Future<String>? _inFlightMobilePhoneId;

  Future<String> getOrCreateSaltoMobilePhoneId() {
    final inFlight = _inFlightMobilePhoneId;
    if (inFlight != null) return inFlight;

    final future = _doGetOrCreateSaltoMobilePhoneId();
    _inFlightMobilePhoneId = future;
    return future.whenComplete(() {
      if (identical(_inFlightMobilePhoneId, future)) {
        _inFlightMobilePhoneId = null;
      }
    });
  }

  Future<String> _doGetOrCreateSaltoMobilePhoneId() async {
    final existing = await _secureStorage.read(key: _keySaltoMobilePhoneId);
    final normalized = existing?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }

    const uuid = Uuid();
    final generated = uuid.v4();
    await _secureStorage.write(key: _keySaltoMobilePhoneId, value: generated);
    return generated;
  }

  // ─── Salto digital key persistence (7-day offline cache) ─────────────

  static const _saltoKeyTtl = Duration(days: 7);

  Future<void> saveSaltoDigitalKey(String keyHex) async {
    await _secureStorage.write(key: _keySaltoDigitalKey, value: keyHex);
    await _secureStorage.write(
      key: _keySaltoDigitalKeyAt,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getSaltoDigitalKey() async {
    final keyHex = await _secureStorage.read(key: _keySaltoDigitalKey);
    if (keyHex == null || keyHex.trim().isEmpty) return null;

    final storedAtStr = await _secureStorage.read(key: _keySaltoDigitalKeyAt);
    if (storedAtStr == null) return null;

    final storedAt = DateTime.tryParse(storedAtStr);
    if (storedAt == null) return null;

    if (DateTime.now().difference(storedAt) > _saltoKeyTtl) {
      // Delete key bytes only — keep the timestamp so callers can detect
      // "key was expired" vs "key was never issued" and use forceRefresh=true.
      await _secureStorage.delete(key: _keySaltoDigitalKey);
      return null;
    }

    return keyHex.trim();
  }

  /// Returns when the digital key was stored, without enforcing the TTL.
  /// Returns null if no timestamp is persisted.
  Future<DateTime?> getSaltoDigitalKeyStoredAt() async {
    final str = await _secureStorage.read(key: _keySaltoDigitalKeyAt);
    return str != null ? DateTime.tryParse(str) : null;
  }

  Future<void> clearSaltoDigitalKey() async {
    await _secureStorage.delete(key: _keySaltoDigitalKey);
    await _secureStorage.delete(key: _keySaltoDigitalKeyAt);
  }

  // ─── FCM device token (secure storage) ───────────────────────────────

  Future<void> setFcmToken(String token) async {
    await _secureStorage.write(key: _keyFcmToken, value: token);
  }

  Future<String?> getFcmToken() async {
    return _secureStorage.read(key: _keyFcmToken);
  }

  /// The token value last confirmed synced to the backend (or null if never
  /// synced this session/install). Used by [FcmTokenSyncService] to skip a
  /// redundant PUT when the token hasn't actually changed.
  Future<String?> getLastSyncedFcmToken() async {
    return _secureStorage.read(key: _keyFcmTokenSyncedValue);
  }

  /// Record that [token] was just successfully synced to the backend.
  Future<void> markFcmTokenSynced(String token) async {
    await _secureStorage.write(key: _keyFcmTokenSyncedValue, value: token);
  }

  /// Forget the last-synced token value (e.g. after unregistering it on
  /// logout) so the next login is free to re-PUT the same token value if it
  /// hasn't rotated, rather than treating it as already synced.
  Future<void> clearLastSyncedFcmToken() async {
    await _secureStorage.delete(key: _keyFcmTokenSyncedValue);
  }

  // ─── Salto mobile status persistence (7-day offline cache) ───────────

  static const _saltoStatusTtl = Duration(days: 7);

  Future<void> saveSaltoMobileStatus(String jsonString) async {
    await _secureStorage.write(key: _keySaltoMobileStatus, value: jsonString);
    await _secureStorage.write(
      key: _keySaltoMobileStatusAt,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getSaltoMobileStatus() async {
    final json = await _secureStorage.read(key: _keySaltoMobileStatus);
    if (json == null || json.trim().isEmpty) return null;

    final storedAtStr =
        await _secureStorage.read(key: _keySaltoMobileStatusAt);
    if (storedAtStr == null) return null;

    final storedAt = DateTime.tryParse(storedAtStr);
    if (storedAt == null) return null;

    if (DateTime.now().difference(storedAt) > _saltoStatusTtl) {
      await clearSaltoMobileStatus();
      return null;
    }

    return json.trim();
  }

  Future<void> clearSaltoMobileStatus() async {
    await _secureStorage.delete(key: _keySaltoMobileStatus);
    await _secureStorage.delete(key: _keySaltoMobileStatusAt);
  }

  Future<void> clearSession() async {
    // Capture the outgoing user's ID before it's deleted below, so the SALTO
    // access log can be cleared under the correct per-user-scoped key.
    final outgoingUserId = await _secureStorage.read(key: _keyUserId);

    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _keyUserId);
    await _secureStorage.delete(key: _keyIsLoggedIn);
    await _secureStorage.delete(key: _keySaltoDigitalKey);
    await _secureStorage.delete(key: _keySaltoDigitalKeyAt);
    await _secureStorage.delete(key: _keySaltoMobileStatus);
    await _secureStorage.delete(key: _keySaltoMobileStatusAt);
    // Device-identity UUID and push token — cleared on every logout so a
    // shared/resold device never binds a new account to the previous
    // user's SALTO device identity or misdirects push notifications.
    await _secureStorage.delete(key: _keySaltoMobilePhoneId);
    await _secureStorage.delete(key: _keyFcmToken);
    await _secureStorage.delete(key: _keyFcmTokenSyncedValue);
    // SALTO access/attempt logs (this user's scoped entries, plus any
    // legacy unscoped entries from before per-user scoping existed) — never
    // leave a shared device holding one user's building-access history for
    // the next person who logs in.
    await AccessLogRepository(userId: outgoingUserId).clearAttempts();
    // Clear SharedPreferences session backup flags.
    final prefsForSession = await _sharedPrefs;
    await prefsForSession.remove(_keySessionExistsBackup);
    await prefsForSession.remove(_keyUserIdBackup);
    await prefsForSession.remove(_keyRegistrationPending);

    // Session/account boundary cleanup for user-scoped SharedPreferences data.
    final prefs = await _sharedPrefs;
    final keysToRemove = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(_saltoDesignKeyPrefix) ||
              key.startsWith(_saltoCustomImageKeyPrefix),
        )
        .toList(growable: false);
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    // Clear cached profile resume sections.
    await ProfileCacheService.clearAll();

    // Never let a queued offline profile edit replay against a different
    // account on a shared device.
    await ProfilePendingEditService.clear();
  }

  // ─── Onboarding / first-launch flags ─────────────────────────────────

  /// Whether the user has completed the onboarding flow.
  Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await _sharedPrefs;
      return prefs.getBool(_keyHasSeenOnboarding) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark onboarding as completed.
  Future<void> setOnboardingSeen() async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(_keyHasSeenOnboarding, true);
  }

  /// Whether the user has selected a language.
  Future<bool> hasSelectedLanguage() async {
    try {
      final prefs = await _sharedPrefs;
      return prefs.getBool(_keyHasSelectedLanguage) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark language selection as done.
  Future<void> setLanguageSelected() async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(_keyHasSelectedLanguage, true);
  }

  // ─── Offline mode ────────────────────────────────────────────────────

  /// Whether the app is in offline mode (no network connectivity).
  /// When offline, local auth is allowed but API calls are restricted.
  Future<bool> isOfflineMode() async {
    try {
      final prefs = await _sharedPrefs;
      return prefs.getBool(_keyIsOfflineMode) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Set the offline mode flag.
  Future<void> setOfflineMode(bool offline) async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(_keyIsOfflineMode, offline);
  }

  // ─── PIN management ──────────────────────────────────────────────────

  /// Store the hashed PIN and its salt.
  Future<void> savePinHash({required String hash, required String salt}) async {
    await _secureStorage.write(key: _keyPinHash, value: hash);
    await _secureStorage.write(key: _keyPinSalt, value: salt);
    await _secureStorage.write(key: _keyHasPin, value: 'true');
    // Also persist a non-sensitive backup flag in SharedPreferences.
    // This survives Android Keystore cold-start failures.
    final prefs = await _sharedPrefs;
    await prefs.setBool(_keyHasPinBackup, true);
  }

  /// Whether the user has created a PIN.
  Future<bool> hasPin() async {
    try {
      final value = await _secureStorage.read(key: _keyHasPin);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Read the stored PIN hash.
  Future<String?> getPinHash() async {
    return _secureStorage.read(key: _keyPinHash);
  }

  /// Read the stored PIN salt.
  Future<String?> getPinSalt() async {
    return _secureStorage.read(key: _keyPinSalt);
  }

  /// Clear the stored PIN.
  Future<void> clearPin() async {
    await _secureStorage.delete(key: _keyPinHash);
    await _secureStorage.delete(key: _keyPinSalt);
    await _secureStorage.delete(key: _keyHasPin);
    await clearPinLock();
    // Also remove the SharedPreferences backup flag.
    final prefs = await _sharedPrefs;
    await prefs.remove(_keyHasPinBackup);
  }

  /// Fallback check using SharedPreferences when secure storage is
  /// unavailable (e.g. Android Keystore not ready on cold start).
  Future<bool> hasPinFallback() async {
    try {
      final prefs = await _sharedPrefs;
      return prefs.getBool(_keyHasPinBackup) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Fallback check: does a session exist (SharedPreferences backup)?
  Future<bool> hasSessionFallback() async {
    try {
      final prefs = await _sharedPrefs;
      return prefs.getBool(_keySessionExistsBackup) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Fallback: get the user ID from SharedPreferences backup.
  Future<String?> getUserIdFallback() async {
    try {
      final prefs = await _sharedPrefs;
      return prefs.getString(_keyUserIdBackup);
    } catch (e) {
      return null;
    }
  }

  // ─── PIN lock (brute-force protection) ───────────────────────────────

  /// Get the number of failed PIN attempts.
  Future<int> getPinFailedAttempts() async {
    try {
      final value = await _secureStorage.read(key: _keyPinFailedAttempts);
      return value != null ? int.tryParse(value) ?? 0 : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Increment the failed PIN attempt counter and return the new value.
  ///
  /// If [current] is provided, avoids an extra secure-storage read.
  Future<int> incrementPinFailedAttempts({int? current}) async {
    final next = (current ?? await getPinFailedAttempts()) + 1;
    await _secureStorage.write(
      key: _keyPinFailedAttempts,
      value: next.toString(),
    );
    return next;
  }

  /// Reset the failed PIN attempt counter.
  Future<void> resetPinFailedAttempts() async {
    await _secureStorage.delete(key: _keyPinFailedAttempts);
  }

  /// Set a lock-until timestamp (milliseconds since epoch).
  Future<void> setPinLockUntil(DateTime until) async {
    await _secureStorage.write(
      key: _keyPinLockUntil,
      value: until.millisecondsSinceEpoch.toString(),
    );
  }

  /// Get the lock-until timestamp. Returns null if not locked.
  Future<DateTime?> getPinLockUntil() async {
    try {
      final value = await _secureStorage.read(key: _keyPinLockUntil);
      if (value == null) return null;
      final ms = int.tryParse(value);
      if (ms == null) return null;
      final lockTime = DateTime.fromMillisecondsSinceEpoch(ms);
      if (lockTime.isBefore(DateTime.now())) {
        await clearPinLock();
        return null;
      }
      return lockTime;
    } catch (_) {
      return null;
    }
  }

  /// Clear the PIN lock.
  Future<void> clearPinLock() async {
    await _secureStorage.delete(key: _keyPinFailedAttempts);
    await _secureStorage.delete(key: _keyPinLockUntil);
  }

  // ─── Biometric preference ───────────────────────────────────────────

  /// Whether the user has enabled biometric authentication for app unlock.
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _keyBiometricEnabled);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Set the biometric authentication preference.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  /// Whether the biometric setup prompt has been shown.
  Future<bool> isBiometricSetupCompleted() async {
    try {
      final value = await _secureStorage.read(key: _keyBiometricSetupCompleted);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Mark the biometric setup prompt as completed.
  Future<void> setBiometricSetupCompleted() async {
    await _secureStorage.write(key: _keyBiometricSetupCompleted, value: 'true');
  }

  // ─── Full wipe ───────────────────────────────────────────────────────

  /// Nuclear option — clears everything (used for account deletion).
  Future<void> clearAll() async {
    await clearSession();
    await clearPin();
    await _secureStorage.delete(key: _keyBiometricEnabled);
    await _secureStorage.delete(key: _keyBiometricSetupCompleted);
    final prefs = await _sharedPrefs;
    await prefs.remove(_keyHasSeenOnboarding);
    await prefs.remove(_keyHasSelectedLanguage);
  }
}
