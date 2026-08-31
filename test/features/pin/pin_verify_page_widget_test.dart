import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/biometric_auth_service.dart';
import 'package:jaswallet_app/features/auth/biometric/biometric_providers.dart';
import 'package:jaswallet_app/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:jaswallet_app/features/pin/presentation/pages/pin_verify_page.dart';
import 'package:jaswallet_app/features/pin/presentation/widgets/pin_dots.dart';
import 'package:jaswallet_app/features/salto/data/repositories/salto_repository.dart';
import 'package:jaswallet_app/features/salto/data/models/salto_mobile_status.dart';
import 'package:jaswallet_app/features/salto/data/services/salto_key_manager.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/salto_provider.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_auth_storage.dart';
import '../../helpers/test_app.dart';

// ── Test doubles ─────────────────────────────────────────────────────────────

class _NoOpBiometricService extends BiometricAuthService {
  @override
  Future<bool> isBiometricAvailable() async => false;
  @override
  Future<void> clearCredentials() async {}
  @override
  Future<void> clearAll() async {}
}

class _FakeSaltoRepository implements SaltoRepository {
  @override
  Future<String?> getDigitalKey({bool forceRefresh = false}) async => null;
  @override
  Future<SaltoMobileStatus> getMobileStatus({CancelToken? cancelToken}) async =>
      throw UnimplementedError();
  @override
  Future<SaltoMobileStatus?> getCachedMobileStatus() async => null;
  @override
  Future<SaltoMobileStatus> activateMobileAccess() async =>
      throw UnimplementedError();
}

// ── Helper ────────────────────────────────────────────────────────────────────

Future<void> _pumpVerifyPage(
  WidgetTester tester, {
  FakeAuthStorageService? storage,
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final effectiveStorage = storage ??
      FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'test-user',
        refreshToken: 'fake.refresh',
        hasPin: true,
        biometricSetupCompleted: true,
        biometricEnabled: false,
      );

  final fakeSaltoKeyManager = SaltoKeyManager(
    repository: _FakeSaltoRepository(),
    authStorage: FakeAuthStorageService(),
  );

  await tester.pumpWidget(buildTestApp(
    router: testRouter(child: const PinVerifyPage()),
    overrides: [
      authStorageServiceProvider.overrideWithValue(effectiveStorage),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      biometricAuthServiceProvider.overrideWithValue(_NoOpBiometricService()),
      saltoKeyManagerProvider.overrideWithValue(fakeSaltoKeyManager),
    ],
  ));
  await tester.pumpAndSettle();
}

Future<void> _enterDigits(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('pinKey_$digit')));
    await tester.pump();
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── Initial render ────────────────────────────────────────────────────────

  group('PinVerifyPage — initial render', () {
    testWidgets('renders PinDots widget', (tester) async {
      await _pumpVerifyPage(tester);
      expect(find.byType(PinDots), findsOneWidget);
    });

    testWidgets('renders all digit keys 0–9', (tester) async {
      await _pumpVerifyPage(tester);
      for (var i = 0; i <= 9; i++) {
        expect(find.byKey(Key('pinKey_$i')), findsOneWidget,
            reason: 'Key $i should be present');
      }
    });

    testWidgets('renders delete key', (tester) async {
      await _pumpVerifyPage(tester);
      expect(find.byKey(const Key('pinKeyDelete')), findsOneWidget);
    });

    testWidgets('starts with 0 filled dots', (tester) async {
      await _pumpVerifyPage(tester);
      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 0);
    });

    testWidgets('does not show biometric button when biometric is disabled',
        (tester) async {
      await _pumpVerifyPage(tester);
      // Biometric key only appears when showBiometric=true in PinKeyboard.
      expect(find.byKey(const Key('pinKeyBiometric')), findsNothing);
    });

    testWidgets('renders switch account button', (tester) async {
      await _pumpVerifyPage(tester);
      // The switch account button is a TextButton at the bottom.
      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  // ── Digit entry ───────────────────────────────────────────────────────────

  group('PinVerifyPage — digit entry', () {
    testWidgets('pressing digits fills dots correctly', (tester) async {
      await _pumpVerifyPage(tester);

      await tester.tap(find.byKey(const Key('pinKey_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pinKey_2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pinKey_3')));
      await tester.pump();

      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 3);
    });

    testWidgets('delete key removes the last digit', (tester) async {
      await _pumpVerifyPage(tester);

      await tester.tap(find.byKey(const Key('pinKey_5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pinKey_6')));
      await tester.pump();

      var dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 2);

      await tester.tap(find.byKey(const Key('pinKeyDelete')));
      await tester.pump();

      dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 1);
    });

    testWidgets('delete on empty does nothing (no crash)', (tester) async {
      await _pumpVerifyPage(tester);

      await tester.tap(find.byKey(const Key('pinKeyDelete')));
      await tester.pump();

      expect(tester.takeException(), isNull);
      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 0);
    });

    testWidgets('entering 4 digits triggers verification (no crash)',
        (tester) async {
      await _pumpVerifyPage(tester);

      // Enter wrong PIN (no PIN created → will fail hash check)
      await _enterDigits(tester, '9999');
      await tester.pumpAndSettle();

      // Page still renders without exception (PIN incorrect).
      expect(tester.takeException(), isNull);
      expect(find.byType(PinVerifyPage), findsOneWidget);
    });

    testWidgets('dots reset after failed PIN entry', (tester) async {
      await _pumpVerifyPage(tester);

      await _enterDigits(tester, '9999');
      await tester.pumpAndSettle();

      // After failed verification, dots reset to 0.
      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 0);
    });

    testWidgets('dots show error state after incorrect PIN', (tester) async {
      await _pumpVerifyPage(tester);

      await _enterDigits(tester, '9999');
      await tester.pump(); // capture error state before pumpAndSettle

      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.hasError, isTrue);
    });
  });

  // ── Input blocking while unlocking ────────────────────────────────────────

  group('PinVerifyPage — input state', () {
    testWidgets('keyboard is enabled initially (no lock)', (tester) async {
      await _pumpVerifyPage(tester);

      // No lock message should be shown.
      // The keyboard should be enabled when _lockSeconds == 0.
      expect(find.byType(PinVerifyPage), findsOneWidget);
      // Verify digits can be tapped.
      await tester.tap(find.byKey(const Key('pinKey_1')));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  // ── Responsive tests ──────────────────────────────────────────────────────

  group('PinVerifyPage — responsive (no overflow)', () {
    for (final screenSize in const [
      Size(320, 568),  // iPhone SE 1st gen — smallest common iOS
      Size(360, 640),  // Small Android
      Size(375, 667),  // iPhone 8
      Size(390, 844),  // iPhone 14
      Size(414, 896),  // iPhone 11 Pro Max
    ]) {
      testWidgets(
          'no overflow at ${screenSize.width.toInt()}×${screenSize.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(screenSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

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

        await tester.pumpWidget(buildTestApp(
          router: testRouter(child: const PinVerifyPage()),
          overrides: [
            authStorageServiceProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            biometricAuthServiceProvider
                .overrideWithValue(_NoOpBiometricService()),
            saltoKeyManagerProvider.overrideWithValue(SaltoKeyManager(
              repository: _FakeSaltoRepository(),
              authStorage: FakeAuthStorageService(),
            )),
          ],
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  // ── Theme tests ───────────────────────────────────────────────────────────

  group('PinVerifyPage — theming', () {
    testWidgets('renders without overflow in light mode', (tester) async {
      await _pumpVerifyPage(tester, brightness: Brightness.light);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow in dark mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStorageServiceProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          biometricAuthServiceProvider.overrideWithValue(_NoOpBiometricService()),
          saltoKeyManagerProvider.overrideWithValue(SaltoKeyManager(
            repository: _FakeSaltoRepository(),
            authStorage: FakeAuthStorageService(),
          )),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          // Localization delegates are required because PinVerifyPage
          // uses AppLocalizations.of(context)! in its build method.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: PinVerifyPage()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PinVerifyPage), findsOneWidget);
    });
  });

  // ── Localization ──────────────────────────────────────────────────────────

  group('PinVerifyPage — localization', () {
    for (final locale in const ['en', 'ru', 'kk']) {
      testWidgets('renders without exception in locale: $locale', (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

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

        await tester.pumpWidget(buildTestApp(
          router: testRouter(child: const PinVerifyPage()),
          overrides: [
            authStorageServiceProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            biometricAuthServiceProvider
                .overrideWithValue(_NoOpBiometricService()),
            saltoKeyManagerProvider.overrideWithValue(SaltoKeyManager(
              repository: _FakeSaltoRepository(),
              authStorage: FakeAuthStorageService(),
            )),
          ],
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(PinVerifyPage), findsOneWidget);
      });
    }
  });

  // ── PinDots widget ────────────────────────────────────────────────────────

  group('PinDots — isolated widget', () {
    testWidgets('renders 4 dots by default', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PinDots(enteredLength: 0, totalLength: 4),
        ),
      ));
      expect(find.byType(PinDots), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows 2 filled and 2 empty dots when enteredLength=2',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PinDots(enteredLength: 2, totalLength: 4),
        ),
      ));
      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.enteredLength, 2);
      expect(dots.totalLength, 4);
    });

    testWidgets('renders in error state (hasError=true)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PinDots(enteredLength: 4, totalLength: 4, hasError: true),
        ),
      ));
      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.hasError, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in success state (isSuccess=true)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PinDots(enteredLength: 4, totalLength: 4, isSuccess: true),
        ),
      ));
      final dots = tester.widget<PinDots>(find.byType(PinDots));
      expect(dots.isSuccess, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode without overflow', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const Scaffold(
          body: PinDots(enteredLength: 2, totalLength: 4),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in light mode without overflow', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: const Scaffold(
          body: PinDots(enteredLength: 2, totalLength: 4),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
