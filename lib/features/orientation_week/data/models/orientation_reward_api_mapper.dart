import '../../domain/entities/reward.dart';

String pickLocalized(Object? raw, String languageCode) {
  if (raw is! Map) return '';
  final map = Map<String, dynamic>.from(raw);
  final value = map[languageCode] ?? map['en'] ?? map.values.firstOrNull;
  return value?.toString() ?? '';
}

List<String> pickLocalizedList(Object? raw, String languageCode) {
  if (raw is! Map) return const [];
  final map = Map<String, dynamic>.from(raw);
  final list = map[languageCode] ?? map['en'] ?? const [];
  if (list is! List) return const [];
  return [for (final item in list) item.toString()];
}

RewardCategory rewardCategoryFromApi(String? raw) => switch (raw) {
      'merch' => RewardCategory.merch,
      'gift_cards' || 'giftCards' => RewardCategory.giftCards,
      'experiences' => RewardCategory.experiences,
      'other' => RewardCategory.other,
      _ => RewardCategory.merch,
    };

RewardImage rewardImageFromApi(String? raw) => switch (raw) {
      'earbuds' => RewardImage.earbuds,
      'cup' => RewardImage.cup,
      'bag' => RewardImage.bag,
      'ticket' => RewardImage.ticket,
      'notebook' => RewardImage.notebook,
      'speaker' => RewardImage.speaker,
      'giftCard' || 'gift_card' => RewardImage.giftCard,
      'movie' => RewardImage.movie,
      'giftBox' || 'gift_box' => RewardImage.giftBox,
      _ => RewardImage.giftBox,
    };

RewardAvailability rewardAvailabilityFromApi(String? raw, int? stockRemaining) {
  return switch (raw) {
    'out_of_stock' => RewardAvailability.outOfStock,
    'coming_soon' => RewardAvailability.comingSoon,
    'expired' => RewardAvailability.expired,
    'limited' => RewardAvailability.limited,
    'unlimited' => RewardAvailability.unlimited,
    _ => stockRemaining == null
        ? RewardAvailability.unlimited
        : (stockRemaining <= 0
            ? RewardAvailability.outOfStock
            : RewardAvailability.limited),
  };
}

Reward rewardFromApi(Map<String, dynamic> json, String languageCode) {
  return Reward(
    id: json['id'] as String,
    title: pickLocalized(json['title'], languageCode),
    description: pickLocalized(json['description'], languageCode),
    priceTokens: (json['price_tokens'] as num?)?.toInt() ?? 0,
    category: rewardCategoryFromApi(json['category'] as String?),
    image: rewardImageFromApi(json['image_key'] as String?),
    availability: rewardAvailabilityFromApi(
      json['availability'] as String?,
      (json['stock_remaining'] as num?)?.toInt(),
    ),
    stockRemaining: (json['stock_remaining'] as num?)?.toInt(),
    isFeatured: json['is_featured'] == true,
    isHot: json['blocks_further_redeems'] == true,
    blocksFurtherRedeems: json['blocks_further_redeems'] == true,
    canRedeem: json['can_redeem'] != false,
    alreadyRedeemed: json['already_redeemed'] == true,
    terms: pickLocalizedList(json['terms'], languageCode),
    redemptionSteps: pickLocalizedList(json['redemption_steps'], languageCode),
  );
}

RewardRedemption redemptionFromApi(Map<String, dynamic> json, String languageCode) {
  final rewardJson = Map<String, dynamic>.from(json['reward'] as Map);
  return RewardRedemption(
    id: json['id'] as String,
    reward: rewardFromApi(rewardJson, languageCode),
    redeemedAt: DateTime.tryParse(json['redeemed_at']?.toString() ?? '') ??
        DateTime.now().toUtc(),
    spentTokens: (json['tokens_spent'] as num?)?.toInt() ?? 0,
    collectionCode: json['collection_code'] as String?,
    isCollected: json['is_collected'] == true,
  );
}
