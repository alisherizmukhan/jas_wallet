import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/photo_mission.dart';
import 'photo_mission_visuals.dart';
import '../theme/orientation_brand.dart';

/// One mission in the Photo Quest grid.
///
/// The card stretches to its row's height (the grid wraps each pair in an
/// `IntrinsicHeight`), so the lead and title sit at the top and the
/// reward/status row is pinned to the bottom — two cards side by side always
/// line up, whatever their description length.
///
/// A finished mission is treated exactly like a finished Bingo square (see
/// [BingoTileView]): it fades back and shrinks a touch, reading as "done and
/// out of the way", rather than being stamped with a checkmark. Two grids in
/// the same feature marking completion two different ways is what made the
/// screens feel unrelated; the recede also keeps the eye on what's still
/// open, which is the thing a student actually needs to find.
class PhotoMissionCard extends StatelessWidget {
  const PhotoMissionCard({
    super.key,
    required this.mission,
    required this.isSubmitting,
    this.onTap,
  });

  final PhotoMission mission;
  final bool isSubmitting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = PhotoMissionVisuals.accent(mission.category);
    final done = mission.status == MissionStatus.completed;

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // No icon: a photo mission's own photo is the only image the card
          // should carry, and before one exists a decorative glyph says
          // nothing the title doesn't. Submitted missions lead with the
          // capture itself; open ones lead with a plain difficulty chip.
          _Lead(mission: mission, accent: accent, isSubmitting: isSubmitting),
          const SizedBox(height: 10),
          Text(mission.title, style: FeatureStyle.cardTitle.copyWith(fontSize: 14)),
          if (mission.location != null) ...[
            const SizedBox(height: 3),
            // Where to stand, on the line under what to shoot. A student
            // scanning the grid for "what can I do from here" reads places,
            // not descriptions.
            Row(
              children: [
                AppIcon(AppIcons.location, size: 11, color: accent),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    mission.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FeatureStyle.tiny.copyWith(color: accent, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 3),
          // Unclipped: the grid pairs cards in an `IntrinsicHeight` row, so a
          // longer description grows both cards rather than being cut off.
          Text(
            mission.description,
            style: FeatureStyle.tiny.copyWith(
              color: FeatureStyle.mute,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          Row(
            children: [
              // Token artwork keeps its own colours — never tinted.
              const AppIcon(AppIcons.tokenAdsl, size: 14),
              const SizedBox(width: 4),
              Text(
                '+${mission.rewardTokens}',
                style: FeatureStyle.caption.copyWith(
                  color: OrientationBrand.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      );

    // Same recede as a completed Bingo square: dim and shrink, no badge.
    final card = AnimatedContainer(
      duration: FeatureStyle.animationDuration,
      curve: FeatureStyle.animationCurve,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: FeatureStyle.cardFill,
        borderRadius: BorderRadius.circular(FeatureStyle.rCard),
        border: _statusBorder(mission.status),
      ),
      child: AnimatedScale(
        scale: done ? 0.94 : 1,
        duration: FeatureStyle.animationDuration,
        curve: FeatureStyle.animationCurve,
        child: AnimatedOpacity(
          opacity: done ? 0.42 : 1,
          duration: FeatureStyle.animationDuration,
          child: content,
        ),
      ),
    );

    if (onTap == null) return card;
    return PressableScale(onTap: onTap!, child: card);
  }

  /// The card's whole status signal.
  ///
  /// This used to be a caption in the bottom-right corner — "Pending review",
  /// "Needs a better photo" — set at the smallest size in the type scale, in
  /// the tightest corner of the tightest card in the feature. It was the least
  /// readable text in the app carrying some of the most important news.
  ///
  /// The border says the same thing at a glance and costs no layout: amber
  /// while a verdict is outstanding, red when the photo did not count. A
  /// finished mission keeps the plain hairline and lets the recede speak. The
  /// full wording still exists — on the detail page, where there is room for
  /// it.
  static Border _statusBorder(MissionStatus status) {
    return switch (status) {
      MissionStatus.uploading || MissionStatus.pendingReview =>
        Border.fromBorderSide(BorderSide(color: AppColors.orange, width: 1.5)),
      MissionStatus.rejected =>
        Border.fromBorderSide(BorderSide(color: AppColors.error, width: 1.5)),
      MissionStatus.available ||
      MissionStatus.completed ||
      MissionStatus.locked ||
      MissionStatus.expired =>
        FeatureStyle.cardBorder,
    };
  }
}

/// What the card leads with, in place of the old decorative glyph.
///
/// Once a photo exists it *is* the lead — a photo quest card showing the
/// student's own capture is the most useful thing that space can hold. Until
/// then there's no image to show, so the slot carries a plain difficulty chip
/// rather than an icon that would be identical on every card.
class _Lead extends StatelessWidget {
  const _Lead({required this.mission, required this.accent, required this.isSubmitting});

  final PhotoMission mission;
  final Color accent;
  final bool isSubmitting;

  static const double _photoHeight = 84;

  @override
  Widget build(BuildContext context) {
    if (isSubmitting) {
      return SizedBox(
        height: _photoHeight,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
        ),
      );
    }

    final path = mission.photoPath;
    if (path != null && path.isNotEmpty) {
      // A submitted photo lives on the server, so `photoPath` is an https URL
      // — decoding it with Image.file is why the grid showed a blank band
      // while the detail page (which already branched on the scheme) showed
      // the capture perfectly. Local paths still occur on the mock repository,
      // so both are handled.
      final isRemote = path.startsWith('http://') || path.startsWith('https://');
      return ClipRRect(
        borderRadius: BorderRadius.circular(FeatureStyle.rChip),
        child: SizedBox(
          height: _photoHeight,
          width: double.infinity,
          child: isRemote
              ? Image.network(
                  path,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : ColoredBox(color: FeatureStyle.surfaceSoft),
                  errorBuilder: (_, _, _) =>
                      ColoredBox(color: FeatureStyle.surfaceSoft),
                )
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  // A capture can be deleted from disk under us; fall back to
                  // the same neutral band an unstarted mission shows.
                  errorBuilder: (_, _, _) =>
                      ColoredBox(color: FeatureStyle.surfaceSoft),
                ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: FeatureStyle.chipTint(accent),
          borderRadius: BorderRadius.circular(FeatureStyle.rPill),
        ),
        child: Text(
          _difficultyLabel(context, mission.difficulty),
          style: FeatureStyle.tiny.copyWith(color: accent, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static String _difficultyLabel(BuildContext context, MissionDifficulty difficulty) {
    final l10n = AppLocalizations.of(context)!;
    return switch (difficulty) {
      MissionDifficulty.easy => l10n.orientation_pq_easy,
      MissionDifficulty.medium => l10n.orientation_pq_medium,
      MissionDifficulty.hard => l10n.orientation_pq_hard,
    };
  }
}

