import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_client.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/models/referral_model.dart';
import '../../domain/repositories/referral_repository.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  ReferralRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  // Local cache so the referral screen can render the last-known code/count
  // while offline. The server is the source of truth.
  static const _dataKey = 'referral_data_v1';

  @override
  Future<ReferralModel> getReferral({
    required String userId,
    required String username,
    CancelToken? cancelToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await _apiClient.dio.get(
        '/referral/me',
        cancelToken: cancelToken,
      );
      final model = ReferralModel.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
      await _persist(prefs, userId, model);
      return model;
    } on DioException {
      final cached = _readCache(prefs, userId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<ReferralModel> refreshStats({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _readCache(prefs, userId) ??
        const ReferralModel(referralCode: '', invitedFriendsCount: 0);
    final response = await _apiClient.dio.get('/referral/me/stats');
    final data = (response.data as Map).cast<String, dynamic>();
    final updated = existing.copyWith(
      invitedFriendsCount: data['invited_friends_count'] as int? ??
          existing.invitedFriendsCount,
    );
    await _persist(prefs, userId, updated);
    return updated;
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({required String userId}) async {
    final response = await _apiClient.dio.get(
      '/referral/leaderboard',
      queryParameters: {'limit': 10},
    );
    final data = response.data;
    final List rawEntries = data is List
        ? data
        : data is Map
            ? (data['entries'] as List? ?? data['items'] as List? ?? const [])
            : const [];
    return rawEntries
        .map((e) => LeaderboardEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> redeemCode({required String code}) async {
    await _apiClient.dio.post(
      '/referral/redeem',
      data: {'referral_code': code.trim().toUpperCase()},
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  ReferralModel? _readCache(SharedPreferences prefs, String userId) {
    final saved = prefs.getString('${_dataKey}_$userId');
    if (saved == null) return null;
    try {
      return ReferralModel.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist(
    SharedPreferences prefs,
    String userId,
    ReferralModel model,
  ) async {
    await prefs.setString('${_dataKey}_$userId', jsonEncode(model.toJson()));
  }
}
