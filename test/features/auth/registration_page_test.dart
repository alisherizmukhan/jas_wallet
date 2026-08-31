import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/features/auth/data/repositories/auth_repository.dart';
import 'package:jaswallet_app/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:jaswallet_app/features/auth/registration/presentation/pages/registration_page.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_auth_storage.dart';
import '../../helpers/test_app.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Future<void> _pumpRegistrationPage(
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
    child: const RegistrationPage(),
    extraRoutes: {
      '/login': const Scaffold(body: Text('Login Page')),
      '/verification': const Scaffold(body: Text('Verification Page')),
      '/personal-data-consent':
          const Scaffold(body: Text('Personal Data Consent')),
    },
  );

  await tester.pumpWidget(
    buildTestApp(
      router: router,
      overrides: [
        authRepositoryProvider.overrideWithValue(effectiveRepo),
        authStorageServiceProvider.overrideWithValue(effectiveStorage),
        // userProvider needs storage too — use the same fake storage
      ],
    ),
  );
  await tester.pumpAndSettle();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('RegistrationPage — button state', () {
    testWidgets('register button is disabled when email is empty',
        (tester) async {
      await _pumpRegistrationPage(tester);

      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('registrationButton')))
            .onPressed,
        isNull,
      );
    });

    testWidgets(
        'register button is disabled with valid email but no consent checked',
        (tester) async {
      await _pumpRegistrationPage(tester);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')),
          'student@nu.edu.kz');
      await tester.pump();

      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('registrationButton')))
            .onPressed,
        isNull,
      );
    });

    testWidgets(
        'register button is disabled with consent checked but empty email',
        (tester) async {
      await _pumpRegistrationPage(tester);

      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();

      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('registrationButton')))
            .onPressed,
        isNull,
      );
    });

    testWidgets(
        'register button is enabled when valid @nu.edu.kz email and consent',
        (tester) async {
      await _pumpRegistrationPage(tester);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')),
          'student@nu.edu.kz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();

      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('registrationButton')))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('RegistrationPage — email validation', () {
    testWidgets('no error shown when field is empty', (tester) async {
      await _pumpRegistrationPage(tester);

      // Tap field to trigger validation then clear
      await tester.enterText(
          find.byKey(const Key('registrationEmailField')), '');
      await tester.pump();

      expect(find.text('Invalid email format'), findsNothing);
      expect(find.text('Only @nu.edu.kz emails are allowed'), findsNothing);
    });

    testWidgets('shows "Invalid email format" when no @ symbol',
        (tester) async {
      await _pumpRegistrationPage(tester);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')), 'notanemail');
      await tester.pump();

      expect(find.text('Invalid email format'), findsOneWidget);
    });

    testWidgets('shows "Only @nu.edu.kz emails are allowed" for other domains',
        (tester) async {
      await _pumpRegistrationPage(tester);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')), 'user@gmail.com');
      await tester.pump();

      expect(
          find.text('Only @nu.edu.kz emails are allowed'), findsOneWidget);
    });

    testWidgets('clears error when valid @nu.edu.kz email is entered',
        (tester) async {
      await _pumpRegistrationPage(tester);

      // First enter invalid
      await tester.enterText(
          find.byKey(const Key('registrationEmailField')), 'user@gmail.com');
      await tester.pump();
      expect(find.text('Only @nu.edu.kz emails are allowed'), findsOneWidget);

      // Then correct it
      await tester.enterText(
          find.byKey(const Key('registrationEmailField')), 'user@nu.edu.kz');
      await tester.pump();

      expect(find.text('Only @nu.edu.kz emails are allowed'), findsNothing);
      expect(find.text('Invalid email format'), findsNothing);
    });

    testWidgets('button disabled for non-nu.edu.kz domain even with consent',
        (tester) async {
      await _pumpRegistrationPage(tester);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')), 'user@gmail.com');
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();

      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('registrationButton')))
            .onPressed,
        isNull,
      );
    });
  });

  group('RegistrationPage — loading state', () {
    testWidgets('shows CircularProgressIndicator while sending OTP',
        (tester) async {
      final repo = _SlowSendOtpRepo();
      await _pumpRegistrationPage(tester, repo: repo);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')),
          'student@nu.edu.kz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('registrationButton')));
      await tester.pump(); // loading starts

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('RegistrationPage — navigation on success', () {
    testWidgets(
        'navigates to /login when email is already registered',
        (tester) async {
      final repo = FakeAuthRepository()
        ..sendOtpResult = FakeSendOtpResult.alreadyRegistered;
      await _pumpRegistrationPage(tester, repo: repo);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')),
          'existing@nu.edu.kz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('registrationButton')));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);

      // Drain the 4s toast auto-dismiss timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'navigates to /verification when OTP is sent for new email',
        (tester) async {
      final repo = FakeAuthRepository()
        ..sendOtpResult = FakeSendOtpResult.otpSent;
      await _pumpRegistrationPage(tester, repo: repo);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')),
          'new@nu.edu.kz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('registrationButton')));
      await tester.pumpAndSettle();

      expect(find.text('Verification Page'), findsOneWidget);
    });
  });

  group('RegistrationPage — error handling', () {
    testWidgets('shows error toast on network failure', (tester) async {
      final repo = FakeAuthRepository()
        ..sendOtpResult = FakeSendOtpResult.networkError;
      await _pumpRegistrationPage(tester, repo: repo);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')),
          'student@nu.edu.kz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('registrationButton')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text('Network error'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('shows rate-limit error toast on 429', (tester) async {
      final repo = FakeAuthRepository()
        ..sendOtpResult = FakeSendOtpResult.rateLimited;
      await _pumpRegistrationPage(tester, repo: repo);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')),
          'student@nu.edu.kz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('registrationButton')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(
        find.text('Too many requests. Please try again later.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('button re-enabled after network error', (tester) async {
      final repo = FakeAuthRepository()
        ..sendOtpResult = FakeSendOtpResult.networkError;
      await _pumpRegistrationPage(tester, repo: repo);

      await tester.enterText(
          find.byKey(const Key('registrationEmailField')),
          'student@nu.edu.kz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('registrationConsentCheckbox')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('registrationButton')));
      // Advance past the 10ms sendOtp delay so _isLoading becomes false.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('registrationButton')))
            .onPressed,
        isNotNull,
      );

      // Drain the 4s toast auto-dismiss timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('RegistrationPage — consent link', () {
    testWidgets(
        'tapping consent text navigates to /personal-data-consent',
        (tester) async {
      await _pumpRegistrationPage(tester);

      await tester.tap(find.text('I consent to data collection for service improvement'));
      await tester.pumpAndSettle();

      expect(find.text('Personal Data Consent'), findsOneWidget);
    });
  });
}

// ── Test doubles ──────────────────────────────────────────────────────────────

class _SlowSendOtpRepo extends FakeAuthRepository {
  @override
  Future<SendOtpResult> sendOtp(String email) {
    return Completer<SendOtpResult>().future;
  }
}
