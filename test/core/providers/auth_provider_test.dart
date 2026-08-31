import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/core/services/biometric_auth_service.dart';

import '../../helpers/fake_auth_storage.dart';

// ── Test doubles ──────────────────────────────────────────────────────────────

/// BiometricAuthService that never calls platform channels.
/// Passed explicitly to logout()/forceReAuth() to avoid the direct
/// BiometricAuthService() instantiation inside AuthNotifier.
class _NoOpBiometricService extends BiometricAuthService {
  @override
  Future<void> clearCredentials() async {}
  @override
  Future<void> clearAll() async {}
}

// ── Factory ───────────────────────────────────────────────────────────────────

/// Creates a ProviderContainer using the given fake storage and waits for
/// AuthNotifier._init() to complete (FakeAuthStorageService resolves instantly).
Future<ProviderContainer> _makeContainer(FakeAuthStorageService storage) async {
  final container = ProviderContainer(
    overrides: [
      authStorageServiceProvider.overrideWithValue(storage),
    ],
  );
  container.read(authProvider); // triggers AuthNotifier construction + _init()
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return container;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AuthNotifier — initial state resolution', () {
    test('firstLaunch when no language has been selected', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: false,
          hasSeenOnboarding: false,
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(authProvider).status, AuthStatus.firstLaunch);
    });

    test('needsOnboarding when language selected but onboarding not completed',
        () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: false,
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(authProvider).status, AuthStatus.needsOnboarding);
    });

    test('unauthenticated when onboarding done and not logged in', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isLoggedIn: false,
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    });

    test('needsPinSetup when logged in with no PIN', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isLoggedIn: true,
          userId: 'user-123',
          accessToken: 'access.token',
          refreshToken: 'refresh.token',
          hasPin: false,
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(authProvider).status, AuthStatus.needsPinSetup);
    });

    test('needsLocalAuth when logged in with PIN and biometric setup completed',
        () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isLoggedIn: true,
          userId: 'user-123',
          accessToken: 'access.token',
          refreshToken: 'refresh.token',
          hasPin: true,
          biometricSetupCompleted: true,
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(authProvider).status, AuthStatus.needsLocalAuth);
    });

    test('needsBiometricSetup when PIN set but biometric setup not yet shown',
        () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isLoggedIn: true,
          userId: 'user-123',
          accessToken: 'access.token',
          refreshToken: 'refresh.token',
          hasPin: true,
          biometricSetupCompleted: false, // incomplete
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(authProvider).status,
        AuthStatus.needsBiometricSetup,
      );
    });

    test('unauthenticated when PIN retry limit (5) is reached', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isLoggedIn: true,
          userId: 'user-123',
          refreshToken: 'refresh.token',
          hasPin: true,
          biometricSetupCompleted: true,
          pinFailedAttempts: 5,
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    });

    test('unauthenticated when session exists but no refresh token', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isLoggedIn: true,
          userId: 'user-123',
          accessToken: 'access.token',
          // No refreshToken
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    });
  });

  group('AuthNotifier.login()', () {
    test('transitions to needsPinSetup when no PIN exists', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).login(
            userId: 'user-abc',
            accessToken: 'at',
            refreshToken: 'rt',
          );

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.needsPinSetup);
      expect(state.userId, 'user-abc');
    });

    test('transitions to authenticated when PIN already exists', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          hasPin: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).login(
            userId: 'user-abc',
            accessToken: 'at',
            refreshToken: 'rt',
          );

      expect(container.read(authProvider).status, AuthStatus.authenticated);
    });
  });

  group('AuthNotifier.completePinSetup()', () {
    test('transitions to needsBiometricSetup when showBiometricSetup is true',
        () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).login(
            userId: 'user-abc',
            accessToken: 'at',
            refreshToken: 'rt',
          );
      await container
          .read(authProvider.notifier)
          .completePinSetup(showBiometricSetup: true);

      expect(
        container.read(authProvider).status,
        AuthStatus.needsBiometricSetup,
      );
    });

    test('transitions to authenticated when showBiometricSetup is false',
        () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).login(
            userId: 'user-abc',
            accessToken: 'at',
            refreshToken: 'rt',
          );
      await container
          .read(authProvider.notifier)
          .completePinSetup(showBiometricSetup: false);

      expect(container.read(authProvider).status, AuthStatus.authenticated);
    });
  });

  group('AuthNotifier.completeBiometricSetup()', () {
    test('transitions to authenticated', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).login(
            userId: 'user-abc',
            accessToken: 'at',
            refreshToken: 'rt',
          );
      await container
          .read(authProvider.notifier)
          .completePinSetup(showBiometricSetup: true);
      await container.read(authProvider.notifier).completeBiometricSetup();

      expect(container.read(authProvider).status, AuthStatus.authenticated);
    });
  });

  group('AuthNotifier.logout()', () {
    test('transitions to unauthenticated', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isLoggedIn: true,
          userId: 'user-123',
          refreshToken: 'rt',
          hasPin: true,
          biometricSetupCompleted: true,
        ),
      );
      addTearDown(container.dispose);

      // Provide no-op biometric service to bypass direct BiometricAuthService()
      // instantiation inside AuthNotifier.logout()
      await container.read(authProvider.notifier).logout(
            biometricService: _NoOpBiometricService(),
          );

      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    });

    test('clears userId on logout', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isLoggedIn: true,
          userId: 'user-123',
          refreshToken: 'rt',
          hasPin: true,
          biometricSetupCompleted: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).logout(
            biometricService: _NoOpBiometricService(),
          );

      // After logout the state should have no userId
      // (AuthState.unauthenticated has null userId by default)
      expect(container.read(authProvider).userId, isNull);
    });
  });

  group('AuthNotifier.lockApp()', () {
    test('transitions authenticated → needsLocalAuth', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isLoggedIn: true,
          userId: 'user-123',
          refreshToken: 'rt',
          hasPin: true,
          biometricSetupCompleted: true,
        ),
      );
      addTearDown(container.dispose);

      container.read(authProvider.notifier).unlockWithLocalAuth();
      expect(container.read(authProvider).status, AuthStatus.authenticated);

      await container.read(authProvider.notifier).lockApp();

      expect(container.read(authProvider).status, AuthStatus.needsLocalAuth);
    });

    test('is a no-op when status is unauthenticated', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).lockApp();

      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    });
  });

  group('AuthNotifier — onboarding flow', () {
    test('completeLanguageSelection() → unauthenticated when onboarding done',
        () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: false,
          hasSeenOnboarding: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).completeLanguageSelection();

      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    });

    test(
        'completeLanguageSelection() → needsOnboarding when onboarding not done',
        () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: false,
          hasSeenOnboarding: false,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).completeLanguageSelection();

      expect(container.read(authProvider).status, AuthStatus.needsOnboarding);
    });

    test('completeOnboarding() → unauthenticated', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: false,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).completeOnboarding();

      expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    });
  });

  group('AuthNotifier — offline mode', () {
    test('markOfflineMode() sets isOfflineMode = true', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).markOfflineMode();

      expect(container.read(authProvider).isOfflineMode, isTrue);
    });

    test('markOnlineMode() sets isOfflineMode = false', () async {
      final container = await _makeContainer(
        FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isOfflineMode: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).markOnlineMode();

      expect(container.read(authProvider).isOfflineMode, isFalse);
    });
  });

  group('AuthState.copyWith()', () {
    test('only replaces provided fields, preserves others', () {
      const original = AuthState(
        status: AuthStatus.authenticated,
        userId: 'user-1',
        isOfflineMode: false,
        biometricEnabled: true,
      );

      final updated = original.copyWith(isOfflineMode: true);

      expect(updated.status, AuthStatus.authenticated);
      expect(updated.userId, 'user-1');
      expect(updated.isOfflineMode, isTrue);
      expect(updated.biometricEnabled, isTrue);
    });

    test('copyWith can change status without affecting other fields', () {
      const original = AuthState(
        status: AuthStatus.needsLocalAuth,
        userId: 'user-xyz',
        isOfflineMode: true,
        biometricEnabled: false,
      );

      final updated = original.copyWith(status: AuthStatus.authenticated);

      expect(updated.status, AuthStatus.authenticated);
      expect(updated.userId, 'user-xyz');
      expect(updated.isOfflineMode, isTrue);
      expect(updated.biometricEnabled, isFalse);
    });
  });
}
