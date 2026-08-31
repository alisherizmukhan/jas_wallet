import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Retries transient network failures with exponential backoff and jitter.
///
/// Scoped deliberately narrowly:
///  * Only `GET` requests — safe/idempotent by definition, so a retry can
///    never duplicate a side effect (a POST/PUT/DELETE never gets retried
///    here even if it fails transiently).
///  * Only connection-level failures (timeout, connection error) and 5xx
///    server errors — never 4xx client errors, which won't succeed on retry.
///  * Explicitly never touches a 401 — that failure mode is already owned by
///    the API client's own single-flight token-refresh-and-retry interceptor,
///    and the two must never compete over the same request.
///  * Capped at [maxRetries] attempts with jittered exponential backoff, so a
///    real backend outage produces a bounded amount of extra traffic per
///    client instead of an unbounded retry loop.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
    Random? random,
  }) : _random = random ?? Random();

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;
  final Random _random;

  static const _retryCountKey = 'network_retry_count';

  bool _isRetryableMethod(String method) => method.toUpperCase() == 'GET';

  bool _isRetryableError(DioException err) {
    // Never compete with the auth interceptor's own 401 refresh+retry flow.
    if (err.response?.statusCode == 401) return false;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode;
        return code != null && code >= 500;
      default:
        return false;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;

    if (options.extra['skipRetry'] == true ||
        !_isRetryableMethod(options.method) ||
        !_isRetryableError(err)) {
      return handler.next(err);
    }

    final attempt = (options.extra[_retryCountKey] as int?) ?? 0;
    if (attempt >= maxRetries) {
      return handler.next(err);
    }

    // Exponential backoff (base * 2^attempt) with up to ±30% jitter, so a
    // fleet of clients hitting the same transient failure don't all retry in
    // lockstep. Capped at 30s so a slow backoff never itself becomes the
    // dominant source of latency.
    final exponentialMs = baseDelay.inMilliseconds * (1 << attempt);
    final jitterMs =
        (exponentialMs * 0.3 * (_random.nextDouble() * 2 - 1)).round();
    final delayMs = (exponentialMs + jitterMs).clamp(0, 30000);
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    try {
      final retryOptions = options.copyWith(
        extra: {...options.extra, _retryCountKey: attempt + 1},
      );
      final response = await _dio.fetch<dynamic>(retryOptions);
      return handler.resolve(response);
    } catch (_) {
      return handler.next(err);
    }
  }
}
