import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/entities/photo_mission.dart';
import '../providers/orientation_photo_quests_provider.dart';
import '../widgets/mission_difficulty_tabs.dart';
import '../widgets/orientation_error_state.dart';
import '../widgets/orientation_skeletons.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/photo_mission_grid.dart';
import '../widgets/photo_quest_progress_card.dart';

/// Photo Quest — tab 3 of the Orientation Week shell.
///
/// A two-column grid of solo photo missions around campus: hero, progress
/// card, difficulty filter, grid, rewards CTA. Tapping a mission pushes its
/// detail page, where the capture → submit → verify → reward flow lives.
class PhotoQuestsPage extends ConsumerStatefulWidget {
  const PhotoQuestsPage({super.key});

  @override
  ConsumerState<PhotoQuestsPage> createState() => _PhotoQuestsPageState();
}

class _PhotoQuestsPageState extends ConsumerState<PhotoQuestsPage> {
  /// null = "All Missions".
  MissionDifficulty? _difficulty;

  Future<void> _openMission(PhotoMission mission) async {
    await context.push(AppRoutes.orientationPhotoQuestDetail, extra: mission);
    if (!mounted) return;
    // The detail page owns the submission flow; reload so the grid and the
    // progress card reflect whatever happened there.
    await ref.read(orientationPhotoQuestsProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(orientationPhotoQuestsProvider);

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(
        title: l10n.orientation_photo_quests,
        isShellRoot: true,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(orientationPhotoQuestsProvider.notifier).load(),
          child: _buildBody(context, l10n, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, PhotoQuestState state) {
    if (state.isLoading && state.missions.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(padding: EdgeInsets.only(top: 20), child: OrientationDashboardSkeleton()),
      );
    }
    if (state.error != null && state.missions.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: OrientationErrorState(onRetry: () => ref.read(orientationPhotoQuestsProvider.notifier).load()),
      );
    }

    final visible = state.filtered(_difficulty);
    const stagger = Duration(milliseconds: 45);

    return FeaturePageBody(
      children: [
        FeatureFadeIn(child: PhotoQuestProgressCard(progress: state.progress)),
        FeatureFadeIn(
          delay: stagger * 2,
          child: FeatureSection(
            title: l10n.orientation_photo_quests,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MissionDifficultyTabs(
                  selected: _difficulty,
                  allLabel: l10n.orientation_pq_all_missions,
                  labels: {
                    MissionDifficulty.easy: l10n.orientation_pq_easy,
                    MissionDifficulty.medium: l10n.orientation_pq_medium,
                    MissionDifficulty.hard: l10n.orientation_pq_hard,
                  },
                  onChanged: (d) => setState(() => _difficulty = d),
                ),
                const SizedBox(height: FeatureStyle.s16),
                if (visible.isEmpty)
                  FeatureEmptyState(
                    icon: AppIcons.camera,
                    title: l10n.orientation_pq_empty_filter,
                    message: l10n.orientation_pq_progress_subtitle,
                  )
                else
                  PhotoMissionGrid(
                    // Re-key on the filter so a new set animates in rather
                    // than snapping into place.
                    key: ValueKey(_difficulty),
                    missions: visible,
                    submittingMissionId: state.submittingMissionId,
                    onMissionTap: _openMission,
                    staggerFrom: stagger * 3,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
