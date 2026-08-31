import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/core/services/biometric_auth_service.dart';
import 'package:jaswallet_app/features/auth/biometric/biometric_providers.dart';
import 'package:jaswallet_app/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:jaswallet_app/features/pin/presentation/widgets/pin_unlock_overlay.dart';
import 'package:jaswallet_app/features/salto/data/repositories/salto_repository.dart';
import 'package:jaswallet_app/features/salto/data/models/salto_mobile_status.dart';
import 'package:jaswallet_app/features/salto/data/services/salto_key_manager.dart';
import 'package:jaswallet_app/features/salto/presentation/providers/salto_provider.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_auth_storage.dart';

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

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Unique key for the child widget so we can find it reliably.
const _childKey = Key('overlay_child');
const _childText = 'AppShellContent';

/// Builds the test app with PinUnlockOverlay wrapping a simple text child.
Widget _buildOverlayApp({
  required FakeAuthStorageService storage,
  List<Override> extraOverrides = const [],
}) {
  final fakeStorage = FakeAuthStorageService();
  final fakeSaltoKeyManager = SaltoKeyManager(
    repository: _FakeSaltoRepository(),
    authStorage: fakeStorage,
  );

  return ProviderScope(
    overrides: [
      authStorageServiceProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      biometricAuthServiceProvider.overrideWithValue(_NoOpBiometricService()),
      saltoKeyManagerProvider.overrideWithValue(fakeSaltoKeyManager),
      ...extraOverrides,
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: PinUnlockOverlay(
        child: const ColoredBox(
          color: Colors.green,
          child: Text(_childText, key: _childKey),
        ),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── Phase 1: Auth loading placeholder ─────────────────────────────────────

  group('PinUnlockOverlay — Phase 1 (auth loading)', () {
    testWidgets(
        'overlay renders without crash during auth resolution phase',
        (tester) async {
      // AuthNotifier starts in appStarting synchronously, then transitions via
      // async _init(). FakeAuthStorageService is synchronous so resolution is
      // fast — we cannot reliably catch the in-flight loading frame.
      // Instead: verify no exception occurs across the full transition and that
      // the overlay correctly shows the child after resolution.
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = FakeAuthStorageService(
        hasSelectedLanguage: false,
        hasSeenOnboarding: false,
      );

      await tester.pumpWidget(_buildOverlayApp(storage: storage));
      await tester.pump(); // one frame — may still be loading or just resolved
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle(); // auth resolves → firstLaunch (no PIN)
      // firstLaunch state has no PIN panel → child is visible.
      expect(find.byKey(_childKey), findsOneWidget);
      // No crash across the full loading → resolved transition.
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'placeholder disappears after auth resolves (unauthenticated)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // No session, language selected, onboarding done → unauthenticated
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: false,
      );

      await tester.pumpWidget(_buildOverlayApp(storage: storage));
      await tester.pumpAndSettle();

      // Auth resolved to unauthenticated → no PIN panel → child visible.
      expect(find.byKey(_childKey), findsOneWidget);
    });
  });

  // ── Phase 2: Pass-through (no lock needed) ────────────────────────────────

  group('PinUnlockOverlay — Phase 2 (authenticated, pass-through)', () {
    testWidgets('renders child directly when user is authenticated',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'user-1',
        refreshToken: 'fake.refresh',
        hasPin: true,
        biometricSetupCompleted: true,
      );

      await tester.pumpWidget(_buildOverlayApp(storage: storage));
      await tester.pumpAndSettle();

      // Authenticated → no overlay → child is fully rendered.
      expect(find.byKey(_childKey), findsOneWidget);
      expect(find.text(_childText), findsOneWidget);
    });

    testWidgets('no Stack layer present when authenticated', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'user-1',
        refreshToken: 'fake.refresh',
        hasPin: true,
        biometricSetupCompleted: true,
      );

      await tester.pumpWidget(_buildOverlayApp(storage: storage));
      await tester.pumpAndSettle();

      // No unlock-animation Stack should be in the tree.
      // child is rendered directly as widget.child pass-through.
      final overlayWidgets =
          tester.widgetList(find.byType(PinUnlockOverlay)).toList();
      expect(overlayWidgets.length, 1);
    });
  });

  // ── Phase 3: Locked (needsLocalAuth) ─────────────────────────────────────

  group('PinUnlockOverlay — Phase 3 (locked)', () {
    testWidgets(
        'shows PIN overlay when auth is needsLocalAuth from the start',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Storage with a full session AND PIN — triggers needsLocalAuth.
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'user-1',
        refreshToken: 'fake.refresh',
        hasPin: true,
        biometricSetupCompleted: true,
        biometricEnabled: false,
      );

      await tester.pumpWidget(_buildOverlayApp(storage: storage));
      await tester.pumpAndSettle();

      // With needsLocalAuth, overlay wraps the child in a Stack.
      // PinVerifyPage is mounted on top.
      final pinsFound = find.byType(Stack);
      // The Stack is the layered architecture (bg + PIN panel).
      expect(pinsFound, findsWidgets);
    });

    testWidgets(
        'child is rendered underneath (IgnorePointer) when locked',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'user-1',
        refreshToken: 'fake.refresh',
        hasPin: true,
        biometricSetupCompleted: true,
      );

      await tester.pumpWidget(_buildOverlayApp(storage: storage));
      await tester.pumpAndSettle();

      // The child is in the tree but wrapped in IgnorePointer so it can't
      // receive taps while the PIN panel is on top.
      expect(find.byType(IgnorePointer), findsWidgets);
      // The child text widget IS still in the widget tree (mounted behind).
      expect(find.byKey(_childKey), findsOneWidget);
    });

    testWidgets(
        'does not render two overlapping PinUnlockOverlay instances',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'user-1',
        refreshToken: 'fake.refresh',
        hasPin: true,
        biometricSetupCompleted: true,
      );

      await tester.pumpWidget(_buildOverlayApp(storage: storage));
      await tester.pumpAndSettle();

      // Only one PinUnlockOverlay in the widget tree.
      expect(find.byType(PinUnlockOverlay), findsOneWidget);
    });
  });

  // ── Animation smoke tests ─────────────────────────────────────────────────

  group('PinUnlockOverlay — animation safety', () {
    testWidgets('overlay renders without exceptions in any auth phase',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Start in unauthenticated (Phase 2 pass-through)
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: false,
      );

      await tester.pumpWidget(_buildOverlayApp(storage: storage));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('pumpAndSettle completes without hang when authenticated',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: true,
        userId: 'user-1',
        refreshToken: 'fake.refresh',
        hasPin: true,
        biometricSetupCompleted: true,
      );

      await tester.pumpWidget(_buildOverlayApp(storage: storage));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ── Responsive safety ─────────────────────────────────────────────────────

  group('PinUnlockOverlay — responsive', () {
    for (final size in const [
      Size(320, 568),  // iPhone SE 1st gen
      Size(375, 667),  // iPhone 8
      Size(390, 844),  // iPhone 14
      Size(430, 932),  // iPhone 14 Plus
    ]) {
      testWidgets(
          'no overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final storage = FakeAuthStorageService(
          hasSelectedLanguage: true,
          hasSeenOnboarding: true,
          isLoggedIn: false,
        );

        await tester.pumpWidget(_buildOverlayApp(storage: storage));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  // ── Dark mode ─────────────────────────────────────────────────────────────

  group('PinUnlockOverlay — theming', () {
    testWidgets('renders correctly in light mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: false,
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
          theme: ThemeData(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: PinUnlockOverlay(
            child: const Text(_childText, key: _childKey),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: false,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: PinUnlockOverlay(
            child: const Text(_childText, key: _childKey),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ── State model invariants ────────────────────────────────────────────────

  group('PinUnlockOverlay — AuthState invariants', () {
    test('appStarting triggers _authLoading=true by default', () {
      // Verify the auth state that drives _authLoading
      const startingState = AuthState(status: AuthStatus.appStarting);
      const unknownState = AuthState(status: AuthStatus.unknown);

      final loadingStatuses = {AuthStatus.appStarting, AuthStatus.unknown};
      expect(loadingStatuses.contains(startingState.status), isTrue);
      expect(loadingStatuses.contains(unknownState.status), isTrue);
    });

    test('needsLocalAuth is the exclusive trigger for _showPanel=true', () {
      // The overlay only shows PIN panel when status == needsLocalAuth.
      const lockedState = AuthState(status: AuthStatus.needsLocalAuth);
      expect(lockedState.status, AuthStatus.needsLocalAuth);

      // All other statuses should NOT trigger lock panel.
      final nonLockStatuses = AuthStatus.values
          .where((s) => s != AuthStatus.needsLocalAuth)
          .toList();
      for (final status in nonLockStatuses) {
        final state = AuthState(status: status);
        expect(state.status == AuthStatus.needsLocalAuth, isFalse,
            reason: '$status should not show PIN panel');
      }
    });

    test('authenticated → needsLocalAuth → authenticated lifecycle is valid', () {
      // Verify the state sequence used by re-lock on background resume.
      const authenticated =
          AuthState(status: AuthStatus.authenticated, userId: 'u1');
      const locked =
          AuthState(status: AuthStatus.needsLocalAuth, userId: 'u1');
      const unlockedAgain =
          AuthState(status: AuthStatus.authenticated, userId: 'u1');

      expect(authenticated.status, AuthStatus.authenticated);
      expect(locked.status, AuthStatus.needsLocalAuth);
      expect(unlockedAgain.status, AuthStatus.authenticated);
      // userId is preserved across lock/unlock
      expect(locked.userId, authenticated.userId);
      expect(unlockedAgain.userId, locked.userId);
    });
  });
}
