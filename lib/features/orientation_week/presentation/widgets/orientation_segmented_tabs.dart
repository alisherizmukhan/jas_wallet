import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import '../theme/orientation_brand.dart';


/// One tab in [OrientationSegmentedTabs].
class OrientationTabItem {
  const OrientationTabItem({required this.label, this.icon, this.iconColor});

  final String label;

  /// Optional — the "All" tab deliberately runs label-only, which buys the
  /// longest label the most room.
  final AppIconData? icon;

  /// Tint for [icon]. Defaults to the label colour when omitted.
  final Color? iconColor;
}

/// The one filter control shared by every Orientation Week tab that needs a
/// category row — Challenges (All/Daily/Explore/Activity), Photo Quest
/// (All/Easy/Medium/Hard) and Rewards (All/Merch/Gift Cards/Experiences/
/// Other) all render through this exact widget, with no per-page variant:
/// same track, same pill, same height, same horizontally scrollable
/// behaviour. Nothing about the row changes from one page to the next.
///
/// Revolut sub-nav styling: a soft rounded-full track, with the selected tab
/// lifted onto a cobalt pill with white type — the same "emphasis" accent
/// used for every selected state in the feature — while the rest stay flat
/// and muted. No underline, no shadow.
class OrientationSegmentedTabs extends StatelessWidget {
  const OrientationSegmentedTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<OrientationTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

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
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.isSelected, required this.onTap});

  final OrientationTabItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = isSelected ? FeatureStyle.onDark : FeatureStyle.mute;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: FeatureStyle.animationDuration,
        curve: FeatureStyle.animationCurve,
        // Fixed height so every filter row in the feature reads as one size.
        height: FeatureStyle.filterRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? OrientationBrand.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(FeatureStyle.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.icon != null) ...[
              // On the cobalt pill the glyph goes white for contrast; unselected
              // tabs keep their accent tint (colour lives in iconography).
              AppIcon(item.icon!, size: 14, color: isSelected ? FeatureStyle.onDark : (item.iconColor ?? labelColor)),
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
