import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/dio_error_detail.dart';
import '../../domain/entities/orientation_results.dart';
import '../../domain/entities/reward.dart';
import '../models/orientation_reward_api_mapper.dart';

class OrientationRewardsSnapshot {
  const OrientationRewardsSnapshot({
    required this.rewards,
    required this.tokensBalance,
    required this.furtherRedeemsBlocked,
  });

  final List<Reward> rewards;
  final int tokensBalance;
  final bool furtherRedeemsBlocked;
}

/// Talks to `GET/POST /orientation/rewards…`.
class OrientationRewardsRemote {
  OrientationRewardsRemote({
    required ApiClient apiClient,
    required String Function() languageCode,
  })  : _apiClient = apiClient,
        _languageCode = languageCode;

  final ApiClient _apiClient;
  final String Function() _languageCode;

  Future<OrientationRewardsSnapshot> fetchRewards() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/orientation/rewards',
    );
    final data = response.data;
    if (data == null) {
      throw const OrientationRewardsApiException('Empty rewards response');
    }
    final lang = _languageCode();
    final rewards = (data['rewards'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => rewardFromApi(Map<String, dynamic>.from(e), lang))
        .toList(growable: false);
    return OrientationRewardsSnapshot(
      rewards: rewards,
      tokensBalance: (data['tokens_balance'] as num?)?.toInt() ?? 0,
      furtherRedeemsBlocked: data['further_redeems_blocked'] == true,
    );
  }

  Future<List<RewardRedemption>> fetchRedemptions() async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/orientation/rewards/redemptions',
    );
    final lang = _languageCode();
    return (response.data ?? const [])
        .whereType<Map>()
        .map((e) => redemptionFromApi(Map<String, dynamic>.from(e), lang))
        .toList(growable: false);
  }

  Future<RedeemRewardResult> redeem(String rewardId) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/orientation/rewards/$rewardId/redeem',
      );
      final data = response.data;
      if (data == null) {
        return RedeemRewardResult.error('Empty redeem response. Please try again.');
      }
      final lang = _languageCode();
      final reward = rewardFromApi(
        Map<String, dynamic>.from(data['reward'] as Map),
        lang,
      );
      return RedeemRewardResult.success(
        reward: reward,
        remainingTokens: (data['tokens_balance'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      return RedeemRewardResult.error(_messageFromDio(e));
    }
  }

  static String _messageFromDio(DioException e) {
    if (isConnectivityDioError(e)) {
      return 'No internet connection. Check your network and try again.';
    }
    final detail = extractApiDetailFromDio(e);
    return switch (detail) {
      'insufficient_tokens' => 'Not enough tokens.',
      'out_of_stock' => 'This prize is already claimed.',
      'further_redeems_blocked' =>
        'You already claimed an exclusive prize — no further redeems.',
      'reward_not_found' => 'Reward not found.',
      _ => detail?.isNotEmpty == true
          ? detail!
          : 'Could not redeem this prize. Please try again.',
    };
  }
}

class OrientationRewardsApiException implements Exception {
  const OrientationRewardsApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
