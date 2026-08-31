import 'package:dio/dio.dart';

import 'analytics_service.dart';

/// Dio interceptor that measures API performance and tracks outcomes.
///
/// Honest fail-rate strategy (ops dashboard):
/// - **Every** finished request is counted once as either completed or failed.
/// - Failures (`onError`) always track `api_request_failed`.
/// - Successes (`onResponse`) always track `api_request_completed`, with
///   `is_slow: true` when duration ≥ [slowThresholdMs] (for latency charts).
///
/// Dashboard formula:
///   fail_rate = failed / (failed + completed)
/// This is honest only when completed includes *all* successes — not only
/// the slow ones (the previous behaviour inflated fail rate badly).
///
/// Attach after the auth interceptor so retried requests are measured
/// end-to-end including retry latency.
class AnalyticsDioInterceptor extends Interceptor {
  AnalyticsDioInterceptor({this.slowThresholdMs = 300});

  final int slowThresholdMs;

  static const _startTimeKey = '_analytics_start_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startMs = response.requestOptions.extra[_startTimeKey] as int?;
    final durationMs = startMs != null
        ? DateTime.now().millisecondsSinceEpoch - startMs
        : null;
    AnalyticsService.instance.trackApiRequestCompleted(
      endpoint: _sanitizedPath(response.requestOptions),
      method: response.requestOptions.method,
      statusCode: response.statusCode ?? 0,
      durationMs: durationMs ?? 0,
      isSlow: durationMs != null && durationMs >= slowThresholdMs,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startMs = err.requestOptions.extra[_startTimeKey] as int?;
    final durationMs = startMs != null
        ? DateTime.now().millisecondsSinceEpoch - startMs
        : null;

    AnalyticsService.instance.trackApiRequestFailed(
      endpoint: _sanitizedPath(err.requestOptions),
      method: err.requestOptions.method,
      statusCode: err.response?.statusCode,
      errorType: err.type.name,
      durationMs: durationMs,
    );

    handler.next(err);
  }

  /// Strips path parameters (numeric IDs, UUIDs) to reduce cardinality.
  String _sanitizedPath(RequestOptions options) {
    return options.path
        .replaceAll(RegExp(r'/\d+'), '/{id}')
        .replaceAll(
          RegExp(
            r'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
            caseSensitive: false,
          ),
          '/{uuid}',
        );
  }
}
