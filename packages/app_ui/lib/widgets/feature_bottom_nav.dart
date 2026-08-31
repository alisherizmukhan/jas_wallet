import 'package:flutter/material.dart';

import '../feature_kit/feature_style.dart';
import '../icons/app_icon.dart';
import '../icons/app_icon_data.dart';
import '../tokens/app_colors.dart';

/// One item in a [FeatureBottomNav].
class FeatureNavItem {
  const FeatureNavItem({required this.icon, required this.label, required this.onTap});

  final AppIconData icon;
  final String label;
  final VoidCallback onTap;
}

/// The bottom navigation used by a *pushed* feature that has several tabs of
/// its own — Orientation Week, Club Fair.
///
/// Non-Material by design: equal icon+label cells with the current one in the
/// brand accent, a hairline rule on top, no elevation and no ripple, matching
/// the flat surface language the rest of the app uses. It lives in `app_ui`
/// rather than inside either feature so a second multi-tab feature does not
/// arrive with a second nav bar that is subtly two pixels different.
class FeatureBottomNav extends StatelessWidget {
  const FeatureBottomNav({super.key, required this.currentIndex, required this.items, this.accent});

  final int currentIndex;
  final List<FeatureNavItem> items;

  /// Overrides the shared [AppColors.primary] selected-tab colour — null
  /// keeps the default (used by every caller that doesn't opt in, e.g. Club
  /// Fair).
  final Color? accent;

  static const Duration _animation = Duration(milliseconds: 240);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FeatureStyle.cardFill,
        border: Border(top: BorderSide(color: FeatureStyle.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _NavCell(item: items[i], selected: i == currentIndex, accent: accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatefulWidget {
  const _NavCell({required this.item, required this.selected, this.accent});

  final FeatureNavItem item;
  final bool selected;
  final Color? accent;

  @override
  State<_NavCell> createState() => _NavCellState();
}

class _NavCellState extends State<_NavCell> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.accent ?? AppColors.primary;
    final color = widget.selected ? selectedColor : AppColors.grey;

    return GestureDetector(
      onTap: widget.item.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: widget.selected ? 1 : 0),
                duration: FeatureBottomNav._animation,
                curve: FeatureBottomNav._curve,
                builder: (context, t, child) => AppIcon(
                  widget.item.icon,
                  size: 22,
                  color: Color.lerp(AppColors.grey, selectedColor, t),
                ),
              ),
              const SizedBox(height: 4),
              // Keep multi-word labels ("Photo Quest") on one line, scaling
              // down rather than wrapping or breaking a word.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: color,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
