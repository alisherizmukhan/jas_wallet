// ignore_for_file: empty_catches
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../analytics/salto_analytics.dart';
import '../../data/models/salto_mobile_status.dart';
import '../../data/repositories/salto_repository_impl.dart';
import '../../data/salto_platform_channel.dart';
import '../../data/services/salto_key_manager.dart';
import '../../domain/access_attempt_log.dart';
import '../../domain/salto_unlock_result.dart';
import 'access_stats_provider.dart';

/// Whether SALTO native SDK is available (Android/iOS only).
bool get _isPlatformSupported => Platform.isAndroid || Platform.isIOS;

/// Unlock state for UI.
enum SaltoUnlockState {
  idle,
  scanning,
  connecting,
  granted,
  rejected,
  error,
  noKey, // SALTO not configured for this user
}

/// Specific reason behind the current [SaltoUnlockState.error]/[SaltoUnlockState.noKey]
/// (or a would-be-error condition rejected before any state change).
///
/// Kept separate from [SaltoUnlockState] rather than folded into it so the
/// existing 7-value UI state machine (and everything that already switches
/// on it) is untouched — this is purely additive detail for building
/// specific, non-generic error copy (see reliability investigation §16/§10).
enum SaltoFailureReason {
  none,
  permissionDenied,
  bluetoothOff,
  bluetoothNotReady,
  bluetoothUnauthorized,
  bluetoothUnsupported,
  locationOff,
  keyMissing,
  keyExpired,
  sdkTimeout,
  nativeFailure,
  sdkUnavailable,
  rejected,
  unknown,
}

/// Salto repository provider.
final saltoRepositoryProvider = Provider<SaltoRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authStorage = ref.watch(authStorageServiceProvider);
  return SaltoRepositoryImpl(apiClient: apiClient, authStorage: authStorage);
});

/// Manages SALTO key lifecycle (validation, expiry, background refresh).
final saltoKeyManagerProvider = Provider<SaltoKeyManager>((ref) {
  return SaltoKeyManager(
    repository: ref.watch(saltoRepositoryProvider),
    authStorage: ref.watch(authStorageServiceProvider),
  );
});

/// SALTO mobile access status — cache-first, then background network refresh.
///
/// On page open the cached status (secure storage, 7-day TTL) is returned
/// immediately so the Open button is never blocked by a network call.
/// The fresh status arrives silently in the background and rebuilds the UI.
final saltoStatusProvider =
    AsyncNotifierProvider.autoDispose<_SaltoStatusNotifier, SaltoMobileStatus>(
  _SaltoStatusNotifier.new,
);

class _SaltoStatusNotifier extends AutoDisposeAsyncNotifier<SaltoMobileStatus> {
  @override
  Future<SaltoMobileStatus> build() async {
    final repository = ref.read(saltoRepositoryProvider);

    // Abandon any in-flight status request when this (autoDispose) notifier
    // is torn down — e.g. the user navigates off the Access page before the
    // response arrives — instead of letting it run to completion for a
    // result nobody will read.
    final cancelToken = CancelToken();
    ref.onDispose(() => cancelToken.cancel('SaltoStatusNotifier disposed'));

    // Return cached status instantly if available — button is never blocked.
    final cached = await repository.getCachedMobileStatus();
    if (cached != null) {
      // Skip the background refresh when a previous tab visit already
      // fetched status moments ago — this provider is autoDispose and gets
      // rebuilt every time the user re-enters the Access page, so without
      // this check every tab switch would hit /salto/me/status again even
      // though the cache is seconds old.
      if (!repository.isStatusFresh()) {
        unawaited(_refreshFromNetwork(repository, cancelToken));
      }
      return cached;
    }

    // No cache (first-time user or expired) — wait for network.
    return repository.getMobileStatus(cancelToken: cancelToken);
  }

  Future<void> _refreshFromNetwork(
    SaltoRepositoryImpl repository,
    CancelToken cancelToken,
  ) async {
    try {
      final fresh = await repository.getMobileStatus(cancelToken: cancelToken);
      // Setting state on a disposed autoDispose notifier is harmless — the
      // framework discards it. Any StateError here means the notifier was
      // already disposed, so we can safely ignore it.
      state = AsyncValue.data(fresh);
    } catch (_) {
      // Covers both network failures and post-disposal state errors.
      // Either way, keep the cached value already in state.
    }
  }
}

/// Provider for SALTO unlock flow.
final saltoUnlockProvider =
    StateNotifierProvider<SaltoUnlockNotifier, SaltoUnlockState>((ref) {
  final repository = ref.watch(saltoRepositoryProvider);
  return SaltoUnlockNotifier(repository: repository, ref: ref);
});

class SaltoUnlockNotifier extends StateNotifier<SaltoUnlockState> {
  SaltoUnlockNotifier({required SaltoRepositoryImpl repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(SaltoUnlockState.idle);

  final SaltoRepositoryImpl _repository;
  final Ref _ref;

  // ── Unlock lock ──────────────────────────────────────────────────────────
  //
  // A single lock guards every unlock attempt (manual tap, retry-on-rejected,
  // key-refresh-then-retry) so exactly one BLE round trip is ever in flight.
  //
  // Reliability guarantee: this lock can no longer be held forever. Every
  // native call it waits on is now bounded (see [SaltoPlatformChannel.
  // unlockTimeout]), so the `finally` block below is always reached within
  // bounded time. [_staleLockThreshold] is a last-resort safety net on top
  // of that guarantee, not the primary fix — if the lock is somehow still
  // held past a generous multiple of the native timeout, the NEXT tap force-
  // releases it and proceeds, so the user is never required to restart the
  // app to recover.

  bool _isUnlocking = false;
  DateTime? _unlockStartedAt;

  /// Whether an unlock attempt is currently in flight.
  ///
  /// Exposed so the rest of the app (the readiness indicator, in
  /// particular) can always see the same truth this notifier acts on —
  /// previously this was entirely private, which let the UI's notion of
  /// "ready" diverge from the notifier's actual state: `state` could read
  /// `idle`/`error`/`granted` while a stuck attempt silently still held the
  /// lock, making every subsequent tap a silent no-op.
  bool get isUnlocking => _isUnlocking;

  /// Specific reason for the current failure, if known. `none` while idle,
  /// scanning/connecting, or granted. Set alongside every `state = error` /
  /// `state = noKey` transition so the UI can show non-generic copy.
  SaltoFailureReason lastFailureReason = SaltoFailureReason.none;

  /// Generous upper bound a single unlock sequence could legitimately take
  /// (up to two native attempts, each bounded by
  /// [SaltoPlatformChannel.unlockTimeout], plus key-fetch and the fixed
  /// inter-attempt delay). Used only to detect an abandoned lock — normal
  /// completion always happens well before this via the native timeout.
  static Duration get _staleLockThreshold =>
      SaltoPlatformChannel.unlockTimeout * 2 + const Duration(seconds: 20);

  /// Collects log messages during the current unlock attempt.
  List<String> _attemptLogs = [];

  void _log(String message) {
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    final entry = '[$ts] $message';
    _attemptLogs.add(entry);
    if (kDebugMode) debugPrint('SaltoUnlock: $message');
  }

  /// Attempts to acquire the unlock lock.
  ///
  /// Returns true if the caller should proceed. If the lock is held but has
  /// exceeded [_staleLockThreshold], it is treated as abandoned and force-
  /// released here so the caller can proceed anyway — this is what makes
  /// "the user must never need to restart the app" hold even in a
  /// hypothetical future regression that reintroduces an unbounded await.
  bool _tryAcquireLock() {
    if (_isUnlocking) {
      final startedAt = _unlockStartedAt;
      final elapsed =
          startedAt == null ? Duration.zero : DateTime.now().difference(startedAt);
      if (elapsed < _staleLockThreshold) {
        return false;
      }
      _log(
        'WARNING: stale unlock lock force-released after ${elapsed.inSeconds}s '
        '(exceeded ${_staleLockThreshold.inSeconds}s safety threshold) — '
        'this should be unreachable now that the native call is timeout-bounded',
      );
      unawaited(_recordStandaloneAttempt(
        'staleLockRecovered',
        detail:
            'Previous unlock attempt held the lock for ${elapsed.inSeconds}s — force-released to allow recovery without an app restart',
      ));
      SaltoAnalytics.instance.trackStaleLockRecovery();
      // The force-release itself IS the successful recovery action — it
      // always allows the next attempt to proceed, so Started/Succeeded
      // fire back-to-back rather than bookending an async operation.
      SaltoAnalytics.instance.trackRecoveryStarted(recoveryReason: 'stale_lock');
      SaltoAnalytics.instance.trackRecoverySucceeded(recoveryReason: 'stale_lock');
    }
    _isUnlocking = true;
    _unlockStartedAt = DateTime.now();
    return true;
  }

  void _releaseLock() {
    _isUnlocking = false;
    _unlockStartedAt = null;
  }

  /// Persists a one-line attempt-log entry that did NOT go through a full
  /// [_runUnlock] pass (e.g. a busy-lock early return) — without this, the
  /// exact moments this notifier previously failed silently would remain
  /// silent in the persisted log too.
  Future<void> _recordStandaloneAttempt(String result, {required String detail}) async {
    try {
      final ts = DateTime.now().toIso8601String().substring(11, 23);
      final attempt = AccessAttemptLog(
        timestamp: DateTime.now(),
        result: result,
        logs: ['[$ts] $detail'],
      );
      await _ref.read(accessLogRepositoryProvider).recordAttempt(attempt);
      _ref.invalidate(accessAttemptsProvider);
    } catch (e) {}
  }

  /// Attempt an unlock with the currently cached (or newly fetched) key.
  Future<SaltoUnlockResult> unlock() =>
      _runUnlock(forceKeyRefresh: false, triggeredBy: 'unlock');

  /// Force-refreshes the SALTO key, then retries unlock with it.
  ///
  /// Called automatically once after a [SaltoUnlockState.rejected] result
  /// (a rejection strongly implies the current key is stale) and by the
  /// "Retry" button while `state == rejected` — both paths funnel through
  /// the exact same lock-guarded [_runUnlock] as [unlock], so there is
  /// exactly one place that owns "how a retry is performed"; the two
  /// trigger points (automatic vs. manual) can no longer race each other
  /// for the lock, only for who arrives first — the loser is logged, never
  /// silently dropped.
  ///
  /// [isManual] distinguishes the silent auto-retry-after-rejected
  /// (`isManual: false`, the default — the caller never had a preceding
  /// button-press event, so the analytics session id is inherited rather
  /// than freshly minted) from the "Retry" button tap while already
  /// rejected (`isManual: true`) — purely for analytics tagging
  /// (`retry_reason`: `rejected` vs `manual_retry`); the retry itself
  /// behaves identically either way.
  Future<void> refreshAndRetry({bool isManual = false}) async {
    final retryReason = isManual ? 'manual_retry' : 'rejected';
    SaltoAnalytics.instance.trackRetryTriggered(
      triggerSource: isManual ? 'manual' : 'auto',
      retryReason: retryReason,
    );
    if (!isManual) {
      // Only the automatic path counts as a system "recovery attempt" in
      // the recovery_reason vocabulary sense — a manual tap is a deliberate
      // user decision, not the app recovering on its own.
      SaltoAnalytics.instance.trackRecoveryStarted(recoveryReason: 'stale_key');
    }
    final result = await _runUnlock(forceKeyRefresh: true, triggeredBy: 'refreshAndRetry');
    if (!isManual) {
      if (result == SaltoUnlockResult.granted) {
        SaltoAnalytics.instance.trackRecoverySucceeded(recoveryReason: 'stale_key');
      } else {
        SaltoAnalytics.instance.trackRecoveryFailed(recoveryReason: 'stale_key');
      }
    }
  }

  Future<SaltoUnlockResult> _runUnlock({
    required bool forceKeyRefresh,
    required String triggeredBy,
  }) async {
    if (!_tryAcquireLock()) {
      final startedAt = _unlockStartedAt;
      final elapsed =
          startedAt == null ? Duration.zero : DateTime.now().difference(startedAt);
      _log(
        '$triggeredBy() ignored — another attempt is already in progress '
        '(elapsed ${elapsed.inSeconds}s)',
      );
      unawaited(_recordStandaloneAttempt(
        'busyIgnored',
        detail:
            '$triggeredBy() called while another attempt was in progress (elapsed ${elapsed.inSeconds}s)',
      ));
      SaltoAnalytics.instance.trackUnlockCancelled(reason: 'busyIgnored', failureStage: 'retry');
      SaltoAnalytics.instance.trackRapidMultipleTaps(tapContext: 'unlock');
      return SaltoUnlockResult.failure;
    }

    if (!_isPlatformSupported) {
      lastFailureReason = SaltoFailureReason.sdkUnavailable;
      state = SaltoUnlockState.error;
      _releaseLock();
      SaltoAnalytics.instance.trackUnlockFailed(reason: 'sdkUnavailable', failureStage: 'native_sdk');
      return SaltoUnlockResult.failure;
    }

    _attemptLogs = [];
    lastFailureReason = SaltoFailureReason.none;
    _log(
      'Attempt started via $triggeredBy() (forceKeyRefresh=$forceKeyRefresh, '
      'previousState=$state)',
    );
    SaltoAnalytics.instance.trackUnlockStarted(triggerSource: triggeredBy);

    try {
      if (forceKeyRefresh) {
        _log('Force-refreshing key before attempting unlock');
        SaltoAnalytics.instance.trackKeyRefreshStarted();
        SaltoAnalytics.instance.markKeyFetchStarted();
        try {
          await _repository.getDigitalKey(forceRefresh: true);
          _log('Key refreshed');
          SaltoAnalytics.instance.markKeyFetchCompleted();
          SaltoAnalytics.instance.trackKeyRefreshCompleted();
          SaltoAnalytics.instance.trackDigitalKeyRefreshed();
        } catch (e) {
          SaltoAnalytics.instance.markKeyFetchCompleted();
          _log('Key refresh failed: $e');
          lastFailureReason = SaltoFailureReason.keyMissing;
          state = SaltoUnlockState.error;
          unawaited(_saveAttempt('failure'));
          SaltoAnalytics.instance.trackKeyRefreshFailed(reason: e.toString());
          SaltoAnalytics.instance.trackUnlockFailed(reason: 'keyMissing', failureStage: 'key_fetch');
          // Preserves the original refreshAndRetry() contract: the caller
          // (the "Retry" button while rejected) shows a toast for this
          // specific failure. Plain unlock() never takes this branch.
          rethrow;
        }
      }

      // Android BLE permission model changed at API 31: scanning with the
      // BLUETOOTH_SCAN `neverForLocation` flag no longer needs location
      // permission or location services. Only Android 11 and below (API ≤30)
      // require ACCESS_FINE_LOCATION for a BLE scan.
      SaltoAnalytics.instance.markPermissionCheckStarted();
      final sdkInt = Platform.isAndroid
          ? await SaltoPlatformChannel.androidSdkInt()
          : 0;
      final needsLocation = Platform.isAndroid && sdkInt <= 30;
      if (Platform.isAndroid) {
        _log('Android SDK int: $sdkInt (needsLocation=$needsLocation)');
      }

      _log('Requesting BLE permissions');
      final hasPermissions = await _ensureBlePermissions(needsLocation: needsLocation);
      if (!hasPermissions) {
        SaltoAnalytics.instance.markPermissionCheckCompleted();
        _log('BLE permissions denied');
        lastFailureReason = SaltoFailureReason.permissionDenied;
        state = SaltoUnlockState.error;
        unawaited(_saveAttempt('permissionDenied'));
        SaltoAnalytics.instance.trackUnlockFailed(reason: 'permissionDenied', failureStage: 'permission');
        return SaltoUnlockResult.failure;
      }
      _log('BLE permissions granted');

      // Cross-platform Bluetooth adapter/manager readiness check. Replaces
      // the old Android-only serviceStatus check — iOS previously had no
      // pre-flight Bluetooth check at all and relied entirely on the SDK's
      // own failure callback.
      final bluetoothState = await SaltoPlatformChannel.bluetoothState();
      _log('Bluetooth state: $bluetoothState');
      SaltoAnalytics.instance.trackBluetoothStateObserved(bluetoothState);
      if (bluetoothState != SaltoBluetoothState.ready) {
        SaltoAnalytics.instance.markPermissionCheckCompleted();
        lastFailureReason = switch (bluetoothState) {
          SaltoBluetoothState.off => SaltoFailureReason.bluetoothOff,
          SaltoBluetoothState.unauthorized => SaltoFailureReason.bluetoothUnauthorized,
          SaltoBluetoothState.unsupported => SaltoFailureReason.bluetoothUnsupported,
          // turningOn / turningOff / resetting / unknown: adapter exists and
          // is authorized, just not settled yet.
          _ => SaltoFailureReason.bluetoothNotReady,
        };
        _log('Bluetooth not ready ($bluetoothState) — cannot scan');
        state = SaltoUnlockState.error;
        unawaited(_saveAttempt('bluetoothNotReady'));
        SaltoAnalytics.instance.trackUnlockFailed(reason: lastFailureReason.name, failureStage: 'bluetooth');
        if (bluetoothState == SaltoBluetoothState.off) {
          SaltoAnalytics.instance.trackUnlockWhileBluetoothDisabled();
        }
        return SaltoUnlockResult.failure;
      }

      // Location services are only required for BLE scanning on Android ≤11.
      if (Platform.isAndroid && needsLocation) {
        final locService = await Permission.locationWhenInUse.serviceStatus;
        _log('Location service status: $locService');
        if (locService != ServiceStatus.enabled) {
          SaltoAnalytics.instance.markPermissionCheckCompleted();
          _log('Location services OFF — Android ≤11 requires this for BLE scanning');
          lastFailureReason = SaltoFailureReason.locationOff;
          state = SaltoUnlockState.error;
          unawaited(_saveAttempt('locationOff'));
          SaltoAnalytics.instance.trackUnlockFailed(reason: 'locationOff', failureStage: 'permission');
          return SaltoUnlockResult.failure;
        }
      }
      SaltoAnalytics.instance.markPermissionCheckCompleted();

      state = SaltoUnlockState.connecting;

      SaltoUnlockResult result;
      try {
        result = await _attemptUnlock(forceRefresh: forceKeyRefresh);
      } catch (e) {
        _log('Unlock failed before native flow: $e');
        lastFailureReason = SaltoFailureReason.keyMissing;
        state = SaltoUnlockState.error;
        unawaited(_saveAttempt('failure'));
        SaltoAnalytics.instance.trackSdkException(detail: e.toString(), failureStage: 'key_fetch');
        SaltoAnalytics.instance.trackUnlockFailed(reason: 'keyMissing', failureStage: 'key_fetch');
        return SaltoUnlockResult.failure;
      }

      final shouldRetryWithFreshKey =
          !forceKeyRefresh &&
          (result == SaltoUnlockResult.failure ||
              result == SaltoUnlockResult.noKey ||
              result == SaltoUnlockResult.timeout);

      if (shouldRetryWithFreshKey) {
        // Maps the result that triggered this retry onto the standard
        // retry_reason/recovery_reason vocabulary (timeout|stale_key|
        // sdk_failure) — see SALTO_ANALYTICS_INTEGRATION.md.
        final retryReason = switch (result) {
          SaltoUnlockResult.timeout => 'timeout',
          SaltoUnlockResult.noKey => 'stale_key',
          _ => 'sdk_failure',
        };
        if (result == SaltoUnlockResult.timeout) {
          _log('Timeout received from native SDK, retrying once with fresh key');
          SaltoAnalytics.instance.trackTimeoutRecovery();
        }
        SaltoAnalytics.instance.trackRetryTriggered(triggerSource: 'auto', retryReason: retryReason);
        SaltoAnalytics.instance.trackRecoveryStarted(recoveryReason: retryReason);
        _log('Waiting 1s for BLE stack cleanup before retry');
        await Future<void>.delayed(const Duration(seconds: 1));
        _log('Retrying with fresh key from backend');
        state = SaltoUnlockState.connecting;
        try {
          result = await _attemptUnlock(forceRefresh: true);
          if (result == SaltoUnlockResult.granted) {
            SaltoAnalytics.instance.trackRetrySuccess();
            SaltoAnalytics.instance.trackRetryRecovery();
            SaltoAnalytics.instance.trackRecoverySucceeded(recoveryReason: retryReason);
          } else {
            SaltoAnalytics.instance.trackRetryFailed(reason: result.name, failureStage: 'retry');
            SaltoAnalytics.instance.trackRecoveryFailed(recoveryReason: retryReason);
          }
        } catch (e) {
          _log('Fresh-key retry failed: $e');
          lastFailureReason = SaltoFailureReason.keyMissing;
          state = SaltoUnlockState.error;
          unawaited(_saveAttempt('failure'));
          SaltoAnalytics.instance.trackSdkException(detail: e.toString(), failureStage: 'retry');
          SaltoAnalytics.instance.trackRetryFailed(reason: 'exception', failureStage: 'retry');
          SaltoAnalytics.instance.trackRecoveryFailed(recoveryReason: retryReason);
          SaltoAnalytics.instance.trackUnlockFailed(reason: 'keyMissing', failureStage: 'key_fetch');
          return SaltoUnlockResult.failure;
        }
      }

      switch (result) {
        case SaltoUnlockResult.granted:
          _log('Result: ACCESS GRANTED');
          lastFailureReason = SaltoFailureReason.none;
          state = SaltoUnlockState.granted;
          SaltoAnalytics.instance.trackUnlockGranted();
          // Record successful access for analytics counter
          unawaited(_recordAccess());
          break;
        case SaltoUnlockResult.rejected:
          _log('Result: ACCESS REJECTED');
          lastFailureReason = SaltoFailureReason.rejected;
          state = SaltoUnlockState.rejected;
          SaltoAnalytics.instance.trackUnlockRejected(reason: 'rejected');
          break;
        case SaltoUnlockResult.noKey:
          _log('Result: NO KEY (reason=$lastFailureReason)');
          state = SaltoUnlockState.noKey;
          SaltoAnalytics.instance.trackUnlockFailed(reason: 'no_key', failureStage: 'key_fetch');
          break;
        case SaltoUnlockResult.timeout:
          _log('Result: TIMEOUT');
          lastFailureReason = SaltoFailureReason.sdkTimeout;
          state = SaltoUnlockState.error;
          SaltoAnalytics.instance.trackUnlockTimeout(reason: 'timeout');
          break;
        case SaltoUnlockResult.failure:
          _log('Result: FAILURE (reason=$lastFailureReason)');
          if (lastFailureReason == SaltoFailureReason.none) {
            lastFailureReason = SaltoFailureReason.nativeFailure;
          }
          state = SaltoUnlockState.error;
          // Prefer the concrete SaltoFailureReason name over a bare "failure"
          // so the ops dashboard can group by a meaningful label.
          final failureLabel = lastFailureReason == SaltoFailureReason.nativeFailure
              ? 'native_failure'
              : lastFailureReason.name;
          SaltoAnalytics.instance.trackUnlockFailed(
            reason: failureLabel,
            failureStage: 'native_sdk',
          );
          break;
      }

      unawaited(_saveAttempt(result.name));
      return result;
    } finally {
      _releaseLock();
    }
  }

  Future<void> _saveAttempt(String result) async {
    try {
      final attempt = AccessAttemptLog(
        timestamp: DateTime.now(),
        result: result,
        logs: List.unmodifiable(_attemptLogs),
      );
      await _ref.read(accessLogRepositoryProvider).recordAttempt(attempt);
      _ref.invalidate(accessAttemptsProvider);
    } catch (e) {
    }
  }

  Future<void> _recordAccess() async {
    try {
      await _ref.read(accessLogRepositoryProvider).recordAccess();
      // Invalidate stats so they refresh when viewed.
      _ref.invalidate(accessStatsProvider);
      _ref.invalidate(totalAccessCountProvider);
    } catch (e) {
    }
  }

  Future<SaltoUnlockResult> _attemptUnlock({required bool forceRefresh}) async {
    _log('Fetching digital key (forceRefresh=$forceRefresh)');
    SaltoAnalytics.instance.markKeyFetchStarted();
    final keyHex = await _repository.getDigitalKey(forceRefresh: forceRefresh);
    SaltoAnalytics.instance.markKeyFetchCompleted();
    if (keyHex == null || keyHex.isEmpty) {
      // Distinguish "never issued" from "was issued, now expired" — the
      // timestamp survives TTL expiry even after the key bytes are deleted
      // (see AuthStorageService.getSaltoDigitalKey), so this is a reliable
      // signal rather than a guess.
      DateTime? storedAt;
      try {
        storedAt = await _ref.read(authStorageServiceProvider).getSaltoDigitalKeyStoredAt();
      } catch (_) {}
      lastFailureReason =
          storedAt != null ? SaltoFailureReason.keyExpired : SaltoFailureReason.keyMissing;
      _log('No digital key available (reason=$lastFailureReason)');
      return SaltoUnlockResult.noKey;
    }
    _log('Key obtained (${keyHex.length} chars)');

    _log('Validating key with native SDK');
    final isValidKey = await SaltoPlatformChannel.validateKey(keyHex);
    if (!isValidKey) {
      _log('${forceRefresh ? 'Fresh' : 'Cached'} key rejected by native SDK');
      lastFailureReason = SaltoFailureReason.nativeFailure;
      SaltoAnalytics.instance.trackDigitalKeyInvalid();
      return SaltoUnlockResult.failure;
    }
    _log('Key is valid');

    state = SaltoUnlockState.scanning;
    _log('Starting BLE scan for turnstile (native call started)');
    SaltoAnalytics.instance.trackNativeUnlockStarted();

    final stopwatch = Stopwatch()..start();
    final nativeResult = await SaltoPlatformChannel.startUnlock(keyHex);
    stopwatch.stop();
    _log(
      'Native callback received (${forceRefresh ? 'fresh' : 'cached'} key): '
      '${nativeResult.result} — duration ${stopwatch.elapsedMilliseconds}ms',
    );
    if (nativeResult.detail.isNotEmpty) {
      _log('Native detail: ${nativeResult.detail}');
    }
    SaltoAnalytics.instance.trackNativeCallbackReceived(
      result: nativeResult.result.name,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    _trackNativeLayerSignal(nativeResult);

    if (nativeResult.result == SaltoUnlockResult.timeout) {
      lastFailureReason = SaltoFailureReason.sdkTimeout;
    } else if (nativeResult.result == SaltoUnlockResult.failure) {
      lastFailureReason = SaltoFailureReason.nativeFailure;
    }
    return nativeResult.result;
  }

  /// Classifies the native SDK/channel-layer outcome for the "BLE/SDK
  /// reliability" analytics dashboard — a finer grain than the funnel's own
  /// terminal granted/rejected/failed/timeout/noKey result, since a single
  /// unlock attempt can involve up to two native round trips (the initial
  /// try plus the fresh-key retry) and each is worth its own reliability
  /// data point.
  void _trackNativeLayerSignal(SaltoNativeResult nativeResult) {
    final detail = nativeResult.detail;
    if (detail.contains('client-side timeout')) {
      SaltoAnalytics.instance.trackSdkTimeout();
    } else if (detail.contains('MissingPluginException')) {
      SaltoAnalytics.instance.trackMethodChannelFailure(method: 'startUnlock');
    } else if (detail.contains('PlatformException')) {
      SaltoAnalytics.instance.trackNativeChannelError(detail: detail);
    } else if (nativeResult.result == SaltoUnlockResult.timeout) {
      SaltoAnalytics.instance.trackSdkTimeout();
    } else if (nativeResult.result == SaltoUnlockResult.failure) {
      SaltoAnalytics.instance.trackSdkFailure(detail: detail);
    } else {
      SaltoAnalytics.instance.trackSdkReady();
    }
  }

  Future<bool> _ensureBlePermissions({required bool needsLocation}) async {
    if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted || status.isLimited;
    }

    if (Platform.isAndroid) {
      // On Android 12+ (API 31+) BLUETOOTH_SCAN/CONNECT are the runtime
      // permissions and location is NOT requested — the manifest declares
      // location only up to API 30, so requesting it here would always be
      // denied and block the unlock. Only add location on Android ≤11.
      final permissions = <Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        if (needsLocation) Permission.locationWhenInUse,
      ];
      final statuses = await permissions.request();
      return statuses.values.every((status) => status.isGranted || status.isLimited);
    }

    return true;
  }

  void reset() {
    state = SaltoUnlockState.idle;
    lastFailureReason = SaltoFailureReason.none;
  }
}
