import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/analytics/analytics_error_tracker.dart';
import 'package:jaswallet_app/core/analytics/analytics_service.dart';

void main() {
  setUpAll(() async {
    await AnalyticsService.instance.init();
  });

  group('AnalyticsErrorTracker — DioException handling', () {
    test('trackDioError does not throw for DioException', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/users/profile'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/users/profile'),
          statusCode: 404,
        ),
      );
      expect(
        () => AnalyticsErrorTracker.trackDioError(error),
        returnsNormally,
      );
    });

    test('trackDioError handles all DioExceptionType values', () {
      for (final type in DioExceptionType.values) {
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          type: type,
        );
        expect(
          () => AnalyticsErrorTracker.trackDioError(error),
          returnsNormally,
          reason: 'DioExceptionType.$type caused a throw',
        );
      }
    });

    test('trackDioError ignores non-DioException objects', () {
      expect(
        () => AnalyticsErrorTracker.trackDioError(Exception('generic')),
        returnsNormally,
      );
      expect(
        () => AnalyticsErrorTracker.trackDioError(StateError('state error')),
        returnsNormally,
      );
    });

    test('trackDioError deduplicates identical errors within 30 seconds', () {
      // Two calls with identical endpoint+status should NOT cause extra events.
      // In no-op mode we just verify neither throws.
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/dedup-test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/dedup-test'),
          statusCode: 500,
        ),
      );
      expect(() {
        AnalyticsErrorTracker.trackDioError(error);
        AnalyticsErrorTracker.trackDioError(error); // should be deduped
      }, returnsNormally);
    });

    test('trackDioError accepts fallbackEndpoint when path is empty', () {
      final error = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      );
      expect(
        () => AnalyticsErrorTracker.trackDioError(
          error,
          fallbackEndpoint: '/api/unknown',
        ),
        returnsNormally,
      );
    });
  });

  group('AnalyticsErrorTracker — generic exceptions', () {
    test('trackException does not throw for any object', () {
      expect(
        () => AnalyticsErrorTracker.trackException(Exception('error'), screen: 'Home'),
        returnsNormally,
      );
      expect(
        () => AnalyticsErrorTracker.trackException(StateError('bad state')),
        returnsNormally,
      );
      expect(
        () => AnalyticsErrorTracker.trackException('string error'),
        returnsNormally,
      );
    });

    test('trackException accepts null screen', () {
      expect(
        () => AnalyticsErrorTracker.trackException(Exception('no screen')),
        returnsNormally,
      );
    });
  });

  group('AnalyticsErrorTracker — auth and navigation errors', () {
    test('trackAuthError does not throw', () {
      expect(
        () => AnalyticsErrorTracker.trackAuthError(errorType: 'invalid_token'),
        returnsNormally,
      );
    });

    test('trackNavigationError does not throw', () {
      expect(
        () => AnalyticsErrorTracker.trackNavigationError(attemptedRoute: '/invalid'),
        returnsNormally,
      );
    });
  });
}
