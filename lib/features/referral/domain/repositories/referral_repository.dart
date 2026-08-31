import 'package:dio/dio.dart';

import '../models/leaderboard_entry.dart';
import '../models/referral_model.dart';

abstract class ReferralRepository {
  /// Load referral data for the authenticated user.
  ///
  /// BACKEND: GET /api/v1/referral/me
  ///   → { "referral_code": string, "invited_friends_count": int }
  Future<ReferralModel> getReferral({
    required String userId,
    required String username,
    CancelToken? cancelToken,
  });

  /// Refresh invite stats from the server without regenerating the code.
  ///
  /// BACKEND: GET /api/v1/referral/me/stats
  ///   → { "invited_friends_count": int }
  Future<ReferralModel> refreshStats({required String userId});

  /// Fetch the top referrers leaderboard.
  ///
  /// BACKEND: GET /referral/leaderboard?limit=10
  ///   → [ { "name": string, "referral_count": int, "is_current_user": bool, "avatar_url": string? }, ... ]
  Future<List<LeaderboardEntry>> getLeaderboard({required String userId});

  /// Attribute the current (authenticated) account to the owner of [code].
  ///
  /// BACKEND: POST /referral/redeem  { "referral_code": string }
  ///   200 = applied · 400 = self-referral · 404 = unknown code ·
  ///   409 = a code was already applied to this account.
  Future<void> redeemCode({required String code});
}
