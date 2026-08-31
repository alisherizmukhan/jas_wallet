import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../config/orientation_links.dart';
import '../../domain/entities/orientation_schedule.dart';
import '../providers/orientation_schedule_provider.dart';
import 'orientation_setup_sheets.dart';
import 'schedule_session_row.dart';
import '../theme/orientation_brand.dart';

/// Today, on the Home tab — Orientation Week's schedule reduced to the one
/// day that matters on a tab a student opens constantly.
///
/// Deliberately not a day-picker: that is what the Full schedule page is
/// for. Home shows *today's* preview only — at most [_previewCount] rows,
/// soonest and mandatory first, with a plain count of what is left and one
/// button through to the full week.
///
/// Before a student has picked their programme this renders the prompt
/// instead. Showing them a day is not an option: half of every day belongs to
/// the other track, and a first-year reading the graduate column would go to
/// the wrong room.
class ScheduleHomeCard extends ConsumerWidget {
  const ScheduleHomeCard({super.key});

  static const _previewCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final track = ref.watch(orientationTrackProvider).valueOrNull;
    final schedule = ref.watch(orientationMyScheduleProvider);

    if (track == null) return TrackPrompt(l10n: l10n);
    if (schedule == null || schedule.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final day = schedule.dayFor(schedule.initialDate(now)) ?? schedule.days.first;
    final dayIndex = schedule.days.indexOf(day) + 1;
    final isToday = day.date.year == now.year && day.date.month == now.month && day.date.day == now.day;
    final nowMinutes = now.hour * 60 + now.minute;

    // The one session Home leads with: on today, whatever is happening or
    // coming up next; on any other day, the day's own first session. Everyone
    // else on the day is secondary to "what do I do right now".
    final byTime = [...day.sessions]..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final nextSession = isToday
        ? byTime.where((s) => s.endMinutes > nowMinutes).firstOrNull ?? byTime.lastOrNull
        : byTime.firstOrNull;
    final isOngoing = nextSession != null &&
        isToday &&
        nextSession.startMinutes <= nowMinutes &&
        nextSession.endMinutes > nowMinutes;

    // Soonest-first, but a mandatory session outranks an optional one at the
    // same time of day — the rows Home has room for should be the ones a
    // student cannot skip, not whichever happened to sort first.
    final rest = day.sessions.where((s) => s.id != nextSession?.id).toList()
      ..sort((a, b) {
        if (a.importance != b.importance) {
          return a.importance == SessionImportance.mandatory ? -1 : 1;
        }
        return a.startMinutes.compareTo(b.startMinutes);
      });
    final previewCount = nextSession == null ? _previewCount : _previewCount - 1;
    final preview = rest.take(previewCount).toList();
    final remaining = rest.length - preview.length;

    return FeatureSection(
      title: l10n.orientation_schedule,
      overline: l10n.orientation_schedule_label,
      actionLabel: l10n.orientation_schedule_full,
      onAction: () => context.push(AppRoutes.orientationSchedule),
      accentColor: OrientationBrand.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isToday ? l10n.orientation_schedule_today : day.label,
                  style: FeatureStyle.cardTitle.copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FeatureStyle.chipTint(OrientationBrand.accentCobalt),
                  borderRadius: BorderRadius.circular(FeatureStyle.rPill),
                ),
                child: Text(
                  l10n.orientation_journey_subtitle(dayIndex, schedule.days.length),
                  style: FeatureStyle.tiny.copyWith(color: OrientationBrand.accentCobalt, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: FeatureStyle.s12),
          if (day.sessions.isEmpty)
            FeatureCard(
              padding: const EdgeInsets.all(FeatureStyle.s20),
              child: Column(
                children: [
                  Text(l10n.orientation_schedule_empty_title, style: FeatureStyle.cardTitle),
                  const SizedBox(height: FeatureStyle.s4),
                  Text(
                    l10n.orientation_schedule_empty_body,
                    textAlign: TextAlign.center,
                    style: FeatureStyle.secondary,
                  ),
                ],
              ),
            )
          else ...[
            if (nextSession != null) ...[
              _NextSessionCard(session: nextSession, isOngoing: isOngoing),
              const SizedBox(height: FeatureStyle.s8),
            ],
            FeatureRowGroup(
              children: [for (final session in preview) CompactScheduleRow(session: session)],
            ),
            if (remaining > 0) ...[
              const SizedBox(height: FeatureStyle.s8),
              PressableScale(
                onTap: () => context.push(AppRoutes.orientationSchedule),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: FeatureStyle.s12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FeatureStyle.surfaceSoft,
                    borderRadius: BorderRadius.circular(FeatureStyle.rChip),
                  ),
                  child: Text(
                    '+$remaining more · ${l10n.orientation_schedule_full}',
                    style: FeatureStyle.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The one session Home leads the day with — bigger and accent-bordered so
/// it reads before the compact rows underneath it, on the same principle as
/// the leaderboard's "your position" card: one thing on the page is allowed
/// to be the loudest, and here that is "what do I do right now".
class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({required this.session, required this.isOngoing});

  final ScheduleSession session;
  final bool isOngoing;

  @override
  Widget build(BuildContext context) {
    final accent = scheduleImportanceAccent(session.importance);
    final link = session.link;

    final content = Container(
      padding: const EdgeInsets.all(FeatureStyle.s16),
      decoration: BoxDecoration(
        color: FeatureStyle.chipTint(accent),
        borderRadius: BorderRadius.circular(FeatureStyle.rCard),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.startLabel,
                style: FeatureStyle.rowValue.copyWith(fontSize: 16, color: accent),
              ),
              Text(
                session.endLabel,
                style: FeatureStyle.tiny.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: FeatureStyle.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(FeatureStyle.rPill),
                  ),
                  child: Text(
                    isOngoing ? 'NOW' : 'NEXT',
                    style: FeatureStyle.tiny.copyWith(
                      color: FeatureStyle.onDark,
                      fontSize: 10,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FeatureStyle.cardTitle.copyWith(fontSize: 15),
                ),
                if (session.place != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      AppIcon(AppIcons.location, size: 11, color: FeatureStyle.stone),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.place!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FeatureStyle.tiny.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (link == null) return content;
    return PressableScale(onTap: () => openOrientationLink(link), child: content);
  }
}

/// "Which programme are you on?" — shown wherever the schedule cannot be
/// resolved without an answer (the Home card, and the full Schedule page).
class TrackPrompt extends ConsumerWidget {
  const TrackPrompt({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureCard(
      padding: const EdgeInsets.all(FeatureStyle.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: FeatureStyle.iconChip,
                height: FeatureStyle.iconChip,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FeatureStyle.chipTint(OrientationBrand.accent),
                  borderRadius: BorderRadius.circular(FeatureStyle.rChip),
                ),
                child: AppIcon(AppIcons.calendar, size: 18, color: OrientationBrand.accent),
              ),
              const SizedBox(width: FeatureStyle.s12),
              Expanded(
                child: Text(l10n.orientation_track_question, style: FeatureStyle.cardTitle),
              ),
            ],
          ),
          const SizedBox(height: FeatureStyle.s12),
          Text(l10n.orientation_track_body, style: FeatureStyle.secondary),
          const SizedBox(height: FeatureStyle.s16),
          Row(
            children: [
              for (final track in StudentTrack.values) ...[
                if (track != StudentTrack.values.first)
                  const SizedBox(width: FeatureStyle.s12),
                Expanded(
                  child: FeatureCtaButton(accent: OrientationBrand.accent, 
                    label: track == StudentTrack.undergraduate
                        ? l10n.orientation_track_ug
                        : l10n.orientation_track_gr,
                    style: track == StudentTrack.undergraduate
                        ? FeatureCtaStyle.filled
                        : FeatureCtaStyle.outlined,
                    onTap: () =>
                        ref.read(orientationTrackProvider.notifier).select(track),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Opens the programme picker and stores the answer. Exposed so the Schedule
/// page and Home use the same one path.
Future<void> changeTrack(BuildContext context, WidgetRef ref, StudentTrack? current) async {
  final picked = await showTrackPicker(context, current: current);
  if (picked == null) return;
  await ref.read(orientationTrackProvider.notifier).select(picked);
}
