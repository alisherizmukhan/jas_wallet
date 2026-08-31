import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/meal_schedule.dart';
import '../../domain/entities/meal_slot.dart';
import '../../providers/meal_schedule_provider.dart';
import '../widgets/svc_day_meal_sheet.dart';

class SVCMealCalendarPage extends ConsumerStatefulWidget {
  const SVCMealCalendarPage({super.key});

  @override
  ConsumerState<SVCMealCalendarPage> createState() =>
      _SVCMealCalendarPageState();
}

class _SVCMealCalendarPageState extends ConsumerState<SVCMealCalendarPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  List<AppCalendarEvent> _toCalendarEvents(
      List<MealSchedule> schedules, AppLocalizations l10n) {
    final events = <AppCalendarEvent>[];
    for (final schedule in schedules) {
      for (final entry in schedule.meals) {
        // Show all non-scheduled meals; for scheduled, show dots on past+today only
        if (entry.status == MealStatus.scheduled && entry.isFuture) continue;
        events.add(AppCalendarEvent(
          id: entry.id,
          title: _slotLabel(l10n, entry.slot),
          date: entry.date,
          color: _statusColor(entry.status),
          type: 'meal',
          metadata: entry,
        ));
      }
    }
    return events;
  }

  Color _statusColor(MealStatus status) => switch (status) {
        MealStatus.received => AppColors.green,
        MealStatus.cancelled => AppColors.orange,
        MealStatus.noShow => AppColors.red,
        MealStatus.scheduled => AppColors.primary,
      };

  String _slotLabel(AppLocalizations l10n, MealSlot slot) => switch (slot) {
        MealSlot.breakfast => l10n.svc_breakfast,
        MealSlot.lunch => l10n.svc_lunch,
        MealSlot.dinner => l10n.svc_dinner,
      };

  String _statusLabel(AppLocalizations l10n, MealStatus status) =>
      switch (status) {
        MealStatus.scheduled => l10n.svc_statusScheduled,
        MealStatus.cancelled => l10n.svc_statusCancelled,
        MealStatus.received => l10n.svc_statusReceived,
        MealStatus.noShow => l10n.svc_statusNoShow,
      };

  void _openDaySheet(DateTime date) {
    showDayMealSheet(context, ref, date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final monthAsync = ref.watch(mealMonthScheduleProvider(_month));

    final events = monthAsync.whenOrNull(
          data: (schedules) => _toCalendarEvents(schedules, l10n),
        ) ??
        const <AppCalendarEvent>[];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: l10n.svc_calendarTitle,
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: AppCalendar(
        events: events,
        accentColor: AppColors.primary,
        showEventList: true,
        todayLabel: l10n.svc_todayMeals,
        emptyStateTitle: l10n.svc_noMealsOnDay,
        emptyStateSubtitle: null,
        onDateSelected: (date) {
          // Track month changes for data loading
          final newMonth = DateTime(date.year, date.month);
          if (newMonth != _month) {
            setState(() => _month = newMonth);
          }
          // Open day detail sheet for any tapped date
          _openDaySheet(date);
        },
        onEventTap: (event) {
          final entry = event.metadata as MealEntry?;
          if (entry != null) {
            _openDaySheet(entry.date);
          }
        },
        eventBuilder: (ctx, event) => _CalendarMealTile(
          event: event,
          isDark: isDark,
          slotLabel: (slot) => _slotLabel(l10n, slot),
          statusLabel: (status) => _statusLabel(l10n, status),
        ),
      ),
    );
  }
}

// ─── Calendar Event Tile ──────────────────────────────────────────────────────

class _CalendarMealTile extends StatelessWidget {
  const _CalendarMealTile({
    required this.event,
    required this.isDark,
    required this.slotLabel,
    required this.statusLabel,
  });

  final AppCalendarEvent event;
  final bool isDark;
  final String Function(MealSlot) slotLabel;
  final String Function(MealStatus) statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = event.metadata as MealEntry?;
    final status = entry?.status ?? MealStatus.scheduled;
    final slot = entry?.slot;
    final color = event.color ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              slot != null ? slotLabel(slot) : event.title,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: _StatusPill(status: status, color: color, label: statusLabel(status)),
          ),
        ],
      ),
    );
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    required this.color,
    required this.label,
  });

  final MealStatus status;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
