import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/api/api_client.dart';
import 'package:jaswallet_app/features/salto/data/models/salto_mobile_status.dart';
import 'package:jaswallet_app/features/salto/data/repositories/salto_repository_impl.dart';
import 'package:jaswallet_app/features/salto/domain/salto_unlock_result.dart';
import 'package:jaswallet_app/features/salto/data/repositories/access_log_repository.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/access_stats_provider.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/salto_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_storage.dart';

// ── Stub repository ──────────────────────────────────────────────────────────

/// Extends SaltoRepositoryImpl so it satisfies the provider's type constraint
/// while never making real network calls.
class _StubSaltoRepositoryImpl extends SaltoRepositoryImpl {
  _StubSaltoRepositoryImpl()
      : super(
          apiClient: ApiClient(
            authStorage: FakeAuthStorageService(),
            dio: Dio(),
          ),
          authStorage: FakeAuthStorageService(),
        );

  @override
  Future<SaltoMobileStatus> getMobileStatus({CancelToken? cancelToken}) async => _fakeStatus;

  @override
  Future<SaltoMobileStatus?> getCachedMobileStatus() async => null;

  @override
  Future<SaltoMobileStatus> activateMobileAccess() async => _fakeStatus;

  @override
  Future<String?> getDigitalKey({bool forceRefresh = false}) async => null;
}

const _fakeStatus = SaltoMobileStatus(
  linked: true,
  saltoVerified: true,
  mobileAccessEnabled: true,
  activationRequired: false,
  hasCachedKey: true,
);

// ── Test helpers ─────────────────────────────────────────────────────────────

ProviderContainer _makeContainer() {
  return ProviderContainer(
    overrides: [
      saltoRepositoryProvider.overrideWithValue(_StubSaltoRepositoryImpl()),
      accessLogRepositoryProvider.overrideWithValue(AccessLogRepository()),
    ],
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SaltoUnlockNotifier — initial state', () {
    test('starts in idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(container.read(saltoUnlockProvider), SaltoUnlockState.idle);
    });
  });

  group('SaltoUnlockNotifier.reset()', () {
    test('transitions from error back to idle', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      // unlock() on non-mobile platform always fails → error
      await container.read(saltoUnlockProvider.notifier).unlock();
      expect(container.read(saltoUnlockProvider), SaltoUnlockState.error);

      container.read(saltoUnlockProvider.notifier).reset();
      expect(container.read(saltoUnlockProvider), SaltoUnlockState.idle);
    });

    test('reset() on an already-idle notifier stays idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(saltoUnlockProvider.notifier).reset();
      expect(container.read(saltoUnlockProvider), SaltoUnlockState.idle);
    });

    test('reset() after multiple unlock attempts always returns to idle', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(saltoUnlockProvider.notifier);

      await notifier.unlock();
      notifier.reset();
      await notifier.unlock();
      notifier.reset();

      expect(container.read(saltoUnlockProvider), SaltoUnlockState.idle);
    });
  });

  group('SaltoUnlockNotifier.unlock() on non-mobile platform', () {
    test('returns SaltoUnlockResult.failure', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(saltoUnlockProvider.notifier).unlock();
      expect(result, SaltoUnlockResult.failure);
    });

    test('sets state to error', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(saltoUnlockProvider.notifier).unlock();
      expect(container.read(saltoUnlockProvider), SaltoUnlockState.error);
    });

    test('second call while first completed returns failure again', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(saltoUnlockProvider.notifier);

      final r1 = await notifier.unlock();
      notifier.reset();
      final r2 = await notifier.unlock();

      expect(r1, SaltoUnlockResult.failure);
      expect(r2, SaltoUnlockResult.failure);
    });

    test('does not throw', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(saltoUnlockProvider.notifier).unlock(),
        completion(isA<SaltoUnlockResult>()),
      );
    });
  });

  group('SaltoUnlockNotifier — isUnlocking / lastFailureReason', () {
    test('isUnlocking is false before and after a completed attempt', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(saltoUnlockProvider.notifier);

      expect(notifier.isUnlocking, isFalse);
      await notifier.unlock();
      expect(notifier.isUnlocking, isFalse);
    });

    test('lastFailureReason is sdkUnavailable after an unsupported-platform failure',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(saltoUnlockProvider.notifier);

      await notifier.unlock();

      expect(notifier.lastFailureReason, SaltoFailureReason.sdkUnavailable);
    });

    test('reset() clears lastFailureReason back to none', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(saltoUnlockProvider.notifier);

      await notifier.unlock();
      expect(notifier.lastFailureReason, isNot(SaltoFailureReason.none));

      notifier.reset();

      expect(notifier.lastFailureReason, SaltoFailureReason.none);
    });

    test('refreshAndRetry() on an unsupported platform completes safely '
        'without ever touching the repository', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(saltoUnlockProvider.notifier);

      // Must not throw and must not hang — the platform-support check now
      // happens before any repository/key-refresh work, so this never
      // reaches _StubSaltoRepositoryImpl.getDigitalKey at all.
      await expectLater(notifier.refreshAndRetry(), completes);
      expect(container.read(saltoUnlockProvider), SaltoUnlockState.error);
      expect(notifier.lastFailureReason, SaltoFailureReason.sdkUnavailable);
    });
  });

  group('SaltoUnlockNotifier — repeated calls never corrupt state', () {
    // NOTE: on this (unsupported) test platform, unlock() completes
    // synchronously with no `await` reached, so calling it twice back to
    // back cannot reproduce true lock contention (the first call's lock
    // acquire+release both finish before the second call is even
    // invoked) — that specific race requires the Android/iOS-only code
    // path, which this test host cannot exercise (a pre-existing
    // constraint of this suite, see salto_unlock_notifier_test.dart's
    // "non-mobile platform" tests above). What this DOES verify: calling
    // unlock() repeatedly is always safe, deterministic, and leaves the
    // lock released — the busy-guard itself is exercised at the platform
    // channel/native level, not reproducible here.
    test('back-to-back unlock() calls both resolve safely and release the lock',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(saltoUnlockProvider.notifier);

      final results = await Future.wait([notifier.unlock(), notifier.unlock()]);

      expect(results, everyElement(SaltoUnlockResult.failure));
      expect(notifier.isUnlocking, isFalse);
    });
  });

  group('SaltoFailureReason enum coverage', () {
    test('all 14 reasons are defined', () {
      expect(SaltoFailureReason.values.length, 14);
    });

    test('none is the default before any attempt', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(
        container.read(saltoUnlockProvider.notifier).lastFailureReason,
        SaltoFailureReason.none,
      );
    });
  });

  group('SaltoUnlockState enum coverage', () {
    test('all 7 states are defined', () {
      expect(SaltoUnlockState.values.length, 7);
    });

    test('idle, scanning, connecting, granted, rejected, error, noKey exist', () {
      expect(SaltoUnlockState.values, containsAll([
        SaltoUnlockState.idle,
        SaltoUnlockState.scanning,
        SaltoUnlockState.connecting,
        SaltoUnlockState.granted,
        SaltoUnlockState.rejected,
        SaltoUnlockState.error,
        SaltoUnlockState.noKey,
      ]));
    });
  });

  group('SaltoUnlockResult enum coverage', () {
    test('all 5 results are defined', () {
      expect(SaltoUnlockResult.values.length, 5);
    });

    test('granted, rejected, failure, timeout, noKey exist', () {
      expect(SaltoUnlockResult.values, containsAll([
        SaltoUnlockResult.granted,
        SaltoUnlockResult.rejected,
        SaltoUnlockResult.failure,
        SaltoUnlockResult.timeout,
        SaltoUnlockResult.noKey,
      ]));
    });
  });
}
