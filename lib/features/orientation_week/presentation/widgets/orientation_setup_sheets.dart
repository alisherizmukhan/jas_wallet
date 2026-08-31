import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/orientation_schedule.dart';
import '../theme/orientation_brand.dart';

/// "Which programme are you on?"
///
/// The timetable runs two parallel columns every day with genuinely different
/// sessions, so this is not a display preference — without an answer, half of
/// what a student is shown does not apply to them. Asked once, changeable from
/// the Schedule page.
Future<StudentTrack?> showTrackPicker(BuildContext context, {StudentTrack? current}) {
  final l10n = AppLocalizations.of(context)!;

  return AppBottomSheet.show<StudentTrack>(
    context: context,
    title: l10n.orientation_track_question,
    centerTitle: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: FeatureStyle.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.orientation_track_body,
            textAlign: TextAlign.center,
            style: FeatureStyle.secondary,
          ),
          const SizedBox(height: FeatureStyle.s16),
          Row(
            children: [
              for (final track in StudentTrack.values) ...[
                if (track != StudentTrack.values.first) const SizedBox(width: FeatureStyle.s12),
                Expanded(
                  child: _TrackOption(
                    icon: track == StudentTrack.undergraduate ? AppIcons.school : AppIcons.awards,
                    accent: track == StudentTrack.undergraduate
                        ? OrientationBrand.accentCobalt
                        : OrientationBrand.accentTeal,
                    label: track == StudentTrack.undergraduate
                        ? l10n.orientation_track_ug
                        : l10n.orientation_track_gr,
                    selected: current == track,
                    onTap: () => Navigator.of(context).pop(track),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: FeatureStyle.s16),
        ],
      ),
    ),
  );
}

/// One compact, square-ish choice card — the picker is a binary either/or,
/// so two of these side by side read faster and take less sheet height than
/// two full-width list rows stacked on top of each other.
class _TrackOption extends StatelessWidget {
  const _TrackOption({
    required this.icon,
    required this.accent,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppIconData icon;
  final Color accent;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: FeatureStyle.s16, horizontal: FeatureStyle.s12),
        decoration: BoxDecoration(
          color: selected ? FeatureStyle.chipTint(accent) : FeatureStyle.cardFill,
          borderRadius: BorderRadius.circular(FeatureStyle.rCard),
          border: Border.all(color: selected ? accent : FeatureStyle.hairline, width: selected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: FeatureStyle.chipTint(accent), shape: BoxShape.circle),
              child: Center(child: AppIcon(icon, size: 20, color: accent)),
            ),
            const SizedBox(height: FeatureStyle.s8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: FeatureStyle.caption.copyWith(
                color: FeatureStyle.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // Always reserved, just invisible when unselected — so the two
            // cards never change size depending on which one is picked.
            Opacity(
              opacity: selected ? 1 : 0,
              child: AppIcon(AppIcons.checkCircle, size: 16, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
