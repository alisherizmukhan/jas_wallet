import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../analytics/salto_analytics.dart';
import '../../data/models/salto_mobile_status.dart';
import '../../data/repositories/salto_repository_impl.dart';
import '../../domain/access_attempt_log.dart';
import 'access_stats_provider.dart';
import 'salto_provider.dart';

/// Outcome of the guarded activation attempt. The confirmation dialog
/// itself is owned by the calling page (two entry points: the dedicated
/// activation page reached during login, and the reactivation prompt on
/// the Access page) — this covers only what happens once the user has
/// confirmed: the guarded POST and its immediate follow-up.
enum SaltoActivationState { idle, activating, success, error }

/// Specific reason the last attempt didn't reach — or didn't survive —
/// the backend call. Kept separate from [SaltoActivationState] rather than
/// added as new state values, the same way [SaltoFailureReason] sits
/// alongside [SaltoUnlockState]: purely additive detail for building
/// specific copy, without touching an existing switch surface.
enum SaltoActivationFailureReason {
  none,
  internetUnavailable,
  alreadyActivating,
  backendRejected,

  /// The POST was sent but no response came back in time, and a follow-up
  /// status check could not confirm the activation landed either way. The
  /// server may still be finishing — the user must be told to wait, never to
  /// retry, because a second activation cancels the key the first one is
  /// still issuing.
  timedOutStillRunning,
  unknown,
}

/// Owns the single guard for "is a `POST /salto/me/activate-mobile` request
/// currently in flight."
///
/// Root cause this exists to close: activation previously had no shared
/// guard at all — each page tracked its own local `_isLoading`/`_isActivating`
/// flag, set only *after* its own confirmation dialog resolved. Two
/// independent entry points (the login-flow activation page and the Access
/// page's reactivation prompt) could therefore never coordinate with each
/// other, and neither could tell if the *other* already had a request in
/// flight. Routing both through this notifier's [activate] means there is
/// now exactly one place a duplicate/overlapping attempt can be detected
/// and safely turned away — logged, never silent.
class SaltoActivationNotifier extends StateNotifier<SaltoActivationState> {
  SaltoActivationNotifier({
    required SaltoRepositoryImpl repository,
    required Ref ref,
    @visibleForTesting Future<bool> Function()? isConnected,
    @visibleForTesting List<Duration>? reconcileBackoff,
  })  : _repository = repository,
        _ref = ref,
        _isConnected = isConnected ?? ConnectivityService.isConnected,
        _reconcileBackoff = reconcileBackoff ?? _defaultReconcileBackoff,
        super(SaltoActivationState.idle);

  final SaltoRepositoryImpl _repository;
  final Ref _ref;
  final Future<bool> Function() _isConnected;
  final List<Duration> _reconcileBackoff;

  bool _isActivating = false;

  /// Whether an activation POST is currently in flight. Exposed for the
  /// same reason [SaltoUnlockNotifier.isUnlocking] is: so the UI's notion
  /// of "can the user tap this" is never a guess about private state.
  bool get isActivating => _isActivating;

  /// Specific reason the current/last attempt could not proceed or failed.
  SaltoActivationFailureReason lastFailureReason = SaltoActivationFailureReason.none;

  List<String> _logs = [];

  String _timestamped(String message) {
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    return '[$ts] $message';
  }

  void _log(String message) {
    _logs.add(_timestamped(message));
    if (kDebugMode) debugPrint('SaltoActivation: $message');
  }

  // ── Prerequisite-check logging ──────────────────────────────────────────
  //
  // These fire from SaltoActivationPrerequisites, *before* activate() is
  // ever called — a tap that never reaches this notifier's own guard
  // (Bluetooth off, offline, sent to Settings) previously left no trace
  // anywhere. Each is persisted as its own standalone attempt entry so a
  // production report can be diagnosed from the same Access Stats history
  // every other activation/unlock attempt already appears in.

  /// A prerequisite check refused to let activation proceed before the
  /// confirm dialog was even shown. [reason] is a short machine-readable
  /// tag (e.g. `bluetoothOff`, `internetUnavailable`) used as part of the
  /// persisted result string; [detail] is the human-readable specifics.
  Future<void> logBlocked(String reason, {required String detail}) async {
    final message = 'Activation blocked before confirm: $reason — $detail';
    if (kDebugMode) debugPrint('SaltoActivation: $message');
    await _recordStandalone('activation_blocked_$reason', [_timestamped(message)]);
  }

  /// The user was sent to a system Settings screen from a prerequisite
  /// dialog (e.g. "Open Bluetooth Settings").
  Future<void> logSettingsOpened(String settingType) async {
    final message = 'Opened $settingType settings from a prerequisite prompt';
    if (kDebugMode) debugPrint('SaltoActivation: $message');
    await _recordStandalone('activation_settings_opened', [_timestamped(message)]);
  }

  /// The app resumed after the user was sent to Settings — paired with
  /// [logSettingsOpened] so the "did they actually fix it" window is
  /// visible when diagnosing a production report.
  Future<void> logSettingsReturned() async {
    final message = 'Returned from settings — readiness will re-check automatically';
    if (kDebugMode) debugPrint('SaltoActivation: $message');
    await _recordStandalone('activation_settings_returned', [_timestamped(message)]);
  }

  /// Attempts to activate SALTO mobile access.
  ///
  /// Called only after the caller's own confirmation dialog has resolved
  /// to `true` — this method owns everything from that point on: a
  /// pre-flight connectivity check (activation must never silently attempt
  /// the POST while offline), the guarded network call itself, and the
  /// immediate follow-up (invalidating the cached status and forcing a
  /// fresh digital key fetch, since activation issues a new server-side
  /// key that any previously-cached key would now be stale against).
  ///
  /// Returns the fresh [SaltoMobileStatus] on success. Returns `null`
  /// without throwing when the request could not even be attempted — no
  /// internet, or another attempt already in flight — both set
  /// [lastFailureReason] and `state = error` so the caller can show a
  /// specific message instead of a generic one. Rethrows
  /// [SaltoRepositoryException] on a genuine backend/network failure, so
  /// existing callers keep showing its message via a toast exactly as
  /// before.
  Future<SaltoMobileStatus?> activate() async {
    if (_isActivating) {
      _log('activate() ignored — another attempt is already in progress');
      lastFailureReason = SaltoActivationFailureReason.alreadyActivating;
      unawaited(_recordAttempt('activation_busyIgnored'));
      SaltoAnalytics.instance.trackActivationBlocked(reason: 'alreadyActivating', failureStage: 'retry');
      return null;
    }

    _isActivating = true;
    _logs = [];
    lastFailureReason = SaltoActivationFailureReason.none;
    state = SaltoActivationState.activating;
    _log('Activation requested');
    SaltoAnalytics.instance.trackActivationStarted();

    try {
      final online = await _isConnected();
      _log('Connectivity check: ${online ? "online" : "offline"}');
      SaltoAnalytics.instance.trackInternetStateObserved(online);
      if (!online) {
        _log('Offline — activation must not be attempted without a connection');
        lastFailureReason = SaltoActivationFailureReason.internetUnavailable;
        state = SaltoActivationState.error;
        unawaited(_recordAttempt('activation_offline'));
        SaltoAnalytics.instance.trackActivationBlocked(reason: 'internetUnavailable', failureStage: 'internet');
        SaltoAnalytics.instance.trackActivationBlockedByInternet();
        return null;
      }

      _log('Sending POST /salto/me/activate-mobile');
      SaltoAnalytics.instance.trackActivationRequestSent();
      final result = await _repository.activateMobileAccess();
      _log('Activation succeeded');
      return _completeSuccess(result, result: 'activation_success');
    } on SaltoRepositoryException catch (e) {
      // An in-flight timeout is not a failure — it's an unknown. The server
      // very likely finished the (destructive, non-idempotent) sequence after
      // we stopped listening, so ask it what actually happened instead of
      // reporting an error the user will answer by tapping again.
      if (e.isTimeout) {
        _log('Activation timed out in flight — asking the server what landed');
        SaltoAnalytics.instance.trackActivationFailed(reason: 'timeout', failureStage: 'backend');
        final reconciled = await _reconcileAfterTimeout();
        if (reconciled != null) {
          return _completeSuccess(reconciled, result: 'activation_success_after_timeout');
        }
        lastFailureReason = SaltoActivationFailureReason.timedOutStillRunning;
        state = SaltoActivationState.error;
        unawaited(_recordAttempt('activation_timedOut'));
        // Returned, not rethrown: the caller shows the "still finishing"
        // gate message rather than the repository's retry-flavoured one.
        return null;
      }

      _log('Activation failed: ${e.message}');
      lastFailureReason = SaltoActivationFailureReason.backendRejected;
      state = SaltoActivationState.error;
      unawaited(_recordAttempt('activation_failed'));
      SaltoAnalytics.instance.trackActivationFailed(reason: 'backendRejected', failureStage: 'backend');
      rethrow;
    } catch (e) {
      _log('Activation failed (unexpected): $e');
      lastFailureReason = SaltoActivationFailureReason.unknown;
      state = SaltoActivationState.error;
      unawaited(_recordAttempt('activation_failed'));
      SaltoAnalytics.instance.trackActivationFailed(reason: 'unknown', failureStage: 'unknown');
      rethrow;
    } finally {
      _isActivating = false;
    }
  }

  /// The follow-up every confirmed activation needs, whether the POST's own
  /// response delivered it or a post-timeout status check discovered it.
  SaltoMobileStatus _completeSuccess(SaltoMobileStatus status, {required String result}) {
    _ref.invalidate(saltoStatusProvider);
    _log('Status cache invalidated — will refresh in the background');

    // Activation issues a new server-side (SALTO Ship) key; any
    // previously-cached key is now stale. Force a fresh fetch rather
    // than waiting for the existing TTL/staleness checks to notice.
    // SaltoKeyManager.refreshKey() tracks its own Key Refresh Started/
    // Completed/Failed analytics — not duplicated here.
    unawaited(_ref.read(saltoKeyManagerProvider).refreshKey());
    _log('Digital key refresh started');

    state = SaltoActivationState.success;
    unawaited(_recordAttempt(result));
    SaltoAnalytics.instance.trackActivationSucceeded();
    return status;
  }

  /// Backoff between reconciliation probes. Short enough that a student who
  /// is standing at a turnstile isn't left waiting, long enough to give a
  /// server that was mid-sequence when we timed out a real chance to finish.
  static const _defaultReconcileBackoff = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
  ];

  /// After an in-flight timeout, ask the server what actually happened.
  ///
  /// Returns the fresh status when activation did land server-side (the
  /// common case — the backend keeps running after the client stops
  /// listening), or null when it demonstrably hasn't yet or we couldn't find
  /// out. Deliberately uses [SaltoRepositoryImpl.getFreshMobileStatus] rather
  /// than the cache-falling-back [getMobileStatus]: a stale cached "not
  /// enabled" would otherwise look exactly like a real one, and we would
  /// wrongly tell the user activation failed.
  ///
  /// Note this runs while the activation guard is still held, which is the
  /// point — no second attempt can start while the first one's outcome is
  /// still unknown.
  Future<SaltoMobileStatus?> _reconcileAfterTimeout() async {
    for (var attempt = 0; attempt < _reconcileBackoff.length; attempt++) {
      await Future<void>.delayed(_reconcileBackoff[attempt]);
      try {
        final status = await _repository.getFreshMobileStatus();
        if (status.mobileAccessEnabled && !status.deviceBindingRequired) {
          _log('Reconciled after ${attempt + 1} probe(s): activation did complete');
          SaltoAnalytics.instance.trackRecoverySucceeded(recoveryReason: 'activation_timeout');
          return status;
        }
        _log('Reconcile probe ${attempt + 1}: server still reports not activated');
      } catch (e) {
        _log('Reconcile probe ${attempt + 1} could not reach the server: $e');
      }
    }
    _log('Could not confirm the activation outcome — leaving it to the user to re-check');
    SaltoAnalytics.instance.trackRecoveryFailed(recoveryReason: 'activation_timeout');
    return null;
  }

  Future<void> _recordAttempt(String result) => _recordStandalone(result, _logs);

  Future<void> _recordStandalone(String result, List<String> logs) async {
    try {
      final attempt = AccessAttemptLog(
        timestamp: DateTime.now(),
        result: result,
        logs: List.unmodifiable(logs),
      );
      await _ref.read(accessLogRepositoryProvider).recordAttempt(attempt);
      _ref.invalidate(accessAttemptsProvider);
    } catch (_) {}
  }

  void reset() {
    state = SaltoActivationState.idle;
    lastFailureReason = SaltoActivationFailureReason.none;
  }
}

final saltoActivationProvider =
    StateNotifierProvider<SaltoActivationNotifier, SaltoActivationState>((ref) {
  return SaltoActivationNotifier(
    repository: ref.watch(saltoRepositoryProvider),
    ref: ref,
  );
});
