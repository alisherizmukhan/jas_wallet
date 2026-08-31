import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/api/api_client.dart';
import 'package:jaswallet_app/features/salto/data/repositories/salto_repository_impl.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/salto_provider.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/salto_readiness_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_storage.dart';

/// Extends SaltoRepositoryImpl so it satisfies the provider's type
/// constraint while never making real network calls.
class _StubSaltoRepositoryImpl extends SaltoRepositoryImpl {
  _StubSaltoRepositoryImpl()
      : super(
          apiClient: ApiClient(authStorage: FakeAuthStorageService(), dio: Dio()),
          authStorage: FakeAuthStorageService(),
        );

  @override
  Future<String?> getDigitalKey({bool forceRefresh = false}) async => null;
}

ProviderContainer _makeContainer() {
  return ProviderContainer(
    overrides: [
      saltoRepositoryProvider.overrideWithValue(_StubSaltoRepositoryImpl()),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SaltoReadinessNotifier — non-mobile platform', () {
    test('reports unsupportedPlatform on this test host', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      // Reading creates the notifier, which kicks off its initial refresh.
      container.read(saltoReadinessProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(saltoReadinessProvider);
      expect(state.isReady, isFalse);
      expect(state.issue, SaltoReadinessIssue.unsupportedPlatform);
    });

    test('refresh() is idempotent and safe to call repeatedly', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(saltoReadinessProvider.notifier);
      await Future.wait([notifier.refresh(), notifier.refresh(), notifier.refresh()]);

      expect(container.read(saltoReadinessProvider).isReady, isFalse);
    });
  });

  group('SaltoReadinessNotifier reacts to saltoUnlockProvider changes', () {
    test('re-evaluates when the unlock notifier state changes', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      // Establish the readiness listener first.
      container.read(saltoReadinessProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Triggering an unlock attempt (which fails fast on this unsupported
      // platform) still changes saltoUnlockProvider's state, which the
      // readiness notifier listens to — this must not throw or leave the
      // readiness provider stuck.
      await container.read(saltoUnlockProvider.notifier).unlock();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Still correctly reports the same platform limitation — the point
      // of this test is that reacting to the unlock state change doesn't
      // crash or desync the readiness provider, not that the issue changes.
      expect(
        container.read(saltoReadinessProvider).issue,
        SaltoReadinessIssue.unsupportedPlatform,
      );
    });
  });

  group('SaltoReadinessState value semantics', () {
    test('two states with the same fields are equal', () {
      const a = SaltoReadinessState(isReady: false, issue: SaltoReadinessIssue.bluetoothOff);
      const b = SaltoReadinessState(isReady: false, issue: SaltoReadinessIssue.bluetoothOff);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('ready is isReady:true with issue:none', () {
      expect(SaltoReadinessState.ready.isReady, isTrue);
      expect(SaltoReadinessState.ready.issue, SaltoReadinessIssue.none);
    });

    test('initial is isReady:false with issue:none', () {
      expect(SaltoReadinessState.initial.isReady, isFalse);
      expect(SaltoReadinessState.initial.issue, SaltoReadinessIssue.none);
    });
  });

  group('SaltoReadinessIssue enum coverage', () {
    test('all 10 issues are defined', () {
      expect(SaltoReadinessIssue.values.length, 10);
      expect(SaltoReadinessIssue.values, containsAll([
        SaltoReadinessIssue.none,
        SaltoReadinessIssue.unsupportedPlatform,
        SaltoReadinessIssue.unlockInProgress,
        SaltoReadinessIssue.bluetoothOff,
        SaltoReadinessIssue.bluetoothNotReady,
        SaltoReadinessIssue.bluetoothUnauthorized,
        SaltoReadinessIssue.bluetoothUnsupported,
        SaltoReadinessIssue.permissionDenied,
        SaltoReadinessIssue.locationOff,
        SaltoReadinessIssue.internetUnavailable,
      ]));
    });
  });
}
