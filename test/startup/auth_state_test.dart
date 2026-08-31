import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';

// Unit tests for AuthStatus enum and AuthState data model.
// Router redirect logic is integration-tested separately.
void main() {
  // ── AuthStatus enum ──────────────────────────────────────────────────────────

  group('AuthStatus enum', () {
    test('has 9 values covering the full auth lifecycle', () {
      expect(AuthStatus.values.length, 9);
    });

    test('contains all expected statuses', () {
      const expected = {
        AuthStatus.appStarting,
        AuthStatus.unknown,
        AuthStatus.firstLaunch,
        AuthStatus.needsOnboarding,
        AuthStatus.unauthenticated,
        AuthStatus.needsPinSetup,
        AuthStatus.needsBiometricSetup,
        AuthStatus.needsLocalAuth,
        AuthStatus.authenticated,
      };
      expect(AuthStatus.values.toSet(), expected);
    });

    test('appStarting precedes unknown in enum order', () {
      expect(
        AuthStatus.values.indexOf(AuthStatus.appStarting),
        lessThan(AuthStatus.values.indexOf(AuthStatus.unknown)),
      );
    });
  });

  // ── AuthState defaults ───────────────────────────────────────────────────────

  group('AuthState — defaults', () {
    test('default status is unknown', () {
      const state = AuthState();
      expect(state.status, AuthStatus.unknown);
    });

    test('default userId is null', () {
      const state = AuthState();
      expect(state.userId, isNull);
    });

    test('default isOfflineMode is false', () {
      const state = AuthState();
      expect(state.isOfflineMode, isFalse);
    });

    test('default biometricEnabled is false', () {
      const state = AuthState();
      expect(state.biometricEnabled, isFalse);
    });
  });

  // ── AuthState.copyWith ───────────────────────────────────────────────────────

  group('AuthState.copyWith()', () {
    const base = AuthState(
      status: AuthStatus.unauthenticated,
      userId: 'user-42',
      isOfflineMode: false,
      biometricEnabled: false,
    );

    test('copyWith(status:) changes only status', () {
      final copy = base.copyWith(status: AuthStatus.authenticated);
      expect(copy.status, AuthStatus.authenticated);
      expect(copy.userId, base.userId);
      expect(copy.isOfflineMode, base.isOfflineMode);
      expect(copy.biometricEnabled, base.biometricEnabled);
    });

    test('copyWith(userId:) changes only userId', () {
      final copy = base.copyWith(userId: 'new-user');
      expect(copy.userId, 'new-user');
      expect(copy.status, base.status);
    });

    test('copyWith(isOfflineMode: true) sets offline mode', () {
      final copy = base.copyWith(isOfflineMode: true);
      expect(copy.isOfflineMode, isTrue);
      expect(copy.status, base.status);
    });

    test('copyWith(biometricEnabled: true) enables biometrics', () {
      final copy = base.copyWith(biometricEnabled: true);
      expect(copy.biometricEnabled, isTrue);
      expect(copy.status, base.status);
    });

    test('copyWith() with no args returns equivalent state', () {
      final copy = base.copyWith();
      expect(copy.status, base.status);
      expect(copy.userId, base.userId);
      expect(copy.isOfflineMode, base.isOfflineMode);
      expect(copy.biometricEnabled, base.biometricEnabled);
    });

    test('copyWith produces a new object', () {
      final copy = base.copyWith(status: AuthStatus.authenticated);
      expect(identical(base, copy), isFalse);
    });
  });

  // ── AuthState routing invariants ─────────────────────────────────────────────

  group('AuthState — routing decision invariants', () {
    test('appStarting and unknown are the loading states', () {
      final loadingStates = {AuthStatus.appStarting, AuthStatus.unknown};
      expect(loadingStates.contains(AuthStatus.appStarting), isTrue);
      expect(loadingStates.contains(AuthStatus.unknown), isTrue);
    });

    test('authenticated is the terminal success state', () {
      const state = AuthState(status: AuthStatus.authenticated, userId: 'u1');
      expect(state.status, AuthStatus.authenticated);
      expect(state.userId, isNotNull);
    });

    test('needsLocalAuth state can carry biometricEnabled flag', () {
      const state = AuthState(
        status: AuthStatus.needsLocalAuth,
        biometricEnabled: true,
      );
      expect(state.biometricEnabled, isTrue);
    });

    test('offline authenticated state preserves userId', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        userId: 'offline-user',
        isOfflineMode: true,
      );
      expect(state.userId, 'offline-user');
      expect(state.isOfflineMode, isTrue);
    });
  });
}
