import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/core/services/biometric_auth_service.dart';
import 'package:jaswallet_app/features/auth/biometric/biometric_providers.dart';
import 'package:jaswallet_app/features/auth/data/models/token_response.dart';
import 'package:jaswallet_app/features/auth/login/presentation/pages/login_page.dart';
import 'package:jaswallet_app/features/auth/presentation/providers/auth_repository_provider.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_auth_storage.dart';
import '../../helpers/test_app.dart';

// ── Test doubles ──────────────────────────────────────────────────────────────

/// BiometricAuthService that never calls platform channels.
class _NoOpBiometricService extends BiometricAuthService {
  @override
  Future<void> clearCredentials() async {}
  @override
  Future<void> clearAll() async {}
}

/// AuthRepository whose login never completes.
/// Uses Completer to avoid leaving a pending Timer in the fakeAsync zone.
class _NeverResolvingRepo extends FakeAuthRepository {
  @override
  Future<TokenResponse> login(String login, String password) {
    return Completer<TokenResponse>().future;
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

Map<String, Widget> _defaultExtraRoutes() => {
      '/forgot-password': const Scaffold(body: Text('Forgot Password')),
      '/pin-create': const Scaffold(body: Text('Pin Create')),
      '/pin-verify': const Scaffold(body: Text('Pin Verify')),
    };

Future<void> _pumpLoginPage(
  WidgetTester tester, {
  FakeAuthRepository? repo,
  FakeAuthStorageService? storage,
}) async {
  final effectiveRepo = repo ?? FakeAuthRepository();
  final effectiveStorage = storage ??
      FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
      );

  final router = testRouter(
    child: const LoginPage(),
    extraRoutes: _defaultExtraRoutes(),
  );

  await tester.pumpWidget(
    buildTestApp(
      router: router,
      overrides: [
        authRepositoryProvider.overrideWithValue(effectiveRepo),
        authStorageServiceProvider.overrideWithValue(effectiveStorage),
        biometricAuthServiceProvider
            .overrideWithValue(_NoOpBiometricService()),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('LoginPage — button state', () {
    testWidgets('disabled when both fields are empty', (tester) async {
      await _pumpLoginPage(tester);

      expect(
        tester.widget<ElevatedButton>(find.byKey(const Key('loginButton'))).onPressed,
        isNull,
      );
    });

    testWidgets('disabled when only username is filled', (tester) async {
      await _pumpLoginPage(tester);

      await tester.enterText(
          find.byKey(const Key('loginUsernameField')), 'john_doe');
      await tester.pump();

      expect(
        tester.widget<ElevatedButton>(find.byKey(const Key('loginButton'))).onPressed,
        isNull,
      );
    });

    testWidgets('disabled when only password is filled', (tester) async {
      await _pumpLoginPage(tester);

      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'secret123');
      await tester.pump();

      expect(
        tester.widget<ElevatedButton>(find.byKey(const Key('loginButton'))).onPressed,
        isNull,
      );
    });

    testWidgets('enabled when both fields are filled', (tester) async {
      await _pumpLoginPage(tester);

      await tester.enterText(
          find.byKey(const Key('loginUsernameField')), 'john_doe');
      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'secret123');
      await tester.pump();

      expect(
        tester.widget<ElevatedButton>(find.byKey(const Key('loginButton'))).onPressed,
        isNotNull,
      );
    });
  });

  group('LoginPage — loading state', () {
    testWidgets('shows CircularProgressIndicator while request is in-flight',
        (tester) async {
      await _pumpLoginPage(tester, repo: _NeverResolvingRepo());

      await tester.enterText(
          find.byKey(const Key('loginUsernameField')), 'john_doe');
      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'secret123');
      await tester.pump();

      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump(); // one frame — loading starts, async call not yet done

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('button is disabled while loading', (tester) async {
      await _pumpLoginPage(tester, repo: _NeverResolvingRepo());

      await tester.enterText(
          find.byKey(const Key('loginUsernameField')), 'john_doe');
      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'secret123');
      await tester.pump();

      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump();

      expect(
        tester.widget<ElevatedButton>(find.byKey(const Key('loginButton'))).onPressed,
        isNull,
      );
    });
  });

  group('LoginPage — error handling', () {
    testWidgets('shows "Invalid credentials" toast on 401', (tester) async {
      final repo = FakeAuthRepository()
        ..loginResult = LoginResult.invalidCredentials;
      await _pumpLoginPage(tester, repo: repo);

      await tester.enterText(
          find.byKey(const Key('loginUsernameField')), 'wrong');
      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'wrong');
      await tester.pump();
      await tester.tap(find.byKey(const Key('loginButton')));

      // pump past the 10ms fake delay + 100ms toast delay
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text('Invalid credentials'), findsOneWidget);

      // Drain the 4s auto-dismiss timer to avoid "Timer still pending" and
      // reset ToastManager static state for subsequent tests.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('shows "Network error" toast on connection failure',
        (tester) async {
      final repo = FakeAuthRepository()..loginResult = LoginResult.networkError;
      await _pumpLoginPage(tester, repo: repo);

      await tester.enterText(
          find.byKey(const Key('loginUsernameField')), 'john_doe');
      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'secret123');
      await tester.pump();
      await tester.tap(find.byKey(const Key('loginButton')));

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text('Network error'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('shows rate-limit toast on 429', (tester) async {
      final repo = FakeAuthRepository()..loginResult = LoginResult.rateLimited;
      await _pumpLoginPage(tester, repo: repo);

      await tester.enterText(
          find.byKey(const Key('loginUsernameField')), 'john_doe');
      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'secret123');
      await tester.pump();
      await tester.tap(find.byKey(const Key('loginButton')));

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(
        find.text('Too many requests. Please try again later.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('button re-enabled after failed login', (tester) async {
      final repo = FakeAuthRepository()
        ..loginResult = LoginResult.invalidCredentials;
      await _pumpLoginPage(tester, repo: repo);

      await tester.enterText(
          find.byKey(const Key('loginUsernameField')), 'john_doe');
      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'wrong');
      await tester.pump();
      await tester.tap(find.byKey(const Key('loginButton')));

      // Advance past the 10ms login delay so _isLoading becomes false.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(
        tester.widget<ElevatedButton>(find.byKey(const Key('loginButton'))).onPressed,
        isNotNull,
      );

      // Drain the 4s auto-dismiss toast timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('LoginPage — password visibility toggle', () {
    testWidgets('password is obscured by default', (tester) async {
      await _pumpLoginPage(tester);

      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'mypassword');
      await tester.pump();

      final field = tester.widget<TextField>(
          find.byKey(const Key('loginPasswordField')));
      expect(field.obscureText, isTrue);
    });

    testWidgets('tapping toggle un-obscures the password', (tester) async {
      await _pumpLoginPage(tester);

      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'mypassword');
      await tester.pump();
      await tester.tap(find.byKey(const Key('loginPasswordToggle')));
      await tester.pump();

      final field = tester.widget<TextField>(
          find.byKey(const Key('loginPasswordField')));
      expect(field.obscureText, isFalse);
    });

    testWidgets('tapping toggle twice re-obscures the password',
        (tester) async {
      await _pumpLoginPage(tester);

      await tester.enterText(
          find.byKey(const Key('loginPasswordField')), 'mypassword');
      await tester.pump();
      await tester.tap(find.byKey(const Key('loginPasswordToggle')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('loginPasswordToggle')));
      await tester.pump();

      final field = tester.widget<TextField>(
          find.byKey(const Key('loginPasswordField')));
      expect(field.obscureText, isTrue);
    });
  });

  group('LoginPage — navigation', () {
    testWidgets('"Forgot Password?" link navigates to /forgot-password',
        (tester) async {
      await _pumpLoginPage(tester);

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password'), findsOneWidget);
    });

    testWidgets(
        'auth state becomes needsPinSetup after successful login (no prior PIN)',
        (tester) async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
      );
      late ProviderContainer container;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Consumer(
              builder: (ctx, ref, child) {
                container = ProviderScope.containerOf(ctx);
                return const LoginPage();
              },
            ),
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
      );

      await tester.pumpWidget(
        buildTestApp(
          router: router,
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            authStorageServiceProvider.overrideWithValue(storage),
            biometricAuthServiceProvider
                .overrideWithValue(_NoOpBiometricService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Eagerly initialize authProvider so _init() completes before login()
      // is called. Without this, _init() races with login() and may read
      // storage after saveSession() has been called.
      container.read(authProvider);
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

    testWidgets(
        'auth state becomes authenticated after successful login with existing PIN',
        (tester) async {
      final storage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
        hasPin: true,
        biometricSetupCompleted: true,
      );
      late ProviderContainer container;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Consumer(
              builder: (ctx, ref, child) {
                container = ProviderScope.containerOf(ctx);
                return const LoginPage();
              },
            ),
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
      );

      await tester.pumpWidget(
        buildTestApp(
          router: router,
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            authStorageServiceProvider.overrideWithValue(storage),
            biometricAuthServiceProvider
                .overrideWithValue(_NoOpBiometricService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Eagerly initialize authProvider so _init() completes before login().
      container.read(authProvider);
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
        AuthStatus.authenticated,
      );
    });
  });
}
