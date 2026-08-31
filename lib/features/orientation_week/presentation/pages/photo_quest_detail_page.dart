import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';


import '../../../../core/analytics/analytics_service.dart';
import '../../domain/entities/photo_mission.dart';
import '../providers/orientation_bingo_provider.dart';
import '../providers/orientation_dashboard_provider.dart';
import '../providers/orientation_leaderboard_provider.dart';
import '../providers/orientation_photo_quests_provider.dart';
import '../widgets/orientation_confetti.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/photo_mission_visuals.dart';
import '../widgets/photo_submission_sheet.dart';
import '../theme/orientation_brand.dart';

/// Mission detail — a full-bleed header, the brief, the photo checklist, the
/// reward and difficulty, and the capture action.
///
/// The header shows the student's own submitted photo once there is one;
/// before that it is a tinted panel with the mission's glyph, since no stock
/// campus photography ships with the app.
class PhotoQuestDetailPage extends ConsumerWidget {
  const PhotoQuestDetailPage({super.key, required this.mission});

  /// The mission as it was when the page was pushed. Live state is read from
  /// the provider so the page updates itself after a submission.
  final PhotoMission mission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(orientationPhotoQuestsProvider);
    final current = state.missions.firstWhere((m) => m.id == mission.id, orElse: () => mission);
    final accent = PhotoMissionVisuals.accent(current.category);
    final isSubmitting = state.submittingMissionId == current.id;

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(title: current.title, showTokens: true),
      body: SafeArea(
        bottom: false,
        child: FeaturePageBody(
          children: [
            FeatureFadeIn(child: _Header(mission: current, accent: accent)),
            FeatureFadeIn(
              delay: const Duration(milliseconds: 45),
              child: Text(
                current.description,
                style: FeatureStyle.body.copyWith(color: FeatureStyle.mute),
              ),
            ),
            if (current.location != null)
              FeatureFadeIn(
                delay: const Duration(milliseconds: 60),
                child: FeatureCard(
                  child: FeatureListRow(
                    icon: AppIcons.location,
                    iconColor: accent,
                    title: current.location!,
                    subtitle: l10n.orientation_pq_where,
                    showChevron: false,
                  ),
                ),
              ),
            FeatureFadeIn(
              delay: const Duration(milliseconds: 90),
              child: _FactsRow(mission: current, accent: accent),
            ),
            if (current.requirements.isNotEmpty)
              FeatureFadeIn(
                delay: const Duration(milliseconds: 135),
                child: _Checklist(
                  title: l10n.orientation_pq_requirements,
                  items: current.requirements,
                  isDone: current.isCompleted,
                ),
              ),
            FeatureFadeIn(
              delay: const Duration(milliseconds: 180),
              child: _Action(
                mission: current,
                isBusy: isSubmitting,
                onPressed: () => _choosePhoto(context, ref, current),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the source picker and applies whatever the student chose — a new
  /// photo (first submission or a replacement) or removing the current one.
  Future<void> _choosePhoto(BuildContext context, WidgetRef ref, PhotoMission mission) async {
    final choice = await showPhotoSubmissionSheet(context, mission);
    if (!context.mounted || choice == null) return;

    final notifier = ref.read(orientationPhotoQuestsProvider.notifier);
    final result = switch (choice) {
      SubmitPhoto(:final path) => await notifier.submit(mission.id, path),
      DeletePhoto() => await notifier.deletePhoto(mission.id),
    };
    if (!context.mounted) return;

    if (!result.isSuccess) {
      if (result.errorMessage != null) AppToast.showError(context, result.errorMessage!);
      return;
    }

    // Either way the balance may have moved, so refresh what the app bar pill,
    // leaderboard and bingo board read (a photo can close a bingo cell).
    ref.read(orientationDashboardProvider.notifier).load();
    ref.read(orientationLeaderboardProvider.notifier).load();
    ref.read(orientationBingoProvider.notifier).load();

    if (choice is DeletePhoto) return;

    AnalyticsService.instance.trackOrientationPhotoUploaded(questId: mission.id);
    if (result.tokensAwarded > 0) {
      AnalyticsService.instance
          .trackOrientationTokensEarned(amount: result.tokensAwarded, source: 'photo_quest');
    }

    final updated = result.mission ?? mission;
    final l10n = AppLocalizations.of(context)!;

    if (updated.status == MissionStatus.pendingReview) {
      AppToast.showInfo(
        context,
        result.userMessage ?? l10n.orientation_pq_status_pending,
      );
      return;
    }

    if (updated.status == MissionStatus.rejected || updated.status == MissionStatus.available) {
      // Verified as fail — student can retake.
      if (result.userMessage != null && result.userMessage!.isNotEmpty) {
        AppToast.showError(context, result.userMessage!);
      }
      return;
    }

    if (result.tokensAwarded == 0) return;

    RewardToastManager.showReward(
      context,
      RewardItem(
        title: result.reward.questCompleted ? l10n.orientation_pq_bonus_unlocked : mission.title,
        tokenAmount: result.tokensAwarded,
        icon: AppIcons.camera,
        tokenIcon: AppIcons.tokenAdsl,
      ),
    );
    if (result.reward.questCompleted) OrientationConfetti.play(context);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mission, required this.accent});

  final PhotoMission mission;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final path = mission.photoPath;
    final isNetwork = path != null &&
        (path.startsWith('http://') || path.startsWith('https://'));
    final isLocal = path != null && !isNetwork && File(path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(FeatureStyle.rCard),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: isNetwork
            ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => _EmptyFrame(accent: accent),
              )
            : isLocal
                ? Image.file(File(path), fit: BoxFit.cover)
                : _EmptyFrame(accent: accent),
      ),
    );
  }
}

class _EmptyFrame extends StatelessWidget {
  const _EmptyFrame({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FeatureStyle.surfaceSoft,
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.orientation_pq_take_photo,
          style: FeatureStyle.body.copyWith(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Reward and difficulty side by side, in the same card language as the
/// rest of the feature.
class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.mission, required this.accent});

  final PhotoMission mission;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final difficultyLabel = switch (mission.difficulty) {
      MissionDifficulty.easy => l10n.orientation_pq_easy,
      MissionDifficulty.medium => l10n.orientation_pq_medium,
      MissionDifficulty.hard => l10n.orientation_pq_hard,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Fact(
              label: l10n.orientation_pq_reward,
              // Token artwork keeps its own colours — never tinted.
              leading: const AppIcon(AppIcons.tokenAdsl, size: 18),
              value: '+${mission.rewardTokens}',
              valueColor: OrientationBrand.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Fact(
              label: l10n.orientation_pq_difficulty,
              leading: AppIcon(
                AppIcons.camera,
                size: 18,
                color: PhotoMissionVisuals.difficultyColor(mission.difficulty),
              ),
              value: difficultyLabel,
              valueColor: PhotoMissionVisuals.difficultyColor(mission.difficulty),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.leading, required this.value, required this.valueColor});

  final String label;
  final Widget leading;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FeatureStyle.tiny.copyWith(color: FeatureStyle.stone, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              leading,
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: FeatureStyle.cardTitle.copyWith(color: valueColor, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.title, required this.items, required this.isDone});

  final String title;
  final List<String> items;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FeatureStyle.cardFill,
        borderRadius: BorderRadius.circular(FeatureStyle.rCard),
        border: FeatureStyle.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FeatureStyle.cardTitle),
          const SizedBox(height: 10),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(
                  isDone ? AppIcons.checkCircle : AppIcons.circleCheck,
                  size: 16,
                  color: isDone ? AppColors.success : FeatureStyle.stone,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    items[i],
                    style: FeatureStyle.body.copyWith(
                      color: FeatureStyle.bodyInk,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The bottom action.
///
/// A capture button only while the mission is genuinely shootable, and a
/// static badge otherwise.
///
/// **A verified mission is final.** The button used to stay live after
/// completion so the student could swap their photo, but against the real
/// backend that is a trap: a replacement is verified from scratch and pays
/// nothing (the mission is already marked complete), so the only possible
/// outcomes are "no change" and "the good photo is gone". Re-shooting is
/// offered again exactly when it can help — after a CV `fail` (which the API
/// reports as `available`) or a moderator rejection.
class _Action extends StatelessWidget {
  const _Action({required this.mission, required this.isBusy, required this.onPressed});

  final PhotoMission mission;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (mission.canSubmit) {
      final hasPhoto = mission.status == MissionStatus.rejected;
      return FeatureCtaButton(accent: OrientationBrand.accent, 
        label: hasPhoto ? l10n.orientation_pq_retake : l10n.orientation_pq_take_photo,
        isLoading: isBusy,
        icon: AppIcons.camera,
        onTap: onPressed,
      );
    }

    final (label, color, icon) = switch (mission.status) {
      MissionStatus.completed =>
        (l10n.orientation_pq_completed, AppColors.success, AppIcons.verified),
      MissionStatus.uploading ||
      MissionStatus.pendingReview =>
        (l10n.orientation_pq_status_pending, AppColors.orange, AppIcons.pending),
      MissionStatus.locked => (l10n.orientation_pq_status_locked, FeatureStyle.stone, AppIcons.lock),
      _ => (l10n.orientation_pq_status_expired, FeatureStyle.stone, AppIcons.time),
    };

    return _Badge(label: label, color: color, icon: icon);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final AppIconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, style: FeatureStyle.cardTitle.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
