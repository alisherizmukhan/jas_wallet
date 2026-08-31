import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/salto_unlock_result.dart';

/// Result from native unlock including diagnostic detail.
class SaltoNativeResult {
  const SaltoNativeResult(this.result, this.detail);
  final SaltoUnlockResult result;
  final String detail;
}

/// Cross-platform Bluetooth adapter/manager readiness, normalized from
/// Android's `BluetoothAdapter` states and iOS's `CBManagerState`.
///
/// [ready] is the only state in which a native `startUnlock` call is worth
/// attempting — every other value should be surfaced to the user as a
/// specific, actionable reason rather than a generic failure.
enum SaltoBluetoothState {
  ready,
  off,
  turningOn,
  turningOff,
  unauthorized,
  unsupported,
  resetting,
  unknown,
}

/// Platform channel bridge to native SALTO JustIN Mobile SDK.
/// Android: SaltoPlugin.kt, iOS: SaltoHandler.swift
class SaltoPlatformChannel {
  SaltoPlatformChannel._();

  static const _channel = MethodChannel('com.jasaim/salto');

  /// How long to wait for the native SDK to resolve a single `startUnlock`
  /// attempt before giving up client-side.
  ///
  /// The SALTO SDK has its own internal BLE scan/connect timeout (surfaced
  /// as `errorCode 410` → [SaltoUnlockResult.timeout]), but nothing
  /// previously bounded the Dart-side await if that internal timeout ever
  /// failed to fire (SDK bug, BLE stack fault, OS suspending the scan mid
  /// flight). This is the safety net that guarantees `startUnlock` always
  /// resolves, which in turn guarantees the caller's `finally` block runs
  /// and any "unlock in progress" lock is always released.
  ///
  /// Mutable (not `const`) so tests can shorten it instead of waiting out a
  /// real 25-second window, and so this can be tuned in the field without a
  /// broader refactor.
  static Duration unlockTimeout = const Duration(seconds: 25);

  /// Android API level, cached in-memory after the first successful read —
  /// `Build.VERSION.SDK_INT` cannot change during the process lifetime, so
  /// there is no reason to repeat the native round trip on every unlock
  /// attempt. Returns 0 on other platforms or if the native side is
  /// unavailable (never cached in that case, so a transient failure can't
  /// permanently poison the value).
  static int? _cachedAndroidSdkInt;

  /// Start BLE unlock with the given digital key hex.
  ///
  /// Always resolves within [unlockTimeout] plus a small platform-channel
  /// overhead — never hangs indefinitely, even if the native SDK never
  /// invokes a terminal callback. Returns result with diagnostic detail
  /// from the native SDK.
  static Future<SaltoNativeResult> startUnlock(String digitalKeyHex) async {
    try {
      final raw = await _channel
          .invokeMethod('startUnlock', {'digitalKeyHex': digitalKeyHex})
          .timeout(unlockTimeout);

      // New format: native returns Map with "status" and "detail"
      if (raw is Map) {
        final status = raw['status'] as String?;
        final detail = raw['detail'] as String? ?? '';
        return SaltoNativeResult(_parseResult(status), detail);
      }

      // Legacy fallback: plain string
      if (raw is String) {
        return SaltoNativeResult(_parseResult(raw), '');
      }

      return const SaltoNativeResult(SaltoUnlockResult.failure, 'unknown response type');
    } on TimeoutException {
      return SaltoNativeResult(
        SaltoUnlockResult.timeout,
        'client-side timeout after ${unlockTimeout.inSeconds}s — native SDK never returned a result',
      );
    } on PlatformException catch (e) {
      return SaltoNativeResult(
        _errorToResult(e),
        'PlatformException: ${e.code} ${e.message ?? ""}',
      );
    } on MissingPluginException {
      return const SaltoNativeResult(
        SaltoUnlockResult.failure,
        'MissingPluginException: native SALTO bridge is unavailable',
      );
    }
  }

  /// Android API level (Build.VERSION.SDK_INT). Returns 0 on other platforms
  /// or if the native side is unavailable.
  ///
  /// Used to gate BLE runtime permissions: Android 12 (API 31+) scans with
  /// BLUETOOTH_SCAN + `neverForLocation` and does NOT need location, whereas
  /// Android 11 and below require ACCESS_FINE_LOCATION for BLE scanning.
  static Future<int> androidSdkInt() async {
    final cached = _cachedAndroidSdkInt;
    if (cached != null) return cached;

    try {
      final sdkInt = await _channel.invokeMethod<int>('getSdkInt');
      final value = sdkInt ?? 0;
      if (value > 0) _cachedAndroidSdkInt = value;
      return value;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }

  /// Validate key format (optional pre-check).
  static Future<bool> validateKey(String digitalKeyHex) async {
    try {
      final valid = await _channel.invokeMethod<bool>(
        'validateKey',
        {'digitalKeyHex': digitalKeyHex},
      );
      return valid ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static SaltoBluetoothState? _cachedBluetoothState;
  static DateTime? _cachedBluetoothStateAt;

  /// How long a read is reused before the next call reaches the native
  /// channel again. Short enough that a real Bluetooth state change is
  /// still reflected within one poll tick, long enough that the two
  /// independent readiness notifiers driven by the same foreground poll
  /// (unlock + activation) share one native round trip per tick instead of
  /// two.
  static const _bluetoothStateCacheTtl = Duration(seconds: 1, milliseconds: 500);

  /// Current Bluetooth adapter/manager state, normalized across platforms.
  ///
  /// Read-only — never prompts the user and never triggers a scan. Safe to
  /// poll frequently (e.g. from a readiness indicator) since it is a cheap,
  /// synchronous native property read on both platforms, and results are
  /// briefly cached (see [_bluetoothStateCacheTtl]) so back-to-back callers
  /// don't each pay for their own native round trip.
  static Future<SaltoBluetoothState> bluetoothState() async {
    final cachedAt = _cachedBluetoothStateAt;
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt) < _bluetoothStateCacheTtl) {
      return _cachedBluetoothState!;
    }

    final state = await _fetchBluetoothState();
    _cachedBluetoothState = state;
    _cachedBluetoothStateAt = DateTime.now();
    return state;
  }

  static Future<SaltoBluetoothState> _fetchBluetoothState() async {
    try {
      final raw = await _channel.invokeMethod<int>('getBluetoothState');
      if (raw == null) return SaltoBluetoothState.unknown;
      if (Platform.isAndroid) return _androidBluetoothState(raw);
      if (Platform.isIOS) return _iosBluetoothState(raw);
      return SaltoBluetoothState.unknown;
    } on PlatformException {
      return SaltoBluetoothState.unknown;
    } on MissingPluginException {
      return SaltoBluetoothState.unknown;
    }
  }

  /// Maps `BluetoothAdapter.STATE_*` (Android) to [SaltoBluetoothState].
  /// -1 = no adapter present (unsupported hardware); -3 = BLUETOOTH_CONNECT
  /// permission missing (SecurityException reading adapter state).
  static SaltoBluetoothState _androidBluetoothState(int raw) {
    switch (raw) {
      case 10:
        return SaltoBluetoothState.off; // BluetoothAdapter.STATE_OFF
      case 11:
        return SaltoBluetoothState.turningOn; // STATE_TURNING_ON
      case 12:
        return SaltoBluetoothState.ready; // STATE_ON
      case 13:
        return SaltoBluetoothState.turningOff; // STATE_TURNING_OFF
      case -1:
        return SaltoBluetoothState.unsupported;
      case -3:
        return SaltoBluetoothState.unauthorized;
      default:
        return SaltoBluetoothState.unknown;
    }
  }

  /// Maps `CBManagerState` raw values (iOS) to [SaltoBluetoothState].
  static SaltoBluetoothState _iosBluetoothState(int raw) {
    switch (raw) {
      case 0:
        return SaltoBluetoothState.unknown; // .unknown
      case 1:
        return SaltoBluetoothState.resetting; // .resetting
      case 2:
        return SaltoBluetoothState.unsupported; // .unsupported
      case 3:
        return SaltoBluetoothState.unauthorized; // .unauthorized
      case 4:
        return SaltoBluetoothState.off; // .poweredOff
      case 5:
        return SaltoBluetoothState.ready; // .poweredOn
      default:
        return SaltoBluetoothState.unknown;
    }
  }

  static SaltoUnlockResult _parseResult(String? result) {
    switch (result) {
      case 'granted':
        return SaltoUnlockResult.granted;
      case 'rejected':
        return SaltoUnlockResult.rejected;
      case 'timeout':
        return SaltoUnlockResult.timeout;
      case 'noKey':
        return SaltoUnlockResult.noKey;
      default:
        return SaltoUnlockResult.failure;
    }
  }

  static SaltoUnlockResult _errorToResult(PlatformException e) {
    final code = e.code.toLowerCase();
    if (code.contains('timeout')) return SaltoUnlockResult.timeout;
    if (code.contains('key') || code.contains('402')) return SaltoUnlockResult.noKey;
    return SaltoUnlockResult.failure;
  }
}
