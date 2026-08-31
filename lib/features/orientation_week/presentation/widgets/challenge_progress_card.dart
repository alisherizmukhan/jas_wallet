import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/orientation_challenge.dart';
import '../theme/orientation_brand.dart';

/// "Challenges Progress" — the completed counter on the left (~70%) and
/// tokens earned so far on the right (~30%), split by a hairline rule. Same
/// proportions and type scale as [BingoProgressCard] and
/// [PhotoQuestProgressCard], so all three tabs' progress cards line up
/// visually rather than each tab inventing its own summary shape.
///
/// The right column reads differently than the other two by necessity:
/// Bingo and Photo Quest each pay one bonus for finishing everything, and
/// that fixed number is what their right column shows. Challenges has no
/// such bonus — every challenge pays for itself — so the honest figure there
/// is tokens earned so far, not a bonus that does not exist.
class ChallengeProgressCard extends StatelessWidget {
  const ChallengeProgressCard({super.key, required this.progress});

  final ChallengeProgress progress;

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
                    l10n.orientation_ch_progress_title,
                    style: FeatureStyle.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.orientation_ch_progress_subtitle,
                    style: FeatureStyle.caption.copyWith(fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.fraction),
                    duration: const Duration(milliseconds: 700),
                    curve: FeatureStyle.animationCurve,
                    builder: (context, value, _) =>
                        AppProgressBar(progress: value, height: 7, progressColor: OrientationBrand.accent),
                  ),
                  const SizedBox(height: 10),
                  _CompletedSentence(
                    completed: progress.completed,
                    template: l10n.orientation_ch_completed(progress.completed, progress.total),
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
                      '+${progress.tokensEarned}',
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
                    l10n.orientation_ch_tokens_earned,
                    textAlign: TextAlign.center,
                    style: FeatureStyle.tiny.copyWith(color: OrientationBrand.accentOrange, fontWeight: FontWeight.w600),
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

/// Renders "N / M challenges completed" with only the completed count tinted
/// purple, wherever that number lands in the sentence. Matched on digit
/// boundaries so it never tints a digit inside the total.
class _CompletedSentence extends StatelessWidget {
  const _CompletedSentence({required this.completed, required this.template});

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
