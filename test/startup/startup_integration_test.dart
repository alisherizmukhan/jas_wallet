import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_auth_storage.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer({required FakeAuthStorageService storage}) {
  return ProviderContainer(overrides: [
    authStorageServiceProvider.overrideWithValue(storage),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
  ]);
}

/// Wait for authProvider to leave the loading phase (appStarting / unknown).
Future<AuthState> _waitForAuthResolved(ProviderContainer container,
    {int maxMs = 2000}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: maxMs));
  while (DateTime.now().isBefore(deadline)) {
    final state = container.read(authProvider);
    if (state.status != AuthStatus.appStarting &&
        state.status != AuthStatus.unknown) {
      return state;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  return container.read(authProvider);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── Initial state ─────────────────────────────────────────────────────────

  group('AuthNotifier — initial state', () {
    test('starts in appStarting before async init completes', () async {
      final storage = FakeAuthStorageService();
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      // First read is synchronous — should be appStarting before any await.
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.appStarting);

      // Wait for full resolution so the async _init() and safety timer don't
      // fire into an already-disposed container during teardown.
      await _waitForAuthResolved(container);
    });

    test('initializes synchronously to appStarting (not unknown)', () async {
      // AuthNotifier sets appStarting in its constructor before any async work.
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'u1',
        refreshToken: 'fake',
        hasPin: true,
        biometricSetupCompleted: true,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      // Synchronous read before any futures complete.
      expect(container.read(authProvider).status, AuthStatus.appStarting);

      // Wait for resolution to avoid timer-after-dispose crash.
      await _waitForAuthResolved(container);
    });
  });

  // ── First launch flow ─────────────────────────────────────────────────────

  group('AuthNotifier — first launch (no language selected)', () {
    test('resolves to firstLaunch when no language selected', () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: false,
        hasSeenOnboarding: false,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final resolved = await _waitForAuthResolved(container);
      expect(resolved.status, AuthStatus.firstLaunch);
    });
  });

  // ── Onboarding flow ───────────────────────────────────────────────────────

  group('AuthNotifier — needs onboarding', () {
    test('resolves to needsOnboarding when language selected but onboarding not done',
        () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: false,
        isLoggedIn: false,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final resolved = await _waitForAuthResolved(container);
      expect(resolved.status, AuthStatus.needsOnboarding);
    });
  });

  // ── Unauthenticated flow ──────────────────────────────────────────────────

  group('AuthNotifier — unauthenticated', () {
    test('resolves to unauthenticated when no session', () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: false,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final resolved = await _waitForAuthResolved(container);
      expect(resolved.status, AuthStatus.unauthenticated);
    });
  });

  // ── Needs PIN setup ───────────────────────────────────────────────────────

  group('AuthNotifier — needs PIN setup', () {
    test('resolves to needsPinSetup when logged in but no PIN', () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'u1',
        refreshToken: 'fake',
        hasPin: false,
        biometricSetupCompleted: false,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final resolved = await _waitForAuthResolved(container);
      expect(resolved.status, AuthStatus.needsPinSetup);
    });
  });

  // ── Needs biometric setup ─────────────────────────────────────────────────

  group('AuthNotifier — needs biometric setup', () {
    test('resolves to needsBiometricSetup when PIN created but biometric not set up',
        () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'u1',
        refreshToken: 'fake',
        hasPin: true,
        biometricSetupCompleted: false,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final resolved = await _waitForAuthResolved(container);
      expect(resolved.status, AuthStatus.needsBiometricSetup);
    });
  });

  // ── Needs local auth ──────────────────────────────────────────────────────

  group('AuthNotifier — needs local auth (PIN unlock required)', () {
    test('resolves to needsLocalAuth when session + PIN + biometric setup done',
        () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'u1',
        refreshToken: 'fake',
        hasPin: true,
        biometricSetupCompleted: true,
        biometricEnabled: false,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final resolved = await _waitForAuthResolved(container);
      expect(resolved.status, AuthStatus.needsLocalAuth);
    });

    test('biometricEnabled is correctly carried in auth state', () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'u1',
        refreshToken: 'fake',
        hasPin: true,
        biometricSetupCompleted: true,
        biometricEnabled: true,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final resolved = await _waitForAuthResolved(container);
      expect(resolved.status, AuthStatus.needsLocalAuth);
      expect(resolved.biometricEnabled, isTrue);
    });
  });

  // ── Auth state does NOT stay loading ─────────────────────────────────────

  group('AuthNotifier — leaves loading phase', () {
    test('appStarting transitions out (resolves) within 2 seconds', () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: false,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final resolved = await _waitForAuthResolved(container);

      expect(
        resolved.status,
        isNot(AuthStatus.appStarting),
        reason: 'Auth must leave appStarting',
      );
      expect(
        resolved.status,
        isNot(AuthStatus.unknown),
        reason: 'Auth must leave unknown',
      );
    });

    test('auth resolves to a meaningful state (not loading) for all paths',
        () async {
      final scenarios = <FakeAuthStorageService>[
        FakeAuthStorageService(hasSelectedLanguage: false),
        FakeAuthStorageService(
            hasSelectedLanguage: true, hasSeenOnboarding: false),
        FakeAuthStorageService(
            hasSelectedLanguage: true, hasSeenOnboarding: true, isLoggedIn: false),
        FakeAuthStorageService(
            hasSelectedLanguage: true,
            hasSeenOnboarding: true,
            isLoggedIn: true,
            userId: 'u',
            refreshToken: 'r',
            hasPin: false),
        FakeAuthStorageService(
            hasSelectedLanguage: true,
            hasSeenOnboarding: true,
            isLoggedIn: true,
            userId: 'u',
            refreshToken: 'r',
            hasPin: true,
            biometricSetupCompleted: false),
        FakeAuthStorageService(
            hasSelectedLanguage: true,
            hasSeenOnboarding: true,
            isLoggedIn: true,
            userId: 'u',
            refreshToken: 'r',
            hasPin: true,
            biometricSetupCompleted: true),
      ];

      for (final storage in scenarios) {
        final container = _makeContainer(storage: storage);
        final resolved = await _waitForAuthResolved(container);
        container.dispose();

        final isLoading = resolved.status == AuthStatus.appStarting ||
            resolved.status == AuthStatus.unknown;
        expect(
          isLoading,
          isFalse,
          reason: 'Auth should not be stuck loading. Got: ${resolved.status}',
        );
      }
    });
  });

  // ── AuthStatus loading-phase identification ───────────────────────────────

  group('AuthStatus — loading phase identification', () {
    test('only appStarting and unknown are loading-phase states', () {
      final loadingStatuses = AuthStatus.values.where((s) {
        return s == AuthStatus.appStarting || s == AuthStatus.unknown;
      }).toSet();

      expect(loadingStatuses,
          containsAll([AuthStatus.appStarting, AuthStatus.unknown]));
      expect(loadingStatuses.length, 2);
    });

    test('authenticated is always non-loading', () {
      const state = AuthState(status: AuthStatus.authenticated);
      final isLoading = state.status == AuthStatus.appStarting ||
          state.status == AuthStatus.unknown;
      expect(isLoading, isFalse);
    });

    test('needsLocalAuth is always non-loading', () {
      const state = AuthState(status: AuthStatus.needsLocalAuth);
      final isLoading = state.status == AuthStatus.appStarting ||
          state.status == AuthStatus.unknown;
      expect(isLoading, isFalse);
    });
  });

  // ── Cold start: auth state flow assertions ────────────────────────────────

  group('Cold start — auth state lifecycle', () {
    test('fresh install: firstLaunch → languageSelected → needsOnboarding',
        () async {
      // Simulate: user selects language (firstLaunch → needsOnboarding)
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: false,
        hasSeenOnboarding: false,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      // Phase 1: firstLaunch
      final phase1 = await _waitForAuthResolved(container);
      expect(phase1.status, AuthStatus.firstLaunch);

      // Phase 2: User selects language → setLanguageSelected()
      await container.read(authProvider.notifier).completeLanguageSelection();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final phase2 = container.read(authProvider);
      expect(phase2.status, AuthStatus.needsOnboarding);
    });

    test('returning authenticated user: needsLocalAuth (has PIN)', () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'u1',
        refreshToken: 'fake',
        hasPin: true,
        biometricSetupCompleted: true,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final resolved = await _waitForAuthResolved(container);
      // Full session + PIN → user must authenticate locally.
      // userId IS carried in the needsLocalAuth state (needed for PIN context).
      expect(resolved.status, AuthStatus.needsLocalAuth);
      expect(resolved.userId, isNotNull);
    });
  });
}
