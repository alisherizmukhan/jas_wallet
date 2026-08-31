/// Browse-by-category buckets, matching the mockup's chip row. [all] is a
/// filter-only pseudo-category (never assigned to a reward).
enum RewardCategory { all, merch, giftCards, experiences, other }

/// Stock state of a reward, shown as a coloured availability badge.
enum RewardAvailability { unlimited, limited, outOfStock, comingSoon, expired }

/// The glyph/tint family behind a reward, and which product render it uses.
/// A semantic enum keeps this entity Flutter-free — `reward_visuals.dart`
/// maps each value to an image asset and accent colour.
enum RewardImage {
  earbuds,
  cup,
  bag,
  ticket,
  notebook,
  speaker,
  giftCard,
  movie,
  giftBox,
}

/// A single item in the Orientation Week reward shop.
class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.priceTokens,
    required this.category,
    required this.image,
    this.availability = RewardAvailability.unlimited,
    this.stockRemaining,
    this.isFeatured = false,
    this.isHot = false,
    this.blocksFurtherRedeems = false,
    this.canRedeem = true,
    this.alreadyRedeemed = false,
    this.terms = const [],
    this.redemptionSteps = const [],
  });

  final String id;
  final String title;
  final String description;
  final int priceTokens;
  final RewardCategory category;
  final RewardImage image;
  final RewardAvailability availability;

  /// Units left when [availability] is [RewardAvailability.limited]; null
  /// otherwise (unlimited / out of stock / coming soon).
  final int? stockRemaining;

  /// Appears in the horizontal "Featured Rewards" scroll.
  final bool isFeatured;

  /// Shows the small "Hot" badge in the card's corner.
  final bool isHot;

  /// Exclusive top-tier prize: claiming it locks the student out of every
  /// further redeem (server-enforced).
  final bool blocksFurtherRedeems;

  /// Whether *this* student may still press Redeem (stock + mutex + active).
  final bool canRedeem;

  final bool alreadyRedeemed;

  /// Fine print shown on the detail page.
  final List<String> terms;

  /// Numbered "how to redeem" steps on the detail page.
  final List<String> redemptionSteps;

  bool get isRedeemable =>
      canRedeem &&
      availability != RewardAvailability.outOfStock &&
      availability != RewardAvailability.comingSoon &&
      availability != RewardAvailability.expired;

  Reward copyWith({
    RewardAvailability? availability,
    int? stockRemaining,
    bool? canRedeem,
    bool? alreadyRedeemed,
  }) {
    return Reward(
      id: id,
      title: title,
      description: description,
      priceTokens: priceTokens,
      category: category,
      image: image,
      availability: availability ?? this.availability,
      stockRemaining: stockRemaining ?? this.stockRemaining,
      isFeatured: isFeatured,
      isHot: isHot,
      blocksFurtherRedeems: blocksFurtherRedeems,
      canRedeem: canRedeem ?? this.canRedeem,
      alreadyRedeemed: alreadyRedeemed ?? this.alreadyRedeemed,
      terms: terms,
      redemptionSteps: redemptionSteps,
    );
  }
}

/// One entry in the redemption history — a reward the student has already
/// claimed, with when and (for physical items) how to collect it.
class RewardRedemption {
  const RewardRedemption({
    required this.id,
    required this.reward,
    required this.redeemedAt,
    required this.spentTokens,
    this.collectionCode,
    this.isCollected = false,
  });

  final String id;
  final Reward reward;
  final DateTime redeemedAt;
  final int spentTokens;

  /// A short pickup/tracking code for physical rewards; null for digital.
  final String? collectionCode;

  final bool isCollected;
}

/// A token milestone on the bottom timeline. Reaching [threshold] tokens
/// *earned over the week* unlocks [rewardTitle].
class RewardMilestone {
  const RewardMilestone({
    required this.threshold,
    required this.rewardTitle,
    required this.rewardDescription,
  });

  final int threshold;
  final String rewardTitle;
  final String rewardDescription;
}
