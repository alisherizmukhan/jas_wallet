import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/api/api_client.dart';
import 'package:jaswallet_app/features/salto/data/models/salto_mobile_status.dart';
import 'package:jaswallet_app/features/salto/data/repositories/access_log_repository.dart';
import 'package:jaswallet_app/features/salto/data/repositories/salto_repository_impl.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/access_stats_provider.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/salto_activation_provider.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/salto_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_storage.dart';

const _fakeStatus = SaltoMobileStatus(
  linked: true,
  saltoVerified: true,
  mobileAccessEnabled: true,
  activationRequired: false,
  hasCachedKey: true,
);

/// Extends SaltoRepositoryImpl so it satisfies the provider's type
/// constraint while never making real network calls.
class _StubSaltoRepositoryImpl extends SaltoRepositoryImpl {
  _StubSaltoRepositoryImpl()
      : super(
          apiClient: ApiClient(authStorage: FakeAuthStorageService(), dio: Dio()),
          authStorage: FakeAuthStorageService(),
        );

  bool shouldThrow = false;
  Object errorToThrow = const SaltoRepositoryException('backend rejected');
  Duration activateDelay = Duration.zero;
  int activateCalls = 0;

  /// What a post-timeout reconciliation probe finds. Null makes the probe
  /// itself fail, standing in for "the server is still unreachable".
  SaltoMobileStatus? freshStatus;
  int freshStatusCalls = 0;

  /// Number of leading probes that fail before [freshStatus] is served.
  int failFreshProbes = 0;

  @override
  Future<SaltoMobileStatus> activateMobileAccess() async {
    activateCalls++;
    if (activateDelay > Duration.zero) {
      await Future<void>.delayed(activateDelay);
    }
    if (shouldThrow) throw errorToThrow;
    return _fakeStatus;
  }

  @override
  Future<SaltoMobileStatus> getFreshMobileStatus() async {
    freshStatusCalls++;
    final status = freshStatus;
    if (freshStatusCalls <= failFreshProbes || status == null) {
      throw const SaltoRepositoryException('unreachable');
    }
    return status;
  }

  @override
  Future<String?> getDigitalKey({bool forceRefresh = false}) async => 'cached-key-hex';
}

ProviderContainer _makeContainer(
  _StubSaltoRepositoryImpl repo, {
  bool online = true,
}) {
  return ProviderContainer(
    overrides: [
      saltoRepositoryProvider.overrideWithValue(repo),
      accessLogRepositoryProvider.overrideWithValue(AccessLogRepository()),
      saltoActivationProvider.overrideWith((ref) {
        return SaltoActivationNotifier(
          repository: ref.watch(saltoRepositoryProvider),
          ref: ref,
          isConnected: () async => online,
          // Real backoff is 2/4/8s — collapsed here so the reconciliation
          // paths are testable without a 14-second wall clock.
          reconcileBackoff: const [Duration.zero, Duration.zero, Duration.zero],
        );
      }),
    ],
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SaltoActivationNotifier.activate() — success', () {
    test('sends exactly one POST and returns the fresh status', () async {
      final repo = _StubSaltoRepositoryImpl();
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(saltoActivationProvider.notifier).activate();

      expect(result, isNotNull);
      expect(repo.activateCalls, 1);
      expect(container.read(saltoActivationProvider), SaltoActivationState.success);
      expect(
        container.read(saltoActivationProvider.notifier).lastFailureReason,
        SaltoActivationFailureReason.none,
      );
    });

    test('isActivating is false before and after a successful attempt', () async {
      final repo = _StubSaltoRepositoryImpl();
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      expect(notifier.isActivating, isFalse);
      await notifier.activate();
      expect(notifier.isActivating, isFalse);
    });
  });

  group('SaltoActivationNotifier.activate() — offline gate', () {
    test('refuses to send the POST when offline, never touching the '
        'repository', () async {
      final repo = _StubSaltoRepositoryImpl();
      final container = _makeContainer(repo, online: false);
      addTearDown(container.dispose);

      final result = await container.read(saltoActivationProvider.notifier).activate();

      expect(result, isNull);
      expect(repo.activateCalls, 0, reason: 'must never attempt the POST while offline');
      expect(container.read(saltoActivationProvider), SaltoActivationState.error);
      expect(
        container.read(saltoActivationProvider.notifier).lastFailureReason,
        SaltoActivationFailureReason.internetUnavailable,
      );
    });
  });

  group('SaltoActivationNotifier.activate() — already in progress', () {
    test('a second concurrent call is refused; exactly one POST is sent',
        () async {
      final repo = _StubSaltoRepositoryImpl()
        ..activateDelay = const Duration(milliseconds: 60);
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      final results = await Future.wait([notifier.activate(), notifier.activate()]);

      expect(repo.activateCalls, 1);
      expect(results.where((r) => r == null), hasLength(1));
      expect(results.where((r) => r != null), hasLength(1));
    });

    test('the refused call sets alreadyActivating without touching the '
        'winner\'s success state', () async {
      final repo = _StubSaltoRepositoryImpl()
        ..activateDelay = const Duration(milliseconds: 60);
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      final first = notifier.activate();
      // Give the first call a chance to acquire the lock before firing the
      // second — otherwise both could plausibly win the race for the very
      // first synchronous tick.
      await Future<void>.delayed(Duration.zero);
      final second = await notifier.activate();

      expect(second, isNull);
      expect(notifier.lastFailureReason, SaltoActivationFailureReason.alreadyActivating);
      await first;
    });
  });

  group('SaltoActivationNotifier.activate() — backend failure', () {
    test('rethrows SaltoRepositoryException and records backendRejected',
        () async {
      final repo = _StubSaltoRepositoryImpl()..shouldThrow = true;
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      await expectLater(notifier.activate(), throwsA(isA<SaltoRepositoryException>()));

      expect(notifier.lastFailureReason, SaltoActivationFailureReason.backendRejected);
      expect(container.read(saltoActivationProvider), SaltoActivationState.error);
      expect(notifier.isActivating, isFalse,
          reason: 'lock must release even when the POST throws');
    });

    test('a failed attempt does not block the next attempt from proceeding',
        () async {
      final repo = _StubSaltoRepositoryImpl()..shouldThrow = true;
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      await expectLater(notifier.activate(), throwsA(isA<Object>()));

      repo.shouldThrow = false;
      final result = await notifier.activate();

      expect(result, isNotNull);
      expect(repo.activateCalls, 2);
    });
  });

  group('SaltoActivationNotifier.reset()', () {
    test('clears state and lastFailureReason back to idle/none', () async {
      final repo = _StubSaltoRepositoryImpl()..shouldThrow = true;
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      await expectLater(notifier.activate(), throwsA(isA<Object>()));
      notifier.reset();

      expect(container.read(saltoActivationProvider), SaltoActivationState.idle);
      expect(notifier.lastFailureReason, SaltoActivationFailureReason.none);
    });
  });

  group('SaltoActivationNotifier — prerequisite logging', () {
    test('logBlocked persists a standalone attempt entry', () async {
      final repo = _StubSaltoRepositoryImpl();
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      await notifier.logBlocked('bluetoothOff', detail: 'Bluetooth state: off');

      final attempts = await container.read(accessLogRepositoryProvider).getAllAttempts();
      expect(attempts, hasLength(1));
      expect(attempts.single.result, 'activation_blocked_bluetoothOff');
      expect(attempts.single.logs.single, contains('Bluetooth state: off'));
    });

    test('logSettingsOpened persists a standalone attempt entry', () async {
      final repo = _StubSaltoRepositoryImpl();
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      await notifier.logSettingsOpened('bluetooth');

      final attempts = await container.read(accessLogRepositoryProvider).getAllAttempts();
      expect(attempts, hasLength(1));
      expect(attempts.single.result, 'activation_settings_opened');
    });

    test('logSettingsReturned persists a standalone attempt entry', () async {
      final repo = _StubSaltoRepositoryImpl();
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      await notifier.logSettingsReturned();

      final attempts = await container.read(accessLogRepositoryProvider).getAllAttempts();
      expect(attempts, hasLength(1));
      expect(attempts.single.result, 'activation_settings_returned');
    });

    test('prerequisite log calls do not interfere with a later activate() '
        'attempt log', () async {
      final repo = _StubSaltoRepositoryImpl();
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      await notifier.logBlocked('bluetoothOff', detail: 'x');
      await notifier.logSettingsOpened('bluetooth');
      await notifier.logSettingsReturned();
      await notifier.activate();

      final attempts = await container.read(accessLogRepositoryProvider).getAllAttempts();
      expect(attempts, hasLength(4));
      expect(attempts.last.result, 'activation_success');
    });
  });

  // A timeout means "unknown", not "failed": the backend runs a long chain of
  // sequential SHIP calls and keeps going after the client stops listening, so
  // the destructive activation has very likely landed. Reporting an error here
  // is what made students tap the button a second time and race their own
  // still-running request.
  group('SaltoActivationNotifier.activate() — in-flight timeout', () {
    _StubSaltoRepositoryImpl timingOutRepo() => _StubSaltoRepositoryImpl()
      ..shouldThrow = true
      ..errorToThrow = const SaltoRepositoryException('timed out', isTimeout: true);

    test('reports success when a status probe shows the activation did land', () async {
      final repo = timingOutRepo()..freshStatus = _fakeStatus;
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(saltoActivationProvider.notifier).activate();

      expect(result, isNotNull, reason: 'the server finished it, so this is a success');
      expect(repo.activateCalls, 1, reason: 'the destructive POST must never be resent');
      expect(repo.freshStatusCalls, 1);
      expect(container.read(saltoActivationProvider), SaltoActivationState.success);
    });

    test('keeps probing until one succeeds', () async {
      // Unreachable on the first probe, answered on the second — a single
      // transient failure must not be read as "activation did not happen".
      final repo = timingOutRepo()
        ..freshStatus = _fakeStatus
        ..failFreshProbes = 1;
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(saltoActivationProvider.notifier).activate();

      expect(result, isNotNull);
      expect(repo.activateCalls, 1);
      expect(repo.freshStatusCalls, 2);
    });

    test('returns timedOutStillRunning — not an error the user answers by '
        'retrying — when the outcome cannot be confirmed', () async {
      final repo = timingOutRepo()..freshStatus = null;
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      // Returns rather than rethrows, so the page shows the "wait, do not tap
      // again" gate message instead of the repository's own error text.
      final result = await notifier.activate();

      expect(result, isNull);
      expect(repo.activateCalls, 1);
      expect(notifier.lastFailureReason, SaltoActivationFailureReason.timedOutStillRunning);
      expect(container.read(saltoActivationProvider), SaltoActivationState.error);
      expect(notifier.isActivating, isFalse);
    });

    test('a not-yet-activated status is not mistaken for success', () async {
      final repo = timingOutRepo()
        ..freshStatus = const SaltoMobileStatus(
          linked: true,
          saltoVerified: true,
          mobileAccessEnabled: false,
          activationRequired: true,
          hasCachedKey: false,
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      expect(await notifier.activate(), isNull);
      expect(notifier.lastFailureReason, SaltoActivationFailureReason.timedOutStillRunning);
    });

    test('a status still bound to another device is not mistaken for success', () async {
      final repo = timingOutRepo()
        ..freshStatus = const SaltoMobileStatus(
          linked: true,
          saltoVerified: true,
          mobileAccessEnabled: true,
          activationRequired: false,
          hasCachedKey: true,
          deviceBindingRequired: true,
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(saltoActivationProvider.notifier);

      expect(await notifier.activate(), isNull);
      expect(notifier.lastFailureReason, SaltoActivationFailureReason.timedOutStillRunning);
    });
  });

  group('SaltoActivationState / SaltoActivationFailureReason enum coverage', () {
    test('all 4 activation states are defined', () {
      expect(SaltoActivationState.values.length, 4);
      expect(SaltoActivationState.values, containsAll([
        SaltoActivationState.idle,
        SaltoActivationState.activating,
        SaltoActivationState.success,
        SaltoActivationState.error,
      ]));
    });

    test('all 6 failure reasons are defined', () {
      expect(SaltoActivationFailureReason.values.length, 6);
      expect(SaltoActivationFailureReason.values, containsAll([
        SaltoActivationFailureReason.none,
        SaltoActivationFailureReason.internetUnavailable,
        SaltoActivationFailureReason.alreadyActivating,
        SaltoActivationFailureReason.backendRejected,
        SaltoActivationFailureReason.timedOutStillRunning,
        SaltoActivationFailureReason.unknown,
      ]));
    });
  });
}
