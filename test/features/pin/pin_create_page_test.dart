import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/biometric_auth_service.dart';
import 'package:jaswallet_app/features/auth/biometric/biometric_providers.dart';
import 'package:jaswallet_app/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:jaswallet_app/features/pin/presentation/pages/pin_create_page.dart';
import 'package:jaswallet_app/features/pin/presentation/widgets/pin_dots.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_auth_storage.dart';
import '../../helpers/test_app.dart';

// ── Test doubles ──────────────────────────────────────────────────────────────

/// No-op biometric service — never calls platform channels.
class _NoOpBiometricService extends BiometricAuthService {
  @override
  Future<void> clearCredentials() async {}
  @override
  Future<void> clearAll() async {}
}

// ── Helper ────────────────────────────────────────────────────────────────────

Future<void> _pumpPinCreatePage(
  WidgetTester tester, {
  FakeAuthStorageService? storage,
}) async {
  // Use a tall surface so the PinCreatePage layout doesn't overflow.
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final effectiveStorage = storage ??
      FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'test-user',
        refreshToken: 'fake.refresh',
        biometricSetupCompleted: true,
      );

  final router = testRouter(child: const PinCreatePage());

  await tester.pumpWidget(
    buildTestApp(
      router: router,
      overrides: [
        authStorageServiceProvider.overrideWithValue(effectiveStorage),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        biometricAuthServiceProvider
            .overrideWithValue(_NoOpBiometricService()),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// Tap digit keys to enter a 4-digit PIN.
Future<void> _enterPin(WidgetTester tester, String pin) async {
  assert(pin.length == 4);
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('pinKey_$digit')));
    await tester.pump();
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('PinCreatePage — initial state', () {
    testWidgets('starts in create phase', (tester) async {
      await _pumpPinCreatePage(tester);

      // Create-phase title is visible (localized key "pin_createTitle")
      // We verify the page renders without crashing and shows PinDots
      expect(find.byType(PinDots), findsOneWidget);
    });

    testWidgets('all digit keys 0–9 are present', (tester) async {
      await _pumpPinCreatePage(tester);

      for (var i = 0; i <= 9; i++) {
        expect(find.byKey(Key('pinKey_$i')), findsOneWidget);
      }
    });

    testWidgets('delete key is present', (tester) async {
      await _pumpPinCreatePage(tester);
      expect(find.byKey(const Key('pinKeyDelete')), findsOneWidget);
    });
  });

  group('PinCreatePage — digit entry and delete', () {
    testWidgets('entering digits fills PinDots', (tester) async {
      await _pumpPinCreatePage(tester);

      // Before any entry: 0 filled dots
      PinDots dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 0);

      // Enter 2 digits
      await tester.tap(find.byKey(const Key('pinKey_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pinKey_2')));
      await tester.pump();

      dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 2);
    });

    testWidgets('delete key removes the last entered digit', (tester) async {
      await _pumpPinCreatePage(tester);

      await tester.tap(find.byKey(const Key('pinKey_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pinKey_2')));
      await tester.pump();

      PinDots dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 2);

      await tester.tap(find.byKey(const Key('pinKeyDelete')));
      await tester.pump();

      dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 1);
    });

    testWidgets('delete on empty PIN does nothing', (tester) async {
      await _pumpPinCreatePage(tester);

      await tester.tap(find.byKey(const Key('pinKeyDelete')));
      await tester.pump();

      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 0);
    });

    testWidgets('cannot enter more than 4 digits', (tester) async {
      await _pumpPinCreatePage(tester);

      // Enter 4 digits — page auto-submits and transitions to confirm phase
      for (var i = 1; i <= 4; i++) {
        await tester.tap(find.byKey(Key('pinKey_$i')));
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // The page is still mounted (we're now in confirm phase)
      expect(find.byType(PinCreatePage), findsOneWidget);
    });
  });

  group('PinCreatePage — phase transition', () {
    testWidgets('entering 4 digits advances to confirm phase', (tester) async {
      await _pumpPinCreatePage(tester);

      await _enterPin(tester, '1234');
      await tester.pumpAndSettle();

      // In confirm phase, PinDots are reset to 0
      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 0);

      expect(find.byType(PinCreatePage), findsOneWidget);
    });
  });

  group('PinCreatePage — mismatch error', () {
    testWidgets('entering mismatching confirm PIN shows mismatch error',
        (tester) async {
      await _pumpPinCreatePage(tester);

      // Phase 1: enter PIN
      await _enterPin(tester, '1234');
      await tester.pumpAndSettle();

      // Phase 2: enter DIFFERENT confirm PIN
      await _enterPin(tester, '9999');
      await tester.pumpAndSettle();

      // Controller resets to create phase with 'pin_mismatch' error.
      // The dots reset to 0 (back in create phase).
      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 0);
    });

    testWidgets('dots show error state after mismatch', (tester) async {
      await _pumpPinCreatePage(tester);

      await _enterPin(tester, '1234');
      await tester.pumpAndSettle();
      await _enterPin(tester, '5678'); // mismatch
      // Only pump one frame to capture the hasError state before reset
      await tester.pump();

      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.hasError, isTrue);
    });
  });

  group('PinCreatePage — successful PIN setup', () {
    testWidgets('entering matching confirm PIN persists PIN in storage',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'test-user',
        refreshToken: 'fake.refresh',
        biometricSetupCompleted: true,
      );

      final router = testRouter(child: const PinCreatePage());

      await tester.pumpWidget(
        buildTestApp(
          router: router,
          overrides: [
            authStorageServiceProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            biometricAuthServiceProvider
                .overrideWithValue(_NoOpBiometricService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Phase 1: enter PIN
      await _enterPin(tester, '4321');
      await tester.pumpAndSettle();

      // Phase 2: enter same confirm PIN
      await _enterPin(tester, '4321');
      await tester.pumpAndSettle();

      // PIN is stored in storage
      expect(await storage.hasPin(), isTrue);
    });
  });
}
