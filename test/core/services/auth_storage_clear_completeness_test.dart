import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/core/services/auth_storage_service.dart';
import 'package:jaswallet_app/core/services/biometric_auth_service.dart';
import 'package:jaswallet_app/features/salto/data/repositories/access_log_repository.dart';
import 'package:jaswallet_app/features/salto/domain/access_attempt_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple in-memory [FlutterSecureStoragePlatform] fake — a working
/// map-backed store, no concurrency simulation needed for these tests.
class _InMemorySecureStoragePlatform extends FlutterSecureStoragePlatform {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async => data[key];

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    data[key] = value;
  }

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async => data.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async => data.remove(key);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async =>
      data.clear();

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async => Map.of(data);
}

/// BiometricAuthService that never calls platform channels, for use where a
/// notifier method accepts an injectable biometric service.
class _NoOpBiometricService extends BiometricAuthService {
  @override
  Future<void> clearCredentials() async {}
  @override
  Future<void> clearAll() async {}
}

const _userId = 'user-clear-completeness-1';

/// Writes one of every kind of sensitive value a real, fully-used session
/// would have persisted: tokens, PIN, biometric flags, the SALTO digital
/// key/status/device-identity UUID, an FCM token, and a SALTO access-log
/// entry for [_userId].
Future<void> _populateFullSession(AuthStorageService storage) async {
  await storage.saveSession(
    userId: _userId,
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  );
  await storage.savePinHash(hash: 'pin-hash', salt: 'pin-salt');
  await storage.setBiometricEnabled(true);
  await storage.setBiometricSetupCompleted();
  await storage.saveSaltoDigitalKey('deadbeefcafe');
  await storage.saveSaltoMobileStatus('{"mobile_access_enabled":true}');
  await storage.getOrCreateSaltoMobilePhoneId();
  await storage.setFcmToken('fcm-device-token-abc');
  await AccessLogRepository(userId: _userId).recordAccess();
  await AccessLogRepository(userId: _userId).recordAttempt(
    AccessAttemptLog(timestamp: DateTime.now(), result: 'granted', logs: const []),
  );
}

void main() {
  late _InMemorySecureStoragePlatform fakePlatform;
  late AuthStorageService storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakePlatform = _InMemorySecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = fakePlatform;
    storage = AuthStorageService();
  });

  group('AuthStorageService.clearAll() — completeness', () {
    test(
      'every secure-storage key written during a full session is gone, '
      'including the SALTO device-identity UUID, FCM token, and access log',
      () async {
        await _populateFullSession(storage);
        expect(fakePlatform.data, isNotEmpty); // sanity: something was written

        await storage.clearAll();

        expect(
          fakePlatform.data,
          isEmpty,
          reason:
              'clearAll() left secure-storage keys behind: ${fakePlatform.data.keys}',
        );
        expect(
          await AccessLogRepository(userId: _userId).getAll(),
          isEmpty,
          reason: 'clearAll() left this user\'s SALTO access log behind',
        );
        expect(
          await AccessLogRepository(userId: _userId).getAllAttempts(),
          isEmpty,
          reason: 'clearAll() left this user\'s SALTO attempt log behind',
        );
      },
    );

    test('legacy unscoped access-log keys are also cleared', () async {
      // Data written before per-user scoping existed (userId: null).
      await AccessLogRepository().recordAccess();
      await _populateFullSession(storage);

      await storage.clearAll();

      expect(await AccessLogRepository().getAll(), isEmpty);
    });
  });

  group('AuthStorageService.clearSession() — completeness', () {
    test(
      'clears tokens, SALTO key/status/device-identity, FCM token, and the '
      'access log (PIN and biometric flags are intentionally out of scope — '
      'callers clear those via clearPin()/setBiometricEnabled() separately)',
      () async {
        await _populateFullSession(storage);

        await storage.clearSession();

        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);
        expect(await storage.getUserId(), isNull);
        expect(await storage.isLoggedIn(), isFalse);
        expect(await storage.getSaltoDigitalKey(), isNull);
        expect(await storage.getSaltoMobileStatus(), isNull);
        expect(await storage.getFcmToken(), isNull);
        expect(await AccessLogRepository(userId: _userId).getAll(), isEmpty);
        expect(
          await AccessLogRepository(userId: _userId).getAllAttempts(),
          isEmpty,
        );

        // salto_mobile_phone_id has no public getter — assert via the
        // underlying store directly (it must be regenerated, not reused,
        // for the next account that logs in on this device).
        expect(fakePlatform.data.containsKey('salto_mobile_phone_id'), isFalse);
      },
    );
  });

  group('AuthNotifier.deleteAccount() — end-to-end completeness', () {
    test('secure storage is fully empty after account deletion', () async {
      final container = ProviderContainer(
        overrides: [authStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      container.read(authProvider); // construct notifier
      await Future<void>.delayed(Duration.zero);

      await _populateFullSession(storage);

      await container
          .read(authProvider.notifier)
          .deleteAccount(biometricService: _NoOpBiometricService());

      expect(
        fakePlatform.data,
        isEmpty,
        reason:
            'deleteAccount() left secure-storage keys behind: ${fakePlatform.data.keys}',
      );
      expect(await AccessLogRepository(userId: _userId).getAll(), isEmpty);
    });
  });

  group('AuthNotifier.logout() — end-to-end completeness', () {
    test(
      'secure storage is fully empty after the background cleanup finishes '
      '(default logout clears the refresh token, i.e. the "Log Out" button)',
      () async {
        final container = ProviderContainer(
          overrides: [authStorageServiceProvider.overrideWithValue(storage)],
        );
        addTearDown(container.dispose);
        container.read(authProvider);
        await Future<void>.delayed(Duration.zero);

        await _populateFullSession(storage);

        await container
            .read(authProvider.notifier)
            .logout(biometricService: _NoOpBiometricService());
        // logout() flips state synchronously and fires cleanup unawaited in
        // the background so navigation is never blocked — drain the event
        // queue so every awaited cleanup step actually runs before asserting.
        await pumpEventQueue();

        expect(
          fakePlatform.data,
          isEmpty,
          reason:
              'logout() left secure-storage keys behind: ${fakePlatform.data.keys}',
        );
        expect(await AccessLogRepository(userId: _userId).getAll(), isEmpty);
      },
    );
  });
}
