import 'package:flutter/material.dart';

import 'feature_fade_in.dart';

/// The two-column card grid — Photo Quest missions, Club Fair collections.
///
/// Built from `IntrinsicHeight` rows rather than a `GridView` with a fixed
/// `childAspectRatio`: descriptions vary from one to three lines, and an
/// aspect ratio would either clip the long ones or leave the short ones
/// floating. Each pair sizes to its taller card, so the two columns always
/// line up and nothing ever overflows.
///
/// Children are expected to stretch — put the meta at the bottom behind a
/// `Spacer` and two cards side by side will agree on where their reward line
/// sits, whatever their copy does above it.
class FeatureTwoColumnGrid extends StatelessWidget {
  const FeatureTwoColumnGrid({
    super.key,
    required this.children,
    this.staggerFrom = Duration.zero,
  });

  final List<Widget> children;

  /// Base delay for the entrance stagger; each row adds one more step.
  final Duration staggerFrom;

  static const double gap = 12;
  static const Duration _step = Duration(milliseconds: 45);

  @override
  Widget build(BuildContext context) {
    final rowCount = (children.length + 1) ~/ 2;

    return Column(
      children: [
        for (var row = 0; row < rowCount; row++) ...[
          if (row > 0) const SizedBox(height: gap),
          FeatureFadeIn(
            delay: staggerFrom + _step * row,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _at(row * 2)),
                  const SizedBox(width: gap),
                  Expanded(child: _at(row * 2 + 1)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// An empty slot keeps the last row's single card at half width instead of
  /// stretching it across the grid.
  Widget _at(int index) =>
      index >= children.length ? const SizedBox.shrink() : children[index];
}
