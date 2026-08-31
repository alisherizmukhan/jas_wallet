import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/orientation_schedule.dart';
import '../theme/orientation_brand.dart';

/// The week, as one row of five day cells — Orientation Week's "journey" and
/// its schedule are the same five days, so this is the one widget that draws
/// them instead of a progress strip on Home disagreeing with a date picker on
/// the Schedule page about what "day 3" means.
///
/// A cell's fill is where the two ideas actually merge:
/// - a day before today reads as *done* (ink fill, a check — the old journey
///   strip's completed state), because it is done whether or not a student
///   ever opens this page again;
/// - today reads as the current stop, unless something else is selected;
/// - the selected day (defaulting to today) gets the accent fill regardless
///   of where it sits in time, since that is the day the list below is
///   actually showing.
///
/// Deliberately not [AppCalendar]: that widget is a month grid meant to be
/// swiped between months, and Orientation Week is one fixed five-day window.
/// Wrapping five day cells in a swipeable month view would give a student a
/// whole calendar to scroll past to find the one week that exists.
class OrientationWeekStrip extends StatelessWidget {
  const OrientationWeekStrip({
    super.key,
    required this.schedule,
    required this.selected,
    required this.onSelect,
    required this.now,
  });

  final OrientationSchedule schedule;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  /// What counts as "today" — normally the real clock, but every caller
  /// reads this from [orientationNowProvider] so a debug time override moves
  /// this strip's completed/today markers along with the rest of the
  /// schedule.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = now;

    return Row(
      children: [
        for (var i = 0; i < schedule.days.length; i++) ...[
          if (i > 0) const SizedBox(width: FeatureStyle.s8),
          Expanded(
            child: _DayCell(
              day: schedule.days[i],
              isSelected: schedule.days[i].date == selected,
              isPast: schedule.days[i].date.isBefore(
                DateTime(today.year, today.month, today.day),
              ),
              isToday: schedule.days[i].date.year == today.year &&
                  schedule.days[i].date.month == today.month &&
                  schedule.days[i].date.day == today.day,
              locale: locale,
              onTap: () => onSelect(schedule.days[i].date),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isPast,
    required this.isToday,
    required this.locale,
    required this.onTap,
  });

  final ScheduleDay day;
  final bool isSelected;
  final bool isPast;
  final bool isToday;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Selection wins over everything: it is the day the list below is
    // actually showing, whatever its place in the calendar.
    final Color fill;
    final Color ink;
    final Border? border;
    if (isSelected) {
      fill = OrientationBrand.accent;
      ink = FeatureStyle.onDark;
      border = null;
    } else if (isPast) {
      // A fixed dark chip in both themes, not the theme-relative [FeatureStyle.ink]
      // getter — "past" is meant to read as a solid muted-dark tile regardless
      // of light/dark mode, not flip to a light fill once the theme does.
      fill = OrientationBrand.ink;
      ink = FeatureStyle.onDark;
      border = null;
    } else {
      fill = FeatureStyle.cardFill;
      ink = FeatureStyle.ink;
      border = Border.all(
        color: isToday ? OrientationBrand.accent : FeatureStyle.hairline,
        width: isToday ? 1.5 : 1,
      );
    }

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: FeatureStyle.animationDuration,
        curve: FeatureStyle.animationCurve,
        padding: const EdgeInsets.symmetric(vertical: FeatureStyle.s12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(FeatureStyle.rCard),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat.E(locale).format(day.date).toUpperCase(),
              style: FeatureStyle.tiny.copyWith(
                fontSize: 10,
                letterSpacing: 0.4,
                color: isSelected || isPast ? ink.withValues(alpha: 0.72) : FeatureStyle.stone,
              ),
            ),
            const SizedBox(height: 4),
            // A completed day reads as *done*, not as a date to keep reading —
            // the same reason the old journey strip swapped its number for a
            // check.
            if (isPast && !isSelected)
              const AppIcon(AppIcons.check, size: 16, color: FeatureStyle.onDark)
            else
              Text(
                '${day.date.day}',
                style: FeatureStyle.cardTitle.copyWith(
                  fontSize: 17,
                  color: ink,
                  fontFeatures: FeatureStyle.tabular,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
