import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/club_fair_schedule.dart';
import '../theme/orientation_brand.dart';

/// Club Fair atrium timetable: day chips, then collapsible time blocks of clubs.
///
/// All booths share one place (Atrium) and two slots, so this is not the
/// Orientation Week timeline of unique times and rooms.
class ClubFairScheduleCard extends StatefulWidget {
  const ClubFairScheduleCard({super.key, required this.slots, this.showHeader = true});

  final List<ClubFairSlotGroup> slots;
  final bool showHeader;

  @override
  State<ClubFairScheduleCard> createState() => _ClubFairScheduleCardState();
}

class _ClubFairScheduleCardState extends State<ClubFairScheduleCard> {
  DateTime? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected ??= _initialDay();
  }

  DateTime? _initialDay() {
    final dates = _dates;
    if (dates.isEmpty) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final d in dates) {
      if (d.year == today.year && d.month == today.month && d.day == today.day) {
        return d;
      }
    }
    return dates.first;
  }

  List<DateTime> get _dates {
    final seen = <String, DateTime>{};
    for (final slot in widget.slots) {
      final d = slot.standDate;
      if (d == null) continue;
      final key = '${d.year}-${d.month}-${d.day}';
      seen.putIfAbsent(key, () => DateTime(d.year, d.month, d.day));
    }
    final list = seen.values.toList()..sort();
    return list;
  }

  ClubFairSlotGroup? _group(String slotKey) {
    final selected = _selected;
    for (final slot in widget.slots) {
      if (slot.slot != slotKey || slot.standDate == null || selected == null) continue;
      final d = slot.standDate!;
      if (d.year == selected.year && d.month == selected.month && d.day == selected.day) {
        return slot;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = _dates;
    final morning = _group('morning');
    final afternoon = _group('afternoon');
    final dayKey = _selected == null
        ? 'none'
        : '${_selected!.year}-${_selected!.month}-${_selected!.day}';

    return FeatureSection(
      title: l10n.orientation_schedule,
      overline: l10n.orientation_schedule_atrium.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dates.isNotEmpty) ...[
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final day = dates[i];
                  final selected = _selected != null &&
                      day.year == _selected!.year &&
                      day.month == _selected!.month &&
                      day.day == _selected!.day;
                  return PressableScale(
                    onTap: () => setState(() => _selected = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? OrientationBrand.accent
                            : FeatureStyle.chipTint(OrientationBrand.accent),
                        borderRadius: BorderRadius.circular(FeatureStyle.rPill),
                      ),
                      child: Text(
                        _dayLabel(day),
                        style: FeatureStyle.caption.copyWith(
                          color: selected ? FeatureStyle.onDark : OrientationBrand.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (morning != null && morning.clubs.isNotEmpty)
              _SlotBlock(
                key: ValueKey('$dayKey-morning'),
                label: l10n.orientation_schedule_morning,
                clubs: morning.clubs,
              ),
            if (afternoon != null && afternoon.clubs.isNotEmpty) ...[
              const SizedBox(height: 10),
              _SlotBlock(
                key: ValueKey('$dayKey-afternoon'),
                label: l10n.orientation_schedule_afternoon,
                clubs: afternoon.clubs,
              ),
            ],
            if ((morning == null || morning.clubs.isEmpty) &&
                (afternoon == null || afternoon.clubs.isEmpty))
              Text(
                l10n.orientation_schedule_empty_title,
                style: FeatureStyle.secondary,
              ),
          ],
        ],
      ),
    );
  }

  String _dayLabel(DateTime day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${names[day.weekday - 1]} ${day.day}';
  }
}

class _SlotBlock extends StatefulWidget {
  const _SlotBlock({super.key, required this.label, required this.clubs});

  final String label;
  final List<ClubFairClubItem> clubs;

  @override
  State<_SlotBlock> createState() => _SlotBlockState();
}

class _SlotBlockState extends State<_SlotBlock> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FeatureStyle.cardFill,
        borderRadius: BorderRadius.circular(FeatureStyle.rCard),
        border: FeatureStyle.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PressableScale(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: FeatureStyle.cardTitle.copyWith(fontSize: 14),
                  ),
                ),
                Text(
                  '${widget.clubs.length}',
                  style: FeatureStyle.caption.copyWith(
                    color: FeatureStyle.mute,
                    fontFeatures: FeatureStyle.tabular,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: FeatureStyle.mute,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final club in widget.clubs) _ClubChip(club: club),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ClubChip extends StatelessWidget {
  const _ClubChip({required this.club});

  final ClubFairClubItem club;

  @override
  Widget build(BuildContext context) {
    final accent = club.scanned
        ? OrientationBrand.accentTeal
        : club.inQuest
            ? OrientationBrand.accent
            : FeatureStyle.stone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: club.scanned ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (club.scanned) ...[
            AppIcon(AppIcons.check, size: 10, color: accent),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              club.name,
              style: FeatureStyle.tiny.copyWith(
                color: FeatureStyle.ink,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
