import 'package:dio/dio.dart';

/// HTTP interceptor for handling token refresh on 401 responses.
///
/// When an API returns 401 (Unauthorized), this interceptor queues the request
/// and notifies the caller through a callback. The auth system is responsible
/// for token refresh and state management.
///
/// This implements CASE 4 (Token expired) and CASE 5 (Refresh token invalid).
///
/// NOTE: This is a simplified interceptor that doesn't hold auth state.
/// Token refresh logic should be handled by the app's auth provider layer.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({required this.dio, this.onTokenRefreshNeeded});

  final Dio dio;

  /// Called when a 401 response is received to notify the app to refresh token.
  /// The app should refresh the token and then retry the original request.
  final Future<void> Function(DioException error)? onTokenRefreshNeeded;

  /// Track if we're currently refreshing tokens to avoid duplicate refresh calls.
  bool _isRefreshing = false;

  /// Queue of failed requests waiting for token refresh to complete.
  final List<_PendingRequest> _pendingRequests = [];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // CASE 4: Handle 401 Unauthorized (token expired)
    if (err.response?.statusCode == 401) {

      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          // Notify the app that token refresh is needed
          if (onTokenRefreshNeeded != null) {
            await onTokenRefreshNeeded!(err);
          }

          _isRefreshing = false;
          _retryPendingRequests();

          // Retry the original failed request
          return handler.resolve(await _retryRequest(err.requestOptions));
        } catch (e) {
          _isRefreshing = false;
          _clearPendingRequests();
          return handler.next(err);
        }
      } else {
        // Token refresh already in progress — queue this request
        _pendingRequests.add(_PendingRequest(err.requestOptions, handler));
        return;
      }
    }

    handler.next(err);
  }

  /// Retry a failed request with updated access token.
  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return dio.request<dynamic>(
      requestOptions.path,
      queryParameters: requestOptions.queryParameters,
      data: requestOptions.data,
      options: options,
    );
  }

  /// Retry all pending requests after token refresh.
  void _retryPendingRequests() {
    for (final pending in _pendingRequests) {
      _retryRequest(pending.requestOptions).then(
        (response) => pending.handler.resolve(response),
        onError: (error) => pending.handler.next(error),
      );
    }
    _pendingRequests.clear();
  }

  /// Clear all pending requests (when refresh fails).
  void _clearPendingRequests() {
    for (final pending in _pendingRequests) {
      pending.handler.next(
        DioException(
          requestOptions: pending.requestOptions,
          error: 'Token refresh failed',
          type: DioExceptionType.unknown,
        ),
      );
    }
    _pendingRequests.clear();
  }
}

/// Represents a pending request waiting for token refresh.
class _PendingRequest {
  _PendingRequest(this.requestOptions, this.handler);

  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
}
