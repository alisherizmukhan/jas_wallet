import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../config/orientation_links.dart';
import '../../domain/entities/reward.dart';
import 'reward_visuals.dart';
import '../theme/orientation_brand.dart';

/// Who redeemed a prize, shown at the desk.
///
/// Prizes are checked by hand rather than against a code, so what the person
/// handing one over needs is the student in front of them. The sheet is built
/// around that: the reward identifies itself at the top, the two facts about
/// the transaction sit in a stat strip, and the three fields that get read
/// aloud — name, student ID, email — are a grouped list underneath, set large
/// enough to read across a table and selectable for copying.
Future<void> showRedemptionDetailSheet(
  BuildContext context, {
  required RewardRedemption entry,
  required String? studentName,
  required String? studentId,
  required String? studentEmail,
}) {
  return AppBottomSheet.show<void>(
    context: context,
    child: _RedemptionDetailContent(
      entry: entry,
      studentName: studentName,
      studentId: studentId,
      studentEmail: studentEmail,
    ),
  );
}

class _RedemptionDetailContent extends StatelessWidget {
  const _RedemptionDetailContent({
    required this.entry,
    required this.studentName,
    required this.studentId,
    required this.studentEmail,
  });

  final RewardRedemption entry;
  final String? studentName;
  final String? studentId;
  final String? studentEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final tint = RewardVisuals.tint(entry.reward.image);
    final unset = l10n.orientation_rw_field_unset;
    final collected = entry.isCollected;
    final statusColor = collected ? AppColors.success : AppColors.orange;

    // [AppBottomSheet] hands its child the full width with no gutter of its
    // own, which is fine for the centred-text sheets in this feature but let
    // these cards run edge to edge. The gutter matches the sheet's own title
    // padding, so the content sits on the same margin the sheet already uses.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FeatureStyle.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── The prize itself ────────────────────────────────────────────
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(FeatureStyle.rHero),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Image.asset(RewardVisuals.photo(entry.reward), fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: FeatureStyle.s16),
          Text(
            entry.reward.title,
            textAlign: TextAlign.center,
            style: FeatureStyle.sectionTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: FeatureStyle.s8),
          Center(
            child: _StatusPill(
              color: statusColor,
              icon: collected ? AppIcons.checkCircle : AppIcons.time,
              label: collected ? l10n.orientation_rw_collected : l10n.orientation_rw_to_collect,
            ),
          ),
          const SizedBox(height: FeatureStyle.s20),

          // ── The transaction, as two equal figures ─────────────────────────
          FeatureCard(
            padding: const EdgeInsets.symmetric(horizontal: FeatureStyle.s16, vertical: 14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Stat(
                      label: l10n.orientation_rw_redeemed_on,
                      value: DateFormat.yMMMd(locale).format(entry.redeemedAt),
                      caption: DateFormat.Hm(locale).format(entry.redeemedAt),
                    ),
                  ),
                  VerticalDivider(
                    width: FeatureStyle.s20,
                    thickness: 1,
                    color: FeatureStyle.hairline,
                  ),
                  Expanded(
                    child: _Stat(
                      label: l10n.orientation_rw_tokens_spent,
                      value: entry.spentTokens.toString(),
                      valueIcon: AppIcons.tokenAdsl,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: FeatureStyle.s20),

          // ── Who to hand it to ─────────────────────────────────────────────
          Text(l10n.orientation_rw_redeemed_by, style: FeatureStyle.overline),
          const SizedBox(height: FeatureStyle.s8),
          FeatureCard(
            child: Column(
              children: [
                _Field(label: l10n.orientation_rw_field_name, value: studentName ?? unset),
                const _FieldDivider(),
                _Field(label: l10n.orientation_rw_field_student_id, value: studentId ?? unset),
                const _FieldDivider(),
                _Field(label: l10n.orientation_rw_field_email, value: studentEmail ?? unset),
              ],
            ),
          ),
          const SizedBox(height: FeatureStyle.s20),
          FeatureCtaButton(accent: OrientationBrand.accent, 
            label: l10n.orientation_rw_claim_cta,
            icon: AppIcons.whatsapp,
            onTap: () => openOrientationLink(OrientationLinks.prizeWhatsApp),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.color, required this.icon, required this.label});

  final Color color;
  final AppIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(FeatureStyle.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: FeatureStyle.caption.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// One half of the transaction strip: a small label over a large figure.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.caption, this.valueIcon});

  final String label;
  final String value;

  /// A second line under the figure — the time under the date.
  final String? caption;

  /// Rendered before the figure, untinted (the token artwork keeps its own
  /// colours).
  final AppIconData? valueIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: FeatureStyle.caption),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (valueIcon != null) ...[AppIcon(valueIcon!, size: 16), const SizedBox(width: 5)],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: FeatureStyle.cardTitle.copyWith(
                    fontSize: 16,
                    fontFeatures: FeatureStyle.tabular,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(caption!, style: FeatureStyle.tiny.copyWith(fontWeight: FontWeight.w400)),
        ],
      ],
    );
  }
}

/// A label above the line, its value below — the shape that survives a long
/// email address on a narrow phone, where a label/value row would either
/// truncate the email or push the label off the leading edge.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FeatureStyle.s16, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: FeatureStyle.caption),
          const SizedBox(height: 3),
          SelectableText(value, style: FeatureStyle.cardTitle.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: FeatureStyle.s16,
    endIndent: FeatureStyle.s16,
    color: FeatureStyle.hairline,
  );
}
