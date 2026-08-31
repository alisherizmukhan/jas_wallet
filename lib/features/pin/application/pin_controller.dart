// ignore_for_file: empty_catches
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../features/auth/data/repositories/auth_repository.dart';
import '../../../features/auth/presentation/providers/auth_repository_provider.dart';
import '../../../features/events/data/events_service.dart';
import '../data/pin_storage_service.dart';

/// Provides the [PinStorageService] singleton.
final pinStorageServiceProvider = Provider<PinStorageService>((ref) {
  final authStorage = ref.watch(authStorageServiceProvider);
  return PinStorageService(authStorage);
});

/// State for PIN entry UI.
enum PinEntryPhase {
  /// User is entering a new PIN.
  create,

  /// User is confirming the new PIN.
  confirm,

  /// User is verifying an existing PIN.
  verify,
}

/// Manages PIN creation flow.
class PinCreateController extends StateNotifier<PinCreateState> {
  PinCreateController(this._pinService) : super(const PinCreateState());

  final PinStorageService _pinService;

  /// Set the PIN in the create phase, move to confirm phase.
  void setPin(String pin) {
    state = state.copyWith(
      firstPin: pin,
      phase: PinEntryPhase.confirm,
      error: null,
    );
  }

  /// Confirm the PIN. If it matches, save and advance auth state.
  Future<bool> confirmPin(String pin) async {
    if (pin != state.firstPin) {
      state = state.copyWith(
        phase: PinEntryPhase.create,
        firstPin: null,
        error: 'pin_mismatch',
      );
      return false;
    }

    await _pinService.createPin(pin);

    // Callers will handle biometric setup and then call completePinSetup
    return true;
  }

  /// Reset to initial state.
  void reset() {
    state = const PinCreateState();
  }
}

/// State for PIN creation flow.
class PinCreateState {
  const PinCreateState({
    this.phase = PinEntryPhase.create,
    this.firstPin,
    this.error,
  });

  final PinEntryPhase phase;
  final String? firstPin;
  final String? error;

  PinCreateState copyWith({
    PinEntryPhase? phase,
    String? firstPin,
    String? error,
  }) {
    return PinCreateState(
      phase: phase ?? this.phase,
      firstPin: firstPin ?? this.firstPin,
      error: error,
    );
  }
}

/// Provider for PIN creation controller.
final pinCreateControllerProvider =
    StateNotifierProvider.autoDispose<PinCreateController, PinCreateState>((
      ref,
    ) {
      final pinService = ref.watch(pinStorageServiceProvider);
      return PinCreateController(pinService);
    });

/// Manages PIN verification flow.
class PinVerifyController extends StateNotifier<PinVerifyState> {
  PinVerifyController(
    this._pinService,
    this._authNotifier,
    this._authStorage,
    this._authRepository,
  ) : super(const PinVerifyState()) {
    // Warm secure PIN material early so the first attempt is not delayed.
    unawaited(_pinService.warmUp());
    // Warm session credentials so successful unlock avoids secure-storage lag.
    unawaited(warmSessionData());
  }

  final PinStorageService _pinService;
  final AuthNotifier _authNotifier;
  final AuthStorageService _authStorage;
  final AuthRepository _authRepository;
  String? _cachedUserId;
  String? _cachedRefreshToken;
  Future<void>? _sessionWarmUpFuture;

  /// After this many failed attempts (across lock cycles) force a full
  /// re-authentication (credential login). Matches [AuthNotifier.maxPinAttempts].
  static const _forceReAuthThreshold = AuthNotifier.maxPinAttempts;

  Future<void> warmSessionData() async {
    final inFlight = _sessionWarmUpFuture;
    if (inFlight != null) return inFlight;

    _sessionWarmUpFuture = _doWarmSessionData();
    try {
      await _sessionWarmUpFuture!;
    } finally {
      _sessionWarmUpFuture = null;
    }
  }

  Future<void> _doWarmSessionData() async {
    final values = await Future.wait<String?>([
      _authStorage.getUserId(),
      _authStorage.getRefreshToken(),
    ]);
    _cachedUserId = values[0];
    _cachedRefreshToken = values[1];
  }

  Future<void> _refreshSessionInBackground({
    required String userId,
    required String refreshToken,
  }) async {
    try {
      final tokens = await _authRepository.refreshToken(refreshToken);
      _cachedUserId = userId;
      _cachedRefreshToken = tokens.refreshToken;
      await _authStorage.saveSession(
        userId: userId,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } on AuthException catch (e) {
      final shouldForceReAuth = e.statusCode == 401 || e.statusCode == 403;
      if (shouldForceReAuth) {
        final latestRefreshToken = await _authStorage.getRefreshToken();
        final tokenWasRotated =
            latestRefreshToken != null &&
            latestRefreshToken.isNotEmpty &&
            latestRefreshToken != refreshToken;

        // Local unlock can race with ApiClient interceptor refresh.
        // If refresh token already changed, another flow refreshed session.
        if (tokenWasRotated) {
          return;
        }

        await _authNotifier.forceReAuth();
        if (mounted) {
          state = state.copyWith(forceReAuth: true, error: 'session_expired');
        }
        return;
      }

    } catch (e) {
    }
  }

  Future<bool> _completeBackendLocalAuth() async {
    // Use already-cached session data (warmed in constructor).
    // Only fall back to storage if cache missed.
    var userId = _cachedUserId;
    var refreshToken = _cachedRefreshToken;

    if (userId == null ||
        userId.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      // Cache miss — read once, but don't block unlock for too long.
      await warmSessionData();
      userId = _cachedUserId;
      refreshToken = _cachedRefreshToken;
    }

    if (userId == null ||
        userId.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      state = state.copyWith(forceReAuth: true, error: 'session_expired');
      return false;
    }

    // Unlock immediately after local auth success, then refresh in background.
    _authNotifier.unlockWithLocalAuth();
    state = state.copyWith(forceReAuth: false, error: null);

    unawaited(
      _refreshSessionInBackground(userId: userId, refreshToken: refreshToken),
    );

    // Pre-fetch events on cold start so home page has data ready.
    unawaited(EventsService.instance.refresh());

    return true;
  }

  /// Check PIN hash only — does NOT update auth state or failure counters.
  /// Use [completeLocalAuth] after success, [recordPinFailure] after failure.
  Future<bool> checkPinHash(String pin) => _pinService.verifyPin(pin);

  /// Complete local authentication after a successful hash check.
  /// This is the call that changes auth state to authenticated.
  Future<bool> completeLocalAuth() => _completeBackendLocalAuth();

  /// Record a failed PIN attempt and update lock state in provider state.
  /// Call after [checkPinHash] returns false.
  Future<void> recordPinFailure() async {
    final attempts = await _pinService.getFailedAttempts();

    if (attempts >= _forceReAuthThreshold) {
      state = state.copyWith(
        failedAttempts: attempts,
        forceReAuth: true,
        error: 'pin_force_reauth',
      );
      return;
    }

    final remaining = await _pinService.getRemainingLockTime();
    if (remaining > Duration.zero) {
      state = state.copyWith(
        isLocked: true,
        lockRemainingSeconds: remaining.inSeconds,
        failedAttempts: attempts,
        error: 'pin_locked',
      );
    } else {
      state = state.copyWith(failedAttempts: attempts, error: 'pin_incorrect');
    }
  }

  /// Verify the entered PIN (convenience: hash check + auth completion or failure recording).
  /// Kept for backward compatibility with existing tests.
  Future<bool> verifyPin(String pin) async {
    final isValid = await checkPinHash(pin);
    if (isValid) return completeLocalAuth();
    await recordPinFailure();
    return false;
  }

  /// Unlock via biometric authentication.
  Future<bool> unlockWithBiometric() => _completeBackendLocalAuth();

  /// Check and update lock status.
  Future<void> checkLockStatus() async {
    final locked = await _pinService.isLocked();
    if (locked) {
      final remaining = await _pinService.getRemainingLockTime();
      state = state.copyWith(
        isLocked: true,
        lockRemainingSeconds: remaining.inSeconds,
      );
    } else {
      state = state.copyWith(isLocked: false, lockRemainingSeconds: 0);
    }
  }

  /// Trigger force re-auth flow.
  Future<void> executeForceReAuth() async {
    await _authNotifier.forceReAuth();
  }
}

/// State for PIN verification.
class PinVerifyState {
  const PinVerifyState({
    this.failedAttempts = 0,
    this.isLocked = false,
    this.lockRemainingSeconds = 0,
    this.forceReAuth = false,
    this.error,
  });

  final int failedAttempts;
  final bool isLocked;
  final int lockRemainingSeconds;
  final bool forceReAuth;
  final String? error;

  PinVerifyState copyWith({
    int? failedAttempts,
    bool? isLocked,
    int? lockRemainingSeconds,
    bool? forceReAuth,
    String? error,
  }) {
    return PinVerifyState(
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isLocked: isLocked ?? this.isLocked,
      lockRemainingSeconds: lockRemainingSeconds ?? this.lockRemainingSeconds,
      forceReAuth: forceReAuth ?? this.forceReAuth,
      error: error,
    );
  }
}

/// Provider for PIN verification controller.
final pinVerifyControllerProvider =
    StateNotifierProvider.autoDispose<PinVerifyController, PinVerifyState>((
      ref,
    ) {
      final pinService = ref.watch(pinStorageServiceProvider);
      final authNotifier = ref.watch(authProvider.notifier);
      final authStorage = ref.watch(authStorageServiceProvider);
      final authRepository = ref.watch(authRepositoryProvider);
      return PinVerifyController(
        pinService,
        authNotifier,
        authStorage,
        authRepository,
      );
    });
