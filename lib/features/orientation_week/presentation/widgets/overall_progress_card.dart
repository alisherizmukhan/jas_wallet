import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import '../theme/orientation_brand.dart';



/// The feature's headline metric — the same white hairline card as every
/// other surface in the feature, so it sits harmoniously among the rest
/// rather than standing out as a separate dark object. Premiumness comes
/// from the oversized, tightly-tracked number and the single cobalt accent
/// on the ring/bar — not from a different surface colour. Purely
/// presentational.
class OverallProgressCard extends StatelessWidget {
  const OverallProgressCard({super.key, required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final percent = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

    return FeatureCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orientation_overall_progress.toUpperCase(),
            style: FeatureStyle.caption.copyWith(color: OrientationBrand.accentCobalt, fontWeight: FontWeight.w600, letterSpacing: 0.6),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent),
            duration: const Duration(milliseconds: 900),
            curve: FeatureStyle.animationCurve,
            builder: (context, value, _) => Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${(value * 100).round()}', style: FeatureStyle.display.copyWith(fontSize: 44, color: OrientationBrand.accent, letterSpacing: -1.2)),
                  const WidgetSpan(child: SizedBox(width: 3)),
                  TextSpan(text: '%', style: FeatureStyle.display.copyWith(fontSize: 22, color: OrientationBrand.accent.withValues(alpha: 0.5), letterSpacing: -0.4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: FeatureStyle.secondary,
              children: [
                TextSpan(text: '$completed', style: TextStyle(color: FeatureStyle.ink, fontWeight: FontWeight.w700)),
                TextSpan(text: ' / $total ${l10n.orientation_missions_completed_label}'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _AccentBar(percent: percent),
        ],
      ),
    );
  }
}

/// A slim rounded track on the soft neutral fill, with a cobalt fill that
/// animates in — the recurring "emphasis" pattern used across the feature.
class _AccentBar extends StatelessWidget {
  const _AccentBar({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 7,
        color: OrientationBrand.cream,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent),
            duration: const Duration(milliseconds: 900),
            curve: FeatureStyle.animationCurve,
            builder: (context, value, _) => FractionallySizedBox(
              widthFactor: value == 0 ? 0.0001 : value,
              child: Container(
                decoration: BoxDecoration(
                  color: OrientationBrand.accent,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
