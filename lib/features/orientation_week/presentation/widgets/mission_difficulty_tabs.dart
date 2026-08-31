import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/photo_mission.dart';
import 'orientation_segmented_tabs.dart';
import 'photo_mission_visuals.dart';

/// Escalating glyphs, so the icon reinforces the label instead of repeating
/// a camera on all three.
AppIconData _icon(MissionDifficulty difficulty) => switch (difficulty) {
      MissionDifficulty.easy => AppIcons.star,
      MissionDifficulty.medium => AppIcons.flame,
      MissionDifficulty.hard => AppIcons.gem,
    };

/// Difficulty filter for the Photo Quest grid.
///
/// Built to match Challenges' category tabs exactly — same shared tab bar,
/// same icon-plus-label shape, same "All" tab leading with the grid glyph.
///
/// Each difficulty carries a *distinct* icon rather than the camera repeated
/// three times: a glyph that's identical on every tab carries no information
/// and just makes the row heavier. These escalate — one star, flame, gem —
/// so the icons say the same thing the labels do.
///
/// A null [selected] means "All Missions".
class MissionDifficultyTabs extends StatelessWidget {
  const MissionDifficultyTabs({
    super.key,
    required this.selected,
    required this.allLabel,
    required this.labels,
    required this.onChanged,
  });

  final MissionDifficulty? selected;
  final String allLabel;

  /// Label per difficulty.
  final Map<MissionDifficulty, String> labels;
  final ValueChanged<MissionDifficulty?> onChanged;

  @override
  Widget build(BuildContext context) {
    return OrientationSegmentedTabs(
      selectedIndex: selected == null ? 0 : MissionDifficulty.values.indexOf(selected!) + 1,
      onChanged: (index) =>
          onChanged(index == 0 ? null : MissionDifficulty.values[index - 1]),
      items: [
        OrientationTabItem(label: allLabel, icon: AppIcons.grid),
        for (final difficulty in MissionDifficulty.values)
          OrientationTabItem(
            label: labels[difficulty] ?? difficulty.name,
            icon: _icon(difficulty),
            iconColor: PhotoMissionVisuals.difficultyColor(difficulty),
          ),
      ],
    );
  }
}
