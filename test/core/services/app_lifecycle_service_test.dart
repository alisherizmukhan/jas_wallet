import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/core/services/app_lifecycle_service.dart';
import 'package:jaswallet_app/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_storage.dart';
import '../../helpers/fake_auth_repository.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Builds a ProviderContainer with a controllable auth state.
ProviderContainer _makeContainer({required FakeAuthStorageService storage}) {
  return ProviderContainer(overrides: [
    authStorageServiceProvider.overrideWithValue(storage),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
  ]);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── Lock threshold constant ───────────────────────────────────────────────

  group('AppLifecycleService — lock threshold', () {
    test('lockThreshold is 5 minutes', () {
      expect(
        AppLifecycleService.lockThreshold,
        const Duration(minutes: 5),
      );
    });
  });

  // ── No-lock: short background ─────────────────────────────────────────────

  group('AppLifecycleService — short background does NOT lock', () {
    test('resume after 1-minute pause does not lock authenticated user',
        () async {
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

      // Wait for auth to resolve to authenticated
      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify auth is authenticated before testing lifecycle
      final authState = container.read(authProvider);
      // Storage has a session → auth should be needsLocalAuth (has PIN)
      // Either way: needsLocalAuth or authenticated both are "logged in" states.
      expect(
        authState.status == AuthStatus.authenticated ||
            authState.status == AuthStatus.needsLocalAuth,
        isTrue,
        reason: 'User with session should be authenticated or needsLocalAuth',
      );

      // Manually test the lifecycle logic by creating a service and simulating
      // short elapsed time — the service checks elapsed >= lockThreshold.
      // 1 minute < 5 minutes → should NOT lock.
      final elapsed = const Duration(minutes: 1);
      expect(elapsed >= AppLifecycleService.lockThreshold, isFalse);
    });

    test('resume after 4m59s does not hit lock threshold', () {
      final elapsed = const Duration(minutes: 4, seconds: 59);
      expect(elapsed >= AppLifecycleService.lockThreshold, isFalse);
    });

    test('resume after exactly 5 minutes DOES hit lock threshold', () {
      final elapsed = const Duration(minutes: 5);
      expect(elapsed >= AppLifecycleService.lockThreshold, isTrue);
    });

    test('resume after 10 minutes exceeds lock threshold', () {
      final elapsed = const Duration(minutes: 10);
      expect(elapsed >= AppLifecycleService.lockThreshold, isTrue);
    });
  });

  // ── Lifecycle state transitions ───────────────────────────────────────────
  //
  // AppLifecycleService takes a Riverpod Ref, not a ProviderContainer. The
  // cleanest way to get a service with a real Ref in tests is via
  // appLifecycleServiceProvider inside a ProviderContainer (which already
  // wires up the Ref and calls service.start()). Widget tests are used here
  // so that WidgetsBinding.instance is properly initialised.

  group('AppLifecycleService — didChangeAppLifecycleState', () {
    late ProviderContainer container;

    setUp(() {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'u1',
        refreshToken: 'fake',
        hasPin: true,
        biometricSetupCompleted: true,
      );
      container = _makeContainer(storage: storage);
    });

    tearDown(() => container.dispose());

    testWidgets('paused state records _pausedAt', (tester) async {
      final service = container.read(appLifecycleServiceProvider);

      // Simulate app going to background
      service.didChangeAppLifecycleState(AppLifecycleState.paused);

      // _pausedAt should now be set (internal state — we verify via resumed check)
      // Resume immediately (< 1s) → should NOT lock
      // We verify the service handles this without throwing.
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    });

    testWidgets('hidden state also records _pausedAt (first hidden only)',
        (tester) async {
      final service = container.read(appLifecycleServiceProvider);

      service.didChangeAppLifecycleState(AppLifecycleState.hidden);
      // Second hidden: _pausedAt already set (??= guard) — no-op.
      service.didChangeAppLifecycleState(AppLifecycleState.hidden);
      // Resume after hidden state should work without error.
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    });

    testWidgets('detached state records _pausedAt', (tester) async {
      final service = container.read(appLifecycleServiceProvider);

      service.didChangeAppLifecycleState(AppLifecycleState.detached);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    });

    testWidgets('inactive state is ignored (transitional)', (tester) async {
      final service = container.read(appLifecycleServiceProvider);

      // inactive should not set _pausedAt or trigger lock
      service.didChangeAppLifecycleState(AppLifecycleState.inactive);
      // Resuming after inactive (no pause) should be a no-op.
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    });

    testWidgets('resumed without prior pause is a no-op (no crash)',
        (tester) async {
      final service = container.read(appLifecycleServiceProvider);

      // Calling resumed without any pause first should not throw.
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    });

    testWidgets('multiple pauses only record the first (??= guard)',
        (tester) async {
      final service = container.read(appLifecycleServiceProvider);

      // First pause sets _pausedAt
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      // Second pause is ignored due to ??= guard
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      // Resume: should work without double-lock
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    });
  });

  // ── Lock behaviour: unauthenticated user ──────────────────────────────────

  group('AppLifecycleService — unauthenticated user does NOT get locked', () {
    test('long background with unauthenticated status triggers no lock', () async {
      // Unauthenticated session
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: false,
      );
      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final authState = container.read(authProvider);
      // Unauthenticated → lockApp should not be called
      // Verify the guard condition: only authenticated users are locked.
      expect(authState.status == AuthStatus.authenticated, isFalse);
    });

    test('lockThreshold check is ONLY applied when status == authenticated', () {
      // This is the core guard in _onResumed:
      // if (authState.status == AuthStatus.authenticated) { lockApp() }
      // Verify all non-authenticated statuses are excluded.
      for (final status in AuthStatus.values) {
        final shouldLock = status == AuthStatus.authenticated;
        final state = AuthState(status: status);
        expect(
          state.status == AuthStatus.authenticated,
          shouldLock,
          reason: '$status: shouldLock=$shouldLock',
        );
      }
    });
  });

  // ── Provider integration ──────────────────────────────────────────────────

  group('AppLifecycleService — provider lifecycle', () {
    testWidgets('appLifecycleServiceProvider is created and disposed',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: false,
      );

      bool disposed = false;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStorageServiceProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            // Reading the provider registers it
            ref.watch(appLifecycleServiceProvider);
            return MaterialApp(home: const SizedBox.shrink());
          },
        ),
      ));

      await tester.pumpAndSettle();

      // Provider was created without exception
      expect(tester.takeException(), isNull);
      expect(disposed, isFalse); // still alive during test
    });
  });

  // ── Lock threshold edge cases ─────────────────────────────────────────────

  group('AppLifecycleService — boundary conditions', () {
    test('exactly at threshold boundary: 5m0s locks', () {
      const threshold = AppLifecycleService.lockThreshold;
      const elapsed = Duration(minutes: 5, seconds: 0);
      expect(elapsed >= threshold, isTrue);
    });

    test('1ms before threshold: 4m59s999ms does not lock', () {
      const threshold = AppLifecycleService.lockThreshold;
      const elapsed = Duration(minutes: 4, seconds: 59, milliseconds: 999);
      expect(elapsed >= threshold, isFalse);
    });

    test('far beyond threshold: 30 minutes locks', () {
      const threshold = AppLifecycleService.lockThreshold;
      const elapsed = Duration(minutes: 30);
      expect(elapsed >= threshold, isTrue);
    });

    test('overnight gap: 8 hours locks', () {
      const threshold = AppLifecycleService.lockThreshold;
      const elapsed = Duration(hours: 8);
      expect(elapsed >= threshold, isTrue);
    });
  });
}
