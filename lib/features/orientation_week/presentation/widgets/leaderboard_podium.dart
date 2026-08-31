import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/leaderboard_entry.dart';
import 'orientation_avatar.dart';
import '../theme/orientation_brand.dart';

/// Medal palette for a podium place — a light top face, a base fill, and a
/// dark front face, so each column reads as a 3D block.
class _Medal {
  const _Medal(this.light, this.base, this.dark);
  final Color light;
  final Color base;
  final Color dark;

  static const gold = _Medal(Color(0xFFFFDF6E), Color(0xFFF5B301), Color(0xFFDD9600));
  static const silver = _Medal(Color(0xFFEDF0F6), Color(0xFFC4CCDA), Color(0xFF9BA6B8));
  static const bronze = _Medal(Color(0xFFEDB07A), Color(0xFFCD7F41), Color(0xFFA5602D));
}

/// Top-3 podium — rank 1 in the centre on the tallest 3D column, 2 and 3 on
/// either side. Revolut/Apple-styled: glossy gradient columns with a lighter
/// top cap and a soft cast shadow, a crown over first place, and token
/// amounts using the uncoloured token SVG.
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({super.key, required this.topThree, this.onTapEntry});

  /// Exactly the top 3 entries, sorted by rank ascending. Renders nothing if
  /// fewer than 3 are supplied.
  final List<LeaderboardEntry> topThree;
  final void Function(LeaderboardEntry entry)? onTapEntry;

  @override
  Widget build(BuildContext context) {
    if (topThree.length < 3) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumColumn(entry: topThree[1], height: 76, medal: _Medal.silver, onTap: onTapEntry)),
        const SizedBox(width: 10),
        Expanded(child: _PodiumColumn(entry: topThree[0], height: 104, medal: _Medal.gold, isFirst: true, onTap: onTapEntry)),
        const SizedBox(width: 10),
        Expanded(child: _PodiumColumn(entry: topThree[2], height: 58, medal: _Medal.bronze, onTap: onTapEntry)),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.height,
    required this.medal,
    this.isFirst = false,
    this.onTap,
  });

  final LeaderboardEntry entry;
  final double height;
  final _Medal medal;
  final bool isFirst;
  final void Function(LeaderboardEntry entry)? onTap;

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: AppIcon(AppIcons.crown, size: 20, color: Color(0xFFF5B301)),
          )
        else
          const SizedBox(height: 22),
        // Avatar with a medal ring — the current student gets a second,
        // outer accent ring so they can spot themselves at a glance even
        // when they've made the podium.
        Container(
          padding: EdgeInsets.all(isMe ? 3 : 0),
          decoration: isMe
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: OrientationBrand.accent, width: 2),
                )
              : null,
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [medal.light, medal.dark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: medal.base.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: OrientationAvatar(student: entry.student, radius: isFirst ? 26 : 22),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.student.fullName.split(' ').first,
          style: FeatureStyle.caption.copyWith(
            color: isMe ? OrientationBrand.accent : FeatureStyle.ink,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Token artwork keeps its own colours — never tinted.
            const AppIcon(AppIcons.tokenAdsl, size: 13),
            const SizedBox(width: 3),
            Text(
              '${entry.tokens}',
              style: FeatureStyle.caption.copyWith(color: FeatureStyle.ink, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Pillar(height: height, medal: medal, rank: entry.rank),
      ],
    );

    if (onTap == null) return column;
    return PressableScale(onTap: () => onTap!(entry), child: column);
  }
}

/// A single 3D podium block: a lighter top cap over a glossy gradient front
/// face, with the rank numeral embossed on it.
class _Pillar extends StatelessWidget {
  const _Pillar({required this.height, required this.medal, required this.rank});

  final double height;
  final _Medal medal;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [BoxShadow(color: medal.dark.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top cap — the lit face of the block.
          Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [medal.light, medal.base], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
          // Front face.
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [medal.base, medal.dark], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  shadows: [Shadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
