import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/photo_mission.dart';
import 'photo_mission_card.dart';

/// The two-column mission grid — [FeatureTwoColumnGrid] filled with
/// [PhotoMissionCard]s.
class PhotoMissionGrid extends StatelessWidget {
  const PhotoMissionGrid({
    super.key,
    required this.missions,
    required this.submittingMissionId,
    required this.onMissionTap,
    this.staggerFrom = Duration.zero,
  });

  final List<PhotoMission> missions;
  final String? submittingMissionId;
  final void Function(PhotoMission mission) onMissionTap;

  /// Base delay for the entrance stagger; each row adds one more step.
  final Duration staggerFrom;

  @override
  Widget build(BuildContext context) {
    return FeatureTwoColumnGrid(
      staggerFrom: staggerFrom,
      children: [
        for (final mission in missions)
          PhotoMissionCard(
            mission: mission,
            isSubmitting: submittingMissionId == mission.id,
            onTap: () => onMissionTap(mission),
          ),
      ],
    );
  }
}
