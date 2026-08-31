import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/dio_error_detail.dart';
import '../../../../core/errors/profile_api_exception.dart';
import '../../../../core/services/profile_cache_service.dart';
import '../../domain/entities/academy_entity.dart';
import '../../domain/repositories/academy_repository.dart';

class AcademyRepositoryImpl implements AcademyRepository {
  AcademyRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

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

  String _dateFirstOfMonth(int year, int? month) {
    final m = (month ?? 1).clamp(1, 12);
    return '${year.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-01';
  }

  AcademyEntity _fromApi(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    final start = parseDate(json['start_date']);
    final endRaw = json['end_date'];
    final end = endRaw != null ? parseDate(endRaw) : null;

    return AcademyEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['student_id'] ?? '').toString(),
      institutionName: (json['institution_name'] ?? '').toString(),
      degreeKind: (json['degree_kind'] ?? 'bachelor').toString(),
      degreeOther: json['degree_other'] as String?,
      specialization: (json['specialization'] ?? '').toString(),
      startYear: start.year,
      startMonth: start.month,
      endYear: end?.year,
      endMonth: end?.month,
      isCurrentlyStudying: json['is_current'] == true,
      gpa: (json['gpa'] as num?)?.toDouble(),
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> _toApiPayload(AcademyEntity e) {
    return {
      'institution_name': e.institutionName.trim(),
      'degree_kind': e.degreeKind.trim().toLowerCase(),
      'degree_other': e.degreeKind == 'other' ? e.degreeOther?.trim() : null,
      'specialization': e.specialization.trim(),
      'start_date': _dateFirstOfMonth(e.startYear, e.startMonth),
      'end_date': e.isCurrentlyStudying ? null : _dateFirstOfMonth(e.endYear!, e.endMonth),
      'is_current': e.isCurrentlyStudying,
      'gpa': e.gpa,
      'description': e.description?.trim().isEmpty ?? true ? null : e.description!.trim(),
    };
  }

  static const _cacheKey = 'academy';

  /// Education history changes rarely; a short TTL still meaningfully cuts
  /// redundant refetches from repeated profile-tab visits within a session.
  static const cacheTtl = Duration(minutes: 30);

  /// Stale-while-revalidate read for the initial load: returns cached items
  /// (possibly stale) plus a freshness flag, or `null` if nothing is cached.
  Future<({List<AcademyEntity> items, bool isFresh})?> getCachedEntry() async {
    final entry = await ProfileCacheService.loadEntry(_cacheKey, cacheTtl);
    if (entry == null) return null;
    try {
      final items = entry.items.map(AcademyEntity.fromJson).toList();
      return (items: items, isFresh: entry.isFresh);
    } catch (_) {
      return null;
    }
  }

  /// [cancelToken] lets a caller (e.g. a superseded refresh() call) abandon
  /// this request instead of letting it run to completion for a result that
  /// would just be discarded.
  @override
  Future<List<AcademyEntity>> getAcademyList({CancelToken? cancelToken}) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/profile-resume/me/educations',
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
    } on ProfileApiException {
      rethrow;
    } catch (_) {
      throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
    }
  }

  Future<List<AcademyEntity>?> _loadCached() async {
    final maps = await ProfileCacheService.load(_cacheKey);
    if (maps == null) return null;
    try {
      return maps.map((m) => AcademyEntity.fromJson(m)).toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AcademyEntity>> getAcademyByUserId(String userId) async {
    return [];
  }

  @override
  Future<AcademyEntity> addAcademy(AcademyEntity academy) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/profile-resume/me/educations',
        data: _toApiPayload(academy),
      );
      final data = response.data;
      if (data == null) {
        throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
      }
      return _fromApi(data);
    } on DioException catch (e) {
      _throwFromDio(e);
    } on ProfileApiException {
      rethrow;
    } catch (_) {
      throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
    }
  }

  @override
  Future<AcademyEntity> updateAcademy(AcademyEntity academy) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/profile-resume/me/educations/${academy.id}',
        data: _toApiPayload(academy),
      );
      final data = response.data;
      if (data == null) {
        throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
      }
      return _fromApi(data);
    } on DioException catch (e) {
      _throwFromDio(e);
    } on ProfileApiException {
      rethrow;
    } catch (_) {
      throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
    }
  }

  @override
  Future<void> deleteAcademy(String id) async {
    try {
      await _apiClient.dio.delete('/profile-resume/me/educations/$id');
    } on DioException catch (e) {
      _throwFromDio(e);
    } on ProfileApiException {
      rethrow;
    } catch (_) {
      throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
    }
  }
}
