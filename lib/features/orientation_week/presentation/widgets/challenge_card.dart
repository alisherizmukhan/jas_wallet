import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/orientation_challenge.dart';
import 'challenge_visuals.dart';
import '../theme/orientation_brand.dart';

/// One challenge in the grid.
///
/// Built to the same rules as Photo Quest's [PhotoMissionCard]: the card
/// stretches to its row's height, the title sits at the top, the reward is
/// pinned to the bottom by a `Spacer`, and a finished challenge recedes (dims
/// and shrinks) rather than being stamped — so both grids read as one
/// component and the eye stays on what is still open.
///
/// No icon at the top, on the same reasoning [PhotoMissionCard] uses: before
/// there is anything to show, a decorative glyph says nothing the title
/// doesn't. What leads instead is the plain text a photo quest card leads
/// with in place of an icon — there, a difficulty word; here, the verb the
/// button underneath will actually perform ("Scan", "Answer", "Open",
/// "Invite"), so the pill is information rather than decoration.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge, this.onTap});

  final OrientationChallenge challenge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = challengeAccent(challenge.kind);
    final done = challenge.isComplete;
    final tint = done ? FeatureStyle.stone : accent;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: FeatureStyle.chipTint(tint),
              borderRadius: BorderRadius.circular(FeatureStyle.rPill),
            ),
            child: Text(
              challengeActionLabel(challenge),
              style: FeatureStyle.tiny.copyWith(color: tint, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          challenge.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: FeatureStyle.cardTitle.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Text(
            done && challenge.kind.storesAnswer
                ? '${l10n.orientation_challenge_your_answer}: ${challenge.answer}'
                : challenge.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: FeatureStyle.tiny.copyWith(fontWeight: FontWeight.w400, height: 1.35),
          ),
        ),
        const SizedBox(height: 10),
        if (done)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(AppIcons.checkCircle, size: 14, color: OrientationBrand.accentTeal),
              const SizedBox(width: 4),
              Text(
                l10n.orientation_challenge_done,
                style: FeatureStyle.caption.copyWith(
                  color: OrientationBrand.accentTeal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Token artwork keeps its own colours — never tinted.
              const AppIcon(AppIcons.tokenAdsl, size: 14),
              const SizedBox(width: 4),
              Text(
                '+${challenge.rewardTokens}',
                style: FeatureStyle.caption.copyWith(color: accent, fontWeight: FontWeight.w800),
              ),
            ],
          ),
      ],
    );

    // Same recede as a finished Photo Quest or Club Bingo square: dim and
    // shrink, no badge.
    final card = AnimatedContainer(
      duration: FeatureStyle.animationDuration,
      curve: FeatureStyle.animationCurve,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: FeatureStyle.cardFill,
        borderRadius: BorderRadius.circular(FeatureStyle.rCard),
        border: FeatureStyle.cardBorder,
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

    final handler = onTap;
    return handler == null ? card : PressableScale(onTap: handler, child: card);
  }
}
