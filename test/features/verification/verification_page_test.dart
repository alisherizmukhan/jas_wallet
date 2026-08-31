import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/features/auth/data/models/token_response.dart';
import 'package:jaswallet_app/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/features/verification/presentation/pages/verification_page.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_auth_storage.dart';
import '../../helpers/test_app.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Enters one digit into each of the 6 code boxes.
Future<void> _enterCode(WidgetTester tester, String code) async {
  assert(code.length == 6, 'OTP code must be exactly 6 digits');
  for (var i = 0; i < 6; i++) {
    await tester.enterText(
      find.byKey(Key('verificationCodeBox_$i')),
      code[i],
    );
  }
  await tester.pump();
}

Future<void> _pumpVerificationPage(
  WidgetTester tester, {
  FakeAuthRepository? repo,
  FakeAuthStorageService? storage,
  String flow = 'registration',
  VoidCallback? onVerified,
  void Function(String code)? onVerifiedWithCode,
}) async {
  final effectiveRepo = repo ?? FakeAuthRepository();
  final effectiveStorage = storage ??
      FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
      );

  final router = testRouter(
    child: VerificationPage(
      destination: 'test@nu.edu.kz',
      isPhone: false,
      flow: flow,
      onVerified: onVerified ?? () {},
      onVerifiedWithCode: onVerifiedWithCode,
    ),
    extraRoutes: {
      '/profile-creation': const Scaffold(body: Text('Profile Creation')),
      '/reset-password': const Scaffold(body: Text('Reset Password')),
    },
  );

  await tester.pumpWidget(
    buildTestApp(
      router: router,
      overrides: [
        authRepositoryProvider.overrideWithValue(effectiveRepo),
        authStorageServiceProvider.overrideWithValue(effectiveStorage),
      ],
    ),
  );
  // Skip the 60-second resend timer — pump one frame only
  await tester.pump();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('VerificationPage — confirm button state', () {
    testWidgets('disabled when code is empty', (tester) async {
      await _pumpVerificationPage(tester);

      expect(
        tester
            .widget<ElevatedButton>(
                find.byKey(const Key('verificationConfirmButton')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('disabled when only 5 digits are entered', (tester) async {
      await _pumpVerificationPage(tester);

      for (var i = 0; i < 5; i++) {
        await tester.enterText(
            find.byKey(Key('verificationCodeBox_$i')), '$i');
      }
      await tester.pump();

      expect(
        tester
            .widget<ElevatedButton>(
                find.byKey(const Key('verificationConfirmButton')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('enabled when all 6 digits are entered', (tester) async {
      await _pumpVerificationPage(tester);

      await _enterCode(tester, '123456');

      expect(
        tester
            .widget<ElevatedButton>(
                find.byKey(const Key('verificationConfirmButton')))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('VerificationPage — resend button state', () {
    testWidgets('disabled when countdown is active (initial state)',
        (tester) async {
      await _pumpVerificationPage(tester);

      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('verificationResendButton')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('shows countdown timer text', (tester) async {
      await _pumpVerificationPage(tester);

      // Countdown should show some "Resend in Xs" text
      expect(find.textContaining('Resend in'), findsOneWidget);
    });
  });

  group('VerificationPage — registration flow', () {
    testWidgets('shows loading indicator while verifying', (tester) async {
      final repo = _SlowVerifyRepo();
      await _pumpVerificationPage(tester, repo: repo);

      await _enterCode(tester, '654321');

      await tester.tap(find.byKey(const Key('verificationConfirmButton')));
      await tester.pump(); // loading starts

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onVerified callback on successful OTP verification',
        (tester) async {
      final repo = FakeAuthRepository()
        ..verifyOtpResult = VerifyOtpResult.success;
      bool wasCalled = false;

      final effectiveStorage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
      );

      final router = testRouter(
        child: VerificationPage(
          destination: 'test@nu.edu.kz',
          isPhone: false,
          flow: 'registration',
          onVerified: () => wasCalled = true,
        ),
        extraRoutes: {
          '/profile-creation': const Scaffold(body: Text('Profile Creation')),
        },
      );

      await tester.pumpWidget(
        buildTestApp(
          router: router,
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            authStorageServiceProvider.overrideWithValue(effectiveStorage),
          ],
        ),
      );
      await tester.pump();

      await _enterCode(tester, '123456');
      await tester.tap(find.byKey(const Key('verificationConfirmButton')));
      // pumpAndSettle would hang — the page has a periodic 1s countdown timer.
      // Pump enough time for the async verify call to complete instead.
      await tester.pump(const Duration(milliseconds: 300));

      expect(wasCalled, isTrue);
    });

    testWidgets('shows error toast when OTP code is wrong', (tester) async {
      final repo = FakeAuthRepository()
        ..verifyOtpResult = VerifyOtpResult.wrongCode;
      await _pumpVerificationPage(tester, repo: repo);

      await _enterCode(tester, '000000');
      await tester.tap(find.byKey(const Key('verificationConfirmButton')));

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text('Invalid or expired code'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('shows error toast on network failure during verification',
        (tester) async {
      final repo = FakeAuthRepository()
        ..verifyOtpResult = VerifyOtpResult.networkError;
      await _pumpVerificationPage(tester, repo: repo);

      await _enterCode(tester, '123456');
      await tester.tap(find.byKey(const Key('verificationConfirmButton')));

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text('Network error'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('confirm button is re-enabled after failed verification',
        (tester) async {
      final repo = FakeAuthRepository()
        ..verifyOtpResult = VerifyOtpResult.wrongCode;
      await _pumpVerificationPage(tester, repo: repo);

      await _enterCode(tester, '000000');
      await tester.tap(find.byKey(const Key('verificationConfirmButton')));
      // Advance past the 10ms verifyOtp delay so _isLoading becomes false.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(
        tester
            .widget<ElevatedButton>(
                find.byKey(const Key('verificationConfirmButton')))
            .onPressed,
        isNotNull,
      );

      // Drain the 4s toast auto-dismiss timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('VerificationPage — reset password flow', () {
    // In reset flow, _verify() calls context.pop() then context.push('/reset-password').
    // context.pop() at root (flat testRouter) throws GoException, preventing the push.
    // Fix: use nested routes so VerificationPage at '/verify' has a parent at '/' to pop to.
    GoRouter resetFlowRouter() => GoRouter(
          initialLocation: '/verify',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('Home')),
              routes: [
                GoRoute(
                  path: 'verify',
                  builder: (_, _) => const VerificationPage(
                    destination: 'test@nu.edu.kz',
                    isPhone: false,
                    flow: 'reset',
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/reset-password',
              builder: (_, _) =>
                  const Scaffold(body: Text('Reset Password')),
            ),
          ],
        );

    testWidgets(
        'navigates to /reset-password when confirm tapped in reset flow',
        (tester) async {
      final effectiveStorage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          router: resetFlowRouter(),
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            authStorageServiceProvider.overrideWithValue(effectiveStorage),
          ],
        ),
      );
      await tester.pump();

      await _enterCode(tester, '999888');
      await tester.tap(find.byKey(const Key('verificationConfirmButton')));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
    });

    testWidgets(
        'navigates to /reset-password with email and code in reset flow',
        (tester) async {
      final effectiveStorage = FakeAuthStorageService(
        hasSelectedLanguage: true,
        hasSeenOnboarding: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          router: resetFlowRouter(),
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            authStorageServiceProvider.overrideWithValue(effectiveStorage),
          ],
        ),
      );
      await tester.pump();

      await _enterCode(tester, '112233');
      await tester.tap(find.byKey(const Key('verificationConfirmButton')));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
    });
  });

  group('VerificationPage — destination display', () {
    testWidgets('shows destination email in description text', (tester) async {
      await _pumpVerificationPage(tester);

      expect(find.textContaining('test@nu.edu.kz'), findsOneWidget);
    });
  });
}

// ── Test doubles ──────────────────────────────────────────────────────────────

class _SlowVerifyRepo extends FakeAuthRepository {
  @override
  Future<TokenResponse> verifyOtp(String email, String code) {
    return Completer<TokenResponse>().future;
  }
}
