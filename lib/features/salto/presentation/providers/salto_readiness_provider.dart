import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../analytics/salto_analytics.dart';
import '../../data/repositories/salto_repository_impl.dart';
import '../../data/salto_platform_channel.dart';
import 'salto_provider.dart';

/// Whether SALTO native SDK is available (Android/iOS only).
bool get _isPlatformSupported => Platform.isAndroid || Platform.isIOS;

/// Specific reason the Open button is not (yet) actionable.
enum SaltoReadinessIssue {
  none,
  unsupportedPlatform,
  unlockInProgress,
  bluetoothOff,
  bluetoothNotReady,
  bluetoothUnauthorized,
  bluetoothUnsupported,
  permissionDenied,
  locationOff,
  internetUnavailable,
}

/// Maps each unlock-flow readiness issue to the snake_case tag used for the
/// `SALTO Ready State Changed` Mixpanel event's `readiness_issue` property —
/// see [SaltoAnalytics.trackReadinessChanged].
extension SaltoReadinessIssueAnalytics on SaltoReadinessIssue {
  String get analyticsTag => switch (this) {
        SaltoReadinessIssue.none => 'ready_to_unlock',
        SaltoReadinessIssue.unsupportedPlatform => 'unsupported_platform',
        SaltoReadinessIssue.unlockInProgress => 'waiting_for_sdk',
        SaltoReadinessIssue.bluetoothOff => 'bluetooth_off',
        SaltoReadinessIssue.bluetoothNotReady => 'bluetooth_turning_on',
        SaltoReadinessIssue.bluetoothUnauthorized => 'bluetooth_unauthorized',
        SaltoReadinessIssue.bluetoothUnsupported => 'bluetooth_unsupported',
        SaltoReadinessIssue.permissionDenied => 'bluetooth_permission_denied',
        SaltoReadinessIssue.locationOff => 'location_off',
        SaltoReadinessIssue.internetUnavailable => 'internet_offline',
      };
}

/// Single source of truth for "is SALTO actually ready to attempt an
/// unlock right now" — the model requested by the reliability
/// investigation to close the gap where the UI's notion of readiness could
/// silently diverge from [SaltoUnlockNotifier]'s actual state.
///
/// This is a *passive, read-only* signal: evaluating it never requests a
/// permission and never triggers a BLE scan. It exists to explain and gate
/// the Open button proactively; the actual unlock flow
/// ([SaltoUnlockNotifier.unlock]) always re-validates everything itself
/// before attempting a native call, so correctness never depends on this
/// indicator being perfectly up to date — it is a UX layer on top of an
/// independently-correct enforcement layer, not a replacement for it.
class SaltoReadinessState {
  const SaltoReadinessState({required this.isReady, this.issue = SaltoReadinessIssue.none});

  final bool isReady;
  final SaltoReadinessIssue issue;

  static const initial = SaltoReadinessState(isReady: false);
  static const ready = SaltoReadinessState(isReady: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaltoReadinessState && other.isReady == isReady && other.issue == issue);

  @override
  int get hashCode => Object.hash(isReady, issue);

  @override
  String toString() => 'SaltoReadinessState(isReady: $isReady, issue: $issue)';
}

class SaltoReadinessNotifier extends StateNotifier<SaltoReadinessState> {
  SaltoReadinessNotifier({required SaltoRepositoryImpl repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(SaltoReadinessState.initial) {
    // Re-evaluate immediately whenever the unlock notifier's own state
    // changes. This is what keeps this provider from ever diverging from
    // the notifier's actual truth — in particular, `isUnlocking` is
    // otherwise invisible outside the notifier, and both change together.
    _unlockSub = _ref.listen<SaltoUnlockState>(
      saltoUnlockProvider,
      (_, _) => unawaited(refresh()),
      fireImmediately: false,
    );
    unawaited(refresh());
  }

  final SaltoRepositoryImpl _repository;
  final Ref _ref;
  bool _isRefreshing = false;
  late final ProviderSubscription<SaltoUnlockState> _unlockSub;

  @override
  void dispose() {
    _unlockSub.close();
    super.dispose();
  }

  /// Re-evaluates readiness now. Safe to call frequently (e.g. from a
  /// foreground poll or an app-resume hook) — overlapping calls are
  /// coalesced rather than duplicated.
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final stopwatch = Stopwatch()..start();
      final next = await _evaluate();
      stopwatch.stop();
      if (next.issue != state.issue) {
        SaltoAnalytics.instance.trackReadinessChanged(
          flow: 'unlock',
          issue: next.issue.analyticsTag,
          readinessDurationMs: stopwatch.elapsedMilliseconds,
        );
      }
      if (mounted) state = next;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<SaltoReadinessState> _evaluate() async {
    if (!_isPlatformSupported) {
      return const SaltoReadinessState(
        isReady: false,
        issue: SaltoReadinessIssue.unsupportedPlatform,
      );
    }

    // Single source of truth for "is an attempt in flight" — reads the
    // same flag SaltoUnlockNotifier itself acts on, so this can never say
    // "ready" while the notifier is mid-attempt.
    final unlockNotifier = _ref.read(saltoUnlockProvider.notifier);
    if (unlockNotifier.isUnlocking) {
      return const SaltoReadinessState(
        isReady: false,
        issue: SaltoReadinessIssue.unlockInProgress,
      );
    }

    final sdkInt =
        Platform.isAndroid ? await SaltoPlatformChannel.androidSdkInt() : 0;
    final needsLocation = Platform.isAndroid && sdkInt <= 30;

    // Status-only permission check — never prompts. Prompting belongs
    // exclusively to the actual unlock flow (a deliberate user tap); a
    // background readiness poll must never surface an OS permission dialog
    // on its own.
    final hasPermissions = await _hasBlePermissions(needsLocation: needsLocation);
    if (!hasPermissions) {
      return const SaltoReadinessState(
        isReady: false,
        issue: SaltoReadinessIssue.permissionDenied,
      );
    }

    if (needsLocation) {
      final locService = await Permission.locationWhenInUse.serviceStatus;
      if (locService != ServiceStatus.enabled) {
        return const SaltoReadinessState(
          isReady: false,
          issue: SaltoReadinessIssue.locationOff,
        );
      }
    }

    final bluetoothState = await SaltoPlatformChannel.bluetoothState();
    SaltoAnalytics.instance.trackBluetoothStateObserved(bluetoothState);
    if (bluetoothState != SaltoBluetoothState.ready) {
      final issue = switch (bluetoothState) {
        SaltoBluetoothState.off => SaltoReadinessIssue.bluetoothOff,
        SaltoBluetoothState.unauthorized => SaltoReadinessIssue.bluetoothUnauthorized,
        SaltoBluetoothState.unsupported => SaltoReadinessIssue.bluetoothUnsupported,
        // turningOn / turningOff / resetting / unknown.
        _ => SaltoReadinessIssue.bluetoothNotReady,
      };
      return SaltoReadinessState(isReady: false, issue: issue);
    }

    // Internet is only a hard requirement when there is no usable cached
    // key — the whole point of the 7-day/10-minute key cache is that
    // unlock keeps working fully offline once a key exists. This call
    // reuses the repository's existing in-memory/persistent cache and
    // in-flight de-dup, so polling this frequently adds no extra network
    // traffic in the common case.
    final hasKey = await _hasUsableKey();
    if (!hasKey) {
      final online = await ConnectivityService.isConnected();
      SaltoAnalytics.instance.trackInternetStateObserved(online);
      if (!online) {
        return const SaltoReadinessState(
          isReady: false,
          issue: SaltoReadinessIssue.internetUnavailable,
        );
      }
    }

    return SaltoReadinessState.ready;
  }

  Future<bool> _hasBlePermissions({required bool needsLocation}) async {
    if (Platform.isIOS) {
      final status = await Permission.bluetooth.status;
      return status.isGranted || status.isLimited;
    }

    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.status;
      final connect = await Permission.bluetoothConnect.status;
      var granted =
          (scan.isGranted || scan.isLimited) && (connect.isGranted || connect.isLimited);
      if (needsLocation) {
        final location = await Permission.locationWhenInUse.status;
        granted = granted && (location.isGranted || location.isLimited);
      }
      return granted;
    }

    return true;
  }

  Future<bool> _hasUsableKey() async {
    try {
      final key = await _repository.getDigitalKey(forceRefresh: false);
      return key != null && key.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

final saltoReadinessProvider =
    StateNotifierProvider<SaltoReadinessNotifier, SaltoReadinessState>((ref) {
  return SaltoReadinessNotifier(
    repository: ref.watch(saltoRepositoryProvider),
    ref: ref,
  );
});
