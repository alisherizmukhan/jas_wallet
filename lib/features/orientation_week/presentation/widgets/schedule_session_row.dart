import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../config/orientation_links.dart';
import '../../domain/entities/orientation_schedule.dart';
import '../theme/orientation_brand.dart';

/// The accent an importance carries. Mandatory is the only one that gets the
/// brand cobalt: if everything is emphasised, a student cannot see which four
/// sessions they actually cannot miss.
Color scheduleImportanceAccent(SessionImportance importance) => switch (importance) {
      SessionImportance.mandatory => OrientationBrand.accent,
      SessionImportance.recommended => OrientationBrand.accentTeal,
      SessionImportance.optional => FeatureStyle.stone,
    };

/// One session in the day list.
///
/// The time is the leading column, not a trailing detail: a student reading a
/// day is scanning for "what is on at 11", and a title-first row makes them
/// read every line to find it. Rows are tappable only when there is something
/// behind them — an online session's join link — so a row that does nothing
/// never pretends otherwise.
class ScheduleSessionRow extends StatelessWidget {
  const ScheduleSessionRow({super.key, required this.session});

  final ScheduleSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = scheduleImportanceAccent(session.importance);
    final link = session.link;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FeatureStyle.s16,
        vertical: FeatureStyle.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.startLabel,
                  style: FeatureStyle.rowValue.copyWith(
                    fontSize: 14,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  session.endLabel,
                  style: FeatureStyle.tiny.copyWith(
                    fontWeight: FontWeight.w500,
                    fontFeatures: FeatureStyle.tabular,
                  ),
                ),
              ],
            ),
          ),
          // A hairline rail in the importance colour: it reads down the day as
          // a stripe, so "how much of today is mandatory" is answerable
          // without reading a single word.
          Container(
            width: 3,
            height: 34,
            margin: const EdgeInsets.only(right: FeatureStyle.s12, top: 2),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(session.title, style: FeatureStyle.cardTitle.copyWith(fontSize: 14)),
                if (session.place != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: AppIcon(AppIcons.location, size: 11, color: FeatureStyle.stone),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(session.place!, style: FeatureStyle.tiny.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                      ),
                    ],
                  ),
                ],
                if (session.note != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    session.note!,
                    style: FeatureStyle.tiny.copyWith(fontWeight: FontWeight.w400),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (session.importance == SessionImportance.mandatory)
                      _Tag(label: l10n.orientation_schedule_mandatory, accent: accent),
                    if (session.importance == SessionImportance.recommended)
                      _Tag(label: l10n.orientation_schedule_recommended, accent: accent),
                    if (link != null)
                      _Tag(
                        label: session.linkLabel ?? 'Online',
                        accent: OrientationBrand.accentCobalt,
                        icon: AppIcons.link,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (link == null) return content;
    return PressableScale(
      onTap: () => openOrientationLink(link),
      child: content,
    );
  }
}

/// One line: time, a coloured tick, the title — nothing else.
///
/// [ScheduleSessionRow] is built to hold everything a student needs once they
/// have committed to reading a day: place, notes, tags, a join link. That is
/// too much weight for a *preview* — a shared session like "Zumba, Pilates
/// and Yoga Club's activity" wraps onto two or three lines there and turns
/// Home's schedule card into the biggest thing on the page. This is what
/// Home actually shows: just the events, one line each, so a long title
/// truncates instead of growing the row. Full detail is one tap away, on the
/// full Schedule page.
class CompactScheduleRow extends StatelessWidget {
  const CompactScheduleRow({super.key, required this.session});

  final ScheduleSession session;

  @override
  Widget build(BuildContext context) {
    final accent = scheduleImportanceAccent(session.importance);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FeatureStyle.s16, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              session.startLabel,
              style: FeatureStyle.tiny.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
                fontFeatures: FeatureStyle.tabular,
              ),
            ),
          ),
          Container(
            width: 3,
            height: 14,
            margin: const EdgeInsets.only(right: FeatureStyle.s8),
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FeatureStyle.caption.copyWith(color: FeatureStyle.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.accent, this.icon});

  final String label;
  final Color accent;
  final AppIconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FeatureStyle.chipTint(accent),
        borderRadius: BorderRadius.circular(FeatureStyle.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon!, size: 10, color: accent),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: FeatureStyle.tiny.copyWith(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
