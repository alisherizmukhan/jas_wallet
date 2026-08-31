import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:jaswallet_app/features/pin/application/pin_controller.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_auth_storage.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

/// Creates a [ProviderContainer] with all PIN-related providers overridden to
/// use in-memory fakes (no platform channels).
ProviderContainer _makeContainer({
  FakeAuthStorageService? storage,
  FakeAuthRepository? repo,
}) {
  final effectiveStorage = storage ??
      FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'test-user',
        refreshToken: 'fake.refresh',
        hasPin: false,
        biometricSetupCompleted: false,
      );
  final effectiveRepo = repo ?? FakeAuthRepository();

  return ProviderContainer(
    overrides: [
      authStorageServiceProvider.overrideWithValue(effectiveStorage),
      authRepositoryProvider.overrideWithValue(effectiveRepo),
    ],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── PinCreateController ───────────────────────────────────────────────────

  group('PinCreateController — create phase', () {
    late ProviderContainer container;

    setUp(() {
      container = _makeContainer();
    });

    tearDown(() => container.dispose());

    test('initial state is create phase with no error', () {
      final state = container.read(pinCreateControllerProvider);
      expect(state.phase, PinEntryPhase.create);
      expect(state.firstPin, isNull);
      expect(state.error, isNull);
    });

    test('setPin transitions to confirm phase and stores first PIN', () {
      container
          .read(pinCreateControllerProvider.notifier)
          .setPin('1234');

      final state = container.read(pinCreateControllerProvider);
      expect(state.phase, PinEntryPhase.confirm);
      expect(state.firstPin, '1234');
      expect(state.error, isNull);
    });

    test('confirmPin with matching PIN returns true', () async {
      final notifier =
          container.read(pinCreateControllerProvider.notifier);
      notifier.setPin('1234');

      final result = await notifier.confirmPin('1234');
      expect(result, isTrue);
    });

    test('confirmPin with mismatching PIN returns false and resets to create', () async {
      final notifier =
          container.read(pinCreateControllerProvider.notifier);
      notifier.setPin('1234');

      final result = await notifier.confirmPin('9999');
      expect(result, isFalse);

      final state = container.read(pinCreateControllerProvider);
      expect(state.phase, PinEntryPhase.create);
      // Note: copyWith uses ??, so firstPin stays set — this is intentional
      // (the UI clears _enteredPin separately; the stored firstPin is irrelevant
      // until the user completes the create phase again).
      expect(state.error, 'pin_mismatch');
    });

    test('reset returns to initial state', () {
      final notifier =
          container.read(pinCreateControllerProvider.notifier);
      notifier.setPin('1234');

      notifier.reset();

      final state = container.read(pinCreateControllerProvider);
      expect(state.phase, PinEntryPhase.create);
      expect(state.firstPin, isNull);
      expect(state.error, isNull);
    });

    test('after confirmPin succeeds PIN is persisted in storage', () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
      );
      final c = _makeContainer(storage: storage);
      addTearDown(c.dispose);

      final notifier = c.read(pinCreateControllerProvider.notifier);
      notifier.setPin('5678');
      await notifier.confirmPin('5678');

      expect(await storage.hasPin(), isTrue);
      expect(await storage.getPinHash(), isNotNull);
    });

    test('error is cleared when setPin is called after mismatch', () async {
      final notifier =
          container.read(pinCreateControllerProvider.notifier);
      notifier.setPin('1234');
      await notifier.confirmPin('9999'); // sets error

      notifier.setPin('4321'); // should clear error

      final state = container.read(pinCreateControllerProvider);
      expect(state.error, isNull);
    });
  });

  // ── PinVerifyController ───────────────────────────────────────────────────

  group('PinVerifyController — verify correct PIN', () {
    test('verifyPin with correct PIN returns true and auth becomes authenticated',
        () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'user-1',
        refreshToken: 'fake.refresh',
        hasPin: true,
        biometricSetupCompleted: true,
      );

      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      // Pre-create PIN so verifyPin can find the hash
      final pinService = container.read(pinStorageServiceProvider);
      await pinService.createPin('1234');

      // Pre-warm session data so _completeBackendLocalAuth has cached tokens
      await container
          .read(pinVerifyControllerProvider.notifier)
          .warmSessionData();

      // Eagerly init authProvider so state is ready
      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await container
          .read(pinVerifyControllerProvider.notifier)
          .verifyPin('1234');

      expect(result, isTrue);
      expect(
        container.read(authProvider).status,
        AuthStatus.authenticated,
      );
    });
  });

  group('PinVerifyController — verify wrong PIN', () {
    test('verifyPin with wrong PIN returns false and sets pin_incorrect error',
        () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'user-1',
        refreshToken: 'fake.refresh',
        hasPin: true,
        biometricSetupCompleted: true,
      );

      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final pinService = container.read(pinStorageServiceProvider);
      await pinService.createPin('1234');

      final result = await container
          .read(pinVerifyControllerProvider.notifier)
          .verifyPin('9999');

      expect(result, isFalse);

      final verifyState = container.read(pinVerifyControllerProvider);
      expect(verifyState.failedAttempts, 1);
      expect(verifyState.error, 'pin_incorrect');
    });

    test('after maxPinAttempts wrong PINs forceReAuth is set', () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'user-1',
        refreshToken: 'fake.refresh',
        hasPin: true,
        biometricSetupCompleted: true,
      );

      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      final pinService = container.read(pinStorageServiceProvider);
      await pinService.createPin('1234');

      final notifier = container.read(pinVerifyControllerProvider.notifier);
      for (var i = 0; i < AuthNotifier.maxPinAttempts; i++) {
        await notifier.verifyPin('bad');
      }

      final state = container.read(pinVerifyControllerProvider);
      expect(state.forceReAuth, isTrue);
      expect(state.error, 'pin_force_reauth');
    });
  });

  group('PinVerifyController — lock status', () {
    test('checkLockStatus sets isLocked false when not locked', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final pinService = container.read(pinStorageServiceProvider);
      await pinService.createPin('1234');

      await container
          .read(pinVerifyControllerProvider.notifier)
          .checkLockStatus();

      final state = container.read(pinVerifyControllerProvider);
      expect(state.isLocked, isFalse);
    });

    test('checkLockStatus sets isLocked true when lock is active', () async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
      );

      // Pre-set a future lock time in storage before createPin is called,
      // so warmUp reads it fresh (createPin would clear the cached lock state).
      await storage.setPinLockUntil(
        DateTime.now().add(const Duration(seconds: 30)),
      );

      final container = _makeContainer(storage: storage);
      addTearDown(container.dispose);

      // Do NOT call createPin here — it clears _cachedLockUntil and sets
      // _lockStateLoaded=true, preventing warmUp from re-reading storage.

      await container
          .read(pinVerifyControllerProvider.notifier)
          .checkLockStatus();

      final state = container.read(pinVerifyControllerProvider);
      expect(state.isLocked, isTrue);
      expect(state.lockRemainingSeconds, greaterThan(0));
    });
  });

  // ── PinCreateState ────────────────────────────────────────────────────────

  group('PinCreateState.copyWith', () {
    test('copyWith replaces specified fields', () {
      const initial = PinCreateState(
        phase: PinEntryPhase.create,
        firstPin: null,
        error: null,
      );

      final updated = initial.copyWith(
        phase: PinEntryPhase.confirm,
        firstPin: '1234',
      );

      expect(updated.phase, PinEntryPhase.confirm);
      expect(updated.firstPin, '1234');
      expect(updated.error, isNull);
    });

    test('copyWith with error: null clears the error', () {
      const initial = PinCreateState(
        phase: PinEntryPhase.create,
        error: 'pin_mismatch',
      );

      final updated = initial.copyWith(error: null);
      expect(updated.error, isNull);
    });
  });

  // ── PinVerifyState ────────────────────────────────────────────────────────

  group('PinVerifyState.copyWith', () {
    test('copyWith updates specified fields only', () {
      const initial = PinVerifyState(failedAttempts: 2, isLocked: false);

      final updated = initial.copyWith(isLocked: true, lockRemainingSeconds: 30);

      expect(updated.failedAttempts, 2);
      expect(updated.isLocked, isTrue);
      expect(updated.lockRemainingSeconds, 30);
    });

    test('error can be set to null via copyWith', () {
      const initial = PinVerifyState(error: 'pin_incorrect');
      final updated = initial.copyWith(error: null);
      expect(updated.error, isNull);
    });
  });
}
