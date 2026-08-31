import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/meal_slot.dart';
import '../../providers/meal_schedule_provider.dart';

/// Shows a bottom sheet with all three meals for [date].
/// Each meal displays its status and available actions (cancel / undo).
void showDayMealSheet(BuildContext context, WidgetRef ref, DateTime date) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _DayMealSheet(date: date),
    ),
  );
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class _DayMealSheet extends ConsumerWidget {
  const _DayMealSheet({required this.date});

  final DateTime date;

  String _formatDate(DateTime d, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final day = DateTime(d.year, d.month, d.day);

    if (day == today) return l10n.svc_todayMeals;
    if (day == yesterday) return 'Yesterday';
    if (day == tomorrow) return 'Tomorrow';
    return DateFormat('EEEE, d MMMM').format(d);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final surface = isDark ? const Color(0xFF242424) : Colors.white;
    final scheduleAsync = ref.watch(mealScheduleForDateProvider(date));

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Drag handle ───────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ─── Date header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatDate(date, l10n),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── Meal rows ─────────────────────────────────────────────────
          scheduleAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Text(
                'Could not load meals',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.grey),
              ),
            ),
            data: (schedule) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _MealActionRow(
                    entry: schedule.breakfast,
                    isDark: isDark,
                    l10n: l10n,
                    theme: theme,
                    onCancel: () => _cancel(context, ref, schedule.breakfast),
                    onUndo: () => _undo(context, ref, schedule.breakfast),
                  ),
                  _Divider(isDark: isDark),
                  _MealActionRow(
                    entry: schedule.lunch,
                    isDark: isDark,
                    l10n: l10n,
                    theme: theme,
                    onCancel: () => _cancel(context, ref, schedule.lunch),
                    onUndo: () => _undo(context, ref, schedule.lunch),
                  ),
                  _Divider(isDark: isDark),
                  _MealActionRow(
                    entry: schedule.dinner,
                    isDark: isDark,
                    l10n: l10n,
                    theme: theme,
                    onCancel: () => _cancel(context, ref, schedule.dinner),
                    onUndo: () => _undo(context, ref, schedule.dinner),
                  ),
                ],
              ),
            ),
          ),

          // ─── Bottom padding (safe area + button) ───────────────────────
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                  foregroundColor:
                      isDark ? Colors.white : Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.svc_close,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, MealEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(mealScheduleProvider.notifier)
          .cancelMealForDate(entry.date, entry.slot);
      if (context.mounted) {
        AppToast.showSuccess(context, l10n.svc_cancelSuccess);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    }
  }

  Future<void> _undo(
      BuildContext context, WidgetRef ref, MealEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(mealScheduleProvider.notifier)
          .undoCancelForDate(entry.date, entry.slot);
      if (context.mounted) {
        AppToast.showSuccess(context, l10n.svc_undoCancelSuccess);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    }
  }
}

// ─── Meal Action Row ──────────────────────────────────────────────────────────

class _MealActionRow extends StatelessWidget {
  const _MealActionRow({
    required this.entry,
    required this.isDark,
    required this.l10n,
    required this.theme,
    required this.onCancel,
    required this.onUndo,
  });

  final MealEntry entry;
  final bool isDark;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onCancel;
  final VoidCallback onUndo;

  Color _slotColor(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => const Color(0xFFFF9500),
        MealSlot.lunch => AppColors.primary,
        MealSlot.dinner => const Color(0xFF5E5CE6),
      };

  AppIconData _slotIcon(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => AppIcons.sun,
        MealSlot.lunch => AppIcons.info,
        MealSlot.dinner => AppIcons.moon,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // Slot icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: slotColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppIcon(_slotIcon(entry.slot), color: slotColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Name + time
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

          // Action or status
          Flexible(
            fit: FlexFit.loose,
            child: entry.canCancel
                ? _ActionButton(
                    label: l10n.svc_cancelMeal,
                    color: AppColors.red,
                    onTap: onCancel,
                  )
                : entry.canUndoCancel
                    ? _ActionButton(
                        label: l10n.svc_undoCancellation,
                        color: AppColors.primary,
                        onTap: onUndo,
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 48,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}
