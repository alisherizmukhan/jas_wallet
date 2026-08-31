import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/dio_error_detail.dart';
import '../../domain/entities/bingo_board.dart';
import '../../domain/entities/club_fair_club_rank.dart';
import '../../domain/entities/club_fair_stand_qr.dart';
import '../../domain/entities/orientation_challenge.dart';
import '../../domain/entities/orientation_dashboard.dart';
import '../../domain/entities/orientation_results.dart';
import '../models/orientation_task_api_mapper.dart';

/// What one `POST /orientation/tasks/{id}/complete` paid out.
class OrientationTaskCompleteResult {
  const OrientationTaskCompleteResult({
    required this.tokensAwarded,
    required this.bingoLineTokens,
    required this.bingoGrandTokens,
    required this.alreadyCompleted,
  });

  final int tokensAwarded;
  final int bingoLineTokens;
  final int bingoGrandTokens;
  final bool alreadyCompleted;
}

/// A completion the server refused, with the machine-readable `detail` code
/// (`wrong_answer`, `same_school`, `cannot_scan_yourself`, …) so the UI can
/// say why in the student's language.
class OrientationTaskRejected implements Exception {
  const OrientationTaskRejected(this.detail, this.statusCode);

  final String detail;
  final int? statusCode;

  @override
  String toString() => 'OrientationTaskRejected($statusCode: $detail)';
}

/// Talks to the unified Orientation task API: the 28-task catalog, per-kind
/// completions, and the personal 4×4 bingo grid.
class OrientationTasksRemote {
  OrientationTasksRemote({
    required ApiClient apiClient,
    required String Function() languageCode,
  })  : _apiClient = apiClient,
        _languageCode = languageCode;

  final ApiClient _apiClient;

  /// Read per call, not captured — the student can switch language mid-week.
  final String Function() _languageCode;

  /// Non-photo tasks as challenges, in catalog order. Photo tasks are listed
  /// by the Photo Quest board instead.
  Future<List<OrientationChallenge>> fetchChallenges() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/club-fair/tasks',
    );
    final data = response.data;
    if (data == null) {
      throw const OrientationTaskRejected('empty_response', null);
    }
    final lang = _languageCode();
    return (data['tasks'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((task) => isChallengeApiKind(task['kind'] as String? ?? ''))
        .map((task) => challengeFromApiTask(task, lang))
        .toList(growable: false);
  }

  Future<BingoBoard> fetchBingoBoard() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/club-fair/bingo',
    );
    final data = response.data;
    if (data == null) {
      throw const OrientationTaskRejected('empty_response', null);
    }
    return bingoBoardFromApi(data, _languageCode());
  }

  Future<OrientationDashboard> fetchHome() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/club-fair/home',
    );
    final data = response.data;
    if (data == null) {
      throw const OrientationTaskRejected('empty_response', null);
    }
    return dashboardFromClubFairHome(data, _languageCode());
  }

  Future<ClubFairStandQrBundle> fetchClubStandQrs() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/club-fair/me/club-qr',
      );
      final data = response.data;
      if (data == null) {
        throw const OrientationTaskRejected('empty_response', null);
      }
      return clubFairStandQrFromApi(data, _languageCode());
    } on DioException catch (e) {
      final detail = extractApiDetailFromDio(e);
      if (detail != null && detail.isNotEmpty) {
        throw OrientationTaskRejected(detail, e.response?.statusCode);
      }
      if (isConnectivityDioError(e)) {
        throw const OrientationTaskRejected('no_connection', null);
      }
      rethrow;
    }
  }

  Future<ClubFairClubRanking> fetchClubRanking() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/club-fair/clubs/ranking',
      );
      final data = response.data;
      if (data == null) {
        throw const OrientationTaskRejected('empty_response', null);
      }
      return clubFairClubRankingFromApi(data, _languageCode());
    } on DioException catch (e) {
      final detail = extractApiDetailFromDio(e);
      if (detail != null && detail.isNotEmpty) {
        throw OrientationTaskRejected(detail, e.response?.statusCode);
      }
      if (isConnectivityDioError(e)) {
        throw const OrientationTaskRejected('no_connection', null);
      }
      rethrow;
    }
  }

  Future<ClubScanResult> scanClub(String scannedPayload) async {
    final clubId = clubIdFromClubQrPayload(scannedPayload);
    if (clubId == null) {
      throw const OrientationTaskRejected('wrong_club_qr', 422);
    }
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/club-fair/clubs/$clubId/scan',
        data: {'scanned_payload': scannedPayload},
      );
      final data = response.data;
      if (data == null) {
        throw const OrientationTaskRejected('empty_response', null);
      }
      return clubScanResultFromApi(data, _languageCode());
    } on DioException catch (e) {
      final detail = extractApiDetailFromDio(e);
      if (detail != null && detail.isNotEmpty) {
        throw OrientationTaskRejected(detail, e.response?.statusCode);
      }
      if (isConnectivityDioError(e)) {
        throw const OrientationTaskRejected('no_connection', null);
      }
      rethrow;
    }
  }

  /// Completes one task. The body depends on the kind; the server validates
  /// and pays, including any bingo line/grand bonuses the completion closed.
  ///
  /// Throws [OrientationTaskRejected] when the server refuses the submission.
  Future<OrientationTaskCompleteResult> completeTask(
    String taskId, {
    String? answer,
    String? scannedPayload,
    String? mySchoolCode,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/club-fair/tasks/$taskId/complete',
        data: {
          'answer': ?answer,
          'handle': ?answer,
          'scanned_payload': ?scannedPayload,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const OrientationTaskRejected('empty_response', null);
      }
      return OrientationTaskCompleteResult(
        tokensAwarded: (data['tokens_awarded'] as num?)?.toInt() ?? 0,
        bingoLineTokens: (data['bingo_line_tokens'] as num?)?.toInt() ?? 0,
        bingoGrandTokens: (data['bingo_grand_tokens'] as num?)?.toInt() ?? 0,
        alreadyCompleted: data['already_completed'] == true,
      );
    } on DioException catch (e) {
      final detail = extractApiDetailFromDio(e);
      if (detail != null && detail.isNotEmpty) {
        throw OrientationTaskRejected(detail, e.response?.statusCode);
      }
      if (isConnectivityDioError(e)) {
        throw const OrientationTaskRejected('no_connection', null);
      }
      rethrow;
    }
  }
}
