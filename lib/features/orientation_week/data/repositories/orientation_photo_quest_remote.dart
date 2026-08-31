import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/dio_error_detail.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/orientation_results.dart';
import '../../domain/entities/photo_mission.dart';
import '../models/photo_quest_api_mapper.dart';
import '../services/photo_quest_location_service.dart';

/// Talks to `GET/POST /orientation/photo-quests…` on the Jas Wallet backend,
/// which proxies photos to the neighbouring CV verify VM.
class OrientationPhotoQuestRemote {
  OrientationPhotoQuestRemote({
    required ApiClient apiClient,
    PhotoQuestLocationService locationService = const PhotoQuestLocationService(),
    Uuid? uuid,
  })  : _apiClient = apiClient,
        _location = locationService,
        _uuid = uuid ?? const Uuid();

  final ApiClient _apiClient;
  final PhotoQuestLocationService _location;
  final Uuid _uuid;

  static const Duration _uploadTimeout = Duration(seconds: 45);
  static const int _maxBytes = 12 * 1024 * 1024;

  Future<({List<PhotoMission> missions, PhotoQuestProgress progress})> fetchBoard() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/orientation/photo-quests',
    );
    final data = response.data;
    if (data == null) {
      throw const PhotoQuestApiException('Empty photo quest response');
    }
    final missionsJson = data['missions'] as List<dynamic>? ?? const [];
    final missions = missionsJson
        .whereType<Map>()
        .map((e) => photoMissionFromApi(Map<String, dynamic>.from(e)))
        .toList(growable: false);
    final progressJson = data['progress'] as Map<String, dynamic>? ?? const {};
    return (
      missions: missions,
      progress: photoQuestProgressFromApi(progressJson),
    );
  }

  Future<List<PhotoMission>> getPhotoMissions() async {
    final board = await fetchBoard();
    return board.missions;
  }

  Future<OrientationTokensSnapshot> fetchMyTokens() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/orientation/photo-quests/me/tokens',
    );
    final data = response.data;
    if (data == null) {
      throw const PhotoQuestApiException('Empty tokens response');
    }
    return orientationTokensFromApi(data);
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard({int limit = 50}) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/orientation/photo-quests/leaderboard',
      queryParameters: {'limit': limit},
    );
    final data = response.data;
    if (data == null) {
      throw const PhotoQuestApiException('Empty leaderboard response');
    }
    return orientationLeaderboardFromApi(data);
  }

  Future<PhotoMissionSubmitResult> submitMissionPhoto(
    String missionId,
    String localFilePath,
  ) async {
    final normalizedPath = localFilePath.startsWith('file://')
        ? Uri.parse(localFilePath).toFilePath()
        : localFilePath;
    final file = File(normalizedPath);
    if (!await file.exists()) {
      return PhotoMissionSubmitResult.error('Photo file is missing. Please retake.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > _maxBytes) {
      return PhotoMissionSubmitResult.error(
        'Photo is too large (max 12 MB). Please retake without extra editing.',
      );
    }

    final size = await _decodeImageSize(bytes);
    final capturedAt = DateTime.now().toUtc().toIso8601String();
    final submissionId = _uuid.v4();
    final location = await _location.current();

    final filename = normalizedPath.split(Platform.pathSeparator).last;
    final lower = filename.toLowerCase();
    final mime = lower.endsWith('.png')
        ? MediaType('image', 'png')
        : MediaType('image', 'jpeg');

    final formMap = <String, dynamic>{
      'image': MultipartFile.fromBytes(
        bytes,
        filename: filename.isEmpty ? 'capture.jpg' : filename,
        contentType: mime,
      ),
      'submission_id': submissionId,
      'captured_at': capturedAt,
      'source': 'camera',
      'image_bytes': bytes.length,
      'device_platform': Platform.isIOS
          ? 'ios'
          : (Platform.isAndroid ? 'android' : Platform.operatingSystem),
      'app_version': 'mobile',
    };
    if (size != null) {
      formMap['image_width'] = size.$1;
      formMap['image_height'] = size.$2;
    }
    if (location != null) {
      formMap['lat'] = location.lat;
      formMap['lon'] = location.lon;
      formMap['geo_accuracy_m'] = location.accuracyM;
      formMap['location_mocked'] = location.isMocked;
    }

    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/orientation/photo-quests/$missionId/submissions',
        data: FormData.fromMap(formMap),
        options: Options(
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
        ),
      );
      final data = response.data;
      if (data == null) {
        return PhotoMissionSubmitResult.error('Empty verify response. Please try again.');
      }
      return photoMissionSubmitResultFromApi(data);
    } on DioException catch (e) {
      return PhotoMissionSubmitResult.error(_messageFromDio(e));
    } on PhotoQuestApiException catch (e) {
      return PhotoMissionSubmitResult.error(e.message);
    } catch (_) {
      return PhotoMissionSubmitResult.error('Could not upload the photo. Please try again.');
    }
  }

  Future<PhotoMissionSubmitResult> deleteMissionPhoto(String missionId) async {
    return PhotoMissionSubmitResult.error(
      'Removing a verified photo is not available yet.',
    );
  }

  static Future<(int, int)?> _decodeImageSize(List<int> bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      final height = frame.image.height;
      frame.image.dispose();
      return (width, height);
    } catch (_) {
      return null;
    }
  }

  static String _messageFromDio(DioException e) {
    if (isConnectivityDioError(e)) {
      return 'No internet connection. Check your network and try again.';
    }
    final status = e.response?.statusCode;
    if (status == 401) {
      return 'Session expired. Please sign in again.';
    }
    if (status == 413) {
      return 'Photo is too large. Please retake.';
    }
    if (status == 409) {
      return 'This mission already has a photo waiting for review.';
    }
    if (status == 502 || status == 504) {
      return 'Verification service is temporarily unavailable. Please retry.';
    }
    final detail = extractApiDetailFromDio(e);
    if (detail != null && detail.isNotEmpty) {
      if (detail.contains('_') && detail == detail.toLowerCase()) {
        return 'Could not verify the photo. Please try again.';
      }
      return detail;
    }
    return 'Could not verify the photo. Please try again.';
  }
}

class PhotoQuestApiException implements Exception {
  const PhotoQuestApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
