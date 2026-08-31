import 'dart:async';

import 'package:dio/dio.dart';

import '../analytics/analytics_dio_interceptor.dart';
import '../config/api_config.dart';
import '../network/certificate_pinning.dart';
import '../network/retry_interceptor.dart';
import '../services/auth_storage_service.dart';
import '../services/orientation_trusted_clock.dart';

/// Dio-based API client for JasWallet backend.
///
/// Automatically attaches Bearer token from [AuthStorageService] to requests.
/// Handles 401 by refreshing tokens and retrying once.
class ApiClient {
  ApiClient({
    required AuthStorageService authStorage,
    Future<void> Function()? onSessionExpired,
    Dio? dio,
  }) : _authStorage = authStorage,
       _onSessionExpired = onSessionExpired,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: ApiConfig.apiBaseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 15),
               headers: {
                 'Content-Type': 'application/json',
                 'Accept': 'application/json',
               },
             ),
           ) {
    applyApiCertificatePinning(_dio);
    _dio.interceptors.add(
      _AuthInterceptor(_authStorage, _dio, onSessionExpired: _onSessionExpired),
    );
    // GET-only, jittered-backoff retry for transient failures (timeouts,
    // connection errors, 5xx) — added after the auth interceptor and itself
    // excludes 401s, so the two never compete over the same failure.
    _dio.interceptors.add(RetryInterceptor(_dio));
    _dio.interceptors.add(AnalyticsDioInterceptor());
    _dio.interceptors.add(_ServerTimeInterceptor());
  }

  final AuthStorageService _authStorage;
  final Future<void> Function()? _onSessionExpired;
  final Dio _dio;

  Dio get dio => _dio;

  /// Create a copy with optional custom base URL (e.g. for tests).
  ApiClient copyWith({String? baseUrl}) {
    final opts = _dio.options.copyWith(
      baseUrl: baseUrl ?? ApiConfig.apiBaseUrl,
    );
    return ApiClient(
      authStorage: _authStorage,
      onSessionExpired: _onSessionExpired,
      dio: Dio(opts),
    );
  }
}

/// Interceptor that attaches Bearer token to requests.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(
    this._authStorage,
    this._dio, {
    Future<void> Function()? onSessionExpired,
  }) : _onSessionExpired = onSessionExpired;

  final AuthStorageService _authStorage;
  final Dio _dio;
  final Future<void> Function()? _onSessionExpired;

  Completer<void>? _refreshCompleter;

  static const _retryFlagKey = 'auth_refresh_retried';

  bool _isPublicAuthPath(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains('/auth/login') ||
        normalized.contains('/auth/send-otp') ||
        normalized.contains('/auth/verify-otp') ||
        normalized.contains('/auth/forgot-password') ||
        normalized.contains('/auth/reset-password') ||
        normalized.contains('/auth/refresh');
  }

  bool _shouldSkipAuth(RequestOptions options) {
    if (options.extra['skipAuth'] == true) {
      return true;
    }
    return _isPublicAuthPath(options.path);
  }

  bool _shouldSkipRefresh(RequestOptions options) {
    if (options.extra['skipRefresh'] == true ||
        options.extra[_retryFlagKey] == true) {
      return true;
    }
    return _isPublicAuthPath(options.path);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldSkipAuth(options)) {
      return handler.next(options);
    }

    final token = await _authStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 ||
        _shouldSkipRefresh(err.requestOptions)) {
      return handler.next(err);
    }

    try {
      await _refreshTokens();
      final response = await _retryWithFreshToken(err.requestOptions);
      return handler.resolve(response);
    } catch (_) {
      return handler.next(err);
    }
  }

  Future<void> _refreshTokens() async {
    final ongoingRefresh = _refreshCompleter;
    if (ongoingRefresh != null) {
      return ongoingRefresh.future;
    }

    final completer = Completer<void>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await _authStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw StateError('Refresh token is missing');
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: const {'skipAuth': true, 'skipRefresh': true}),
      );

      final data = response.data ?? const <String, dynamic>{};
      final newAccessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;

      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        throw StateError('Invalid token refresh response');
      }

      await _authStorage.setAccessToken(newAccessToken);
      await _authStorage.setRefreshToken(newRefreshToken);

      completer.complete();
    } catch (e) {
      await _handleRefreshFailure(e);
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  Future<void> _handleRefreshFailure(Object error) async {
    if (error is! DioException) {
      return;
    }
    final statusCode = error.response?.statusCode;
    if (statusCode != 401 && statusCode != 403) {
      return;
    }

    if (_onSessionExpired != null) {
      await _onSessionExpired();
      return;
    }

    await _authStorage.clearSession();
  }

  Future<Response<dynamic>> _retryWithFreshToken(
    RequestOptions requestOptions,
  ) {
    final retryHeaders = Map<String, dynamic>.from(requestOptions.headers)
      ..remove('Authorization');
    final retryExtra = Map<String, dynamic>.from(requestOptions.extra)
      ..[_retryFlagKey] = true;

    final retryOptions = requestOptions.copyWith(
      headers: retryHeaders,
      extra: retryExtra,
    );

    return _dio.fetch<dynamic>(retryOptions);
  }
}

/// Feeds every response's HTTP `Date` header into [OrientationTrustedClock]
/// — piggybacks on whatever calls the app is already making (login, wallet,
/// hub content, …), so Orientation Week's close-date check gets a
/// tamper-resistant time source without ever needing an API call of its own,
/// including while the feature itself is closed and making none at all.
class _ServerTimeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    OrientationTrustedClock.instance.reportServerDateHeader(response.headers.value('date'));
    handler.next(response);
  }
}
