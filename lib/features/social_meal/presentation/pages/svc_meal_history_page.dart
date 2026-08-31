import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/meal_schedule.dart';
import '../../domain/entities/meal_slot.dart';
import '../../providers/meal_schedule_provider.dart';
import '../widgets/svc_received_meal_sheet.dart';

class SVCMealHistoryPage extends ConsumerStatefulWidget {
  const SVCMealHistoryPage({super.key});

  @override
  ConsumerState<SVCMealHistoryPage> createState() =>
      _SVCMealHistoryPageState();
}

class _SVCMealHistoryPageState extends ConsumerState<SVCMealHistoryPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackSvcHistoryOpened();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(mealHistoryPagedProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: l10n.svc_mealHistory,
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: _buildBody(context, state, theme, isDark, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MealHistoryState state,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (state.isLoading) {
      return _HistorySkeleton(isDark: isDark);
    }

    if (state.error != null && state.items.isEmpty) {
      return _ErrorState(theme: theme, l10n: l10n,
          onRetry: () => ref.read(mealHistoryPagedProvider.notifier).refresh());
    }

    if (state.items.isEmpty) {
      return _EmptyState(theme: theme, l10n: l10n);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          ref.read(mealHistoryPagedProvider.notifier).loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () =>
            ref.read(mealHistoryPagedProvider.notifier).refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          itemCount: state.items.length + 1,
          itemBuilder: (context, index) {
            if (index == state.items.length) {
              return _LoadMoreFooter(state: state, l10n: l10n, isDark: isDark);
            }
            return _DayHistorySection(
              schedule: state.items[index],
              theme: theme,
              isDark: isDark,
              l10n: l10n,
              onMealTap: (entry) => showReceivedMealSheet(context, ref, entry),
            );
          },
        ),
      ),
    );
  }
}

// ─── Load More Footer ─────────────────────────────────────────────────────────

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.state,
    required this.l10n,
    required this.isDark,
  });

  final MealHistoryState state;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.grey.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.svc_loadingMore,
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            l10n.svc_historyComplete,
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 8);
  }
}

// ─── Day Section ──────────────────────────────────────────────────────────────

class _DayHistorySection extends StatelessWidget {
  const _DayHistorySection({
    required this.schedule,
    required this.theme,
    required this.isDark,
    required this.l10n,
    required this.onMealTap,
  });

  final MealSchedule schedule;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<MealEntry> onMealTap;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return l10n.svc_today;
    if (d == yesterday) return l10n.svc_yesterday;
    return DateFormat('EEE, d MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Row(
            children: [
              Text(
                _formatDate(schedule.date),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(color: dividerColor, thickness: 1),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242424) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dividerColor),
          ),
          child: Column(
            children: [
              _MealHistoryRow(
                entry: schedule.breakfast,
                isFirst: true,
                isLast: false,
                theme: theme,
                isDark: isDark,
                l10n: l10n,
                onTap: onMealTap,
              ),
              Divider(height: 1, indent: 56, color: dividerColor),
              _MealHistoryRow(
                entry: schedule.lunch,
                isFirst: false,
                isLast: false,
                theme: theme,
                isDark: isDark,
                l10n: l10n,
                onTap: onMealTap,
              ),
              Divider(height: 1, indent: 56, color: dividerColor),
              _MealHistoryRow(
                entry: schedule.dinner,
                isFirst: false,
                isLast: true,
                theme: theme,
                isDark: isDark,
                l10n: l10n,
                onTap: onMealTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Meal Row ─────────────────────────────────────────────────────────────────

class _MealHistoryRow extends StatelessWidget {
  const _MealHistoryRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.theme,
    required this.isDark,
    required this.l10n,
    required this.onTap,
  });

  final MealEntry entry;
  final bool isFirst;
  final bool isLast;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<MealEntry> onTap;

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

  String _slotName(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => l10n.svc_breakfast,
        MealSlot.lunch => l10n.svc_lunch,
        MealSlot.dinner => l10n.svc_dinner,
      };

  Color _statusColor(MealStatus status) => switch (status) {
        MealStatus.received => AppColors.green,
        MealStatus.cancelled => AppColors.orange,
        MealStatus.noShow => AppColors.red,
        MealStatus.scheduled => AppColors.primary,
      };

  String _statusLabel(MealStatus status) => switch (status) {
        MealStatus.received => l10n.svc_statusReceived,
        MealStatus.cancelled => l10n.svc_statusCancelled,
        MealStatus.noShow => l10n.svc_statusNoShow,
        MealStatus.scheduled => l10n.svc_statusScheduled,
      };

  @override
  Widget build(BuildContext context) {
    final slotColor = _slotColor(entry.slot);
    final statusColor = _statusColor(entry.status);
    final isReceived = entry.status == MealStatus.received;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: slotColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: AppIcon(_slotIcon(entry.slot), color: slotColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _slotName(entry.slot),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(entry.status),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    if (!isReceived) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(entry),
        child: row,
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final shimmer = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        children: List.generate(
          4,
          (i) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                height: 14,
                width: 80,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              Container(
                height: 130,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme, required this.l10n});

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              AppIcons.utensils,
              size: 64,
              color: AppColors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.svc_noHistoryYet,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.svc_historyEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error State ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.theme,
    required this.l10n,
    required this.onRetry,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            AppIcons.error,
            size: 48,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.svc_couldNotLoad,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.common_retry),
          ),
        ],
      ),
    );
  }
}
