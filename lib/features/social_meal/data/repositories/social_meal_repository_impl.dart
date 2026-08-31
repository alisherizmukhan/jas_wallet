import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../domain/entities/meal_confirmation.dart';
import '../models/social_meal_redeem_response.dart';
import '../models/social_meal_status.dart';

class SocialMealRepositoryException implements Exception {
  const SocialMealRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum _SocialMealOperation { status, saveDeclaration, redeem }

class SocialMealRepositoryImpl {
  SocialMealRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  /// [cancelToken] lets a caller (e.g. a superseded loadState() call)
  /// abandon this request instead of letting it run to completion for a
  /// result that would just be discarded.
  Future<SocialMealStatus> getStatus({CancelToken? cancelToken}) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/social-meals/me',
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data == null) {
        throw Exception('Invalid response');
      }
      return SocialMealStatus.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e, operation: _SocialMealOperation.status);
    }
  }

  Future<MealConfirmation> saveTomorrowDeclaration({
    required bool breakfast,
    required bool lunch,
    required bool dinner,
  }) async {
    try {
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/social-meals/declarations/tomorrow',
        data: {
          'wants_breakfast': breakfast,
          'wants_lunch': lunch,
          'wants_dinner': dinner,
        },
      );
      final data = response.data;
      if (data == null) {
        throw Exception('Invalid response');
      }
      return MealConfirmation(
        studentId: 'current_user',
        date: DateTime.parse(data['meal_date'] as String),
        breakfast: data['wants_breakfast'] as bool? ?? false,
        lunch: data['wants_lunch'] as bool? ?? false,
        dinner: data['wants_dinner'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw _mapError(e, operation: _SocialMealOperation.saveDeclaration);
    }
  }

  Future<SocialMealRedeemResponse> redeemMeal(String qrCode) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/social-meals/redeem',
        data: {'qr_code': qrCode},
      );
      final data = response.data;
      if (data == null) {
        throw Exception('Invalid response');
      }
      return SocialMealRedeemResponse.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e, operation: _SocialMealOperation.redeem);
    }
  }

  SocialMealRepositoryException _mapError(
    DioException e, {
    required _SocialMealOperation operation,
  }) {
    final detail = _extractDetail(e)?.toLowerCase() ?? '';
    final statusCode = e.response?.statusCode;

    if (statusCode == 401 || statusCode == 403 && detail.contains('session')) {
      return const SocialMealRepositoryException(
        'Your session expired. Please sign in again and try once more.',
      );
    }

    if (_isConnectivityError(e)) {
      switch (operation) {
        case _SocialMealOperation.status:
          return const SocialMealRepositoryException(
            'Could not load social meal status right now. Check your internet and try again.',
          );
        case _SocialMealOperation.saveDeclaration:
          return const SocialMealRepositoryException(
            'Could not save your meal selection right now. Please try again.',
          );
        case _SocialMealOperation.redeem:
          return const SocialMealRepositoryException(
            'Could not process the QR scan right now. Please try again.',
          );
      }
    }

    if (operation == _SocialMealOperation.saveDeclaration) {
      if (detail.contains('not an active social meal program member')) {
        return const SocialMealRepositoryException(
          'Social meal is not available for this account.',
        );
      }
      if (detail.contains('confirmation for tomorrow is already closed')) {
        return const SocialMealRepositoryException(
          'The meal selection window for tomorrow is already closed.',
        );
      }
      return const SocialMealRepositoryException(
        'Could not save your meal selection. Please try again later.',
      );
    }

    if (operation == _SocialMealOperation.redeem) {
      if (detail.contains('invalid cashier qr code')) {
        return const SocialMealRepositoryException(
          'This QR code is not valid for social meal check-in.',
        );
      }
      if (detail.contains('not an active social meal program member')) {
        return const SocialMealRepositoryException(
          'Social meal is not available for this account.',
        );
      }
      if (detail.contains('daily redemption limit reached')) {
        return const SocialMealRepositoryException(
          'You have already used all available meals for today.',
        );
      }
      if (detail.contains('concurrent scan')) {
        return const SocialMealRepositoryException(
          'This scan is already being processed. Please try again.',
        );
      }
      return const SocialMealRepositoryException(
        'Could not complete the QR scan. Please try again.',
      );
    }

    return const SocialMealRepositoryException(
      'Could not load social meal data right now. Please try again.',
    );
  }

  String? _extractDetail(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    }
    return e.message;
  }

  bool _isConnectivityError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }
}
