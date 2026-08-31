import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';


/// Frequently-asked questions about Orientation Week — expandable rows in one
/// rounded card, mirroring the SALTO Access page's FAQ structure but styled
/// with the Orientation type scale.
class OrientationFaqSection extends StatelessWidget {
  const OrientationFaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = <(String, String)>[
      (l10n.orientation_faq_q1, l10n.orientation_faq_a1),
      (l10n.orientation_faq_q2, l10n.orientation_faq_a2),
      (l10n.orientation_faq_q3, l10n.orientation_faq_a3),
      (l10n.orientation_faq_q4, l10n.orientation_faq_a4),
      (l10n.orientation_faq_q5, l10n.orientation_faq_a5),
      (l10n.orientation_faq_q6, l10n.orientation_faq_a6),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.orientation_faq_title, style: FeatureStyle.sectionTitle),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: FeatureStyle.cardFill,
            borderRadius: BorderRadius.circular(FeatureStyle.rCard),
            border: FeatureStyle.cardBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: FeatureStyle.hairline),
                // ExpansionTile paints ink on the nearest Material; without a
                // local one the card's DecoratedBox hides it and widget tests
                // throw a ListTile assertion that fails pumpAndSettle.
                Material(
                  color: Colors.transparent,
                  child: _FaqItem(question: items[i].$1, answer: items[i].$2),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    // Strip the ExpansionTile's default dividers so the card's own hairlines
    // are the only ones visible. Kept compact: smaller row height and text
    // sized to the page's body scale.
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent),
      child: ExpansionTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        minTileHeight: 44,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: FeatureStyle.ink,
        collapsedIconColor: FeatureStyle.stone,
        title: Text(question, style: FeatureStyle.body.copyWith(fontWeight: FontWeight.w600, color: FeatureStyle.ink)),
        children: [
          Text(
            answer,
            style: FeatureStyle.body.copyWith(color: FeatureStyle.mute, fontWeight: FontWeight.w400, height: 1.5),
          ),
        ],
      ),
    );
  }
}
