import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/api/api_client.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/features/salto/data/models/salto_mobile_status.dart';
import 'package:jaswallet_app/features/salto/data/repositories/access_log_repository.dart';
import 'package:jaswallet_app/features/salto/data/repositories/salto_repository_impl.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/access_stats_provider.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/salto_activation_provider.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/salto_activation_readiness_provider.dart';
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

/// Resolves status/key instantly with no network call, so tests never risk
/// hitting real Dio/network and never linger in a "checkingStatus" state
/// longer than a single microtask.
class _StubSaltoRepositoryImpl extends SaltoRepositoryImpl {
  _StubSaltoRepositoryImpl({required FakeAuthStorageService authStorage})
      : super(
          apiClient: ApiClient(authStorage: authStorage, dio: Dio()),
          authStorage: authStorage,
        );

  Duration activateDelay = Duration.zero;

  @override
  Future<SaltoMobileStatus> getMobileStatus({CancelToken? cancelToken}) async => _fakeStatus;

  @override
  Future<SaltoMobileStatus?> getCachedMobileStatus() async => _fakeStatus;

  @override
  Future<String?> getDigitalKey({bool forceRefresh = false}) async => 'cached-key-hex';

  @override
  Future<SaltoMobileStatus> activateMobileAccess() async {
    if (activateDelay > Duration.zero) await Future<void>.delayed(activateDelay);
    return _fakeStatus;
  }
}

ProviderContainer _makeContainer({
  String? accessToken = 'a-valid-token',
  bool online = true,
}) {
  final authStorage = FakeAuthStorageService(accessToken: accessToken);
  final repo = _StubSaltoRepositoryImpl(authStorage: authStorage);
  return ProviderContainer(
    overrides: [
      // The readiness notifier reads authStorageServiceProvider directly
      // (for the access-token and mobile_phone_id checks) independently of
      // the repository's own internal authStorage field — both must point
      // at the same fake, or the notifier falls back to the real
      // FlutterSecureStorage-backed provider default.
      authStorageServiceProvider.overrideWithValue(authStorage),
      saltoRepositoryProvider.overrideWithValue(repo),
      accessLogRepositoryProvider.overrideWithValue(AccessLogRepository()),
      saltoActivationProvider.overrideWith((ref) {
        return SaltoActivationNotifier(
          repository: ref.watch(saltoRepositoryProvider),
          ref: ref,
          isConnected: () async => online,
        );
      }),
      saltoActivationReadinessProvider.overrideWith((ref) {
        return SaltoActivationReadinessNotifier(ref: ref, isConnected: () async => online);
      }),
    ],
  );
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SaltoActivationReadinessNotifier — notAuthenticated', () {
    test('reports notAuthenticated when no access token is stored', () async {
      final container = _makeContainer(accessToken: null);
      addTearDown(container.dispose);

      container.read(saltoActivationReadinessProvider); // creates + triggers refresh
      await _settle();

      final state = container.read(saltoActivationReadinessProvider);
      expect(state.isReady, isFalse);
      expect(state.issue, SaltoActivationReadinessIssue.notAuthenticated);
    });
  });

  group('SaltoActivationReadinessNotifier — internetUnavailable', () {
    test('reports internetUnavailable when a token exists, status is '
        'loaded, and connectivity is false', () async {
      final container = _makeContainer(online: false);
      addTearDown(container.dispose);

      // saltoStatusProvider is autoDispose — hold a listener so it isn't
      // torn down and recreated (back to AsyncLoading) between warming it
      // here and the readiness notifier reading it below.
      final statusSub = container.listen(saltoStatusProvider, (_, _) {});
      addTearDown(statusSub.close);
      await container.read(saltoStatusProvider.future);

      container.read(saltoActivationReadinessProvider);
      await _settle();

      final state = container.read(saltoActivationReadinessProvider);
      expect(state.isReady, isFalse);
      expect(state.issue, SaltoActivationReadinessIssue.internetUnavailable);
    });
  });

  group('SaltoActivationReadinessNotifier — alreadyActivating', () {
    test('reports alreadyActivating while a POST is genuinely in flight',
        () async {
      final authStorage = FakeAuthStorageService(accessToken: 'token');
      final repo = _StubSaltoRepositoryImpl(authStorage: authStorage)
        ..activateDelay = const Duration(milliseconds: 200);
      final container = ProviderContainer(
        overrides: [
          authStorageServiceProvider.overrideWithValue(authStorage),
          saltoRepositoryProvider.overrideWithValue(repo),
          accessLogRepositoryProvider.overrideWithValue(AccessLogRepository()),
        ],
      );
      addTearDown(container.dispose);

      // Kick off a real activate() call and let it run long enough (via
      // activateDelay) that the readiness check below is guaranteed to
      // observe isActivating still true.
      final activationNotifier = container.read(saltoActivationProvider.notifier);
      unawaited(activationNotifier.activate());
      await _settle();

      container.read(saltoActivationReadinessProvider);
      await _settle();

      final state = container.read(saltoActivationReadinessProvider);
      expect(state.issue, SaltoActivationReadinessIssue.alreadyActivating);
    });
  });

  group('SaltoActivationReadinessNotifier — reacts to activation state changes', () {
    test('refresh() is safe to call repeatedly and settles without throwing',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final statusSub = container.listen(saltoStatusProvider, (_, _) {});
      addTearDown(statusSub.close);
      await container.read(saltoStatusProvider.future);

      final notifier = container.read(saltoActivationReadinessProvider.notifier);
      await Future.wait([notifier.refresh(), notifier.refresh(), notifier.refresh()]);

      expect(container.read(saltoActivationReadinessProvider), isNotNull);
    });
  });

  group('SaltoActivationReadinessState value semantics', () {
    test('two states with the same fields are equal', () {
      const a = SaltoActivationReadinessState(
        isReady: false,
        issue: SaltoActivationReadinessIssue.bluetoothOff,
      );
      const b = SaltoActivationReadinessState(
        isReady: false,
        issue: SaltoActivationReadinessIssue.bluetoothOff,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('ready is isReady:true with issue:none', () {
      expect(SaltoActivationReadinessState.ready.isReady, isTrue);
      expect(SaltoActivationReadinessState.ready.issue, SaltoActivationReadinessIssue.none);
    });
  });

  group('SaltoActivationReadinessIssue enum coverage', () {
    test('all 10 issues are defined', () {
      expect(SaltoActivationReadinessIssue.values.length, 10);
      expect(SaltoActivationReadinessIssue.values, containsAll([
        SaltoActivationReadinessIssue.none,
        SaltoActivationReadinessIssue.notAuthenticated,
        SaltoActivationReadinessIssue.checkingStatus,
        SaltoActivationReadinessIssue.preparingDevice,
        SaltoActivationReadinessIssue.internetUnavailable,
        SaltoActivationReadinessIssue.bluetoothOff,
        SaltoActivationReadinessIssue.bluetoothNotReady,
        SaltoActivationReadinessIssue.bluetoothUnauthorized,
        SaltoActivationReadinessIssue.bluetoothUnsupported,
        SaltoActivationReadinessIssue.alreadyActivating,
      ]));
    });
  });
}
