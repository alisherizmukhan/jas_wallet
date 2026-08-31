import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/meal_slot.dart';
import '../../providers/meal_schedule_provider.dart';

/// Shows a bottom sheet for cancelling a scheduled meal.
///
/// Handles both the cancellable state (before deadline) and the locked state
/// (deadline passed), keeping a consistent surface regardless of entry state.
void showCancellationSheet(
  BuildContext context,
  MealEntry entry,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _CancellationSheet(entry: entry),
  );
}

class _CancellationSheet extends ConsumerStatefulWidget {
  const _CancellationSheet({required this.entry});

  final MealEntry entry;

  @override
  ConsumerState<_CancellationSheet> createState() => _CancellationSheetState();
}

class _CancellationSheetState extends ConsumerState<_CancellationSheet> {
  bool _isLoading = false;

  Future<void> _cancelMeal() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(mealScheduleProvider.notifier)
          .cancelMeal(widget.entry.slot);
      if (!mounted) return;
      AppToast.showSuccess(
          context, AppLocalizations.of(context)!.svc_cancelSuccess);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF242424) : Colors.white;

    final deadline = widget.entry.cancellationDeadline;
    final canCancel = widget.entry.canCancel;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Slot label + icon
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _slotColor(widget.entry.slot)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcon(
                  _slotIcon(widget.entry.slot),
                  color: _slotColor(widget.entry.slot),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _slotLabel(l10n, widget.entry.slot),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.entry.slot.timeRange,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (canCancel) ...[
            // Deadline info
            _InfoRow(
              icon: AppIcons.time,
              label: l10n.svc_cancelDeadlineLabel,
              value: _fmtDeadline(deadline),
              color: AppColors.orange,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: AppIcons.flame,
              label: l10n.svc_honestCancelInfo,
              value: '',
              color: AppColors.green,
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              l10n.svc_cancelMealDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                          color: AppColors.grey.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.svc_keepMeal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _cancelMeal,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : Text(l10n.svc_cancelConfirm),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Locked state
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  AppIcon(AppIcons.lock, size: 20, color: AppColors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.svc_cancelWindowClosed,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.svc_cancelWindowClosedDesc,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.grey,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.common_close),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDeadline(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final day = dt.day;
    final month = dt.month;
    return '$h:$m  ·  $day.$month';
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final AppIconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AppIcon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? label : '$label: $value',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
