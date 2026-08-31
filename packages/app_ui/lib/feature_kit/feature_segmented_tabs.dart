import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_data.dart';
import 'feature_style.dart';

/// One tab in [FeatureSegmentedTabs].
class FeatureTabItem {
  const FeatureTabItem({required this.label, this.icon, this.iconColor});

  final String label;

  /// Optional — the "All" tab deliberately runs label-only, which buys the
  /// longest label the most room.
  final AppIconData? icon;

  /// Tint for [icon]. Defaults to the label colour when omitted.
  final Color? iconColor;
}

/// The one filter control shared by every tab that needs a category row.
///
/// Orientation Week's Photo Quest (All/Easy/Medium/Hard) and Rewards
/// (All/Merch/Gift Cards/…) and Club Fair's Clubs, Rewards and Photo Quest
/// rows all render through this exact widget, with no per-page variant: same
/// track, same pill, same height, same horizontally scrollable behaviour.
/// Nothing about the row changes from one page — or one feature — to the next.
///
/// Revolut sub-nav styling: a soft rounded-full track, with the selected tab
/// lifted onto a cobalt pill with white type — the same "emphasis" accent used
/// for every selected state — while the rest stay flat and muted. No
/// underline, no shadow.
class FeatureSegmentedTabs extends StatelessWidget {
  const FeatureSegmentedTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.accent,
  });

  final List<FeatureTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Overrides the shared [FeatureStyle.accent] selected-tab fill — null
  /// keeps the default (used by every caller that doesn't opt in, e.g. Club
  /// Fair).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: FeatureStyle.surfaceSoft,
          borderRadius: BorderRadius.circular(FeatureStyle.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: _Tab(
                  item: items[i],
                  isSelected: i == selectedIndex,
                  onTap: () => onChanged(i),
                  accent: accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.isSelected, required this.onTap, this.accent});

  final FeatureTabItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final labelColor = isSelected ? FeatureStyle.onDark : FeatureStyle.mute;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: FeatureStyle.animationDuration,
        curve: FeatureStyle.animationCurve,
        // Fixed height so every filter row in the app reads as one size.
        height: FeatureStyle.filterRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? (accent ?? FeatureStyle.accent) : Colors.transparent,
          borderRadius: BorderRadius.circular(FeatureStyle.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.icon != null) ...[
              // On the cobalt pill the glyph goes white for contrast;
              // unselected tabs keep their accent tint (colour lives in
              // iconography).
              AppIcon(
                item.icon!,
                size: 14,
                color: isSelected ? FeatureStyle.onDark : (item.iconColor ?? labelColor),
              ),
              const SizedBox(width: 4),
            ],
            // A tab label always stays on one line; the row scrolls rather
            // than any individual label wrapping or shrinking.
            Text(
              item.label,
              maxLines: 1,
              style: FeatureStyle.caption.copyWith(
                color: labelColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
