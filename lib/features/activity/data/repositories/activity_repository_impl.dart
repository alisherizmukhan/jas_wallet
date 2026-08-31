import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/dio_error_detail.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/profile_cache_service.dart';
import '../../domain/activity_api_exception.dart';
import '../../domain/entities/user_activity_entity.dart';

class ActivityRepositoryImpl {
  ActivityRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const int _maxActivityImages = 5;

  /// Converts any relative `/media/...` path returned by the backend into
  /// a full absolute URL. Absolute URLs pass through unchanged.
  String _resolveMediaUrl(String raw) {
    final url = raw.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${ApiConfig.baseUrl}$url';
    return url;
  }

  bool _isAlreadyUploadedUrl(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    final lower = t.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return true;
    if (lower.startsWith('/media/')) return true;
    return false;
  }

  MediaType _mimeTypeForPath(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  Never _throwFromDio(DioException e) {
    if (isConnectivityDioError(e)) {
      throw ActivityApiException('', kind: ActivityErrorKind.network);
    }
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      throw ActivityApiException('', kind: ActivityErrorKind.session);
    }
    final extracted = extractApiDetailFromDio(e);
    if (status == 413) {
      throw ActivityApiException(
        extracted ?? '',
        kind: ActivityErrorKind.imageTooLarge,
      );
    }
    if (extracted != null && extracted.isNotEmpty) {
      throw ActivityApiException(extracted, kind: ActivityErrorKind.serverDetail);
    }
    throw ActivityApiException('', kind: ActivityErrorKind.unknown);
  }

  Future<String> _uploadLocalMedia(String path) async {
    final normalizedPath = path.startsWith('file://')
        ? Uri.parse(path).toFilePath()
        : path;
    final filename = normalizedPath.split(RegExp(r'[\\/]')).last;
    late final MultipartFile file;
    try {
      file = await MultipartFile.fromFile(
        normalizedPath,
        filename: filename,
        contentType: _mimeTypeForPath(filename),
      );
    } on FileSystemException {
      throw ActivityApiException('', kind: ActivityErrorKind.imageRead);
    }
    final formData = FormData.fromMap({'file': file});
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/profile-resume/me/activities/media',
        data: formData,
      );
      final data = response.data;
      final url = data?['media_url']?.toString().trim();
      if (url == null || url.isEmpty) {
        throw ActivityApiException('', kind: ActivityErrorKind.unknown);
      }
      return url;
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  Future<List<String>> _resolveImageUrls(List<String> urls) async {
    final trimmed = urls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (trimmed.length > _maxActivityImages) {
      throw ActivityApiException('', kind: ActivityErrorKind.maxPhotos);
    }
    return Future.wait(
      trimmed.map((u) => _isAlreadyUploadedUrl(u) ? Future.value(u) : _uploadLocalMedia(u)),
    );
  }

  UserActivityEntity _fromApi(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    final rawMedia = (json['media_items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    rawMedia.sort(
      (a, b) => ((a['sort_order'] as num?)?.toInt() ?? 0)
          .compareTo((b['sort_order'] as num?)?.toInt() ?? 0),
    );
    final mediaItems = rawMedia
        .map((item) => _resolveMediaUrl((item['media_url'] ?? '').toString()))
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    return UserActivityEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['student_id'] ?? '').toString(),
      name: (json['title'] ?? '').toString(),
      date: parseDate(json['activity_date']),
      description: (json['description'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['description'] as String).trim(),
      imageUrls: mediaItems,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> _toApiPayload(UserActivityEntity activity) {
    final date = activity.date;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return {
      'title': activity.name.trim(),
      'activity_date': dateStr,
      'description': activity.description?.trim(),
      'media_urls': activity.imageUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    };
  }

  static const _cacheKey = 'activities';

  /// Activities change rarely; a short TTL still meaningfully cuts redundant
  /// refetches from repeated profile-tab visits within a session.
  static const cacheTtl = Duration(minutes: 30);

  /// Whether the cached activity list is still within [cacheTtl]. Used by
  /// the notifier to skip the background revalidate network call entirely
  /// when the cache is fresh.
  Future<bool> isCacheFresh() async {
    final entry = await ProfileCacheService.loadEntry(_cacheKey, cacheTtl);
    return entry?.isFresh ?? false;
  }

  /// [cancelToken] lets a caller abandon this request (e.g. the notifier
  /// that started it is disposed or superseded before the response arrives)
  /// instead of letting it run to completion for a result nobody will read.
  Future<List<UserActivityEntity>> getActivities({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/profile-resume/me/activities',
        cancelToken: cancelToken,
      );
      final data = response.data ?? const [];
      final items = data
          .whereType<Map<String, dynamic>>()
          .map(_fromApi)
          .toList(growable: false);
      await ProfileCacheService.save(
        _cacheKey,
        items.map((e) => e.toJson()).toList(),
      );
      return items;
    } on DioException catch (e) {
      final cached = await _loadCached();
      if (cached != null) return cached;
      _throwFromDio(e);
    }
  }

  /// Returns the previously cached activity list synchronously (from prefs).
  /// Returns an empty list if no cache exists yet.
  /// Call this before [getActivities] so the UI renders immediately.
  Future<List<UserActivityEntity>> getCachedActivities() async {
    final cached = await _loadCached();
    return cached ?? const [];
  }

  Future<List<UserActivityEntity>?> _loadCached() async {
    final maps = await ProfileCacheService.load(_cacheKey);
    if (maps == null) return null;
    try {
      return maps.map((m) => UserActivityEntity.fromJson(m)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> addActivity(UserActivityEntity activity) async {
    final resolved = await _resolveImageUrls(activity.imageUrls);
    try {
      await _apiClient.dio.post(
        '/profile-resume/me/activities',
        data: _toApiPayload(activity.copyWith(imageUrls: resolved)),
      );
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  Future<void> updateActivity(UserActivityEntity activity) async {
    final resolved = await _resolveImageUrls(activity.imageUrls);
    try {
      await _apiClient.dio.put(
        '/profile-resume/me/activities/${activity.id}',
        data: _toApiPayload(activity.copyWith(imageUrls: resolved)),
      );
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      await _apiClient.dio.delete('/profile-resume/me/activities/$id');
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  Future<void> clearActivities() async {
    final activities = await getActivities();
    for (final item in activities) {
      await deleteActivity(item.id);
    }
  }
}
