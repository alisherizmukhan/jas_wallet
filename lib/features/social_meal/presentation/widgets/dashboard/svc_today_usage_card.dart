import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../domain/entities/svc_meal_state.dart';

/// Card showing today's meal usage (X/3).
class SVCTodayUsageCard extends StatefulWidget {
  final SVCMealState mealState;
  final ThemeData theme;
  final AppLocalizations l10n;

  const SVCTodayUsageCard({
    required this.mealState,
    required this.theme,
    required this.l10n,
    super.key,
  });

  @override
  State<SVCTodayUsageCard> createState() => _SVCTodayUsageCardState();
}

class _SVCTodayUsageCardState extends State<SVCTodayUsageCard> {
  @override
  Widget build(BuildContext context) {
    final used = widget.mealState.todayMealsUsed;
    const total = SVCMealState.maxMealsPerDay;
    final isLight = widget.theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: () => _showTodayDetailsSheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLight ? AppColors.white : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLight ? AppColors.borderGrey : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLight
                    ? AppColors.primaryLight
                    : AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AppIcon(
                  AppIcons.calendarMonth,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.l10n.svc_todayUsage,
                    style: widget.theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$used ${widget.l10n.svc_mealsUsed}',
                    style: widget.theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: (used / total).clamp(0.0, 1.0),
                      backgroundColor: isLight
                          ? AppColors.borderGrey
                          : AppColors.borderDark,
                      color: used >= total ? AppColors.red : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: used >= total
                    ? (isLight ? AppColors.errorLight : AppColors.red.withValues(alpha: 0.16))
                    : (isLight ? AppColors.primaryLight : AppColors.primary.withValues(alpha: 0.16)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$used/$total',
                style: widget.theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: used >= total ? AppColors.red : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTodayDetailsSheet(BuildContext context) {
    final isLight = widget.theme.brightness == Brightness.light;
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? AppColors.background : AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.l10n.svc_todayUsage,
              style: widget.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildTodayDetails(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTodayDetails() {
    final widgets = <Widget>[];
    final used = widget.mealState.todayMealsUsed;
    const total = SVCMealState.maxMealsPerDay;

    final isLight = widget.theme.brightness == Brightness.light;

    widgets.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLight
              ? AppColors.primaryLight.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  widget.l10n.svc_used,
                  style: widget.theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  used.toString(),
                  style: widget.theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  widget.l10n.svc_remaining,
                  style: widget.theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (total - used).toString(),
                  style: widget.theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  widget.l10n.svc_total,
                  style: widget.theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total.toString(),
                  style: widget.theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.mealState.todayRedeemedSlots.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        Text(
          widget.l10n.svc_redeemedMeals,
          style: widget.theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      for (final slot in widget.mealState.todayRedeemedSlots) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '• ${slot.label}',
              style: widget.theme.textTheme.bodySmall,
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
