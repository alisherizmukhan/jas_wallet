import 'package:jaswallet_app/features/auth/data/models/token_response.dart';
import 'package:jaswallet_app/features/auth/data/repositories/auth_repository.dart';

/// Configurable fake AuthRepository for widget and unit tests.
/// No real network calls are made — all responses are deterministic.
class FakeAuthRepository implements AuthRepository {
  static const _fakeAccessToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0LXVzZXItaWQifQ.fake';
  static const _fakeRefreshToken = 'fake.refresh.token';

  // ── Configurable behaviors ───────────────────────────────────────────
  LoginResult loginResult = LoginResult.success;
  FakeSendOtpResult sendOtpResult = FakeSendOtpResult.otpSent;
  VerifyOtpResult verifyOtpResult = VerifyOtpResult.success;
  ForgotPasswordResult forgotPasswordResult = ForgotPasswordResult.success;

  // ── Login ─────────────────────────────────────────────────────────────

  @override
  Future<TokenResponse> login(String login, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return switch (loginResult) {
      LoginResult.success => const TokenResponse(
          accessToken: _fakeAccessToken,
          refreshToken: _fakeRefreshToken,
        ),
      LoginResult.invalidCredentials =>
        throw AuthException('Invalid credentials', statusCode: 401),
      LoginResult.networkError => throw AuthException('Network error'),
      LoginResult.rateLimited => throw AuthException(
          'Too many requests. Please try again later.',
          statusCode: 429,
        ),
    };
  }

  // ── OTP ───────────────────────────────────────────────────────────────

  @override
  Future<SendOtpResult> sendOtp(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return switch (sendOtpResult) {
      FakeSendOtpResult.otpSent => const SendOtpResult(
          status: SendOtpStatus.otpSent,
          message: 'Code sent',
        ),
      FakeSendOtpResult.alreadyRegistered => const SendOtpResult(
          status: SendOtpStatus.alreadyRegistered,
          message: 'Already registered',
        ),
      FakeSendOtpResult.networkError => throw AuthException('Network error'),
      FakeSendOtpResult.rateLimited => throw AuthException(
          'Too many requests. Please try again later.',
          statusCode: 429,
        ),
    };
  }

  @override
  Future<TokenResponse> verifyOtp(String email, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return switch (verifyOtpResult) {
      VerifyOtpResult.success => const TokenResponse(
          accessToken: _fakeAccessToken,
          refreshToken: _fakeRefreshToken,
        ),
      VerifyOtpResult.wrongCode =>
        throw AuthException('Invalid or expired code', statusCode: 400),
      VerifyOtpResult.networkError => throw AuthException('Network error'),
    };
  }

  // ── Forgot / Reset password ───────────────────────────────────────────

  @override
  Future<void> forgotPassword(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (forgotPasswordResult == ForgotPasswordResult.networkError) {
      throw AuthException('Network error');
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {}

  // ── Profile / Lookup ──────────────────────────────────────────────────

  @override
  Future<String> completeProfile({
    required String firstName,
    required String lastName,
    required String nuStudentId,
    required String username,
    required String password,
    String? phone,
    String? consentVersion,
  }) async =>
      'fake-user-id-uuid';

  @override
  Future<TokenResponse> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async =>
      const TokenResponse(
        accessToken: _fakeAccessToken,
        refreshToken: _fakeRefreshToken,
      );

  /// When true, the fake reports looked-up student IDs as already registered.
  bool studentIdAlreadyRegistered = false;

  @override
  Future<StudentIdLookupResult> lookupStudentId(String studentId) async {
    return StudentIdLookupResult(
      studentId: '20220001',
      firstName: 'Test',
      lastName: 'User',
      fullName: 'Test User',
      source: 'fake',
      alreadyRegistered: studentIdAlreadyRegistered,
    );
  }

  /// Set of usernames the fake should report as already taken.
  Set<String> takenUsernames = {};

  @override
  Future<UsernameAvailability> checkUsernameAvailable(String username) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final normalized = username.trim().toLowerCase();
    final valid = RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(normalized);
    return UsernameAvailability(
      username: normalized,
      valid: valid,
      available: valid && !takenUsernames.contains(normalized),
    );
  }

  // ── Token / Session ───────────────────────────────────────────────────

  @override
  Future<void> logout() async {}

  @override
  Future<TokenResponse> refreshToken(String refreshToken) async {
    return const TokenResponse(
      accessToken: _fakeAccessToken,
      refreshToken: _fakeRefreshToken,
    );
  }
}

// ── Result enums ──────────────────────────────────────────────────────────

enum LoginResult { success, invalidCredentials, networkError, rateLimited }

enum FakeSendOtpResult { otpSent, alreadyRegistered, networkError, rateLimited }

enum VerifyOtpResult { success, wrongCode, networkError }

enum ForgotPasswordResult { success, networkError }
