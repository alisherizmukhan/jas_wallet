import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/services/auth_storage_service.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/services/home_cache_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth storage service provider (singleton)
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the [AuthStorageService] singleton.
final authStorageServiceProvider = Provider<AuthStorageService>((ref) {
  return AuthStorageService();
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth state model
// ─────────────────────────────────────────────────────────────────────────────

/// The possible auth lifecycle states the app can be in.
enum AuthStatus {
  /// App is starting — checking secure storage for session / tokens.
  /// This is the FIRST state before any routing decision.
  appStarting,

  /// Still resolving persisted session.
  unknown,

  /// First launch — user hasn't selected a language yet.
  firstLaunch,

  /// Language selected but onboarding not completed.
  needsOnboarding,

  /// Onboarding done but user is not logged in.
  unauthenticated,

  /// User logged in but has not created a PIN code yet.
  needsPinSetup,

  /// PIN created, biometric setup prompt not yet shown.
  needsBiometricSetup,

  /// User has an active session but needs local auth (PIN / biometric).
  needsLocalAuth,

  /// User has an active session and has been verified.
  authenticated,
}

/// Immutable snapshot of the current auth state.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.isOfflineMode = false,
    this.biometricEnabled = false,
  });

  final AuthStatus status;
  final String? userId;

  /// True if the app is running in offline mode (no network).
  /// Local auth (PIN/biometric) is allowed, but API calls are restricted.
  final bool isOfflineMode;

  /// True if biometric auth is enabled for this user.
  /// Cached here to avoid storage reads on PIN page.
  final bool biometricEnabled;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    bool? isOfflineMode,
    bool? biometricEnabled,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, userId: $userId, offlineMode: $isOfflineMode, biometric: $biometricEnabled)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth state notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the global auth lifecycle.
///
/// On construction it reads persisted flags from [AuthStorageService] and
/// resolves the initial [AuthStatus]. The rest of the app reacts to this state.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage)
    : super(const AuthState(status: AuthStatus.appStarting)) {
    _init();
    // Safety net: if _init() never sets a state (hang, crash, whatever),
    // force-resolve after [_safetyDelay] so the user is never stuck loading.
    _safetyTimer = Timer(_safetyDelay, _emergencyResolve);
  }

  final AuthStorageService _storage;

  /// Timeout for individual secure-storage operations.
  /// Android EncryptedSharedPreferences can be very slow on cold start
  /// (device may skip 200+ frames while loading the Keystore).
  static const _opTimeout = Duration(seconds: 8);

  /// Maximum time allowed for the entire init sequence.
  /// Must be generous enough for slow cold-start devices.
  static const _initTimeout = Duration(seconds: 10);

  /// Safety timer fires independently if _init never completes.
  /// This is the absolute maximum wait before forcing a resolution.
  static const _safetyDelay = Duration(seconds: 12);

  /// Maximum PIN retry failures before forced logout.
  static const maxPinAttempts = 5;

  Timer? _safetyTimer;

  // ── Initialisation ────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      await _resolveAuthState().timeout(_initTimeout);
    } catch (e) {
      if (state.status == AuthStatus.appStarting ||
          state.status == AuthStatus.unknown) {
        // Secure storage timed out. Check SharedPreferences backup so we
        // don't falsely log the user out on slow cold-start devices.
        await _fallbackToSharedPrefs();
      }
    } finally {
      _safetyTimer?.cancel();
      _safetyTimer = null;
      // Absolute guarantee: state must never remain appStarting or unknown.
      if (state.status == AuthStatus.appStarting ||
          state.status == AuthStatus.unknown) {
        await _fallbackToSharedPrefs();
      }
    }
  }

  /// Use SharedPreferences backup flags to resolve auth state when
  /// secure storage is unavailable (cold-start timeout).
  Future<void> _fallbackToSharedPrefs() async {
    try {
      final hasSession = await _storage.hasSessionFallback();
      final hasPin = await _storage.hasPinFallback();
      final userId = await _storage.getUserIdFallback();

      if (hasSession && hasPin && userId != null) {
        state = AuthState(status: AuthStatus.needsLocalAuth, userId: userId);
        return;
      }
      if (hasSession && userId != null) {
        state = AuthState(status: AuthStatus.needsPinSetup, userId: userId);
        return;
      }
    } catch (_) {}

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Timer callback — bypasses all storage, just sets state.
  void _emergencyResolve() {
    if (!mounted) return;
    if (state.status == AuthStatus.appStarting ||
        state.status == AuthStatus.unknown) {
      _fallbackToSharedPrefs();
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    super.dispose();
  }

  // ── State resolution ──────────────────────────────────────────────────

  Future<void> _resolveAuthState() async {
    await _storage.init();

    // ── Stage 1: SharedPreferences (fast, synchronous after init) ──────
    // Read all SharedPreferences values in parallel - these are cached and fast.
    final prefsResults = await Future.wait([
      _storage.hasSelectedLanguage(),
      _storage.hasSeenOnboarding(),
      _storage.isOfflineMode().catchError((_) => false),
      _storage.isRegistrationPending().catchError((_) => false),
    ]);

    final hasLanguage = prefsResults[0];
    final hasOnboarding = prefsResults[1];
    final isOfflineMode = prefsResults[2];
    final registrationPending = prefsResults[3];

    if (!hasLanguage) {
      state = const AuthState(status: AuthStatus.firstLaunch);
      return;
    }

    if (!hasOnboarding) {
      state = const AuthState(status: AuthStatus.needsOnboarding);
      return;
    }

    // ── Stage 2: Batch read ALL secure storage keys in ONE call ─────────
    // This is MUCH faster than multiple individual reads during cold start.
    // Single readAll() vs 7 separate read() calls = ~5x faster.
    Map<String, String?> authKeys;
    try {
      authKeys = await _storage.readAllAuthKeys().timeout(_opTimeout);
    } catch (e) {
      // Secure storage is slow (Android Keystore cold-start).
      // Check SharedPreferences backup flags to avoid false logout.
      final hasSession = await _storage.hasSessionFallback();
      final hasPin = await _storage.hasPinFallback();
      final fallbackUserId = await _storage.getUserIdFallback();

      if (hasSession && hasPin && fallbackUserId != null) {
        state = AuthState(
          status: AuthStatus.needsLocalAuth,
          userId: fallbackUserId,
          isOfflineMode: isOfflineMode,
        );
        return;
      }
      if (hasSession && fallbackUserId != null) {
        // A session exists but no PIN yet. If registration never finished
        // (OTP verified, profile/password not set), discard it instead of
        // resuming into PIN setup with a half-created account.
        if (registrationPending) {
          await _safeWipe();
          state = AuthState(
            status: AuthStatus.unauthenticated,
            isOfflineMode: isOfflineMode,
          );
          return;
        }
        state = AuthState(
          status: AuthStatus.needsPinSetup,
          userId: fallbackUserId,
          isOfflineMode: isOfflineMode,
        );
        return;
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isOfflineMode: isOfflineMode,
      );
      return;
    }

    // Parse values from batch read
    final loggedIn = authKeys['isLoggedIn'] == 'true';
    final userId = authKeys['userId'];
    final refreshToken = authKeys['refreshToken'];
    final hasPin = authKeys['hasPin'] == 'true' || await _storage.hasPinFallback();
    final hasBiometric = authKeys['biometricEnabled'] == 'true';
    final biometricSetupCompleted = authKeys['biometricSetupCompleted'] == 'true';
    final failedAttempts = int.tryParse(authKeys['pinFailedAttempts'] ?? '0') ?? 0;

    if (!loggedIn) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isOfflineMode: isOfflineMode,
      );
      return;
    }

    if (userId == null || userId.isEmpty) {
      await _safeWipe();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isOfflineMode: isOfflineMode,
      );
      return;
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      await _storage.clearSession();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isOfflineMode: isOfflineMode,
      );
      return;
    }

    // ── Stage 3: PIN-lock safety ────────────────────────────────────
    if (failedAttempts >= maxPinAttempts) {
      await _safeWipe();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isOfflineMode: isOfflineMode,
      );
      return;
    }

    // ── Stage 4: State transitions based on PIN/biometric ────────────
    // If PIN is set and biometric setup step is incomplete, resume setup.
    if (hasPin && !biometricSetupCompleted) {
      state = AuthState(
        status: AuthStatus.needsBiometricSetup,
        userId: userId,
        isOfflineMode: isOfflineMode,
        biometricEnabled: hasBiometric,
      );
      return;
    }

    // Standard returning-session flow: PIN gate first, then backend refresh.
    if (hasPin) {
      state = AuthState(
        status: AuthStatus.needsLocalAuth,
        userId: userId,
        isOfflineMode: isOfflineMode,
        biometricEnabled: hasBiometric,
      );
      return;
    }

    // Session exists but PIN not created yet. An incomplete registration
    // (OTP verified, but profile/password never finished) must not be resumed
    // as a valid session — otherwise the user would land on PIN setup and into
    // the app without a password or a completed profile. Discard it.
    if (registrationPending) {
      await _safeWipe();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isOfflineMode: isOfflineMode,
      );
      return;
    }

    // Session exists but PIN not created yet: continue setup, do not force
    // credentials again after cold start.
    state = AuthState(
      status: AuthStatus.needsPinSetup,
      userId: userId,
      isOfflineMode: isOfflineMode,
    );
  }

  /// Runs a best-effort cleanup [action] with a bounded [timeout].
  ///
  /// Failures are intentionally non-fatal — a single storage-clear failure
  /// must never block the rest of logout/session cleanup — but are no
  /// longer silently discarded — each is reported to Sentry tagged with
  /// [step] so a systemic failure (e.g. a platform-channel exception on a
  /// specific OEM device) is observable instead of only surfacing as a
  /// vague, undiagnosable user report ("logout didn't fully work").
  Future<void> _safeCleanup(
    String step,
    Future<void> Function() action, {
    Duration timeout = _opTimeout,
  }) async {
    try {
      await action().timeout(timeout);
    } catch (e, stackTrace) {
      unawaited(
        Sentry.captureException(
          e,
          stackTrace: stackTrace,
          hint: Hint.withMap({'auth_cleanup_step': step}),
        ),
      );
    }
  }

  Future<void> _safeWipe() async {
    await _safeCleanup('safeWipe.clearSession', () => _storage.clearSession());
    await _safeCleanup('safeWipe.clearPin', () => _storage.clearPin());
    await _safeCleanup(
      'safeWipe.setBiometricEnabled',
      // delete() rather than write 'false' — leaves no trace in secure
      // storage after a full wipe (read call sites already treat an absent
      // key identically to 'false', so behavior is unchanged).
      () => _storage.delete(key: 'auth_biometric_enabled'),
    );
    await _safeCleanup(
      'safeWipe.clearBiometricSetupCompleted',
      () => _storage.delete(key: 'auth_biometric_setup_completed'),
    );
    await _safeCleanup(
      'safeWipe.clearBiometricService',
      () => BiometricAuthService().clearAll(),
    );
    await _safeCleanup(
      'safeWipe.setOfflineMode',
      () => _storage.setOfflineMode(false),
    );
  }

  /// Call after user picks a language on the language selection screen.
  Future<void> completeLanguageSelection() async {
    await _storage.setLanguageSelected();
    final hasOnboarding = await _storage.hasSeenOnboarding();
    state = AuthState(
      status: hasOnboarding
          ? AuthStatus.unauthenticated
          : AuthStatus.needsOnboarding,
    );
  }

  /// Call after the last onboarding page.
  Future<void> completeOnboarding() async {
    await _storage.setOnboardingSeen();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Go back to language selection from onboarding.
  void resetToFirstLaunch() {
    state = const AuthState(status: AuthStatus.firstLaunch);
  }

  /// Call after successful login / registration.
  ///
  /// Persists session credentials and then asks for PIN setup.
  /// PIN is required for all subsequent sessions.
  Future<void> login({
    required String userId,
    String? accessToken,
    String? refreshToken,
  }) async {
    await _storage.saveSession(
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    // Always wipe any existing PIN and biometric Keychain data before
    // requiring fresh setup. On iOS, Keychain survives app deletion, so a
    // stale PIN from a previous install would otherwise let the user skip
    // the setup flow entirely on the very next login.
    await _safeCleanup('login.clearPin', () => _storage.clearPin());
    await _safeCleanup(
      'login.setBiometricEnabled',
      // delete() rather than write 'false' — leaves no trace in secure
      // storage after a full wipe (read call sites already treat an absent
      // key identically to 'false', so behavior is unchanged).
      () => _storage.delete(key: 'auth_biometric_enabled'),
    );
    await _safeCleanup(
      'login.clearBiometricSetupCompleted',
      () => _storage.delete(key: 'auth_biometric_setup_completed'),
    );
    await _safeCleanup(
      'login.clearBiometricService',
      () => BiometricAuthService().clearAll(),
    );

    state = AuthState(status: AuthStatus.needsPinSetup, userId: userId);
  }

  /// Call after PIN code creation completes.
  ///
  /// Always transitions to biometric setup prompt to allow user to enable
  /// biometric authentication. User can skip if preferred.
  Future<void> completePinSetup({bool showBiometricSetup = true}) async {
    // After PIN is set, always ask for biometric setup
    // User can skip if they don't want biometrics
    if (showBiometricSetup) {
      // Check if biometric was already configured earlier
      final alreadyEnabled = await _storage.isBiometricEnabled();
      final setupCompleted = await _storage.isBiometricSetupCompleted();
      if (alreadyEnabled || setupCompleted) {
        await _storage.setBiometricSetupCompleted();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          biometricEnabled: alreadyEnabled,
        );
        return;
      }
      state = state.copyWith(status: AuthStatus.needsBiometricSetup);
    } else {
      await _storage.setBiometricSetupCompleted();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        biometricEnabled: false,
      );
    }
  }

  /// Call after biometric setup prompt (enable or skip).
  ///
  /// [biometricEnabled] should reflect the user's choice — pass it directly
  /// instead of reading it back from storage so the app opens immediately.
  /// The storage write runs in the background.
  Future<void> completeBiometricSetup({bool biometricEnabled = false}) async {
    unawaited(_storage.setBiometricSetupCompleted());
    state = state.copyWith(
      status: AuthStatus.authenticated,
      biometricEnabled: biometricEnabled,
    );
  }

  /// Sync in-memory biometric flag with persisted storage.
  Future<void> syncBiometricPreference() async {
    final biometricEnabled = await _storage.isBiometricEnabled();
    state = state.copyWith(biometricEnabled: biometricEnabled);
  }

  /// Call only after successful PIN/biometric verification AND backend
  /// session refresh.
  void unlockWithLocalAuth() {
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  /// Call on logout.
  ///
  /// Sets auth state to [AuthStatus.unauthenticated] immediately so the router
  /// redirects to the welcome screen in the same frame, then fires all storage
  /// cleanup in the background so it never blocks navigation.
  ///
  /// [clearRefreshToken] — if true, also deletes refresh token (force full
  /// login next time). If false, keeps refresh token for fast PIN/biometric
  /// login on app return (CASE 11 Option A).
  Future<void> logout({
    BiometricAuthService? biometricService,
    bool clearRefreshToken = true,
  }) async {
    // Instant state change — the router redirect fires on the very next frame.
    state = const AuthState(status: AuthStatus.unauthenticated);
    // All storage cleanup runs in the background so callers never wait on it.
    unawaited(
      _doLogoutCleanup(
        biometricService: biometricService,
        clearRefreshToken: clearRefreshToken,
      ),
    );
  }

  Future<void> _doLogoutCleanup({
    BiometricAuthService? biometricService,
    bool clearRefreshToken = true,
  }) async {
    // Delete login marker so cold start never restores an authenticated session.
    await _safeCleanup(
      'logout.clearIsLoggedIn',
      () => _storage.delete(key: 'auth_is_logged_in'),
    );

    if (clearRefreshToken) {
      // clearSession() also clears the SALTO access log, device-identity
      // UUID, and FCM token — see AuthStorageService.clearSession().
      await _safeCleanup('logout.clearSession', () => _storage.clearSession());
      await _safeCleanup(
        'logout.clearHomeCache',
        () => HomeCacheService.clearAll(),
      );
    } else {
      await _safeCleanup(
        'logout.clearAccessToken',
        () => _storage.clearAccessToken(),
      );
      await _safeCleanup(
        'logout.clearUserId',
        () => _storage.delete(key: 'auth_user_id'),
      );
    }
    await _safeCleanup('logout.clearPin', () => _storage.clearPin());
    await _safeCleanup(
      'logout.setBiometricEnabled',
      // delete() rather than write 'false' — leaves no trace in secure
      // storage after a full wipe (read call sites already treat an absent
      // key identically to 'false', so behavior is unchanged).
      () => _storage.delete(key: 'auth_biometric_enabled'),
    );
    await _safeCleanup(
      'logout.clearBiometricSetupCompleted',
      () => _storage.delete(key: 'auth_biometric_setup_completed'),
    );

    final localBiometricService = biometricService ?? BiometricAuthService();
    await _safeCleanup(
      'logout.clearBiometricService',
      () => localBiometricService.clearAll(),
    );

    await _safeCleanup(
      'logout.setOfflineMode',
      () => _storage.setOfflineMode(false),
    );
  }

  /// Mark the app as offline (no network available).
  /// Allows local unlock (PIN/biometric) but restricts API calls.
  Future<void> markOfflineMode() async {
    await _storage.setOfflineMode(true);
    state = state.copyWith(isOfflineMode: true);
  }

  /// Mark the app as online (network available).
  /// Resumes normal API operations.
  Future<void> markOnlineMode() async {
    await _storage.setOfflineMode(false);
    state = state.copyWith(isOfflineMode: false);
  }

  /// Full wipe — account deletion.
  Future<void> deleteAccount({BiometricAuthService? biometricService}) async {
    state = const AuthState(status: AuthStatus.firstLaunch);
    // clearAll() clears everything clearSession() does (SALTO access log,
    // device-identity UUID, FCM token included) plus PIN and biometric
    // flags — the full "nuclear" wipe for account deletion.
    await _safeCleanup(
      'deleteAccount.clearAll',
      () => _storage.clearAll(),
      timeout: const Duration(seconds: 4),
    );
    if (biometricService != null) {
      await _safeCleanup(
        'deleteAccount.clearBiometricService',
        () => biometricService.clearAll(),
      );
    }
  }

  /// Force re-authentication (e.g., after PIN lock-out).
  Future<void> forceReAuth() async {
    await _safeCleanup(
      'forceReAuth.clearIsLoggedIn',
      () => _storage.delete(key: 'auth_is_logged_in'),
    );

    state = const AuthState(status: AuthStatus.unauthenticated);
    // clearSession() also clears the SALTO access log, device-identity
    // UUID, and FCM token — see AuthStorageService.clearSession().
    await _safeCleanup(
      'forceReAuth.clearSession',
      () => _storage.clearSession(),
    );
    await _safeCleanup('forceReAuth.clearPin', () => _storage.clearPin());
    await _safeCleanup(
      'forceReAuth.clearPinLock',
      () => _storage.clearPinLock(),
    );
    await _safeCleanup(
      'forceReAuth.setBiometricEnabled',
      // delete() rather than write 'false' — leaves no trace in secure
      // storage after a full wipe (read call sites already treat an absent
      // key identically to 'false', so behavior is unchanged).
      () => _storage.delete(key: 'auth_biometric_enabled'),
    );
    await _safeCleanup(
      'forceReAuth.clearBiometricSetupCompleted',
      () => _storage.delete(key: 'auth_biometric_setup_completed'),
    );
    await _safeCleanup(
      'forceReAuth.clearBiometricService',
      () => BiometricAuthService().clearAll(),
    );
    await _safeCleanup(
      'forceReAuth.setOfflineMode',
      () => _storage.setOfflineMode(false),
    );
  }

  /// Request the app to re-lock (e.g., after returning from background).
  ///
  /// Only locks if user is currently authenticated and has a PIN.
  Future<void> lockApp() async {
    if (state.status != AuthStatus.authenticated) return;
    state = state.copyWith(status: AuthStatus.needsLocalAuth);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

/// Global auth state provider.
///
/// The entire app should react to this provider for auth-based routing,
/// conditional UI, and session management.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(authStorageServiceProvider);
  return AuthNotifier(storage);
});
