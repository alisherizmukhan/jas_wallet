import '../models/token_response.dart';

/// Current version of the personal-data consent text shown at registration.
/// Bump this whenever the consent wording changes so the backend audit trail
/// can record exactly which version a user accepted.
const String kPersonalDataConsentVersion = '1.0';

enum SendOtpStatus { otpSent, alreadyRegistered }

class SendOtpResult {
  const SendOtpResult({
    required this.status,
    required this.message,
  });

  final SendOtpStatus status;
  final String message;

  bool get alreadyRegistered => status == SendOtpStatus.alreadyRegistered;
}

/// Result of a username availability check.
class UsernameAvailability {
  const UsernameAvailability({
    required this.username,
    required this.valid,
    required this.available,
  });

  /// Normalized (lowercased / trimmed) username the server evaluated.
  final String username;

  /// Whether the username matches the allowed format (3-30, a-z 0-9 _).
  final bool valid;

  /// Whether the username is free to use.
  final bool available;
}

class StudentIdLookupResult {
  const StudentIdLookupResult({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.source,
    this.alreadyRegistered = false,
    this.schoolCode,
    this.isNufyp = false,
  });

  final String studentId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String source;

  /// Whether this student ID is already tied to another registered account.
  final bool alreadyRegistered;

  /// Orientation Week school derived from the SALTO directory
  /// (SSH/SEDS/…/NUFYP), or null when the directory doesn't know.
  final String? schoolCode;
  final bool isNufyp;
}

/// Repository for authentication API calls.
abstract class AuthRepository {
  /// Send OTP to email (@nu.edu.kz only).
  /// Throws [AuthException] on rate limit (429) or other errors.
  Future<SendOtpResult> sendOtp(String email);

  /// Verify OTP and return tokens.
  /// [isNewUser] indicates if this is first-time registration (profile not yet completed).
  Future<TokenResponse> verifyOtp(String email, String code);

  /// Login with username/email and password.
  Future<TokenResponse> login(String login, String password);

  /// Complete profile after OTP registration (requires valid access token).
  /// Returns the student ID (UUID string) for session.
  ///
  /// [consentVersion] records which version of the personal-data consent the
  /// user accepted during registration (persisted server-side for audit).
  Future<String> completeProfile({
    required String firstName,
    required String lastName,
    required String nuStudentId,
    required String username,
    required String password,
    String? phone,
    String? consentVersion,
  });

  /// Resolve a student's first and last name from the university directory.
  Future<StudentIdLookupResult> lookupStudentId(String studentId);

  /// Check whether a username is correctly formatted and not yet taken.
  /// Requires a valid access token (used during registration / profile edit).
  Future<UsernameAvailability> checkUsernameAvailable(String username);

  /// Send password reset OTP to email.
  Future<void> forgotPassword(String email);

  /// Reset password using OTP code.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Change the password for the authenticated user.
  ///
  /// Verifies [oldPassword] server-side and sets [newPassword]. Returns a fresh
  /// token pair (the server revokes other sessions), which the caller must
  /// persist so the current device stays signed in.
  Future<TokenResponse> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Logout (revoke tokens on server).
  /// Requires valid access token.
  Future<void> logout();

  /// Refresh access token.
  Future<TokenResponse> refreshToken(String refreshToken);
}

/// Auth-related exceptions.
class AuthException implements Exception {
  AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AuthException: $message';
}
