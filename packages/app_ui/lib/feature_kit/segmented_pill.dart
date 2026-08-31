import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';
import 'feature_style.dart';

/// A single option in a [SegmentedPill] row.
class SegmentedPillOption<T> {
  const SegmentedPillOption({required this.value, required this.label});
  final T value;
  final String label;
}

/// Apple-style segmented control — a track of equal-width pills with one
/// filled selection. Used for Leaderboard's scope selector and Club Fair's
/// Passport / Rewards section switches.
class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.scrollable = false,
    this.accent,
  });

  final T value;
  final List<SegmentedPillOption<T>> options;
  final ValueChanged<T> onChanged;

  /// More than three options rarely fit equal-width on a phone; scrollable
  /// lets the track run off the edge instead of crushing every label.
  final bool scrollable;

  /// Overrides the shared [FeatureStyle.accent] selected-pill fill — null
  /// keeps the default (used by every caller that doesn't opt in, e.g. Club
  /// Fair).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final track = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FeatureStyle.surfaceSoft,
        borderRadius: AppSpacing.borderRadiusRound,
      ),
      child: Row(
        mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
        children: [
          for (final option in options) _pill(option),
        ],
      ),
    );

    if (!scrollable) return track;
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: track);
  }

  Widget _pill(SegmentedPillOption<T> option) {
    final isSelected = option.value == value;
    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
      margin: scrollable ? const EdgeInsets.symmetric(horizontal: 3) : EdgeInsets.zero,
      decoration: BoxDecoration(
        // The same cobalt "emphasis" fill used for every selected state.
        color: isSelected ? (accent ?? FeatureStyle.accent) : Colors.transparent,
        borderRadius: AppSpacing.borderRadiusRound,
      ),
      alignment: Alignment.center,
      child: Text(
        option.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelMedium.copyWith(
          color: isSelected ? FeatureStyle.onDark : FeatureStyle.mute,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final tappable = GestureDetector(onTap: () => onChanged(option.value), child: pill);
    return scrollable ? tappable : Expanded(child: tappable);
  }
}
