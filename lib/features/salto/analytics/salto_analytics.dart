// ignore_for_file: use_null_aware_elements
import 'package:uuid/uuid.dart';

import '../../../core/analytics/analytics_properties.dart';
import '../../../core/analytics/analytics_service.dart';
import '../data/salto_platform_channel.dart';

/// The integrated SALTO JustIN Mobile SDK version, sourced from the actual
/// native dependency on both platforms:
/// `ios/SaltoJustINMobileSDK/SaltoJustINMobileSDK.podspec` (`s.version`) and
/// `android/app/libs/justin-mobile-sdk-android-4.1.0.aar`. Update this
/// constant when the native SDK dependency is upgraded on either platform —
/// this is the ONE place `sdk_version` is sourced from; never hardcode it
/// at an individual call site.
const String kSaltoSdkVersion = '4.1.0';

const _uuid = Uuid();

/// Centralized Mixpanel event catalog for the entire SALTO feature —
/// activation funnel, unlock funnel, readiness, Bluetooth, Internet, SDK,
/// user behaviour, and automatic-recovery reliability events.
///
/// This is the ONLY place a SALTO Mixpanel event name is constructed —
/// every call site elsewhere (providers, prerequisite dialogs, pages) calls
/// one of the typed methods below instead of touching [AnalyticsService]
/// directly, the same way every other feature centralizes its event names
/// in `AnalyticsEvents`/`AnalyticsService`. [AnalyticsService.trackEvent] is
/// the sanctioned pass-through this facade is built on — Mixpanel itself
/// stays private to `analytics_service.dart` either way.
///
/// Local diagnostic logs ([AccessAttemptLog], persisted via
/// `AccessLogRepository` for on-device debugging) are a separate system —
/// this class never mirrors those into Mixpanel; it only fires on a
/// meaningful *product* event.
///
/// Screen-open/close for the Access page, the Activation page, and the
/// Student Card page are already covered generically by
/// `AnalyticsNavigationObserver` for every named GoRouter route — this
/// facade does not duplicate a screen-view event of its own.
///
/// ## Correlation (v2)
///
/// Every activation/unlock funnel, SDK/native, retry, and recovery event
/// carries a `salto_session_id` that stays identical across one entire
/// attempt — including any automatic retry — so the whole thing can be
/// reconstructed in Mixpanel by filtering on one ID. Passive background
/// signals (readiness polling, standalone Bluetooth/Internet observation)
/// deliberately do NOT carry a session id — they aren't scoped to one
/// attempt. See SALTO_ANALYTICS_INTEGRATION.md for the full session
/// lifecycle and an example Mixpanel timeline.
class SaltoAnalytics {
  SaltoAnalytics({void Function(String event, [Map<String, dynamic>? properties])? sink})
      : _sink = sink ?? AnalyticsService.instance.trackEvent;

  /// Application-wide singleton — the one every real call site should use.
  /// Tests construct their own instance with an injected `sink` instead.
  static final SaltoAnalytics instance = SaltoAnalytics();

  final void Function(String event, [Map<String, dynamic>? properties]) _sink;

  void _track(String event, [Map<String, dynamic>? properties]) => _sink(event, properties);

  // ── App lifecycle context ────────────────────────────────────────────────
  //
  // Mirrors whatever SaltoAccessPage/SaltoActivationPage's own
  // WidgetsBindingObserver already observes — both pages call
  // [updateAppLifecycleState] from their existing didChangeAppLifecycleState
  // override, so this needs no new lifecycle plumbing of its own.

  String? _appLifecycleState;

  /// Call with `state.name` (Flutter's `AppLifecycleState`) whenever it
  /// changes. Attached to every unlock/activation event that follows, so a
  /// failure occurring right after backgrounding is identifiable.
  void updateAppLifecycleState(String state) {
    _appLifecycleState = state;
  }

  // ── Duration bookkeeping ─────────────────────────────────────────────────
  //
  // Explicit, queryable duration properties — matches the existing
  // trackApiRequestCompleted/trackScreenActiveTime idiom already used
  // elsewhere in AnalyticsService, rather than relying solely on Mixpanel's
  // own less-visible timeEvent/$duration pairing.

  DateTime? _activationStartedAt;
  DateTime? _unlockStartedAt;

  int? _elapsedMs(DateTime? startedAt) =>
      startedAt == null ? null : DateTime.now().difference(startedAt).inMilliseconds;

  // Per-attempt granular timing, rolled into SALTO Unlock Completed.
  DateTime? _permissionCheckStartedAt;
  int? _lastPermissionDurationMs;
  DateTime? _keyFetchStartedAt;
  int? _lastKeyFetchDurationMs;
  int? _lastNativeDurationMs;

  /// Call right before the permission/Bluetooth pre-flight check begins in
  /// the unlock flow.
  void markPermissionCheckStarted() => _permissionCheckStartedAt = DateTime.now();

  /// Call right after that check completes, pass or fail either way.
  void markPermissionCheckCompleted() {
    final startedAt = _permissionCheckStartedAt;
    if (startedAt != null) {
      _lastPermissionDurationMs = DateTime.now().difference(startedAt).inMilliseconds;
    }
    _permissionCheckStartedAt = null;
  }

  /// Call right before fetching or force-refreshing the digital key.
  void markKeyFetchStarted() => _keyFetchStartedAt = DateTime.now();

  /// Call right after the key fetch resolves, success or failure either way.
  void markKeyFetchCompleted() {
    final startedAt = _keyFetchStartedAt;
    if (startedAt != null) {
      _lastKeyFetchDurationMs = DateTime.now().difference(startedAt).inMilliseconds;
    }
    _keyFetchStartedAt = null;
  }

  // ── Session correlation ──────────────────────────────────────────────────

  String? _unlockSessionId;
  String? _activationSessionId;

  /// How many attempts (0 = original, 1 = first retry, 2 = a further retry,
  /// …) have occurred within the current unlock session. Reset to 0 only
  /// when a fresh session begins.
  int _unlockAttemptNumber = 0;

  String _newSessionId() => _uuid.v4();

  /// The unlock flow's current session id, minted lazily if nothing has
  /// started one yet — a defensive fallback for an entry point that reaches
  /// the unlock flow without a preceding Open Button tap (e.g. the
  /// automatic unlock immediately following a successful activation).
  String get _currentUnlockSessionId => _unlockSessionId ??= _newSessionId();

  String get _currentActivationSessionId => _activationSessionId ??= _newSessionId();

  Map<String, dynamic> _unlockProps([Map<String, dynamic>? extra]) => {
        AnalyticsProperties.saltoSessionId: _currentUnlockSessionId,
        if (_appLifecycleState != null)
          AnalyticsProperties.appLifecycleState: _appLifecycleState,
        ...?extra,
      };

  Map<String, dynamic> _activationProps([Map<String, dynamic>? extra]) => {
        AnalyticsProperties.saltoSessionId: _currentActivationSessionId,
        if (_appLifecycleState != null)
          AnalyticsProperties.appLifecycleState: _appLifecycleState,
        ...?extra,
      };

  Map<String, dynamic> _sdkProps([Map<String, dynamic>? extra]) => {
        AnalyticsProperties.saltoSdkVersion: kSaltoSdkVersion,
        ...?extra,
      };

  // ══════════════════════════════════════════════════════════════════════
  // ACTIVATION FUNNEL
  // ══════════════════════════════════════════════════════════════════════

  void trackActivationButtonPressed() {
    _activationSessionId = _newSessionId();
    // A fresh top-level action invalidates any stale unlock session that
    // never got a terminal Completed (e.g. a long-abandoned rejected retry
    // chain) — the next unlock() call should mint its own fresh session
    // rather than silently inherit unrelated history.
    _unlockSessionId = null;
    _track('SALTO Activation Button Pressed', _activationProps());
  }

  void trackActivationConfirmDialogOpened() {
    _track('SALTO Activation Confirmation Dialog Opened', _activationProps());
  }

  void trackActivationConfirmed() {
    _track('SALTO Activation Confirmed', _activationProps());
  }

  void trackActivationCancelled() {
    _track('SALTO Activation Cancelled', _activationProps());
  }

  /// [reason] is a short machine tag, e.g. `bluetoothOff`,
  /// `internetUnavailable`, `alreadyActivating` — the same names
  /// `SaltoActivationReadinessIssue`/`SaltoActivationFailureReason` already
  /// use, so this can be filtered/joined against those in Mixpanel.
  /// [failureStage] is one of the standard failure-stage tags (see
  /// [AnalyticsProperties.saltoFailureStage]).
  void trackActivationBlocked({required String reason, String? failureStage}) {
    _track('SALTO Activation Blocked', _activationProps({
      AnalyticsProperties.failureReason: reason,
      if (failureStage != null) AnalyticsProperties.saltoFailureStage: failureStage,
    }));
  }

  void trackActivationStarted() {
    _activationStartedAt = DateTime.now();
    _track('SALTO Activation Started', _activationProps());
  }

  void trackActivationRequestSent() {
    _track('SALTO Activation POST Sent', _activationProps());
  }

  void trackActivationSucceeded() {
    final durationMs = _elapsedMs(_activationStartedAt);
    _track('SALTO Activation Success', _activationProps({
      if (durationMs != null) AnalyticsProperties.durationMs: durationMs,
      if (durationMs != null) AnalyticsProperties.saltoTotalDurationMs: durationMs,
    }));
    _trackActivationCompleted(result: 'success', durationMs: durationMs);
  }

  void trackActivationFailed({required String reason, String? failureStage}) {
    final durationMs = _elapsedMs(_activationStartedAt);
    _track('SALTO Activation Failed', _activationProps({
      AnalyticsProperties.failureReason: reason,
      if (failureStage != null) AnalyticsProperties.saltoFailureStage: failureStage,
      if (durationMs != null) AnalyticsProperties.durationMs: durationMs,
      if (durationMs != null) AnalyticsProperties.saltoTotalDurationMs: durationMs,
    }));
    _trackActivationCompleted(result: 'failed', durationMs: durationMs);
  }

  void _trackActivationCompleted({required String result, int? durationMs}) {
    _track('SALTO Activation Completed', _activationProps({
      AnalyticsProperties.saltoResult: result,
      if (durationMs != null) AnalyticsProperties.durationMs: durationMs,
      if (durationMs != null) AnalyticsProperties.saltoTotalDurationMs: durationMs,
    }));
    _activationStartedAt = null;
    _activationSessionId = null;
  }

  // ══════════════════════════════════════════════════════════════════════
  // UNLOCK FUNNEL
  // ══════════════════════════════════════════════════════════════════════

  void trackOpenButtonPressed() {
    _unlockSessionId = _newSessionId();
    _unlockAttemptNumber = 0;
    _activationSessionId = null;
    _track('SALTO Open Button Pressed', _unlockProps());
  }

  /// [triggerSource]: `unlock` (fresh tap or programmatic call) or
  /// `refreshAndRetry` (the fresh-key retry path) — matches the
  /// `triggeredBy` tags [SaltoUnlockNotifier] already uses internally.
  void trackUnlockStarted({required String triggerSource}) {
    _unlockStartedAt = DateTime.now();
    if (_unlockSessionId == null) {
      _unlockSessionId = _newSessionId();
      _unlockAttemptNumber = 0;
    }
    _track('SALTO Unlock Started', _unlockProps({
      AnalyticsProperties.saltoTriggerSource: triggerSource,
      AnalyticsProperties.saltoRetryAttempt: _unlockAttemptNumber,
    }));
  }

  void trackNativeUnlockStarted() {
    _track('SALTO Native Unlock Started', _unlockProps(_sdkProps({
      AnalyticsProperties.saltoRetryAttempt: _unlockAttemptNumber,
      if (_lastKeyFetchDurationMs != null)
        AnalyticsProperties.saltoKeyFetchDurationMs: _lastKeyFetchDurationMs,
    })));
  }

  void trackNativeCallbackReceived({
    required String result,
    required int durationMs,
  }) {
    _lastNativeDurationMs = durationMs;
    _track('SALTO Native Callback Received', _unlockProps(_sdkProps({
      AnalyticsProperties.saltoResult: result,
      AnalyticsProperties.durationMs: durationMs,
      AnalyticsProperties.saltoNativeDurationMs: durationMs,
      AnalyticsProperties.saltoRetryAttempt: _unlockAttemptNumber,
    })));
  }

  void trackUnlockGranted() {
    _trackUnlockTerminal('SALTO Unlock Granted', result: 'granted');
  }

  void trackUnlockRejected({String reason = 'rejected'}) {
    // Always set failure_reason so ops dashboards never show "(no reason)"
    // for the common door-reject path.
    _trackUnlockTerminal(
      'SALTO Unlock Rejected',
      result: 'rejected',
      reason: reason,
      failureStage: 'native_sdk',
    );
  }

  void trackUnlockFailed({required String reason, String? failureStage}) {
    _trackUnlockTerminal(
      'SALTO Unlock Failed',
      result: 'failed',
      reason: reason,
      failureStage: failureStage,
    );
  }

  void trackUnlockTimeout({String reason = 'timeout'}) {
    _trackUnlockTerminal(
      'SALTO Unlock Timeout',
      result: 'timeout',
      reason: reason,
      failureStage: 'native_sdk',
    );
  }

  /// A would-be attempt refused before it could even start (the busy lock
  /// was already held) — distinct from the user explicitly dismissing a
  /// dialog ([trackUserCancelledActivation]/
  /// [trackUserCancelledBluetoothDialog]). No matching [trackUnlockStarted]
  /// was ever fired for this attempt, so this does not also emit
  /// `SALTO Unlock Completed` — there is no duration to report.
  void trackUnlockCancelled({required String reason, String? failureStage}) {
    _track('SALTO Unlock Cancelled', _unlockProps({
      AnalyticsProperties.failureReason: reason,
      if (failureStage != null) AnalyticsProperties.saltoFailureStage: failureStage,
    }));
  }

  void _trackUnlockTerminal(
    String event, {
    required String result,
    String? reason,
    String? failureStage,
  }) {
    _track(event, _unlockProps({
      if (reason != null) AnalyticsProperties.failureReason: reason,
      if (failureStage != null) AnalyticsProperties.saltoFailureStage: failureStage,
      AnalyticsProperties.saltoRetryAttempt: _unlockAttemptNumber,
    }));

    final durationMs = _elapsedMs(_unlockStartedAt);
    _track('SALTO Unlock Completed', _unlockProps({
      AnalyticsProperties.saltoResult: result,
      if (reason != null) AnalyticsProperties.failureReason: reason,
      if (failureStage != null) AnalyticsProperties.saltoFailureStage: failureStage,
      if (durationMs != null) AnalyticsProperties.durationMs: durationMs,
      if (durationMs != null) AnalyticsProperties.saltoTotalDurationMs: durationMs,
      if (_lastNativeDurationMs != null)
        AnalyticsProperties.saltoNativeDurationMs: _lastNativeDurationMs,
      if (_lastKeyFetchDurationMs != null)
        AnalyticsProperties.saltoKeyFetchDurationMs: _lastKeyFetchDurationMs,
      if (_lastPermissionDurationMs != null)
        AnalyticsProperties.saltoPermissionDurationMs: _lastPermissionDurationMs,
      AnalyticsProperties.saltoRetryAttempt: _unlockAttemptNumber,
    }));

    _unlockStartedAt = null;
    _lastNativeDurationMs = null;
    _lastKeyFetchDurationMs = null;
    _lastPermissionDurationMs = null;
    // Rejected is the one terminal outcome with a deliberate automatic
    // continuation (the page's silent retry-after-rejected) — the session
    // must survive into that follow-up call, so it is not cleared here.
    if (result != 'rejected') {
      _unlockSessionId = null;
    }
  }

  /// [triggerSource]: `auto` (no preceding button press this call chain) or
  /// `manual` (a Retry button tap). [retryReason]: one of `timeout`,
  /// `rejected`, `stale_key`, `sdk_failure`, `manual_retry`, `recovery`.
  void trackRetryTriggered({required String triggerSource, required String retryReason}) {
    _unlockAttemptNumber += 1;
    _track('SALTO Retry Triggered', _unlockProps({
      AnalyticsProperties.saltoTriggerSource: triggerSource,
      AnalyticsProperties.saltoRetryReason: retryReason,
      AnalyticsProperties.saltoRetryAttempt: _unlockAttemptNumber,
    }));
  }

  void trackRetrySuccess() {
    _track('SALTO Retry Success', _unlockProps({
      AnalyticsProperties.saltoRetryAttempt: _unlockAttemptNumber,
    }));
  }

  void trackRetryFailed({required String reason, String? failureStage}) {
    _track('SALTO Retry Failed', _unlockProps({
      AnalyticsProperties.failureReason: reason,
      if (failureStage != null) AnalyticsProperties.saltoFailureStage: failureStage,
      AnalyticsProperties.saltoRetryAttempt: _unlockAttemptNumber,
    }));
  }

  // ══════════════════════════════════════════════════════════════════════
  // READINESS
  // ══════════════════════════════════════════════════════════════════════
  //
  // Callers are responsible for only invoking this when the issue actually
  // changed (both SaltoReadinessNotifier and SaltoActivationReadinessNotifier
  // compare old vs. new state before calling in) — this method itself does
  // not de-dup, since each flow has its own state to compare against.
  //
  // Deliberately does NOT carry salto_session_id/app_lifecycle_state —
  // readiness is a continuous background signal, not scoped to one
  // attempt (see the class doc's "Correlation" note).

  /// [flow]: `activation` or `unlock`. [issue] is a snake_case tag from the
  /// relevant readiness enum's `.analyticsTag` extension (see
  /// `salto_readiness_provider.dart` / `salto_activation_readiness_provider.dart`).
  /// [readinessDurationMs], if given, is how long the readiness evaluation
  /// itself took to compute.
  void trackReadinessChanged({
    required String flow,
    required String issue,
    int? readinessDurationMs,
  }) {
    _track('SALTO Ready State Changed', {
      AnalyticsProperties.saltoFlow: flow,
      AnalyticsProperties.saltoReadinessIssue: issue,
      if (readinessDurationMs != null)
        AnalyticsProperties.saltoReadinessDurationMs: readinessDurationMs,
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // BLUETOOTH
  // ══════════════════════════════════════════════════════════════════════
  //
  // De-duped against the last-observed state here (not by the caller) —
  // both readiness providers poll Bluetooth independently and would
  // otherwise double-report every real transition. Same scope note as
  // Readiness above: no session id, since this fires from independent
  // background polling as often as from within an active attempt.

  SaltoBluetoothState? _lastBluetoothState;

  /// Call with every freshly-observed [SaltoBluetoothState] (from either
  /// readiness provider's poll, or the unlock flow's own pre-flight check).
  /// Only fires when the state actually differs from the last call.
  void trackBluetoothStateObserved(SaltoBluetoothState state) {
    final previous = _lastBluetoothState;
    _lastBluetoothState = state;
    if (previous == null || previous == state) return;

    _track('SALTO Bluetooth State Changed', {
      AnalyticsProperties.saltoBluetoothStateFrom: previous.name,
      AnalyticsProperties.saltoBluetoothState: state.name,
    });

    if (state == SaltoBluetoothState.ready) {
      _track('SALTO Bluetooth Enabled');
      // Bluetooth coming back on is itself a form of successful recovery —
      // no matching "Recovery Started" exists for this specific reason
      // since there is no active recovery attempt to bookend, only a
      // passive state restoration (see class doc).
      _track('SALTO Recovery Success', {
        AnalyticsProperties.saltoRecoveryReason: 'bluetooth_restored',
      });
      if (previous == SaltoBluetoothState.unauthorized) {
        _track('SALTO Bluetooth Permission Granted');
      }
    } else if (state == SaltoBluetoothState.off) {
      _track('SALTO Bluetooth Disabled');
    } else if (state == SaltoBluetoothState.unauthorized) {
      _track('SALTO Bluetooth Permission Denied');
    } else if (state == SaltoBluetoothState.unsupported) {
      _track('SALTO Bluetooth Unsupported');
    }
  }

  /// [flow]: `activation` or `unlock`.
  void trackBluetoothSettingsOpened({required String flow}) {
    _track('SALTO Bluetooth Settings Opened', {AnalyticsProperties.saltoFlow: flow});
  }

  /// [flow]: `activation` or `unlock`.
  void trackBluetoothSettingsReturned({required String flow}) {
    _track('SALTO Bluetooth Settings Returned', {AnalyticsProperties.saltoFlow: flow});
  }

  // ══════════════════════════════════════════════════════════════════════
  // INTERNET
  // ══════════════════════════════════════════════════════════════════════
  //
  // De-duped the same way as Bluetooth, for the same reason.

  bool? _lastInternetAvailable;

  void trackInternetStateObserved(bool isConnected) {
    final previous = _lastInternetAvailable;
    _lastInternetAvailable = isConnected;
    if (previous == null || previous == isConnected) return;

    _track(isConnected ? 'SALTO Internet Connected' : 'SALTO Internet Lost', {
      AnalyticsProperties.saltoInternetAvailable: isConnected,
    });
    if (isConnected) {
      // Same reasoning as Bluetooth above — a passive restoration counted
      // as a recovery outcome, with no matching "Started" bookend.
      _track('SALTO Recovery Success', {
        AnalyticsProperties.saltoRecoveryReason: 'internet_restored',
      });
    }
  }

  void trackNetworkSettingsOpened() {
    _track('SALTO Network Settings Opened');
  }

  void trackNetworkSettingsReturned() {
    _track('SALTO Network Settings Returned');
  }

  void trackActivationBlockedByInternet() {
    _track('SALTO Activation Blocked By Internet');
  }

  // ══════════════════════════════════════════════════════════════════════
  // SDK / NATIVE
  // ══════════════════════════════════════════════════════════════════════
  //
  // Every method here attaches sdk_version from the single kSaltoSdkVersion
  // constant, and the current unlock session id (these all fire from
  // within an active unlock attempt).

  void trackSdkReady() {
    _track('SALTO SDK Ready', _unlockProps(_sdkProps()));
  }

  void trackSdkTimeout() {
    _track('SALTO SDK Timeout', _unlockProps(_sdkProps({
      AnalyticsProperties.saltoFailureStage: 'native_sdk',
    })));
  }

  void trackSdkFailure({String? detail}) {
    _track('SALTO SDK Failure', _unlockProps(_sdkProps({
      if (detail != null) AnalyticsProperties.errorMessage: detail,
      AnalyticsProperties.saltoFailureStage: 'native_sdk',
    })));
  }

  /// A Dart-side exception thrown while driving the SDK (key fetch/validate/
  /// unlock sequence) that never resolved into a typed [SaltoNativeResult]
  /// at all — distinct from [trackSdkFailure], which covers a native call
  /// that *did* return, just with a failure status. [failureStage] defaults
  /// to `native_sdk` but callers pass a more specific stage when known
  /// (e.g. `key_fetch`, `retry`).
  void trackSdkException({String? detail, String failureStage = 'native_sdk'}) {
    _track('SALTO SDK Exception', _unlockProps(_sdkProps({
      if (detail != null) AnalyticsProperties.errorMessage: detail,
      AnalyticsProperties.saltoFailureStage: failureStage,
    })));
  }

  void trackNativeChannelError({String? detail}) {
    _track('SALTO Native Channel Error', _unlockProps(_sdkProps({
      if (detail != null) AnalyticsProperties.errorMessage: detail,
      AnalyticsProperties.saltoFailureStage: 'method_channel',
    })));
  }

  void trackMethodChannelFailure({required String method}) {
    _track('SALTO MethodChannel Failure', _unlockProps(_sdkProps({
      AnalyticsProperties.saltoNativeMethod: method,
      AnalyticsProperties.saltoFailureStage: 'method_channel',
    })));
  }

  void trackDigitalKeyInvalid() {
    _track('SALTO Digital Key Invalid', _unlockProps(_sdkProps({
      AnalyticsProperties.saltoFailureStage: 'key_validation',
    })));
  }

  void trackDigitalKeyRefreshed() {
    _track('SALTO Digital Key Refreshed', _sdkProps());
  }

  void trackKeyRefreshStarted() {
    _track('SALTO Key Refresh Started', _sdkProps());
  }

  void trackKeyRefreshCompleted() {
    _track('SALTO Key Refresh Completed', _sdkProps());
  }

  void trackKeyRefreshFailed({String? reason}) {
    _track('SALTO Key Refresh Failed', _sdkProps({
      if (reason != null) AnalyticsProperties.failureReason: reason,
      AnalyticsProperties.saltoFailureStage: 'key_fetch',
    }));
  }

  // ══════════════════════════════════════════════════════════════════════
  // USER BEHAVIOUR
  // ══════════════════════════════════════════════════════════════════════

  void trackUserCancelledActivation() {
    _track('SALTO User Cancelled Activation');
  }

  void trackUserCancelledBluetoothDialog() {
    _track('SALTO User Cancelled Bluetooth Dialog');
  }

  void trackUserContinuedWithoutBluetooth() {
    _track('SALTO User Continued Without Bluetooth');
  }

  /// [settingsType]: `bluetooth` or `network`.
  void trackUserOpenedSettings({required String settingsType}) {
    _track('SALTO User Opened Settings', {
      AnalyticsProperties.saltoSettingsType: settingsType,
    });
  }

  void trackUserReturnedFromSettings() {
    _track('SALTO User Returned From Settings');
  }

  void trackUserRetriedUnlock() {
    _track('SALTO User Retried Unlock');
  }

  void trackRapidMultipleTaps({required String tapContext}) {
    _track('SALTO Rapid Multiple Taps', {
      AnalyticsProperties.saltoTapContext: tapContext,
    });
  }

  void trackUnlockWhileOffline() {
    _track('SALTO Unlock While Offline');
  }

  void trackUnlockWhileBluetoothDisabled() {
    _track('SALTO Unlock While Bluetooth Disabled');
  }

  // ══════════════════════════════════════════════════════════════════════
  // RELIABILITY (automatic recovery)
  // ══════════════════════════════════════════════════════════════════════
  //
  // The five original v1 events below are unchanged — kept exactly as they
  // were (fire-once signals) rather than folded into the new structured
  // Started/Finished pattern, per "do not remove any existing analytics".
  // The new v2 Recovery Started/Finished/Success/Failed events extend this
  // with an explicit reason + measured duration for the *active* recovery
  // attempts (timeout-triggered retry, stale-lock force-release, general
  // retry-recovery) — see trackRecoveryStarted below and its call sites.

  void trackTimeoutRecovery() {
    _track('SALTO Timeout Recovery', _unlockProps());
  }

  void trackStaleLockRecovery() {
    _track('SALTO Stale Lock Recovery', _unlockProps());
  }

  void trackRetryRecovery() {
    _track('SALTO Retry Recovery', _unlockProps());
  }

  void trackBackgroundRecovery() {
    _track('SALTO Background Recovery');
  }

  void trackResumeRecovery() {
    _track('SALTO Resume Recovery');
  }

  DateTime? _recoveryStartedAt;

  /// [recoveryReason]: `timeout`, `stale_lock`, `stale_key`, `sdk_failure`,
  /// `bluetooth_restored`, or `internet_restored`. Pair with
  /// [trackRecoverySucceeded]/[trackRecoveryFailed] once the recovery
  /// attempt resolves — `bluetooth_restored`/`internet_restored` have no
  /// "Started" moment of their own (see [trackBluetoothStateObserved]/
  /// [trackInternetStateObserved]) since they are passive restorations, not
  /// active attempts.
  void trackRecoveryStarted({required String recoveryReason}) {
    _recoveryStartedAt = DateTime.now();
    _track('SALTO Recovery Started', _unlockProps({
      AnalyticsProperties.saltoRecoveryReason: recoveryReason,
    }));
  }

  void trackRecoverySucceeded({required String recoveryReason}) {
    _trackRecoveryFinished(recoveryReason: recoveryReason, success: true);
  }

  void trackRecoveryFailed({required String recoveryReason}) {
    _trackRecoveryFinished(recoveryReason: recoveryReason, success: false);
  }

  void _trackRecoveryFinished({required String recoveryReason, required bool success}) {
    final durationMs = _elapsedMs(_recoveryStartedAt);
    _track('SALTO Recovery Finished', _unlockProps({
      AnalyticsProperties.saltoRecoveryReason: recoveryReason,
      AnalyticsProperties.saltoResult: success ? 'success' : 'failed',
      if (durationMs != null) AnalyticsProperties.durationMs: durationMs,
      if (durationMs != null) AnalyticsProperties.saltoRecoveryDurationMs: durationMs,
    }));
    _track(success ? 'SALTO Recovery Success' : 'SALTO Recovery Failed', _unlockProps({
      AnalyticsProperties.saltoRecoveryReason: recoveryReason,
      if (durationMs != null) AnalyticsProperties.saltoRecoveryDurationMs: durationMs,
    }));
    _recoveryStartedAt = null;
  }
}
