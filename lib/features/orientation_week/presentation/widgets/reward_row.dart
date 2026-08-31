import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';


import '../../domain/entities/reward.dart';
import 'reward_availability_badge.dart';
import 'reward_price_tag.dart';
import 'reward_visuals.dart';

/// One row of the "Token Rewards" list: product thumbnail, title/description/
/// availability, then the token price and a chevron. The rows share one
/// rounded container ([RewardListCard]) with hairline dividers between them.
class RewardRow extends StatelessWidget {
  const RewardRow({super.key, required this.reward, required this.onTap});

  final Reward reward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = RewardVisuals.tint(reward.image);

    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Image.asset(RewardVisuals.photo(reward), fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reward.title, style: FeatureStyle.cardTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RewardAvailabilityBadge(reward: reward, compact: true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            RewardPriceTag(tokens: reward.priceTokens, iconSize: 15, fontSize: 14),
            const SizedBox(width: 4),
            AppIcon(AppIcons.chevronRight, size: 15, color: FeatureStyle.stone),
          ],
        ),
      ),
    );
  }
}

/// The rounded white container that wraps the reward rows, drawing a hairline
/// divider between each.
class RewardListCard extends StatelessWidget {
  const RewardListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, indent: 14, endIndent: 14, color: FeatureStyle.hairline),
            children[i],
          ],
        ],
      ),
    );
  }
}
