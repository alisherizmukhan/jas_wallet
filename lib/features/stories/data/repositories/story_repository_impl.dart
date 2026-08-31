import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/dio_error_detail.dart';
import '../../../../core/errors/profile_api_exception.dart';
import '../../domain/entities/story.dart';

class StoryRepositoryImpl {
  StoryRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  static const int _storyMaxSizeBytes = 30 * 1024 * 1024;
  static const Duration _storyUploadTimeout = Duration(minutes: 2);

  Never _throwFromDio(DioException e) {
    final request = e.requestOptions;
    final status = e.response?.statusCode;

    if (isConnectivityDioError(e)) {
      throw ProfileApiException('', category: ProfileApiErrorCategory.network);
    }
    if (status == 401) {
      throw ProfileApiException('', category: ProfileApiErrorCategory.session);
    }

    final isCreateStoryRequest =
        request.method.toUpperCase() == 'POST' && request.path == '/stories/';
    final isDeleteStoryRequest =
        request.method.toUpperCase() == 'DELETE' &&
        request.path.startsWith('/stories/');

    if (isCreateStoryRequest && status == 403) {
      throw ProfileApiException(
        'stories_publish_forbidden',
        category: ProfileApiErrorCategory.serverDetail,
      );
    }
    if (isDeleteStoryRequest && status == 403) {
      throw ProfileApiException(
        'stories_delete_forbidden',
        category: ProfileApiErrorCategory.serverDetail,
      );
    }
    if (isDeleteStoryRequest && status == 404) {
      throw ProfileApiException(
        'stories_not_found',
        category: ProfileApiErrorCategory.serverDetail,
      );
    }
    if (isCreateStoryRequest && status == 413) {
      throw ProfileApiException(
        'stories_media_too_large',
        category: ProfileApiErrorCategory.serverDetail,
      );
    }
    if (isCreateStoryRequest && status == 415) {
      throw ProfileApiException(
        'stories_media_unsupported',
        category: ProfileApiErrorCategory.serverDetail,
      );
    }

    final extracted = extractApiDetailFromDio(e);
    if (extracted != null && extracted.isNotEmpty) {
      throw ProfileApiException(
        extracted,
        category: ProfileApiErrorCategory.serverDetail,
      );
    }
    throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
  }

  MediaType? _mimeTypeForPath(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.mp4')) return MediaType('video', 'mp4');
    if (lower.endsWith('.webm')) return MediaType('video', 'webm');
    if (lower.endsWith('.mov')) return MediaType('video', 'quicktime');
    return null;
  }

  /// [cancelToken] lets a caller abandon this request (e.g. the provider
  /// that started it is disposed before the response arrives) instead of
  /// letting it run to completion for a result nobody will read.
  Future<List<Story>> getFeed({CancelToken? cancelToken}) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/stories/feed',
        cancelToken: cancelToken,
      );
      final data = response.data ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(Story.fromApi)
          .toList(growable: false);
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  Future<List<StoryPublisherOrganization>> getMyOrganizations() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/stories/my-organizations',
      );
      final data = response.data ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(StoryPublisherOrganization.fromApi)
          .toList(growable: false);
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  Future<Story> createStory({
    required String organizationId,
    required String filePath,
    void Function(double? progress)? onProgress,
  }) async {
    final normalizedPath = filePath.startsWith('file://')
        ? Uri.parse(filePath).toFilePath()
        : filePath;
    final filename = normalizedPath.split(RegExp(r'[\\/]')).last;
    final mimeType = _mimeTypeForPath(filename);
    if (mimeType == null) {
      throw ProfileApiException(
        'stories_media_unsupported',
        category: ProfileApiErrorCategory.serverDetail,
      );
    }

    final inputFile = File(normalizedPath);
    int fileSizeBytes;
    try {
      fileSizeBytes = await inputFile.length();
      if (fileSizeBytes > _storyMaxSizeBytes) {
        throw ProfileApiException(
          'stories_media_too_large',
          category: ProfileApiErrorCategory.serverDetail,
        );
      }
    } on FileSystemException {
      throw ProfileApiException(
        '',
        category: ProfileApiErrorCategory.unknown,
      );
    }

    late final MultipartFile file;
    try {
      file = await MultipartFile.fromFile(
        normalizedPath,
        filename: filename,
        contentType: mimeType,
      );
    } on FileSystemException {
      throw ProfileApiException(
        '',
        category: ProfileApiErrorCategory.unknown,
      );
    }

    final formData = FormData.fromMap({
      'organization_id': organizationId,
      'file': file,
    });

    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/stories/',
        data: formData,
        options: Options(
          sendTimeout: _storyUploadTimeout,
          receiveTimeout: _storyUploadTimeout,
        ),
        onSendProgress: (sent, total) {
          if (onProgress == null) return;
          if (total <= 0) {
            onProgress(null);
            return;
          }
          onProgress((sent / total).clamp(0, 1));
        },
      );
      final data = response.data;
      if (data == null) {
        throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
      }
      return Story.fromApi(data);
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await _apiClient.dio.delete('/stories/$storyId');
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }
}
