import 'package:jaswallet_app/core/services/auth_storage_service.dart';

/// In-memory implementation of AuthStorageService for tests.
/// No platform channels (FlutterSecureStorage / SharedPreferences) are called.
class FakeAuthStorageService extends AuthStorageService {
  final Map<String, String?> _secure = {};
  bool _hasSelectedLanguage;
  bool _hasSeenOnboarding;
  bool _isOfflineMode;

  FakeAuthStorageService({
    bool hasSelectedLanguage = true,
    bool hasSeenOnboarding = true,
    bool isOfflineMode = false,
    bool isLoggedIn = false,
    String? userId,
    String? accessToken,
    String? refreshToken,
    bool hasPin = false,
    bool biometricEnabled = false,
    bool biometricSetupCompleted = false,
    int pinFailedAttempts = 0,
  })  : _hasSelectedLanguage = hasSelectedLanguage,
        _hasSeenOnboarding = hasSeenOnboarding,
        _isOfflineMode = isOfflineMode {
    if (isLoggedIn) _secure['auth_is_logged_in'] = 'true';
    if (userId != null) _secure['auth_user_id'] = userId;
    if (accessToken != null) _secure['auth_access_token'] = accessToken;
    if (refreshToken != null) _secure['auth_refresh_token'] = refreshToken;
    if (hasPin) _secure['auth_has_pin'] = 'true';
    if (biometricEnabled) _secure['auth_biometric_enabled'] = 'true';
    if (biometricSetupCompleted) {
      _secure['auth_biometric_setup_completed'] = 'true';
    }
    if (pinFailedAttempts > 0) {
      _secure['auth_pin_failed_attempts'] = pinFailedAttempts.toString();
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  Future<void> init() async {}

  @override
  Future<Map<String, String?>> readAllAuthKeys() async => {
        'isLoggedIn': _secure['auth_is_logged_in'],
        'userId': _secure['auth_user_id'],
        'refreshToken': _secure['auth_refresh_token'],
        'hasPin': _secure['auth_has_pin'],
        'biometricEnabled': _secure['auth_biometric_enabled'],
        'biometricSetupCompleted': _secure['auth_biometric_setup_completed'],
        'pinFailedAttempts': _secure['auth_pin_failed_attempts'],
      };

  // ── SharedPreferences-backed flags ────────────────────────────────────

  @override
  Future<bool> hasSelectedLanguage() async => _hasSelectedLanguage;

  @override
  Future<void> setLanguageSelected() async => _hasSelectedLanguage = true;

  @override
  Future<bool> hasSeenOnboarding() async => _hasSeenOnboarding;

  @override
  Future<void> setOnboardingSeen() async => _hasSeenOnboarding = true;

  @override
  Future<bool> isOfflineMode() async => _isOfflineMode;

  @override
  Future<void> setOfflineMode(bool offline) async => _isOfflineMode = offline;

  // ── Session ───────────────────────────────────────────────────────────

  @override
  Future<void> saveSession({
    required String userId,
    String? accessToken,
    String? refreshToken,
  }) async {
    _secure['auth_is_logged_in'] = 'true';
    _secure['auth_user_id'] = userId;
    if (accessToken != null) _secure['auth_access_token'] = accessToken;
    if (refreshToken != null) _secure['auth_refresh_token'] = refreshToken;
    // SharedPreferences backup
    _secure['_backup_session'] = 'true';
    _secure['_backup_userId'] = userId;
  }

  @override
  Future<bool> isLoggedIn() async => _secure['auth_is_logged_in'] == 'true';

  @override
  Future<String?> getUserId() async => _secure['auth_user_id'];

  @override
  Future<String?> getAccessToken() async => _secure['auth_access_token'];

  @override
  Future<String?> getRefreshToken() async => _secure['auth_refresh_token'];

  @override
  Future<void> setAccessToken(String token) async =>
      _secure['auth_access_token'] = token;

  @override
  Future<void> setRefreshToken(String token) async =>
      _secure['auth_refresh_token'] = token;

  @override
  Future<void> clearAccessToken() async => _secure.remove('auth_access_token');

  @override
  Future<void> clearRefreshToken() async =>
      _secure.remove('auth_refresh_token');

  @override
  Future<void> delete({required String key}) async => _secure.remove(key);

  @override
  Future<void> clearSession() async {
    _secure.remove('auth_is_logged_in');
    _secure.remove('auth_user_id');
    _secure.remove('auth_access_token');
    _secure.remove('auth_refresh_token');
    _secure.remove('_backup_session');
    _secure.remove('_backup_userId');
  }

  // ── PIN ───────────────────────────────────────────────────────────────

  @override
  Future<bool> hasPin() async => _secure['auth_has_pin'] == 'true';

  @override
  Future<void> savePinHash({required String hash, required String salt}) async {
    _secure['auth_pin_hash'] = hash;
    _secure['auth_pin_salt'] = salt;
    _secure['auth_has_pin'] = 'true';
    _secure['_backup_hasPin'] = 'true';
  }

  @override
  Future<String?> getPinHash() async => _secure['auth_pin_hash'];

  @override
  Future<String?> getPinSalt() async => _secure['auth_pin_salt'];

  @override
  Future<void> clearPin() async {
    _secure.remove('auth_pin_hash');
    _secure.remove('auth_pin_salt');
    _secure.remove('auth_has_pin');
    _secure.remove('_backup_hasPin');
  }

  // ── Biometric ─────────────────────────────────────────────────────────

  @override
  Future<bool> isBiometricEnabled() async =>
      _secure['auth_biometric_enabled'] == 'true';

  @override
  Future<void> setBiometricEnabled(bool enabled) async =>
      _secure['auth_biometric_enabled'] = enabled ? 'true' : 'false';

  @override
  Future<bool> isBiometricSetupCompleted() async =>
      _secure['auth_biometric_setup_completed'] == 'true';

  @override
  Future<void> setBiometricSetupCompleted() async =>
      _secure['auth_biometric_setup_completed'] = 'true';

  // ── PIN locking ───────────────────────────────────────────────────────

  @override
  Future<int> getPinFailedAttempts() async =>
      int.tryParse(_secure['auth_pin_failed_attempts'] ?? '0') ?? 0;

  @override
  Future<int> incrementPinFailedAttempts({int? current}) async {
    final next = (current ?? await getPinFailedAttempts()) + 1;
    _secure['auth_pin_failed_attempts'] = next.toString();
    return next;
  }

  @override
  Future<void> resetPinFailedAttempts() async =>
      _secure.remove('auth_pin_failed_attempts');

  @override
  Future<void> setPinLockUntil(DateTime until) async =>
      _secure['auth_pin_lock_until'] =
          until.millisecondsSinceEpoch.toString();

  @override
  Future<DateTime?> getPinLockUntil() async {
    final raw = _secure['auth_pin_lock_until'];
    if (raw == null) return null;
    final ms = int.tryParse(raw);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  @override
  Future<void> clearPinLock() async => _secure.remove('auth_pin_lock_until');

  // ── SharedPreferences fallback flags ─────────────────────────────────

  @override
  Future<bool> hasPinFallback() async => _secure['auth_has_pin'] == 'true';

  @override
  Future<bool> hasSessionFallback() async =>
      _secure['auth_is_logged_in'] == 'true';

  @override
  Future<String?> getUserIdFallback() async => _secure['auth_user_id'];

  // ── Registration pending flag ─────────────────────────────────────────

  @override
  Future<bool> isRegistrationPending() async =>
      _secure['_registration_pending'] == 'true';

  @override
  Future<void> setRegistrationPending(bool pending) async {
    if (pending) {
      _secure['_registration_pending'] = 'true';
    } else {
      _secure.remove('_registration_pending');
    }
  }

  // ── Full wipe ─────────────────────────────────────────────────────────

  @override
  Future<void> clearAll() async => _secure.clear();
}
