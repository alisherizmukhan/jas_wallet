import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/dio_error_detail.dart';
import '../../../../core/errors/profile_api_exception.dart';
import '../../../../core/services/profile_cache_service.dart';
import '../../domain/entities/experience_entity.dart';
import '../../domain/repositories/experience_repository.dart';

class ExperienceRepositoryImpl implements ExperienceRepository {
  ExperienceRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Never _throwFromDio(DioException e) {
    if (isConnectivityDioError(e)) {
      throw ProfileApiException('', category: ProfileApiErrorCategory.network);
    }
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      throw ProfileApiException('', category: ProfileApiErrorCategory.session);
    }
    final extracted = extractApiDetailFromDio(e);
    if (extracted != null && extracted.isNotEmpty) {
      throw ProfileApiException(extracted, category: ProfileApiErrorCategory.serverDetail);
    }
    throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
  }

  ExperienceEntity _fromApi(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    final startDate = parseDate(json['start_date']) ?? DateTime.now();
    final endDate = parseDate(json['end_date']);
    return ExperienceEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['student_id'] ?? '').toString(),
      companyName: (json['company_name'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
      startYear: startDate.year,
      startMonth: startDate.month,
      endYear: endDate?.year,
      endMonth: endDate?.month,
      isCurrentJob: json['is_current'] == true,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> _toApiPayload(ExperienceEntity experience) {
    String formatDate(int year, int? month) {
      final m = (month ?? 1).clamp(1, 12).toString().padLeft(2, '0');
      return '$year-$m-01';
    }

    return {
      'company_name': experience.companyName.trim(),
      'position': experience.position.trim(),
      'start_date': formatDate(experience.startYear, experience.startMonth),
      'end_date': experience.isCurrentJob
          ? null
          : (experience.endYear != null
                ? formatDate(experience.endYear!, experience.endMonth)
                : null),
      'is_current': experience.isCurrentJob,
      'description': null,
    };
  }

  static const _cacheKey = 'experience';

  /// Work history changes rarely; a short TTL still meaningfully cuts
  /// redundant refetches from repeated profile-tab visits within a session.
  static const cacheTtl = Duration(minutes: 30);

  /// Stale-while-revalidate read for the initial load: returns cached items
  /// (possibly stale) plus a freshness flag, or `null` if nothing is cached.
  Future<({List<ExperienceEntity> items, bool isFresh})?> getCachedEntry() async {
    final entry = await ProfileCacheService.loadEntry(_cacheKey, cacheTtl);
    if (entry == null) return null;
    try {
      final items = entry.items.map(ExperienceEntity.fromJson).toList();
      return (items: items, isFresh: entry.isFresh);
    } catch (_) {
      return null;
    }
  }

  /// [cancelToken] lets a caller (e.g. a superseded refresh() call) abandon
  /// this request instead of letting it run to completion for a result that
  /// would just be discarded.
  @override
  Future<List<ExperienceEntity>> getExperienceList({CancelToken? cancelToken}) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/profile-resume/me/work-experiences',
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

  Future<List<ExperienceEntity>?> _loadCached() async {
    final maps = await ProfileCacheService.load(_cacheKey);
    if (maps == null) return null;
    try {
      return maps.map((m) => ExperienceEntity.fromJson(m)).toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ExperienceEntity>> getExperienceByUserId(String userId) async {
    return [];
  }

  @override
  Future<ExperienceEntity> addExperience(ExperienceEntity experience) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/profile-resume/me/work-experiences',
        data: _toApiPayload(experience),
      );
      final data = response.data;
      if (data == null) return experience;
      return _fromApi(data);
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  @override
  Future<ExperienceEntity> updateExperience(ExperienceEntity experience) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/profile-resume/me/work-experiences/${experience.id}',
        data: _toApiPayload(experience),
      );
      final data = response.data;
      if (data == null) return experience;
      return _fromApi(data);
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  @override
  Future<void> deleteExperience(String id) async {
    try {
      await _apiClient.dio.delete('/profile-resume/me/work-experiences/$id');
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }
}
