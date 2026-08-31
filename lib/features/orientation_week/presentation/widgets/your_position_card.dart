import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/leaderboard_entry.dart';
import 'orientation_avatar.dart';
import '../theme/orientation_brand.dart';

/// The current student's own rank as the page's featured card — a cobalt
/// surface with white type (design.md `plan-card-featured`): the single
/// brand-colour stamp on the leaderboard.
class YourPositionCard extends StatelessWidget {
  const YourPositionCard({super.key, required this.entry, required this.entryAbove});

  final LeaderboardEntry entry;

  /// The entry ranked one place above [entry], if any — drives the
  /// "N tokens to rank #M" line. Null when [entry] is already #1.
  final LeaderboardEntry? entryAbove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gap = entryAbove == null ? 0 : entryAbove!.tokens - entry.tokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OrientationBrand.accent,
        borderRadius: BorderRadius.circular(FeatureStyle.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orientation_your_position.toUpperCase(),
            style: FeatureStyle.tiny.copyWith(color: Colors.white.withValues(alpha: 0.72), letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OrientationAvatar(student: entry.student, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.student.fullName,
                      style: FeatureStyle.cardTitle.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gap > 0 ? l10n.orientation_tokens_to_rank(gap, entryAbove!.rank) : l10n.orientation_top_of_leaderboard,
                      style: FeatureStyle.caption.copyWith(color: Colors.white.withValues(alpha: 0.72)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '#${entry.rank}',
                    style: FeatureStyle.display.copyWith(fontSize: 24, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(FeatureStyle.rPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Token artwork keeps its own colours — never tinted.
                        const AppIcon(AppIcons.tokenAdsl, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${entry.tokens}',
                          style: FeatureStyle.tiny.copyWith(color: FeatureStyle.ink, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
