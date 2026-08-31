import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/leaderboard_entry.dart';
import 'orientation_avatar.dart';
import '../theme/orientation_brand.dart';

/// A compact top-N leaderboard for the Overview page — one rounded card,
/// borderless rows separated by whitespace rather than divider lines, in the
/// same no-clutter language as the podium above it. The current student's
/// row is marked the same way the podium marks them: an accent ring on the
/// avatar plus a small "You" tag, never a coloured block or bar.
class LeaderboardPreview extends StatelessWidget {
  const LeaderboardPreview({super.key, required this.entries, this.onTapEntry});

  /// Already sliced to the desired length (e.g. top 10) by the caller.
  final List<LeaderboardEntry> entries;

  /// Optional row tap (e.g. open a student profile).
  final void Function(LeaderboardEntry entry)? onTapEntry;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // FeatureCard already clips to its radius.
    return FeatureCard(
      padding: const EdgeInsets.symmetric(vertical: FeatureStyle.s4),
      child: Column(
        children: [
          for (final entry in entries)
            _PreviewRow(
              entry: entry,
              onTap: onTapEntry == null || entry.isCurrentUser ? null : () => onTapEntry!(entry),
            ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.entry, this.onTap});

  final LeaderboardEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final medal = switch (entry.rank) {
      1 => AppColors.gold,
      2 => const Color(0xFFB8C0CC),
      3 => const Color(0xFFCD9B6A),
      _ => null,
    };
    final isMe = entry.isCurrentUser;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Rank: a bold tabular number, medal-coloured for 1–3 — no chip,
          // no background, just type.
          SizedBox(
            width: 24,
            child: Text(
              '${entry.rank}',
              style: FeatureStyle.cardTitle.copyWith(
                color: medal ?? FeatureStyle.stone,
                fontWeight: FontWeight.w800,
                fontFeatures: FeatureStyle.tabular,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // The current student gets the same accent ring the podium uses —
          // never a coloured row background or a border bar.
          OrientationAvatar(
            student: entry.student,
            radius: 17,
            ringColor: isMe ? OrientationBrand.accent : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.student.fullName,
                    style: FeatureStyle.cardTitle.copyWith(fontSize: 14, color: FeatureStyle.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: FeatureStyle.chipTint(OrientationBrand.accent),
                      borderRadius: BorderRadius.circular(FeatureStyle.rPill),
                    ),
                    child: Text(
                      l10n.orientation_you,
                      style: FeatureStyle.tiny.copyWith(color: OrientationBrand.accent, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Token artwork keeps its own colours — never tinted.
          const AppIcon(AppIcons.tokenAdsl, size: 15),
          const SizedBox(width: 4),
          Text(
            '${entry.tokens}',
            style: FeatureStyle.cardTitle.copyWith(
              fontSize: 14,
              letterSpacing: -0.2,
              fontFeatures: FeatureStyle.tabular,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return PressableScale(onTap: onTap!, child: row);
  }
}

/// A tappable "Leaderboard / View All" section header, matching the Overview
/// page's other section headers.
class LeaderboardPreviewHeader extends StatelessWidget {
  const LeaderboardPreviewHeader({super.key, required this.title, required this.viewAllLabel, required this.onViewAll});

  final String title;
  final String viewAllLabel;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: FeatureStyle.sectionTitle)),
        PressableScale(
          onTap: onViewAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(viewAllLabel, style: FeatureStyle.secondary.copyWith(color: OrientationBrand.accent, fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              AppIcon(AppIcons.chevronRight, size: 16, color: OrientationBrand.accent),
            ],
          ),
        ),
      ],
    );
  }
}
