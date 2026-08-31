import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/dio_error_detail.dart';
import '../../../../core/errors/profile_api_exception.dart';
import '../../../../core/services/profile_cache_service.dart';
import '../../domain/entities/skill_entity.dart';
import '../../domain/repositories/skills_repository.dart';

class SkillsRepositoryImpl implements SkillsRepository {
  SkillsRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

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

  SkillEntity _fromApi(Map<String, dynamic> json) {
    return SkillEntity(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  static const _cacheKey = 'skills';

  /// Skills change rarely; a short TTL still meaningfully cuts redundant
  /// refetches from repeated profile-tab visits within a session.
  static const cacheTtl = Duration(minutes: 30);

  /// Stale-while-revalidate read for the initial load: returns cached items
  /// (possibly stale) plus a freshness flag, or `null` if nothing is cached.
  Future<({List<SkillEntity> items, bool isFresh})?> getCachedEntry() async {
    final entry = await ProfileCacheService.loadEntry(_cacheKey, cacheTtl);
    if (entry == null) return null;
    try {
      final items = entry.items.map(SkillEntity.fromJson).toList();
      return (items: items, isFresh: entry.isFresh);
    } catch (_) {
      return null;
    }
  }

  /// [cancelToken] lets a caller (e.g. a superseded refresh() call) abandon
  /// this request instead of letting it run to completion for a result that
  /// would just be discarded.
  @override
  Future<List<SkillEntity>> getUserSkills({CancelToken? cancelToken}) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/profile-resume/me/skills',
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

  Future<List<SkillEntity>?> _loadCached() async {
    final maps = await ProfileCacheService.load(_cacheKey);
    if (maps == null) return null;
    try {
      return maps.map((m) => SkillEntity.fromJson(m)).toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SkillEntity>> getSkillsByUserId(String userId) async {
    return [];
  }

  @override
  Future<List<SkillEntity>> getAllAvailableSkills() async {
    return SkillEntity.suggestions;
  }

  @override
  Future<void> addSkill(SkillEntity skill) async {
    try {
      await _apiClient.dio.post(
        '/profile-resume/me/skills',
        data: {'name': skill.name.trim()},
      );
    } on DioException catch (e) {
      _throwFromDio(e);
    } on ProfileApiException {
      rethrow;
    } catch (_) {
      throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
    }
  }

  @override
  Future<void> removeSkill(String id) async {
    try {
      await _apiClient.dio.delete('/profile-resume/me/skills/$id');
    } on DioException catch (e) {
      _throwFromDio(e);
    } on ProfileApiException {
      rethrow;
    } catch (_) {
      throw ProfileApiException('', category: ProfileApiErrorCategory.unknown);
    }
  }

  @override
  Future<void> setSkills(List<SkillEntity> skills) async {
    final remote = await getUserSkills();
    final remoteByLowerName = {
      for (final s in remote) s.name.trim().toLowerCase(): s,
    };
    final targetByLowerName = {
      for (final s in skills.where((x) => x.name.trim().isNotEmpty))
        s.name.trim().toLowerCase(): s,
    };

    for (final remoteSkill in remote) {
      final key = remoteSkill.name.trim().toLowerCase();
      if (!targetByLowerName.containsKey(key)) {
        await removeSkill(remoteSkill.id);
      }
    }

    for (final entry in targetByLowerName.entries) {
      if (!remoteByLowerName.containsKey(entry.key)) {
        await addSkill(entry.value);
      }
    }
  }
}
