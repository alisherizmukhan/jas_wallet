import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';


import '../../domain/entities/bingo_board.dart';
import '../theme/orientation_brand.dart';

/// "Bingo Progress" card — the line counter on the left (~70%) and the grand
/// bonus on the right (~30%), split by a hairline rule as in the mockup.
///
/// Everything here is derived from [BingoProgress], which the board computes
/// from its own tiles, so the card can never disagree with the grid below it.
class BingoProgressCard extends StatelessWidget {
  const BingoProgressCard({super.key, required this.progress, this.bonusTokens = BingoBoard.grandBonusTokens});

  final BingoProgress progress;

  /// One-time payout for closing [BingoProgress.targetLines].
  final int bonusTokens;

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
                    l10n.orientation_bingo_progress_title,
                    style: FeatureStyle.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.orientation_bingo_progress_subtitle(progress.targetLines),
                    style: FeatureStyle.caption.copyWith(fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.lineProgress),
                    duration: const Duration(milliseconds: 700),
                    curve: FeatureStyle.animationCurve,
                    builder: (context, value, _) =>
                        AppProgressBar(progress: value, height: 7, progressColor: OrientationBrand.accent),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _LinesSentence(
                          completed: progress.completedLines,
                          template: l10n.orientation_bingo_lines_completed(
                              progress.completedLines, progress.targetLines),
                        ),
                      ),
                      const SizedBox(width: FeatureStyle.s8),
                      // How much of the board is closed, as a figure. The bar
                      // above tracks *lines*, which is what wins the bonus;
                      // this tracks squares, which is what the student is
                      // actually working through, and the two are rarely the
                      // same number.
                      Text(
                        '${(progress.totalTiles == 0 ? 0 : progress.completedTiles * 100 ~/ progress.totalTiles)}%',
                        style: FeatureStyle.caption.copyWith(
                          color: OrientationBrand.accent,
                          fontWeight: FontWeight.w800,
                          fontFeatures: FeatureStyle.tabular,
                        ),
                      ),
                    ],
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Token artwork keeps its own colours — never tinted.
                  const AppIcon(AppIcons.tokenAdsl, size: 30),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+$bonusTokens',
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
                    style: FeatureStyle.tiny.copyWith(color: OrientationBrand.accentTeal, fontWeight: FontWeight.w600),
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

/// Renders the localized "N / M lines completed" line with only the completed
/// count tinted purple, wherever that number lands in the sentence. Matched
/// on digit boundaries so it never tints a digit inside the total.
class _LinesSentence extends StatelessWidget {
  const _LinesSentence({required this.completed, required this.template});

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
