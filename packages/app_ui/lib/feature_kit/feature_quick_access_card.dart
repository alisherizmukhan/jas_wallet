import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_data.dart';
import 'feature_style.dart';
import 'pressable_scale.dart';

/// One tile in the "Quick Access" row.
///
/// Every tile is dimensionally identical by construction — same overall
/// height, same icon chip, and a label slot that always occupies exactly two
/// lines whether the label fills them or not. That fixed slot is the whole
/// point: previously each label was split into one `FittedBox` per word, so a
/// one-word label ("Challenges") produced a shorter, differently-centred
/// column than a two-word one ("Networking Bingo"), *and* each word was
/// scaled to a different font size. Four tiles ended up with four different
/// type sizes and four different icon baselines. Here the type size is fixed
/// and the icons line up across the row.
class FeatureQuickAccessCard extends StatelessWidget {
  const FeatureQuickAccessCard({super.key, required this.icon, required this.color, required this.label, required this.onTap});

  final AppIconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  static const double _iconChip = 40;
  static const double _labelLineHeight = 1.25;

  /// Fixed for the whole row, so no `IntrinsicHeight` is needed to keep the
  /// tiles in step. Sized generously enough for two lines of label under the
  /// icon chip; the label slot below takes whatever is left rather than the
  /// height being derived from font metrics, which rounds differently across
  /// text scales and overflowed by a couple of pixels when computed that way.
  static const double height = 104;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        // Minimum, not fixed: the four tiles are laid out in an
        // `IntrinsicHeight` row, so if a translation needs a second line every
        // tile grows together rather than one of them clipping.
        constraints: const BoxConstraints(minHeight: height),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: FeatureStyle.cardFill,
          borderRadius: BorderRadius.circular(FeatureStyle.rCard),
          border: FeatureStyle.cardBorder,
        ),
        child: Column(
          // Centred as a group rather than pinned to the top: a label that
          // only needs one line no longer leaves its slack dumped below it
          // as dead space — the whole icon+label block balances in whatever
          // height the tile ends up being, including the still-reserved
          // two-line case for a longer translation.
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The accent colour lives in the icon chip only — never as the
            // whole tile surface (Revolut keeps accents inside illustrations).
            Container(
              width: _iconChip,
              height: _iconChip,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(FeatureStyle.rChip)),
              child: Center(child: AppIcon(icon, size: 21, color: color)),
            ),
            const SizedBox(height: 8),
            // No ellipsis: the quick-access labels are their own short l10n
            // strings (`orientation_qa_*`) chosen to fit, and the tile grows
            // if a translation still needs two lines.
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: FeatureStyle.tiny.copyWith(
                fontWeight: FontWeight.w600,
                color: FeatureStyle.ink,
                height: _labelLineHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
