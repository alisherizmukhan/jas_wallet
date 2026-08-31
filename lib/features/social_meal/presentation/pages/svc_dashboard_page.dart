import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../../tutorial/data/tutorial_service.dart';
import '../../../tutorial/domain/tutorial_content.dart';
import '../../../tutorial/domain/tutorial_ids.dart';
import '../../../tutorial/presentation/pages/tutorial_story_page.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/meal_schedule.dart';
import '../../domain/entities/meal_slot.dart';
import '../../domain/entities/meal_streak.dart';
import '../../providers/meal_schedule_provider.dart';
import '../widgets/dashboard/svc_faq_section.dart';

class SVCDashboardPage extends ConsumerStatefulWidget {
  const SVCDashboardPage({super.key});

  @override
  ConsumerState<SVCDashboardPage> createState() => _SVCDashboardPageState();
}

class _SVCDashboardPageState extends ConsumerState<SVCDashboardPage> {
  @override
  void initState() {
    super.initState();
    final shouldShowTutorial =
        TutorialService.instance.shouldShowSync(TutorialIds.svcMeal);
    if (shouldShowTutorial) {
      TutorialService.instance.markSeenSync(TutorialIds.svcMeal);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AnalyticsService.instance.trackSvcOpened();
      ref.read(mealScheduleProvider.notifier).load();
      ref.read(mealStreakProvider.notifier).load();
      if (shouldShowTutorial) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder<void>(
            opaque: true,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (ctx, animation, _) => FadeTransition(
              opacity: animation,
              child: TutorialStoryPage(
                tutorialId: TutorialIds.svcMeal,
                slides: TutorialContent.svcMeal(l10n),
              ),
            ),
          ),
        );
      }
    });
  }

  Future<void> _refresh() async {
    await ref.read(mealScheduleProvider.notifier).load();
    await ref.read(mealStreakProvider.notifier).load(full: true);
  }

  String _greeting(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 12) return l10n.svc_greetingMorning;
    if (h < 17) return l10n.svc_greetingAfternoon;
    return l10n.svc_greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final streakAsync = ref.watch(mealStreakProvider);
    final firstName = ref.watch(
      userProvider.select((u) => u.valueOrNull?.firstName.split(' ').first ?? ''),
    );

    final Widget scaffold = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: l10n.svc_mealDashboard,
        showBackButton: true,
        onBackPressed: () => context.go(AppRoutes.hub),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ─── Greeting ───────────────────────────────────────
                      _GreetingHeader(
                        greeting: _greeting(l10n),
                        firstName: firstName,
                        subtitle: l10n.svc_greetingSubtitle,
                        theme: theme,
                      ),

                      const SizedBox(height: 24),

                      // ─── Meal calendar with inline event list ────────────
                      _MealCalendarInline(
                        l10n: l10n,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 20),

                      // ─── Streak card ─────────────────────────────────────
                      streakAsync.when(
                        data: (streak) => _MealStreakCard(
                          streak: streak,
                          theme: theme,
                          isDark: isDark,
                          l10n: l10n,
                          onTap: () => context.push(AppRoutes.svcStreak),
                        ),
                        loading: () => const _SkeletonCard(height: 76),
                        error: (_, _) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 8),

                      // ─── History entry ───────────────────────────────────
                      _NavEntryCard(
                        icon: AppIcons.history,
                        label: l10n.svc_mealHistory,
                        subtitle: l10n.svc_viewHistory,
                        isDark: isDark,
                        theme: theme,
                        onTap: () => context.push(AppRoutes.svcHistory),
                      ),

                      const SizedBox(height: 28),

                      // ─── Status legend ───────────────────────────────────
                      _StatusLegendSection(theme: theme, isDark: isDark, l10n: l10n),

                      const SizedBox(height: 20),

                      // ─── FAQ ─────────────────────────────────────────────
                      SVCFaqSection(theme: theme, l10n: l10n),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ─── Floating QR button (bottom-right) ──────────────────────────
          Positioned(
            bottom: 24,
            right: 20,
            child: _FloatingQrButton(
              l10n: l10n,
              isDark: isDark,
              onTap: () => context.push(AppRoutes.svcQrScan),
            ),
          ),
        ],
      ),
    );
    return scaffold;
  }
}

// ─── Greeting ─────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.greeting,
    required this.firstName,
    required this.subtitle,
    required this.theme,
  });

  final String greeting;
  final String firstName;
  final String subtitle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firstName.isEmpty ? greeting : '$greeting, $firstName',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }
}

// ─── Calendar ─────────────────────────────────────────────────────────────────

class _MealCalendarInline extends ConsumerStatefulWidget {
  const _MealCalendarInline({
    required this.l10n,
    required this.isDark,
  });

  final AppLocalizations l10n;
  final bool isDark;

  @override
  ConsumerState<_MealCalendarInline> createState() =>
      _MealCalendarInlineState();
}

class _MealCalendarInlineState extends ConsumerState<_MealCalendarInline> {
  late DateTime _viewedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = widget.isDark;
    final monthAsync = ref.watch(mealMonthScheduleProvider(_viewedMonth));
    final events =
        monthAsync.whenOrNull(data: _toCalendarEvents) ?? const [];

    return AppCalendar(
      events: events,
      accentColor: AppColors.primary,
      showEventList: true,
      showTodayButton: true,
      todayLabel: l10n.svc_today,
      todayButtonLabel: l10n.svc_today,
      emptyStateTitle: l10n.svc_noMealsOnDay,
      onMonthChanged: (m) =>
          setState(() => _viewedMonth = DateTime(m.year, m.month)),
      eventBuilder: (ctx, event) {
        final entry = event.metadata as MealEntry;
        return _CalendarMealRow(
          entry: entry,
          l10n: l10n,
          isDark: isDark,
          onSkip: entry.canCancel
              ? () async {
                  await ref
                      .read(mealScheduleProvider.notifier)
                      .cancelMealForDate(entry.date, entry.slot);
                  await ref.read(mealStreakProvider.notifier).load();
                }
              : null,
          onGoing: entry.canUndoCancel
              ? () async {
                  await ref
                      .read(mealScheduleProvider.notifier)
                      .undoCancelForDate(entry.date, entry.slot);
                  await ref.read(mealStreakProvider.notifier).load();
                }
              : null,
        );
      },
    );
  }

  List<AppCalendarEvent> _toCalendarEvents(List<MealSchedule> schedules) {
    final events = <AppCalendarEvent>[];
    for (final schedule in schedules) {
      for (final entry in schedule.meals) {
        events.add(AppCalendarEvent(
          id: entry.id,
          title: _slotLabel(entry.slot),
          date: entry.date,
          time: _slotTime(entry.slot),
          color: _statusColor(entry.status),
          type: 'meal',
          metadata: entry,
        ));
      }
    }
    return events;
  }

  String _slotLabel(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => widget.l10n.svc_breakfast,
        MealSlot.lunch => widget.l10n.svc_lunch,
        MealSlot.dinner => widget.l10n.svc_dinner,
      };

  TimeOfDay _slotTime(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => const TimeOfDay(hour: 8, minute: 0),
        MealSlot.lunch => const TimeOfDay(hour: 12, minute: 30),
        MealSlot.dinner => const TimeOfDay(hour: 18, minute: 0),
      };

  Color _statusColor(MealStatus status) => switch (status) {
        MealStatus.scheduled => AppColors.primary,
        MealStatus.cancelled => AppColors.orange,
        MealStatus.received => AppColors.green,
        MealStatus.noShow => AppColors.red,
      };
}

// ─── Calendar Meal Row ────────────────────────────────────────────────────────

class _CalendarMealRow extends StatelessWidget {
  const _CalendarMealRow({
    required this.entry,
    required this.l10n,
    required this.isDark,
    this.onSkip,
    this.onGoing,
  });

  final MealEntry entry;
  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback? onSkip;
  final VoidCallback? onGoing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slotColor = _slotColor(entry.slot);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: slotColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: AppIcon(_slotIcon(entry.slot), color: slotColor, size: 18),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _slotLabel(l10n, entry.slot),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.slot.timeRange,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: onSkip != null
                ? _InlineAction(
                    label: l10n.svc_skip,
                    color: AppColors.orange,
                    onTap: onSkip!,
                  )
                : onGoing != null
                    ? _InlineAction(
                        label: l10n.svc_going,
                        color: AppColors.primary,
                        onTap: onGoing!,
                      )
                    : _StatusPill(status: entry.status, l10n: l10n),
          ),
        ],
      ),
    );
  }

  String _slotLabel(AppLocalizations l10n, MealSlot slot) => switch (slot) {
        MealSlot.breakfast => l10n.svc_breakfast,
        MealSlot.lunch => l10n.svc_lunch,
        MealSlot.dinner => l10n.svc_dinner,
      };

  AppIconData _slotIcon(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => AppIcons.sun,
        MealSlot.lunch => AppIcons.info,
        MealSlot.dinner => AppIcons.moon,
      };

  Color _slotColor(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => const Color(0xFFFF9500),
        MealSlot.lunch => AppColors.primary,
        MealSlot.dinner => const Color(0xFF5E5CE6),
      };
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.l10n});

  final MealStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      MealStatus.scheduled => (AppColors.primary, l10n.svc_statusScheduled),
      MealStatus.cancelled => (AppColors.orange, l10n.svc_statusCancelled),
      MealStatus.received => (AppColors.green, l10n.svc_statusReceived),
      MealStatus.noShow => (AppColors.red, l10n.svc_statusNoShow),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Streak Card ──────────────────────────────────────────────────────────────

class _MealStreakCard extends StatelessWidget {
  const _MealStreakCard({
    required this.streak,
    required this.theme,
    required this.isDark,
    required this.l10n,
    required this.onTap,
  });

  final MealStreak streak;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF242424) : Colors.white;
    final hasStreak = streak.currentStreak > 0;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasStreak
                    ? const Color(0xFFFF9500).withValues(alpha: 0.12)
                    : AppColors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(
                AppIcons.flame,
                color: hasStreak ? const Color(0xFFFF9500) : AppColors.grey,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.svc_mealStreak,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  Text(
                    hasStreak
                        ? l10n.svc_streakDays(streak.currentStreak)
                        : l10n.svc_noStreakYet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.svc_bestStreak,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey,
                    fontSize: 10,
                  ),
                ),
                Text(
                  l10n.svc_streakDays(streak.bestStreak),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            AppIcon(
              AppIcons.chevronRight,
              size: 18,
              color: AppColors.grey.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Navigation Entry Card ────────────────────────────────────────────────────

class _NavEntryCard extends StatelessWidget {
  const _NavEntryCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  final AppIconData icon;
  final String label;
  final String subtitle;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF242424) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            AppIcon(
              AppIcons.chevronRight,
              size: 18,
              color: AppColors.grey.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Legend ────────────────────────────────────────────────────────────

class _StatusLegendSection extends StatelessWidget {
  const _StatusLegendSection({
    required this.theme,
    required this.isDark,
    required this.l10n,
  });

  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    final entries = [
      (AppColors.primary, l10n.svc_statusScheduled, l10n.svc_statusScheduledDesc),
      (AppColors.orange, l10n.svc_statusCancelled, l10n.svc_statusSkippedDesc),
      (AppColors.green, l10n.svc_statusReceived, l10n.svc_statusReceivedDesc),
      (AppColors.red, l10n.svc_statusNoShow, l10n.svc_statusNoShowDesc),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.svc_statusLegend,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries.map((e) {
            final (color, label, desc) = e;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242424) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.5),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Floating QR Button ───────────────────────────────────────────────────────

class _FloatingQrButton extends StatelessWidget {
  const _FloatingQrButton({
    required this.l10n,
    required this.isDark,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const AppIcon(
                AppIcons.qrCode,
                color: Colors.white,
                size: 18,
              ),
            ),
            SizedBox(width: 10),
            Text(
              l10n.svc_mealPass,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(width: 10),
            AppIcon(
              AppIcons.arrowForward,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton placeholder ─────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
