import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// Helpers for tracking errors through [AnalyticsService].
///
/// Wraps the type-safe track methods with smart deduplication and Dio error
/// parsing so feature code can call these once-liners without manual parsing.
///
/// Usage:
/// ```dart
/// } catch (e, st) {
///   AnalyticsErrorTracker.trackDioError(e);
///   rethrow;
/// }
/// ```
abstract class AnalyticsErrorTracker {
  /// Rate-limit window for identical API errors.
  static const _dedupWindow = Duration(seconds: 30);

  /// Tracks the last error key + time for deduplication.
  static final _lastErrors = <String, DateTime>{};

  // ── Dio / API errors ─────────────────────────────────────────────────────

  /// Extract structured info from a [DioException] and report to analytics.
  ///
  /// Deduplicates identical (endpoint, statusCode) pairs within 30 s to
  /// avoid spamming Mixpanel on retry loops.
  static void trackDioError(Object error, {String? fallbackEndpoint}) {
    if (error is! DioException) return;

    final endpoint = error.requestOptions.path.isNotEmpty
        ? error.requestOptions.path
        : (fallbackEndpoint ?? 'unknown');
    final statusCode = error.response?.statusCode ?? 0;
    final errorType = _dioTypeLabel(error.type);

    final key = '$endpoint:$statusCode:$errorType';
    final last = _lastErrors[key];
    if (last != null && DateTime.now().difference(last) < _dedupWindow) return;
    _lastErrors[key] = DateTime.now();

    AnalyticsService.instance.trackApiError(
      endpoint: endpoint,
      statusCode: statusCode,
      errorType: errorType,
    );
  }

  // ── Generic exceptions ────────────────────────────────────────────────────

  /// Report an unexpected, unhandled exception. Strips PII from the message.
  static void trackException(Object error, {String? screen}) {
    final errorType = error.runtimeType.toString();
    AnalyticsService.instance.trackUnexpectedException(
      errorType: errorType,
      sourceScreen: screen,
    );
    if (kDebugMode) {
    }
  }

  // ── Auth errors ───────────────────────────────────────────────────────────

  static void trackAuthError({required String errorType}) {
    AnalyticsService.instance.trackAuthError(errorType: errorType);
  }

  // ── Navigation errors ─────────────────────────────────────────────────────

  static void trackNavigationError({required String attemptedRoute}) {
    AnalyticsService.instance.trackNavigationError(attemptedRoute: attemptedRoute);
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  static String _dioTypeLabel(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'connection_timeout';
      case DioExceptionType.sendTimeout:
        return 'send_timeout';
      case DioExceptionType.receiveTimeout:
        return 'receive_timeout';
      case DioExceptionType.badResponse:
        return 'bad_response';
      case DioExceptionType.cancel:
        return 'cancelled';
      case DioExceptionType.connectionError:
        return 'connection_error';
      case DioExceptionType.unknown:
        return 'unknown';
      case DioExceptionType.badCertificate:
        return 'bad_certificate';
    }
  }
}
