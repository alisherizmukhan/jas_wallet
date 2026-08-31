import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/salto/data/salto_platform_channel.dart';
import 'package:jaswallet_app/features/salto/domain/salto_unlock_result.dart';

const _channel = MethodChannel('com.jasaim/salto');

void _setHandler(Future<Object?> Function(MethodCall call)? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // Restore defaults so state never leaks between tests in this file.
    SaltoPlatformChannel.unlockTimeout = const Duration(seconds: 25);
    _setHandler(null);
  });

  group('SaltoPlatformChannel.startUnlock — client-side timeout', () {
    test('resolves with SaltoUnlockResult.timeout if native never responds', () async {
      SaltoPlatformChannel.unlockTimeout = const Duration(milliseconds: 50);
      _setHandler((call) async {
        // Simulate a hung native SDK: never complete within the timeout.
        await Future<void>.delayed(const Duration(seconds: 5));
        return {'status': 'granted', 'detail': 'too-late'};
      });

      final stopwatch = Stopwatch()..start();
      final result = await SaltoPlatformChannel.startUnlock('deadbeef');
      stopwatch.stop();

      expect(result.result, SaltoUnlockResult.timeout);
      expect(result.detail, contains('client-side timeout'));
      // Resolved close to the configured timeout, not the 5s native delay —
      // this is the guarantee that makes _isUnlocking always release.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('resolves normally well within the timeout when native responds promptly',
        () async {
      SaltoPlatformChannel.unlockTimeout = const Duration(seconds: 25);
      _setHandler((call) async {
        return {'status': 'granted', 'detail': 'ok'};
      });

      final result = await SaltoPlatformChannel.startUnlock('deadbeef');

      expect(result.result, SaltoUnlockResult.granted);
    });

    test('maps a legacy plain-string response the same as before', () async {
      _setHandler((call) async => 'rejected');

      final result = await SaltoPlatformChannel.startUnlock('deadbeef');

      expect(result.result, SaltoUnlockResult.rejected);
    });

    test('MissingPluginException (no handler registered) yields a clear failure',
        () async {
      _setHandler(null);

      final result = await SaltoPlatformChannel.startUnlock('deadbeef');

      expect(result.result, SaltoUnlockResult.failure);
      expect(result.detail, contains('MissingPluginException'));
    });
  });

  group('SaltoPlatformChannel.androidSdkInt — caching', () {
    test('caches the result after the first successful call', () async {
      var callCount = 0;
      _setHandler((call) async {
        if (call.method == 'getSdkInt') {
          callCount++;
          return 33;
        }
        return null;
      });

      final first = await SaltoPlatformChannel.androidSdkInt();
      final second = await SaltoPlatformChannel.androidSdkInt();

      expect(first, 33);
      expect(second, 33);
      expect(callCount, 1, reason: 'second call must be served from cache, not the channel');
    });
  });

  group('SaltoPlatformChannel.bluetoothState — non-mobile platform', () {
    test('returns SaltoBluetoothState.unknown when platform is neither Android nor iOS',
        () async {
      // This test host is neither Android nor iOS, so bluetoothState() can
      // never reach the platform-specific mapping branches — mirrors the
      // same "non-mobile platform" constraint the rest of this feature's
      // test suite already works within.
      _setHandler((call) async => 5);

      final state = await SaltoPlatformChannel.bluetoothState();

      expect(state, SaltoBluetoothState.unknown);
    });

    test('returns unknown when no native handler is registered', () async {
      _setHandler(null);

      final state = await SaltoPlatformChannel.bluetoothState();

      expect(state, SaltoBluetoothState.unknown);
    });
  });

  group('SaltoBluetoothState enum coverage', () {
    test('all 8 states are defined', () {
      expect(SaltoBluetoothState.values.length, 8);
      expect(SaltoBluetoothState.values, containsAll([
        SaltoBluetoothState.ready,
        SaltoBluetoothState.off,
        SaltoBluetoothState.turningOn,
        SaltoBluetoothState.turningOff,
        SaltoBluetoothState.unauthorized,
        SaltoBluetoothState.unsupported,
        SaltoBluetoothState.resetting,
        SaltoBluetoothState.unknown,
      ]));
    });
  });
}
