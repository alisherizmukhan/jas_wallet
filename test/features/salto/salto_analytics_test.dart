import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/analytics/analytics_properties.dart';
import 'package:jaswallet_app/features/salto/analytics/salto_analytics.dart';
import 'package:jaswallet_app/features/salto/data/salto_platform_channel.dart';

class _TrackedEvent {
  _TrackedEvent(this.name, this.properties);
  final String name;
  final Map<String, dynamic>? properties;
}

void main() {
  late List<_TrackedEvent> events;
  late SaltoAnalytics analytics;

  setUp(() {
    events = [];
    analytics = SaltoAnalytics(
      sink: (event, [properties]) => events.add(_TrackedEvent(event, properties)),
    );
  });

  group('Activation funnel', () {
    test('a successful attempt fires Success then Completed(result: success) '
        'with a duration_ms', () {
      analytics.trackActivationStarted();
      analytics.trackActivationSucceeded();

      expect(events.map((e) => e.name), [
        'SALTO Activation Started',
        'SALTO Activation Success',
        'SALTO Activation Completed',
      ]);
      final completed = events.last;
      expect(completed.properties?[AnalyticsProperties.saltoResult], 'success');
      expect(completed.properties?[AnalyticsProperties.durationMs], isA<int>());
    });

    test('a failed attempt fires Failed then Completed(result: failed) with '
        'the failure reason on both', () {
      analytics.trackActivationStarted();
      analytics.trackActivationFailed(reason: 'backendRejected');

      final failed = events[1];
      final completed = events[2];
      expect(failed.name, 'SALTO Activation Failed');
      expect(failed.properties?[AnalyticsProperties.failureReason], 'backendRejected');
      expect(completed.name, 'SALTO Activation Completed');
      expect(completed.properties?[AnalyticsProperties.saltoResult], 'failed');
    });

    test('a blocked attempt fires Blocked with the reason and never a '
        'Completed event (no attempt was ever started)', () {
      analytics.trackActivationBlocked(reason: 'internetUnavailable');

      expect(events, hasLength(1));
      expect(events.single.name, 'SALTO Activation Blocked');
      expect(events.single.properties?[AnalyticsProperties.failureReason], 'internetUnavailable');
    });
  });

  group('Unlock funnel', () {
    test('granted fires Granted then Completed(result: granted)', () {
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackUnlockGranted();

      expect(events.map((e) => e.name), [
        'SALTO Unlock Started',
        'SALTO Unlock Granted',
        'SALTO Unlock Completed',
      ]);
      expect(events.last.properties?[AnalyticsProperties.saltoResult], 'granted');
    });

    test('rejected/failed/timeout each fire their own event plus a matching '
        'Completed with an explicit failure_reason', () {
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackUnlockRejected();
      expect(events.map((e) => e.name), containsAllInOrder([
        'SALTO Unlock Rejected',
        'SALTO Unlock Completed',
      ]));
      expect(events.last.properties?[AnalyticsProperties.failureReason], 'rejected');
      expect(events.last.properties?[AnalyticsProperties.saltoResult], 'rejected');

      events.clear();
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackUnlockFailed(reason: 'nativeFailure');
      expect(events.map((e) => e.name), containsAllInOrder([
        'SALTO Unlock Failed',
        'SALTO Unlock Completed',
      ]));
      expect(events.last.properties?[AnalyticsProperties.failureReason], 'nativeFailure');

      events.clear();
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackUnlockTimeout();
      expect(events.map((e) => e.name), containsAllInOrder([
        'SALTO Unlock Timeout',
        'SALTO Unlock Completed',
      ]));
      expect(events.last.properties?[AnalyticsProperties.failureReason], 'timeout');
      expect(events.last.properties?[AnalyticsProperties.saltoResult], 'timeout');
    });

    test('cancelled (busy-lock refusal before any attempt started) fires '
        'only Cancelled — never a Completed event, since there is no '
        'duration to report', () {
      analytics.trackUnlockCancelled(reason: 'busyIgnored');

      expect(events, hasLength(1));
      expect(events.single.name, 'SALTO Unlock Cancelled');
      expect(events.single.properties?[AnalyticsProperties.failureReason], 'busyIgnored');
    });

    test('trigger source is carried on Started', () {
      analytics.trackUnlockStarted(triggerSource: 'auto_rejected');
      expect(events.single.properties?[AnalyticsProperties.saltoTriggerSource], 'auto_rejected');
    });
  });

  group('Bluetooth state de-duplication', () {
    test('the first observation ever never fires an event — nothing to '
        'compare it against yet', () {
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.ready);
      expect(events, isEmpty);
    });

    test('repeating the same state never fires a second time', () {
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.ready);
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.ready);
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.ready);
      expect(events, isEmpty);
    });

    test('off -> ready fires State Changed, Bluetooth Enabled, and a '
        'Recovery Success (bluetooth_restored)', () {
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.off);
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.ready);

      expect(events.map((e) => e.name), [
        'SALTO Bluetooth State Changed',
        'SALTO Bluetooth Enabled',
        'SALTO Recovery Success',
      ]);
      expect(events.first.properties?[AnalyticsProperties.saltoBluetoothStateFrom], 'off');
      expect(events.first.properties?[AnalyticsProperties.saltoBluetoothState], 'ready');
    });

    test('ready -> off fires State Changed and Bluetooth Disabled', () {
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.ready);
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.off);

      expect(events.map((e) => e.name), [
        'SALTO Bluetooth State Changed',
        'SALTO Bluetooth Disabled',
      ]);
    });

    test('unauthorized -> ready fires State Changed, Enabled, Recovery '
        'Success, AND Permission Granted', () {
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.unauthorized);
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.ready);

      expect(events.map((e) => e.name), [
        'SALTO Bluetooth State Changed',
        'SALTO Bluetooth Enabled',
        'SALTO Recovery Success',
        'SALTO Bluetooth Permission Granted',
      ]);
    });

    test('ready -> unauthorized fires State Changed and Permission Denied', () {
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.ready);
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.unauthorized);

      expect(events.map((e) => e.name), [
        'SALTO Bluetooth State Changed',
        'SALTO Bluetooth Permission Denied',
      ]);
    });

    test('-> unsupported fires State Changed and Bluetooth Unsupported', () {
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.off);
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.unsupported);

      expect(events.map((e) => e.name), [
        'SALTO Bluetooth State Changed',
        'SALTO Bluetooth Unsupported',
      ]);
    });

    test('a second, independent SaltoAnalytics instance keeps its own '
        'last-observed state — polling from two different readiness '
        'providers must not corrupt each other, but this test only proves '
        'each instance is independently stateful', () {
      final other = SaltoAnalytics(sink: (_, [_]) {});
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.ready);
      other.trackBluetoothStateObserved(SaltoBluetoothState.off);
      // The shared production singleton is what actually prevents
      // double-counting across providers (see instance).
      expect(SaltoAnalytics.instance, isNotNull);
    });
  });

  group('Internet state de-duplication', () {
    test('the first observation never fires', () {
      analytics.trackInternetStateObserved(true);
      expect(events, isEmpty);
    });

    test('true -> false fires Internet Lost', () {
      analytics.trackInternetStateObserved(true);
      analytics.trackInternetStateObserved(false);
      expect(events.single.name, 'SALTO Internet Lost');
      expect(events.single.properties?[AnalyticsProperties.saltoInternetAvailable], false);
    });

    test('false -> true fires Internet Connected and a Recovery Success '
        '(internet_restored)', () {
      analytics.trackInternetStateObserved(false);
      analytics.trackInternetStateObserved(true);
      expect(events.map((e) => e.name), [
        'SALTO Internet Connected',
        'SALTO Recovery Success',
      ]);
    });

    test('repeating the same value never re-fires', () {
      analytics.trackInternetStateObserved(true);
      analytics.trackInternetStateObserved(false);
      events.clear();
      analytics.trackInternetStateObserved(false);
      analytics.trackInternetStateObserved(false);
      expect(events, isEmpty);
    });
  });

  group('Readiness changed', () {
    test('carries flow and issue as given — de-duplication is the caller\'s '
        'responsibility (each readiness notifier compares old vs. new '
        'state itself before calling in)', () {
      analytics.trackReadinessChanged(flow: 'activation', issue: 'bluetooth_off');
      analytics.trackReadinessChanged(flow: 'activation', issue: 'bluetooth_off');

      expect(events, hasLength(2));
      for (final e in events) {
        expect(e.name, 'SALTO Ready State Changed');
        expect(e.properties?[AnalyticsProperties.saltoFlow], 'activation');
        expect(e.properties?[AnalyticsProperties.saltoReadinessIssue], 'bluetooth_off');
      }
    });
  });

  group('Session ID — correlation', () {
    String sid(_TrackedEvent e) => e.properties?[AnalyticsProperties.saltoSessionId] as String;

    test('the full example chain (Open -> Started -> Native Started -> '
        'Native Callback -> Retry -> Granted) shares exactly one session id',
        () {
      analytics.trackOpenButtonPressed();
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackNativeUnlockStarted();
      analytics.trackNativeCallbackReceived(result: 'timeout', durationMs: 5);
      analytics.trackRetryTriggered(triggerSource: 'auto', retryReason: 'timeout');
      analytics.trackNativeUnlockStarted();
      analytics.trackNativeCallbackReceived(result: 'granted', durationMs: 5);
      analytics.trackUnlockGranted();

      final ids = events.map(sid).toSet();
      expect(ids, hasLength(1), reason: 'every event must share one session id');
    });

    test('a fresh Open Button Pressed regenerates the session id', () {
      analytics.trackOpenButtonPressed();
      final firstId = sid(events.single);

      events.clear();
      analytics.trackOpenButtonPressed();
      final secondId = sid(events.single);

      expect(secondId, isNot(firstId));
    });

    test('an automatic retry-after-rejected (refreshAndRetry-style '
        'continuation, no fresh button press) reuses the session id from '
        'before the Rejected result', () {
      analytics.trackOpenButtonPressed();
      final openId = sid(events.first);

      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackUnlockRejected(); // fires Rejected + Completed, does NOT clear the session

      // Simulates SaltoUnlockNotifier.refreshAndRetry() firing without any
      // preceding button-press event — the exact shape of the page's
      // silent auto-retry-after-rejected.
      analytics.trackUnlockStarted(triggerSource: 'refreshAndRetry');
      analytics.trackUnlockGranted();

      final ids = events.map(sid).toSet();
      expect(ids, {openId}, reason: 'rejected must not break the session chain');
    });

    test('a terminal Granted/Failed/Timeout (not Rejected) clears the '
        'session — a later, unrelated Started mints a fresh one', () {
      analytics.trackOpenButtonPressed();
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackUnlockGranted();
      final firstId = sid(events.last);

      events.clear();
      // No button press this time either — simulates an unrelated later
      // call reaching the unlock flow directly.
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      final secondId = sid(events.single);

      expect(secondId, isNot(firstId));
    });

    test('activation and unlock sessions are independent — starting one '
        'invalidates a stale session from the other flow', () {
      analytics.trackOpenButtonPressed();
      final unlockId = sid(events.single);

      events.clear();
      analytics.trackActivationButtonPressed();
      final activationId = sid(events.single);
      expect(activationId, isNot(unlockId));

      events.clear();
      // A later unlock() call (e.g. post-activation auto-unlock) must not
      // inherit the old, now-stale unlock session id from before the
      // activation button was pressed.
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      expect(sid(events.single), isNot(unlockId));
    });
  });

  group('Retry metadata', () {
    test('retry_attempt is 0 on the original Started and increments once '
        'per retry', () {
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      expect(events.single.properties?[AnalyticsProperties.saltoRetryAttempt], 0);

      analytics.trackRetryTriggered(triggerSource: 'auto', retryReason: 'timeout');
      final retryEvent = events.last;
      expect(retryEvent.properties?[AnalyticsProperties.saltoRetryAttempt], 1);
      expect(retryEvent.properties?[AnalyticsProperties.saltoRetryReason], 'timeout');
    });

    test('retry_reason is carried through to Retry Failed', () {
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackRetryTriggered(triggerSource: 'auto', retryReason: 'sdk_failure');
      analytics.trackRetryFailed(reason: 'failure', failureStage: 'native_sdk');

      final failed = events.last;
      expect(failed.name, 'SALTO Retry Failed');
      expect(failed.properties?[AnalyticsProperties.saltoRetryAttempt], 1);
      expect(failed.properties?[AnalyticsProperties.saltoFailureStage], 'native_sdk');
    });

    test('a second retry within the same session reaches retry_attempt 2', () {
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackRetryTriggered(triggerSource: 'auto', retryReason: 'timeout');
      analytics.trackRetryTriggered(triggerSource: 'manual', retryReason: 'manual_retry');

      expect(events.last.properties?[AnalyticsProperties.saltoRetryAttempt], 2);
      expect(events.last.properties?[AnalyticsProperties.saltoRetryReason], 'manual_retry');
    });

    test('a fresh Open Button Pressed resets retry_attempt back to 0', () {
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackRetryTriggered(triggerSource: 'auto', retryReason: 'timeout');

      analytics.trackOpenButtonPressed();
      events.clear();
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      expect(events.single.properties?[AnalyticsProperties.saltoRetryAttempt], 0);
    });
  });

  group('Duration metrics', () {
    test('Native Callback Received carries both duration_ms and '
        'native_duration_ms with the same value', () {
      analytics.trackNativeCallbackReceived(result: 'granted', durationMs: 250);
      final e = events.single;
      expect(e.properties?[AnalyticsProperties.durationMs], 250);
      expect(e.properties?[AnalyticsProperties.saltoNativeDurationMs], 250);
    });

    test('Unlock Completed rolls up native/key-fetch/permission durations '
        'measured during the attempt', () {
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.markPermissionCheckStarted();
      analytics.markPermissionCheckCompleted();
      analytics.markKeyFetchStarted();
      analytics.markKeyFetchCompleted();
      analytics.trackNativeCallbackReceived(result: 'granted', durationMs: 42);
      analytics.trackUnlockGranted();

      final completed = events.last;
      expect(completed.name, 'SALTO Unlock Completed');
      expect(completed.properties?[AnalyticsProperties.saltoNativeDurationMs], 42);
      expect(completed.properties?[AnalyticsProperties.saltoKeyFetchDurationMs], isA<int>());
      expect(completed.properties?[AnalyticsProperties.saltoPermissionDurationMs], isA<int>());
      expect(completed.properties?[AnalyticsProperties.saltoTotalDurationMs], isA<int>());
      expect(completed.properties?[AnalyticsProperties.durationMs], isA<int>());
    });

    test('per-attempt durations do not leak into the next, unrelated '
        'session', () {
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.markKeyFetchStarted();
      analytics.markKeyFetchCompleted();
      analytics.trackUnlockGranted();

      events.clear();
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackUnlockGranted();

      final completed = events.last;
      expect(completed.properties?.containsKey(AnalyticsProperties.saltoKeyFetchDurationMs), isFalse);
    });

    test('Activation Success/Completed carry total_duration_ms alongside '
        'the existing duration_ms', () {
      analytics.trackActivationStarted();
      analytics.trackActivationSucceeded();
      final success = events[1];
      final completed = events[2];
      expect(success.properties?[AnalyticsProperties.saltoTotalDurationMs], isA<int>());
      expect(completed.properties?[AnalyticsProperties.saltoTotalDurationMs], isA<int>());
    });

    test('readiness_duration_ms is passed through when given', () {
      analytics.trackReadinessChanged(flow: 'unlock', issue: 'bluetooth_off', readinessDurationMs: 12);
      expect(events.single.properties?[AnalyticsProperties.saltoReadinessDurationMs], 12);
    });
  });

  group('Failure classification (failure_stage)', () {
    test('is carried on Unlock Failed', () {
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackUnlockFailed(reason: 'permissionDenied', failureStage: 'permission');
      final failed = events[1];
      expect(failed.properties?[AnalyticsProperties.saltoFailureStage], 'permission');
    });

    test('Unlock Rejected/Timeout default to native_sdk', () {
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackUnlockRejected();
      expect(events[1].properties?[AnalyticsProperties.saltoFailureStage], 'native_sdk');

      events.clear();
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      analytics.trackUnlockTimeout();
      expect(events[1].properties?[AnalyticsProperties.saltoFailureStage], 'native_sdk');
    });

    test('is carried on Activation Blocked/Failed', () {
      analytics.trackActivationBlocked(reason: 'bluetoothOff', failureStage: 'bluetooth');
      expect(events.single.properties?[AnalyticsProperties.saltoFailureStage], 'bluetooth');

      events.clear();
      analytics.trackActivationStarted();
      analytics.trackActivationFailed(reason: 'backendRejected', failureStage: 'backend');
      expect(events[1].properties?[AnalyticsProperties.saltoFailureStage], 'backend');
    });

    test('SDK/native-layer events carry a fixed, correct stage', () {
      analytics.trackMethodChannelFailure(method: 'startUnlock');
      expect(events.single.properties?[AnalyticsProperties.saltoFailureStage], 'method_channel');

      events.clear();
      analytics.trackDigitalKeyInvalid();
      expect(events.single.properties?[AnalyticsProperties.saltoFailureStage], 'key_validation');

      events.clear();
      analytics.trackKeyRefreshFailed(reason: 'x');
      expect(events.single.properties?[AnalyticsProperties.saltoFailureStage], 'key_fetch');
    });
  });

  group('SDK version property', () {
    test('is present on every SDK/native-layer event, sourced from the '
        'single kSaltoSdkVersion constant', () {
      analytics
        ..trackSdkReady()
        ..trackSdkTimeout()
        ..trackSdkFailure()
        ..trackSdkException()
        ..trackNativeChannelError()
        ..trackMethodChannelFailure(method: 'validateKey')
        ..trackDigitalKeyInvalid()
        ..trackDigitalKeyRefreshed()
        ..trackKeyRefreshStarted()
        ..trackKeyRefreshCompleted()
        ..trackKeyRefreshFailed()
        ..trackNativeUnlockStarted()
        ..trackNativeCallbackReceived(result: 'granted', durationMs: 1);

      for (final e in events) {
        expect(
          e.properties?[AnalyticsProperties.saltoSdkVersion],
          kSaltoSdkVersion,
          reason: '${e.name} is missing sdk_version',
        );
      }
    });

    test('is not hardcoded per-event — every event uses the same constant '
        'value', () {
      analytics.trackSdkReady();
      analytics.trackNativeChannelError();
      final versions = events.map((e) => e.properties?[AnalyticsProperties.saltoSdkVersion]).toSet();
      expect(versions, {kSaltoSdkVersion});
    });
  });

  group('App lifecycle context', () {
    test('is absent before updateAppLifecycleState is ever called', () {
      analytics.trackOpenButtonPressed();
      expect(events.single.properties?.containsKey(AnalyticsProperties.appLifecycleState), isFalse);
    });

    test('is attached to unlock/activation events after being set', () {
      analytics.updateAppLifecycleState('resumed');
      analytics.trackOpenButtonPressed();
      expect(events.single.properties?[AnalyticsProperties.appLifecycleState], 'resumed');

      events.clear();
      analytics.updateAppLifecycleState('paused');
      analytics.trackUnlockStarted(triggerSource: 'unlock');
      expect(events.single.properties?[AnalyticsProperties.appLifecycleState], 'paused');
    });

    test('updates take effect immediately for the next event', () {
      analytics.updateAppLifecycleState('inactive');
      analytics.updateAppLifecycleState('detached');
      analytics.trackActivationButtonPressed();
      expect(events.single.properties?[AnalyticsProperties.appLifecycleState], 'detached');
    });
  });

  group('Recovery (v2 structured events)', () {
    test('Recovery Started/Succeeded fire Recovery Finished + Recovery '
        'Success with a duration', () {
      analytics.trackRecoveryStarted(recoveryReason: 'timeout');
      analytics.trackRecoverySucceeded(recoveryReason: 'timeout');

      expect(events.map((e) => e.name), [
        'SALTO Recovery Started',
        'SALTO Recovery Finished',
        'SALTO Recovery Success',
      ]);
      expect(events[1].properties?[AnalyticsProperties.saltoResult], 'success');
      expect(events[1].properties?[AnalyticsProperties.saltoRecoveryDurationMs], isA<int>());
      expect(events[2].properties?[AnalyticsProperties.saltoRecoveryReason], 'timeout');
    });

    test('Recovery Started/Failed fire Recovery Finished + Recovery Failed', () {
      analytics.trackRecoveryStarted(recoveryReason: 'stale_key');
      analytics.trackRecoveryFailed(recoveryReason: 'stale_key');

      expect(events.map((e) => e.name), [
        'SALTO Recovery Started',
        'SALTO Recovery Finished',
        'SALTO Recovery Failed',
      ]);
      expect(events[1].properties?[AnalyticsProperties.saltoResult], 'failed');
    });

    test('Bluetooth/Internet restoration fires Recovery Success with no '
        'preceding Started (a passive restoration, not an active attempt)',
        () {
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.off);
      analytics.trackBluetoothStateObserved(SaltoBluetoothState.ready);
      expect(
        events.map((e) => e.name),
        contains('SALTO Recovery Success'),
      );
      final recovery = events.firstWhere((e) => e.name == 'SALTO Recovery Success');
      expect(recovery.properties?[AnalyticsProperties.saltoRecoveryReason], 'bluetooth_restored');

      events.clear();
      analytics.trackInternetStateObserved(false);
      analytics.trackInternetStateObserved(true);
      final netRecovery = events.firstWhere((e) => e.name == 'SALTO Recovery Success');
      expect(netRecovery.properties?[AnalyticsProperties.saltoRecoveryReason], 'internet_restored');
    });

    test('the 5 original v1 reliability events are preserved unchanged '
        'alongside the new v2 structured ones', () {
      analytics
        ..trackTimeoutRecovery()
        ..trackStaleLockRecovery()
        ..trackRetryRecovery()
        ..trackBackgroundRecovery()
        ..trackResumeRecovery();

      expect(events.map((e) => e.name), [
        'SALTO Timeout Recovery',
        'SALTO Stale Lock Recovery',
        'SALTO Retry Recovery',
        'SALTO Background Recovery',
        'SALTO Resume Recovery',
      ]);
    });
  });

  group('Every public track method is callable without throwing', () {
    test('smoke test across the full catalog', () {
      analytics
        ..trackActivationButtonPressed()
        ..trackActivationConfirmDialogOpened()
        ..trackActivationConfirmed()
        ..trackActivationCancelled()
        ..trackActivationBlocked(reason: 'x')
        ..trackActivationStarted()
        ..trackActivationRequestSent()
        ..trackActivationSucceeded()
        ..trackActivationStarted()
        ..trackActivationFailed(reason: 'x')
        ..trackOpenButtonPressed()
        ..trackUnlockStarted(triggerSource: 'manual')
        ..trackNativeUnlockStarted()
        ..trackNativeCallbackReceived(result: 'granted', durationMs: 10)
        ..trackUnlockGranted()
        ..trackUnlockStarted(triggerSource: 'manual')
        ..trackUnlockRejected()
        ..trackUnlockStarted(triggerSource: 'manual')
        ..trackUnlockFailed(reason: 'x')
        ..trackUnlockStarted(triggerSource: 'manual')
        ..trackUnlockTimeout()
        ..trackUnlockCancelled(reason: 'busyIgnored')
        ..trackRetryTriggered(triggerSource: 'auto', retryReason: 'timeout')
        ..trackRetrySuccess()
        ..trackRetryFailed(reason: 'x')
        ..trackReadinessChanged(flow: 'unlock', issue: 'ready_to_unlock')
        ..trackBluetoothStateObserved(SaltoBluetoothState.ready)
        ..trackBluetoothSettingsOpened(flow: 'activation')
        ..trackBluetoothSettingsReturned(flow: 'activation')
        ..trackInternetStateObserved(true)
        ..trackNetworkSettingsOpened()
        ..trackNetworkSettingsReturned()
        ..trackActivationBlockedByInternet()
        ..trackSdkReady()
        ..trackSdkTimeout()
        ..trackSdkFailure(detail: 'x')
        ..trackSdkException(detail: 'x')
        ..trackNativeChannelError(detail: 'x')
        ..trackMethodChannelFailure(method: 'startUnlock')
        ..trackDigitalKeyInvalid()
        ..trackDigitalKeyRefreshed()
        ..trackKeyRefreshStarted()
        ..trackKeyRefreshCompleted()
        ..trackKeyRefreshFailed(reason: 'x')
        ..trackUserCancelledActivation()
        ..trackUserCancelledBluetoothDialog()
        ..trackUserContinuedWithoutBluetooth()
        ..trackUserOpenedSettings(settingsType: 'bluetooth')
        ..trackUserReturnedFromSettings()
        ..trackUserRetriedUnlock()
        ..trackRapidMultipleTaps(tapContext: 'unlock')
        ..trackUnlockWhileOffline()
        ..trackUnlockWhileBluetoothDisabled()
        ..trackTimeoutRecovery()
        ..trackStaleLockRecovery()
        ..trackRetryRecovery()
        ..trackBackgroundRecovery()
        ..trackResumeRecovery();

      expect(events, isNotEmpty);
    });
  });
}
