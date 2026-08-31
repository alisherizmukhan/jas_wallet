/// Integration test: full auth flow from Welcome → Registration → Verification
/// → Login → auth state transitions.
///
/// Uses FakeAuthRepository (no real network) and FakeAuthStorageService
/// (no real Keystore/SharedPreferences) so tests run offline, headlessly,
/// and deterministically.
///
/// Run with:
///   flutter test integration_test/auth_flow_test.dart
///
/// Or on a connected device / emulator:
///   flutter test integration_test/auth_flow_test.dart --device-id DEVICE_ID
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/core/services/biometric_auth_service.dart';
import 'package:jaswallet_app/features/auth/biometric/biometric_providers.dart';
import 'package:jaswallet_app/features/auth/login/presentation/pages/login_page.dart';
import 'package:jaswallet_app/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:jaswallet_app/features/auth/registration/presentation/pages/registration_page.dart';
import 'package:jaswallet_app/features/auth/welcome/presentation/pages/welcome_page.dart';
import 'package:jaswallet_app/features/verification/presentation/pages/verification_page.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../test/helpers/fake_auth_repository.dart';
import '../test/helpers/fake_auth_storage.dart';

// ── Test doubles ──────────────────────────────────────────────────────────────

class _NoOpBiometricService extends BiometricAuthService {
  @override
  Future<void> clearCredentials() async {}
  @override
  Future<void> clearAll() async {}
  @override
  Future<bool> isDeviceSupported() async => false;
  @override
  Future<bool> canCheckBiometrics() async => false;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [];
}

// ── Helper ────────────────────────────────────────────────────────────────────

/// Minimal app wrapper: ProviderScope + MaterialApp.router with English locale.
/// Uses a standalone GoRouter (no auth-redirect logic) so page behavior can be
/// tested in isolation from the full routing state machine.
Widget _buildApp({
  required Widget initialPage,
  required List<Override> overrides,
  Map<String, WidgetBuilder> extraRoutes = const {},
}) {
  final routes = <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => initialPage,
    ),
    for (final entry in extraRoutes.entries)
      GoRoute(
        path: entry.key,
        builder: (context, state) => entry.value(context),
      ),
  ];

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: GoRouter(initialLocation: '/', routes: routes),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    ),
  );
}

List<Override> _defaultOverrides({
  FakeAuthRepository? repo,
  FakeAuthStorageService? storage,
}) {
  return [
    authRepositoryProvider.overrideWithValue(repo ?? FakeAuthRepository()),
    authStorageServiceProvider.overrideWithValue(
      storage ??
          FakeAuthStorageService(
            hasSelectedLanguage: true,
            hasSeenOnboarding: true,
          ),
    ),
    biometricAuthServiceProvider.overrideWithValue(_NoOpBiometricService()),
  ];
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Welcome page ───────────────────────────────────────────────────────

  group('Welcome page', () {
    testWidgets('shows Login and Register buttons', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          initialPage: const WelcomePage(),
          overrides: _defaultOverrides(),
          extraRoutes: {
            '/login': (_) => const Scaffold(body: Text('Login')),
            '/registration': (_) => const Scaffold(body: Text('Registration')),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('welcomeLoginButton')), findsOneWidget);
      expect(find.byKey(const Key('welcomeRegisterButton')), findsOneWidget);
    });

    testWidgets('tapping Login navigates to /login', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          initialPage: const WelcomePage(),
          overrides: _defaultOverrides(),
          extraRoutes: {
            '/login': (_) => const Scaffold(body: Text('Login Page')),
            '/registration': (_) =>
                const Scaffold(body: Text('Registration Page')),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('welcomeLoginButton')));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('tapping Register navigates to /registration', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          initialPage: const WelcomePage(),
          overrides: _defaultOverrides(),
          extraRoutes: {
            '/login': (_) => const Scaffold(body: Text('Login Page')),
            '/registration': (_) =>
                const Scaffold(body: Text('Registration Page')),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('welcomeRegisterButton')));
      await tester.pumpAndSettle();

      expect(find.text('Registration Page'), findsOneWidget);
    });
  });

  // ── Registration → Verification flow ──────────────────────────────────

  group('Registration → Verification flow', () {
    testWidgets(
        'valid email + consent → OTP sent → navigates to VerificationPage',
        (tester) async {
      final repo = FakeAuthRepository()
        ..sendOtpResult = FakeSendOtpResult.otpSent;

      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides(repo: repo),
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/registration',
              routes: [
                GoRoute(
                  path: '/registration',
                  builder: (context, state) => const RegistrationPage(),
                ),
                GoRoute(
                  path: '/verification',
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return VerificationPage(
                      destination:
                          extra?['destination'] as String? ?? 'test@nu.edu.kz',
                      isPhone: extra?['isPhone'] as bool? ?? false,
                      flow: extra?['flow'] as String? ?? 'registration',
                      onVerified: extra?['onVerified'] as VoidCallback?,
                    );
                  },
                ),
                GoRoute(
                  path: '/login',
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return LoginPage(
                      initialLogin: extra?['initialLogin'] as String?,
                    );
                  },
                ),
                GoRoute(
                  path: '/forgot-password',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Forgot Password')),
                ),
                GoRoute(
                  path: '/pin-create',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Pin Create')),
                ),
                GoRoute(
                  path: '/personal-data-consent',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Consent Page')),
                ),
              ],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')), 'new@nu.edu.kz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationButton')));
      await tester.pumpAndSettle();

      expect(find.byType(VerificationPage), findsOneWidget);
    });

    testWidgets(
        'already-registered email redirects to LoginPage with pre-filled email',
        (tester) async {
      final repo = FakeAuthRepository()
        ..sendOtpResult = FakeSendOtpResult.alreadyRegistered;

      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides(repo: repo),
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/registration',
              routes: [
                GoRoute(
                  path: '/registration',
                  builder: (context, state) => const RegistrationPage(),
                ),
                GoRoute(
                  path: '/login',
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    return LoginPage(
                      initialLogin: extra?['initialLogin'] as String?,
                    );
                  },
                ),
                GoRoute(
                  path: '/forgot-password',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Forgot Password')),
                ),
                GoRoute(
                  path: '/pin-create',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Pin Create')),
                ),
                GoRoute(
                  path: '/personal-data-consent',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Consent')),
                ),
              ],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')),
          'existing@nu.edu.kz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationButton')));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  // ── Login flow ─────────────────────────────────────────────────────────

  group('Login flow', () {
    testWidgets(
        'successful login transitions auth state to needsPinSetup',
        (tester) async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        isLoggedIn: false,
      );
      final repo = FakeAuthRepository()..loginResult = LoginResult.success;
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            authStorageServiceProvider.overrideWithValue(storage),
            biometricAuthServiceProvider
                .overrideWithValue(_NoOpBiometricService()),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/login',
              routes: [
                GoRoute(
                  path: '/login',
                  builder: (ctx, state) {
                    container = ProviderScope.containerOf(ctx);
                    return const LoginPage();
                  },
                ),
                GoRoute(
                  path: '/forgot-password',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Forgot Password')),
                ),
                GoRoute(
                  path: '/pin-create',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Pin Create')),
                ),
              ],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('loginUsernameField')), 'john_doe');
      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'secret123');
      await tester.pump();
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      expect(
        container.read(authProvider).status,
        AuthStatus.needsPinSetup,
      );
    });

    testWidgets('invalid credentials shows error toast', (tester) async {
      final repo = FakeAuthRepository()
        ..loginResult = LoginResult.invalidCredentials;

      await tester.pumpWidget(
        _buildApp(
          initialPage: const LoginPage(),
          overrides: _defaultOverrides(repo: repo),
          extraRoutes: {
            '/forgot-password': (_) =>
                const Scaffold(body: Text('Forgot Password')),
            '/pin-create': (_) => const Scaffold(body: Text('Pin Create')),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('loginUsernameField')), 'bad_user');
      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'bad_pass');
      await tester.pump();
      await tester.tap(find.byKey(const Key('loginButton')));

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });

  // ── OTP Verification flow ──────────────────────────────────────────────

  group('OTP Verification flow', () {
    testWidgets('correct 6-digit code calls onVerified callback', (tester) async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
      );
      final repo = FakeAuthRepository()
        ..verifyOtpResult = VerifyOtpResult.success;

      bool verified = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides(repo: repo, storage: storage),
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/verification',
              routes: [
                GoRoute(
                  path: '/verification',
                  builder: (context, state) => VerificationPage(
                    destination: 'test@nu.edu.kz',
                    isPhone: false,
                    flow: 'registration',
                    onVerified: () => verified = true,
                  ),
                ),
              ],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pump();

      for (var i = 0; i < 6; i++) {
        await tester.enterText(
            find.byKey(Key('verificationCodeBox_$i')), '$i');
      }
      await tester.pump();
      await tester.tap(find.byKey(const Key('verificationConfirmButton')));
      await tester.pumpAndSettle();

      expect(verified, isTrue);
    });

    testWidgets('wrong OTP code shows error toast', (tester) async {
      final repo = FakeAuthRepository()
        ..verifyOtpResult = VerifyOtpResult.wrongCode;

      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides(repo: repo),
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/verification',
              routes: [
                GoRoute(
                  path: '/verification',
                  builder: (context, state) => const VerificationPage(
                    destination: 'test@nu.edu.kz',
                    isPhone: false,
                    flow: 'registration',
                  ),
                ),
              ],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pump();

      for (var i = 0; i < 6; i++) {
        await tester.enterText(
            find.byKey(Key('verificationCodeBox_$i')), '0');
      }
      await tester.pump();
      await tester.tap(find.byKey(const Key('verificationConfirmButton')));

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text('Invalid or expired code'), findsOneWidget);
    });

    testWidgets(
        'reset flow navigates to /reset-password on confirm',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides(),
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/verification',
              routes: [
                GoRoute(
                  path: '/verification',
                  builder: (context, state) => const VerificationPage(
                    destination: 'test@nu.edu.kz',
                    isPhone: false,
                    flow: 'reset',
                  ),
                ),
                GoRoute(
                  path: '/reset-password',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Reset Password')),
                ),
              ],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pump();

      for (var i = 0; i < 6; i++) {
        await tester.enterText(
            find.byKey(Key('verificationCodeBox_$i')), '1');
      }
      await tester.pump();
      await tester.tap(find.byKey(const Key('verificationConfirmButton')));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
    });
  });
}
