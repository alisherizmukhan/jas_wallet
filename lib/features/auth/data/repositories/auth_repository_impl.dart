import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../models/token_response.dart';
import 'auth_repository.dart';

/// Implementation of [AuthRepository] using JasWallet backend API.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required ApiClient apiClient,
    required AuthStorageService authStorage,
  }) : _client = apiClient;

  final ApiClient _client;

  @override
  Future<SendOtpResult> sendOtp(String email) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/send-otp',
        data: {'email': email.toLowerCase().trim()},
      );
      final data = response.data ?? const <String, dynamic>{};
      final status = data['status'] as String?;
      final message =
          data['message'] as String? ?? 'Verification code sent to your email';
      return SendOtpResult(
        status: status == 'already_registered'
            ? SendOtpStatus.alreadyRegistered
            : SendOtpStatus.otpSent,
        message: message,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<TokenResponse> verifyOtp(String email, String code) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'email': email.toLowerCase().trim(),
          'code': code.trim(),
        },
      );
      final data = response.data;
      if (data == null) throw AuthException('Invalid response');
      return TokenResponse.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<TokenResponse> login(String login, String password) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'login': login.trim().toLowerCase(),
          'password': password,
        },
      );
      final data = response.data;
      if (data == null) throw AuthException('Invalid response');
      return TokenResponse.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<String> completeProfile({
    required String firstName,
    required String lastName,
    required String nuStudentId,
    required String username,
    required String password,
    String? phone,
    String? consentVersion,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/students/me/complete-profile',
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'nu_student_id': nuStudentId.trim(),
          'username': username.trim().toLowerCase(),
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
          if (consentVersion != null && consentVersion.isNotEmpty)
            'consent_version': consentVersion,
        },
      );
      final id = response.data?['id'] as String?;
      if (id == null || id.isEmpty) throw AuthException('Invalid response');
      return id;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<StudentIdLookupResult> lookupStudentId(String studentId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/students/student-id-lookup',
        queryParameters: {'student_id': studentId.trim()},
      );
      final data = response.data;
      if (data == null) throw AuthException('Invalid response');
      return StudentIdLookupResult(
        studentId: data['student_id'] as String,
        firstName: data['first_name'] as String,
        lastName: data['last_name'] as String,
        fullName: data['full_name'] as String,
        source: data['source'] as String? ?? 'salto_index',
        alreadyRegistered: data['already_registered'] as bool? ?? false,
        schoolCode: data['school_code'] as String?,
        isNufyp: data['is_nufyp'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<UsernameAvailability> checkUsernameAvailable(String username) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/students/username-available',
        queryParameters: {'username': username.trim().toLowerCase()},
      );
      final data = response.data;
      if (data == null) throw AuthException('Invalid response');
      return UsernameAvailability(
        username: data['username'] as String? ?? username.trim().toLowerCase(),
        valid: data['valid'] as bool? ?? false,
        available: data['available'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _client.dio.post(
        '/auth/forgot-password',
        data: {'email': email.toLowerCase().trim()},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _client.dio.post(
        '/auth/reset-password',
        data: {
          'email': email.toLowerCase().trim(),
          'code': code.trim(),
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<TokenResponse> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      final data = response.data;
      if (data == null) throw AuthException('Invalid response');
      return TokenResponse.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } on DioException catch (e) {
      // 401 = already logged out, ignore
      if (e.response?.statusCode != 401) {
        throw _mapDioError(e);
      }
    }
  }

  @override
  Future<TokenResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      if (data == null) throw AuthException('Invalid response');
      return TokenResponse.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  AuthException _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Network error';

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        message = detail.first.toString();
      }
    }

    if (statusCode == 401) {
      message = 'Invalid credentials';
    } else if (statusCode == 429) {
      message = 'Too many requests. Please try again later.';
    }

    return AuthException(message, statusCode: statusCode);
  }
}
