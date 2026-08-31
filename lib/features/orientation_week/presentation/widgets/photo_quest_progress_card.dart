import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';


import '../../domain/entities/photo_mission.dart';
import '../theme/orientation_brand.dart';

/// "Photo Quest Progress" — the mission counter on the left (~70%) and the
/// all-missions bonus on the right (~30%), split by a hairline rule. Same
/// proportions and type scale as the Bingo progress card so the two tabs
/// line up visually.
class PhotoQuestProgressCard extends StatelessWidget {
  const PhotoQuestProgressCard({super.key, required this.progress});

  final PhotoQuestProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FeatureCard(
      padding: const EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 68,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.orientation_pq_progress_title,
                    style: FeatureStyle.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.orientation_pq_progress_subtitle,
                    style: FeatureStyle.caption.copyWith(fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.percent),
                    duration: const Duration(milliseconds: 700),
                    curve: FeatureStyle.animationCurve,
                    builder: (context, value, _) =>
                        AppProgressBar(progress: value, height: 7, progressColor: OrientationBrand.accent),
                  ),
                  const SizedBox(height: 10),
                  _MissionsSentence(
                    completed: progress.completedCount,
                    template: l10n.orientation_pq_missions_completed(
                      progress.completedCount,
                      progress.totalCount,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(width: 1, color: FeatureStyle.hairline),
            const SizedBox(width: 14),
            Expanded(
              flex: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Token artwork keeps its own colours — never tinted.
                  const AppIcon(AppIcons.tokenAdsl, size: 30),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+${progress.bonusTokens}',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: OrientationBrand.accent,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.orientation_bingo_bonus_tokens,
                    textAlign: TextAlign.center,
                    style: FeatureStyle.tiny.copyWith(color: OrientationBrand.accentCobalt, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.orientation_pq_complete_all,
                    textAlign: TextAlign.center,
                    style: FeatureStyle.tiny.copyWith(
                      color: OrientationBrand.accentCobalt,
                      fontWeight: FontWeight.w400,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders "N / M missions completed" with only the completed count tinted
/// purple, wherever that number lands in the sentence. Matched on digit
/// boundaries so it never tints a digit inside the total.
class _MissionsSentence extends StatelessWidget {
  const _MissionsSentence({required this.completed, required this.template});

  final int completed;
  final String template;

  @override
  Widget build(BuildContext context) {
    final base = FeatureStyle.secondary;
    final highlight = TextStyle(color: OrientationBrand.accent, fontWeight: FontWeight.w800, fontSize: 15);
    final match = RegExp(r'(?<!\d)' + RegExp.escape('$completed') + r'(?!\d)').firstMatch(template);

    if (match == null) return Text(template, style: base);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: template.substring(0, match.start)),
          TextSpan(text: '$completed', style: highlight),
          TextSpan(text: template.substring(match.end)),
        ],
      ),
    );
  }
}
