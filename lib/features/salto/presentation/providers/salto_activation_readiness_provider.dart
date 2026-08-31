import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../analytics/salto_analytics.dart';
import '../../data/salto_platform_channel.dart';
import 'salto_activation_provider.dart';
import 'salto_provider.dart';

/// Specific, ambient reason activation isn't fully ready yet — driven
/// entirely by conditions the user can act on or that resolve themselves,
/// never a generic "not ready" state.
///
/// Unlike [SaltoReadinessIssue] (built for gating the *unlock* button),
/// none of these ever disable the activation button — per design, the
/// button always stays tappable and tapping while an issue is present
/// surfaces the specific explanation via a dialog
/// ([SaltoActivationPrerequisites]) rather than doing nothing. This state
/// exists purely to show ambient, Apple-Wallet/Revolut-style status text
/// ("Preparing your device...", "Ready to activate") *before* the user has
/// even tapped.
enum SaltoActivationReadinessIssue {
  none,
  notAuthenticated,
  checkingStatus,
  preparingDevice,
  internetUnavailable,
  bluetoothOff,
  bluetoothNotReady,
  bluetoothUnauthorized,
  bluetoothUnsupported,
  alreadyActivating,
}

/// Maps each activation-flow readiness issue to the snake_case tag used for
/// the `SALTO Ready State Changed` Mixpanel event's `readiness_issue`
/// property — see [SaltoAnalytics.trackReadinessChanged].
extension SaltoActivationReadinessIssueAnalytics on SaltoActivationReadinessIssue {
  String get analyticsTag => switch (this) {
        SaltoActivationReadinessIssue.none => 'ready',
        SaltoActivationReadinessIssue.notAuthenticated => 'not_authenticated',
        SaltoActivationReadinessIssue.checkingStatus => 'checking_status',
        SaltoActivationReadinessIssue.preparingDevice => 'preparing_device',
        SaltoActivationReadinessIssue.internetUnavailable => 'internet_offline',
        SaltoActivationReadinessIssue.bluetoothOff => 'bluetooth_off',
        SaltoActivationReadinessIssue.bluetoothNotReady => 'bluetooth_turning_on',
        SaltoActivationReadinessIssue.bluetoothUnauthorized => 'bluetooth_unauthorized',
        SaltoActivationReadinessIssue.bluetoothUnsupported => 'bluetooth_unsupported',
        SaltoActivationReadinessIssue.alreadyActivating => 'waiting_for_sdk',
      };
}

class SaltoActivationReadinessState {
  const SaltoActivationReadinessState({required this.isReady, this.issue = SaltoActivationReadinessIssue.none});

  final bool isReady;
  final SaltoActivationReadinessIssue issue;

  static const initial = SaltoActivationReadinessState(isReady: false);
  static const ready = SaltoActivationReadinessState(isReady: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaltoActivationReadinessState && other.isReady == isReady && other.issue == issue);

  @override
  int get hashCode => Object.hash(isReady, issue);

  @override
  String toString() => 'SaltoActivationReadinessState(isReady: $isReady, issue: $issue)';
}

/// Computes the ambient "is activation ready right now" signal shown on
/// both activation entry points (the dedicated login-flow page and the
/// Access page's reactivation prompt) — purely informational, read-only,
/// never prompts a permission dialog or triggers a BLE scan on its own.
///
/// Reactively re-evaluates whenever [saltoActivationProvider]'s state
/// changes (so "alreadyActivating" always reflects the real, current lock)
/// and whenever [refresh] is called explicitly — the calling page is
/// responsible for calling that on a foreground poll and on app resume,
/// mirroring the pattern already established for the unlock flow's
/// `SaltoReadinessNotifier`.
class SaltoActivationReadinessNotifier extends StateNotifier<SaltoActivationReadinessState> {
  SaltoActivationReadinessNotifier({
    required Ref ref,
    Future<bool> Function()? isConnected,
  })  : _ref = ref,
        _isConnected = isConnected ?? ConnectivityService.isConnected,
        super(SaltoActivationReadinessState.initial) {
    _activationSub = _ref.listen<SaltoActivationState>(
      saltoActivationProvider,
      (_, _) => unawaited(refresh()),
    );
    unawaited(_prewarmPhoneId());
    unawaited(refresh());
  }

  final Ref _ref;
  final Future<bool> Function() _isConnected;
  late final ProviderSubscription<SaltoActivationState> _activationSub;

  bool _isRefreshing = false;
  bool _phoneIdReady = false;

  /// Short-lived cache for the connectivity probe. Unlike the unlock flow's
  /// [SaltoReadinessNotifier] (which only checks connectivity when no
  /// usable key already makes it moot), activation always needs the
  /// network, so the check itself can't be skipped — but the 3-second
  /// foreground poll driving [refresh] doesn't need a brand new DNS lookup
  /// on every single tick. Caching it for a few ticks cuts real network
  /// probes by roughly 80% while a page with this provider stays open,
  /// without meaningfully delaying detection of a real connectivity change.
  bool? _cachedOnline;
  DateTime? _cachedOnlineAt;
  static const _connectivityCacheTtl = Duration(seconds: 15);

  Future<bool> _isConnectedCached() async {
    final cachedAt = _cachedOnlineAt;
    if (cachedAt != null && DateTime.now().difference(cachedAt) < _connectivityCacheTtl) {
      return _cachedOnline!;
    }
    final online = await _isConnected();
    _cachedOnline = online;
    _cachedOnlineAt = DateTime.now();
    return online;
  }

  @override
  void dispose() {
    _activationSub.close();
    super.dispose();
  }

  /// Warms the mobile_phone_id once, up front, so "Preparing your device..."
  /// reflects a real, observable condition (the one first-run race this
  /// whole activation-reliability effort exists to close — see
  /// AuthStorageService.getOrCreateSaltoMobilePhoneId) rather than an
  /// arbitrary delay. Safe to call even if the id is already cached — the
  /// underlying call is a fast no-op in that case.
  Future<void> _prewarmPhoneId() async {
    try {
      await _ref.read(authStorageServiceProvider).getOrCreateSaltoMobilePhoneId();
    } catch (_) {
      // Best-effort — activate() will surface any real failure itself.
    } finally {
      _phoneIdReady = true;
      unawaited(refresh());
    }
  }

  /// Re-evaluates readiness now. Safe to call frequently (foreground poll,
  /// app resume) — overlapping calls are coalesced, never duplicated.
  Future<void> refresh() async {
    if (_isRefreshing || !mounted) return;
    _isRefreshing = true;
    try {
      final stopwatch = Stopwatch()..start();
      final next = await _evaluate();
      stopwatch.stop();
      if (next.issue != state.issue) {
        SaltoAnalytics.instance.trackReadinessChanged(
          flow: 'activation',
          issue: next.issue.analyticsTag,
          readinessDurationMs: stopwatch.elapsedMilliseconds,
        );
      }
      if (mounted) state = next;
    } catch (_) {
      // The container may have been disposed mid-flight — e.g. the
      // deferred refresh() inside _prewarmPhoneId's `finally` firing after
      // this notifier (or the whole ProviderContainer) is already gone.
      // Nothing to recover; stop quietly, the same tolerance
      // _SaltoStatusNotifier already applies to a disposed notifier.
    } finally {
      _isRefreshing = false;
    }
  }

  Future<SaltoActivationReadinessState> _evaluate() async {
    if (_ref.read(saltoActivationProvider.notifier).isActivating) {
      return const SaltoActivationReadinessState(
        isReady: false,
        issue: SaltoActivationReadinessIssue.alreadyActivating,
      );
    }

    // A stored access token is what actually matters for the backend call
    // to succeed — both activation entry points are only ever reached
    // after a successful login, so this is a defensive check rather than
    // one expected to fire in practice.
    final token = await _ref.read(authStorageServiceProvider).getAccessToken();
    if (token == null || token.trim().isEmpty) {
      return const SaltoActivationReadinessState(
        isReady: false,
        issue: SaltoActivationReadinessIssue.notAuthenticated,
      );
    }

    final statusAsync = _ref.read(saltoStatusProvider);
    if (statusAsync.isLoading && statusAsync.valueOrNull == null) {
      return const SaltoActivationReadinessState(
        isReady: false,
        issue: SaltoActivationReadinessIssue.checkingStatus,
      );
    }

    if (!_phoneIdReady) {
      return const SaltoActivationReadinessState(
        isReady: false,
        issue: SaltoActivationReadinessIssue.preparingDevice,
      );
    }

    final online = await _isConnectedCached();
    SaltoAnalytics.instance.trackInternetStateObserved(online);
    if (!online) {
      return const SaltoActivationReadinessState(
        isReady: false,
        issue: SaltoActivationReadinessIssue.internetUnavailable,
      );
    }

    final bluetoothState = await SaltoPlatformChannel.bluetoothState();
    SaltoAnalytics.instance.trackBluetoothStateObserved(bluetoothState);
    if (bluetoothState != SaltoBluetoothState.ready) {
      final issue = switch (bluetoothState) {
        SaltoBluetoothState.off => SaltoActivationReadinessIssue.bluetoothOff,
        SaltoBluetoothState.unauthorized => SaltoActivationReadinessIssue.bluetoothUnauthorized,
        SaltoBluetoothState.unsupported => SaltoActivationReadinessIssue.bluetoothUnsupported,
        // turningOn / turningOff / resetting / unknown.
        _ => SaltoActivationReadinessIssue.bluetoothNotReady,
      };
      return SaltoActivationReadinessState(isReady: false, issue: issue);
    }

    return SaltoActivationReadinessState.ready;
  }
}

final saltoActivationReadinessProvider =
    StateNotifierProvider<SaltoActivationReadinessNotifier, SaltoActivationReadinessState>((ref) {
  return SaltoActivationReadinessNotifier(ref: ref);
});
