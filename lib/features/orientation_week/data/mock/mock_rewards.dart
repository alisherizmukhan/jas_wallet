import '../../domain/entities/reward.dart';

/// Local fallback catalog (mock repository / widget tests).
/// Production uses the live backend seed — keep these three in sync.
List<Reward> mockRewards() => const [
      Reward(
        id: 'reward_apple_watch_se3',
        title: 'iPhone 17',
        description: 'iPhone 17 — the Club Fair top prize.',
        priceTokens: 9500,
        category: RewardCategory.merch,
        image: RewardImage.bag,
        availability: RewardAvailability.limited,
        stockRemaining: 1,
        isFeatured: true,
        isHot: true,
        blocksFurtherRedeems: true,
        terms: [
          'One unit available campus-wide.',
          'One exclusive top prize per student.',
        ],
        redemptionSteps: [
          'Tap Redeem and confirm — tokens are deducted immediately.',
          'Message +7 707 840 31 16 on WhatsApp and say which prize you claimed.',
          'Arrange pickup / activation with the team.',
        ],
      ),
      Reward(
        id: 'reward_airpods_4',
        title: 'AirPods 4',
        description: 'Apple AirPods (4th generation) — limited to one on campus.',
        priceTokens: 8000,
        category: RewardCategory.merch,
        image: RewardImage.earbuds,
        availability: RewardAvailability.limited,
        stockRemaining: 1,
        isFeatured: true,
        isHot: true,
        blocksFurtherRedeems: true,
        terms: [
          'One unit available campus-wide.',
          'One exclusive top prize per student.',
        ],
        redemptionSteps: [
          'Tap Redeem and confirm — tokens are deducted immediately.',
          'Message +7 707 840 3116 on WhatsApp and say which prize you claimed.',
          'Arrange pickup / activation with the team.',
        ],
      ),
      Reward(
        id: 'reward_gold_cafe_card',
        title: 'Gold Café Card',
        description:
            'A gold Apple Wallet card for one year: any one drink per day, free. Activation is arranged over WhatsApp after you redeem.',
        priceTokens: 6000,
        category: RewardCategory.experiences,
        image: RewardImage.giftCard,
        availability: RewardAvailability.limited,
        stockRemaining: 1,
        isFeatured: true,
        isHot: true,
        blocksFurtherRedeems: true,
        terms: [
          'One unit available campus-wide.',
          'One exclusive top prize per student.',
          'Activation via WhatsApp after redeem.',
        ],
        redemptionSteps: [
          'Tap Redeem and confirm — tokens are deducted immediately.',
          'Message +7 707 840 3116 on WhatsApp and say which prize you claimed.',
          'Arrange activation with the team.',
        ],
      ),
    ];

/// Milestones removed from the product — kept empty for the repository contract.
List<RewardMilestone> mockRewardMilestones() => const [];
