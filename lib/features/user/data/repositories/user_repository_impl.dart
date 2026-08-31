import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/dio_error_detail.dart';
import '../../../../core/services/avatar_cache_service.dart';
import '../../../../core/services/profile_cache_service.dart';
import '../../../../core/services/profile_pending_edit_service.dart';
import '../../../../core/utils/image_utils.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/repositories/user_repository.dart';

/// Implementation of UserRepository.
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required ApiClient apiClient,
    AvatarCacheService? avatarCacheService,
  }) : _apiClient = apiClient,
       _avatarCache = avatarCacheService ?? AvatarCacheService();

  final ApiClient _apiClient;
  final AvatarCacheService _avatarCache;

  // Current user data - cached in memory after first successful load
  UserEntity? _currentUser;
  UserStatsEntity _currentStats = const UserStatsEntity();

  @override
  Future<UserEntity?> getCachedCurrentUser() async {
    // Keep user data in memory for the active session until logout.
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
      final json = await ProfileCacheService.loadUser();
      if (json != null) {
        final storedUser = UserEntity.fromJson(json);
        if (storedUser.id.trim().isNotEmpty) {
          _currentUser = storedUser;
          // Load cached avatar path for offline display
          await _loadCachedAvatarPath();
          return _currentUser;
        }
      }
    } catch (_) {
      // Corrupt or incompatible cache — treat as no cached user.
    }

    return null;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final cached = await getCachedCurrentUser();
    if (cached != null) {
      return cached;
    }

    return refreshCurrentUser();
  }

  @override
  Future<UserEntity?> refreshCurrentUser() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/students/me',
      );
      final data = response.data;
      if (data != null) {
        final user = _mapBackendProfile(data);
        _currentUser = user;
        await _cacheUser(user); // Also caches avatar in background
        return user;
      }
      throw Exception('Invalid user response');
    } catch (e, st) {

      // Preserve UX continuity: if cache exists, keep serving it.
      final fallback = await getCachedCurrentUser();
      if (fallback != null) {
        return fallback;
      }

      Error.throwWithStackTrace(e, st);
    }
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    if (_currentUser != null && id == _currentUser!.id) {
      return _currentUser;
    }
    return null;
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    final hasStableIdentity = user.id.trim().isNotEmpty;

    // During pre-auth/registration drafts we keep state locally in notifier only.
    // Never bind repository cache to a transient empty-id user.
    if (!hasStableIdentity) {
      return user;
    }

    final baselineUser = _currentUser ?? await getCachedCurrentUser();
    final payload = _buildProfileUpdatePayload(user, baseline: baselineUser);

    if (payload.isNotEmpty) {
      try {
        final response = await _apiClient.dio.put<Map<String, dynamic>>(
          '/students/me',
          data: payload,
        );
        final data = response.data;
        if (data != null) {
          final updatedFromBackend = _mapBackendProfile(data);
          final merged = _mergeWithLocalDraft(updatedFromBackend, user);
          _currentUser = merged;
          await _cacheUser(merged);
          // This write just succeeded, so it supersedes anything queued
          // from an earlier failed attempt.
          await ProfilePendingEditService.clear();
          return merged;
        }
        throw Exception('Invalid profile update response');
      } on DioException catch (e) {
        // Connectivity failure (not a validation/auth rejection): queue the
        // attempted write so it can be silently replayed the next time the
        // app confirms it has a working connection (see [flushPendingEdit]).
        // Existing error surfacing to the caller is unchanged — this is a
        // pure backstop, not a substitute for it.
        if (isConnectivityDioError(e)) {
          await ProfilePendingEditService.save({
            'payload': payload,
            'draft': user.toJson(),
          });
        }
        throw _mapDioError(e);
      } catch (e) {
        rethrow;
      }
    }

    // Nothing to send: keep local state/cache.
    _currentUser = user;
    await _cacheUser(user);
    return _currentUser!;
  }

  /// Best-effort replay of a profile write queued by [updateUser] after a
  /// connectivity failure. Called opportunistically once the app has just
  /// confirmed a working connection (a successful `/students/me` GET) —
  /// never polls or gates on [ConnectivityService] itself.
  ///
  /// Silent by design: success or failure here is never surfaced to the UI.
  /// A later manual edit (or the original one, retried by the user) always
  /// wins — [updateUser] overwrites or clears this queue on every attempt.
  Future<void> flushPendingEdit() async {
    final pending = await ProfilePendingEditService.load();
    if (pending == null) return;

    final payload = pending['payload'];
    final draftJson = pending['draft'];
    if (payload is! Map<String, dynamic> || draftJson is! Map<String, dynamic>) {
      await ProfilePendingEditService.clear();
      return;
    }

    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/students/me',
        data: payload,
      );
      final data = response.data;
      if (data == null) return;

      final updatedFromBackend = _mapBackendProfile(data);
      final draft = UserEntity.fromJson(draftJson);
      final merged = _mergeWithLocalDraft(updatedFromBackend, draft);
      _currentUser = merged;
      await _cacheUser(merged);
      await ProfilePendingEditService.clear();
    } catch (_) {
      // Still offline, or the queued edit is no longer valid — leave it
      // queued (bounded by ProfilePendingEditService.maxAge) for the next
      // opportunistic flush.
    }
  }

  @override
  Future<UserEntity> uploadAvatar(String filePath) async {
    final trimmedPath = filePath.trim();
    final avatarFile = await _buildAvatarMultipartFile(trimmedPath);

    final formData = FormData.fromMap({'avatar': avatarFile});

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/students/me/avatar',
      data: formData,
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Invalid avatar upload response');
    }

    final updated = _mapBackendProfile(data);
    _currentUser = updated;
    // Evict stale cached avatar so the old image isn't shown
    // while the new one downloads in the background.
    setCachedAvatarPath(null);
    await _cacheUser(updated);
    return updated;
  }

  Future<MultipartFile> _buildAvatarMultipartFile(String path) async {
    if (path.startsWith('assets/')) {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final filename = path.split('/').last;
      return MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: _mimeTypeForPath(filename),
      );
    }

    final normalizedPath = path.startsWith('file://')
        ? Uri.parse(path).toFilePath()
        : path;
    final filename = normalizedPath.split(RegExp(r'[\\/]')).last;

    return MultipartFile.fromFile(
      normalizedPath,
      filename: filename,
      contentType: _mimeTypeForPath(filename),
    );
  }

  MediaType _mimeTypeForPath(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  @override
  Future<UserEntity> deleteAvatar() async {
    final response = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/students/me/avatar',
    );
    final data = response.data;
    if (data == null) {
      throw Exception('Invalid avatar delete response');
    }

    final updated = _mapBackendProfile(data);
    _currentUser = updated;
    // Clear stale cached avatar
    setCachedAvatarPath(null);
    _avatarCache.clearCache();
    await _cacheUser(updated);
    return updated;
  }

  @override
  Future<UserStatsEntity> getUserStats() async {
    return _currentStats;
  }

  @override
  Future<UserStatsEntity> updateUserStats(UserStatsEntity stats) async {
    _currentStats = stats;
    return _currentStats;
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _apiClient.dio.delete('/students/me');
      clearCache();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  void clearCache() {
    _currentUser = null;
    _currentStats = const UserStatsEntity();
    // Clear avatar cache on logout
    _avatarCache.clearCache();
    setCachedAvatarPath(null);
  }

  /// Load the cached avatar path and set it in image_utils for offline display.
  Future<void> _loadCachedAvatarPath() async {
    final cachedPath = await _avatarCache.getCachedAvatarPath();
    if (cachedPath != null) {
      setCachedAvatarPath(cachedPath);
    }
  }

  /// Cache the avatar image in background for offline use.
  void _cacheAvatarInBackground(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return;
    
    // Cache avatar in background (fire and forget)
    _avatarCache.cacheAvatarFromUrl(avatarUrl).then((cachedPath) {
      if (cachedPath != null) {
        setCachedAvatarPath(cachedPath);
      }
    });
  }

  Future<void> _cacheUser(UserEntity user) async {
    final userId = user.id.trim();
    if (userId.isEmpty) {
      // Do not overwrite auth session identity with a transient profile draft.
      return;
    }

    await ProfileCacheService.saveUser(user.toJson());

    // Cache avatar image for offline use (background, non-blocking)
    _cacheAvatarInBackground(user.avatarUrl);
  }

  UserEntity _mapBackendProfile(Map<String, dynamic> profile) {
    final id = _stringValue(profile['id']) ?? '';
    final username =
        _stringValue(profile['username']) ??
        (_stringValue(profile['email']) ?? id);

    return UserEntity(
      id: id,
      firstName: _stringValue(profile['first_name']) ?? '',
      lastName: _stringValue(profile['last_name']) ?? '',
      username: username,
      avatarUrl: _stringValue(profile['avatar_url']),
      bio: _stringValue(profile['bio']) ?? _stringValue(profile['about_me']),
      phone: _stringValue(profile['phone']),
      email: _stringValue(profile['email']),
      studentId: _stringValue(profile['nu_student_id']),
      gender: _stringValue(profile['gender']),
      dateOfBirth: _dateValue(profile['date_of_birth']),
      role: UserRole.student,
    );
  }

  UserEntity _mergeWithLocalDraft(
    UserEntity backendUser,
    UserEntity draftUser,
  ) {
    String choose(String backend, String draft) {
      final backendTrimmed = backend.trim();
      if (backendTrimmed.isNotEmpty) return backend;
      return draft;
    }

    String? chooseOptional(String? backend, String? draft) {
      final backendTrimmed = backend?.trim();
      if (backendTrimmed != null && backendTrimmed.isNotEmpty) {
        return backend;
      }

      final draftTrimmed = draft?.trim();
      if (draftTrimmed != null && draftTrimmed.isNotEmpty) {
        return draft;
      }
      return null;
    }

    return backendUser.copyWith(
      firstName: choose(backendUser.firstName, draftUser.firstName),
      lastName: choose(backendUser.lastName, draftUser.lastName),
      username: choose(backendUser.username, draftUser.username),
      bio: chooseOptional(backendUser.bio, draftUser.bio),
      phone: chooseOptional(backendUser.phone, draftUser.phone),
      email: chooseOptional(backendUser.email, draftUser.email),
      studentId: chooseOptional(backendUser.studentId, draftUser.studentId),
      gender: chooseOptional(backendUser.gender, draftUser.gender),
      avatarUrl: chooseOptional(backendUser.avatarUrl, draftUser.avatarUrl),
      dateOfBirth: backendUser.dateOfBirth ?? draftUser.dateOfBirth,
      city: chooseOptional(backendUser.city, draftUser.city),
    );
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  DateTime? _dateValue(dynamic value) {
    final dateStr = _stringValue(value);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  Exception _mapDioError(DioException e) {
    final data = e.response?.data;
    String message = e.message ?? 'Network error';

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map<String, dynamic>) {
          final msg = first['msg'];
          if (msg is String && msg.trim().isNotEmpty) {
            message = msg;
          }
        } else {
          final value = first.toString().trim();
          if (value.isNotEmpty) {
            message = value;
          }
        }
      }
    }

    return Exception(message);
  }

  Map<String, dynamic> _buildProfileUpdatePayload(
    UserEntity user, {
    UserEntity? baseline,
  }) {
    final payload = <String, dynamic>{};

    void putChangedString(String key, String? next, String? previous) {
      if (next == null) return;
      final trimmed = next.trim();
      if (trimmed.isEmpty) return;
      final previousTrimmed = previous?.trim();
      if (previousTrimmed == trimmed) return;
      payload[key] = trimmed;
    }

    // For optional fields that the user is allowed to clear: when the value
    // changed to empty, send "" so the backend (which clears on empty string)
    // actually removes it. A null `next` means the field wasn't part of the
    // edit and is left untouched.
    void putClearableString(String key, String? next, String? previous) {
      if (next == null) return;
      final trimmed = next.trim();
      final previousTrimmed = previous?.trim() ?? '';
      if (previousTrimmed == trimmed) return;
      payload[key] = trimmed;
    }

    putChangedString('first_name', user.firstName, baseline?.firstName);
    putChangedString('last_name', user.lastName, baseline?.lastName);
    putChangedString('username', user.username, baseline?.username);
    putClearableString('bio', user.bio, baseline?.bio);
    putClearableString('phone', user.phone, baseline?.phone);
    putChangedString('gender', user.gender, baseline?.gender);

    final avatarUrl = user.avatarUrl?.trim();
    final baselineAvatarUrl = baseline?.avatarUrl?.trim();
    final avatarChanged = avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl != baselineAvatarUrl;
    if (avatarChanged && _canSendAvatarUrlViaProfileUpdate(avatarUrl)) {
      payload['avatar_url'] = avatarUrl;
    }

    final nextDob = user.dateOfBirth;
    final baselineDob = baseline?.dateOfBirth;
    final dobChanged = !_isSameDay(nextDob, baselineDob);
    if (nextDob != null && dobChanged) {
      payload['date_of_birth'] = nextDob.toIso8601String().split('T').first;
    }

    return payload;
  }

  bool _canSendAvatarUrlViaProfileUpdate(String avatarUrl) {
    // Backend currently accepts built-in avatar assets in profile update.
    // Uploaded/custom images must go through /students/me/avatar endpoint.
    return avatarUrl.startsWith('assets/avatars/');
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
