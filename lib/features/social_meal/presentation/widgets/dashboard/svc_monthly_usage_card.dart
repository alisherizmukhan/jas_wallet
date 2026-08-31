import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../domain/entities/svc_meal_state.dart';

/// Card showing monthly meal usage with quota tracking.
class SVCMonthlyUsageCard extends StatefulWidget {
  final SVCMealState mealState;
  final ThemeData theme;
  final AppLocalizations l10n;

  const SVCMonthlyUsageCard({
    required this.mealState,
    required this.theme,
    required this.l10n,
    super.key,
  });

  @override
  State<SVCMonthlyUsageCard> createState() => _SVCMonthlyUsageCardState();
}

class _SVCMonthlyUsageCardState extends State<SVCMonthlyUsageCard> {
  @override
  Widget build(BuildContext context) {
    final used = widget.mealState.monthlyMealsUsed;
    final total = SVCMealState.maxMealsPerMonth;
    final progress = (used / total).clamp(0.0, 1.0);
    final limitReached = widget.mealState.isMonthlyLimitReached;
    final isLight = widget.theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: () => _showMonthlyDetailsSheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLight ? AppColors.white : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLight ? AppColors.borderGrey : AppColors.borderDark,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: limitReached
                        ? (isLight ? AppColors.errorLight : AppColors.red.withValues(alpha: 0.16))
                        : (isLight ? AppColors.primaryLight : AppColors.primary.withValues(alpha: 0.16)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: AppIcon(
                      AppIcons.history,
                      size: 24,
                      color: limitReached ? AppColors.red : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.l10n.svc_monthlyUsage,
                        style: widget.theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$used/$total ${widget.l10n.svc_mealsPerMonth}',
                        style: widget.theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                backgroundColor: isLight
                    ? AppColors.borderGrey
                    : AppColors.borderDark,
                color: limitReached ? AppColors.red : AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.l10n.svc_remaining,
                  style: widget.theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.mealState.remainingMonthlyMeals} ${widget.l10n.svc_meals}',
                      style: widget.theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: limitReached ? AppColors.red : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '≈ ${(widget.mealState.remainingMonthlyMeals / 3).ceil()} days (3/day)',
                      style: widget.theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthlyDetailsSheet(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day - DateTime(now.year, now.month, 1).day + 1;
    final daysPassedInMonth = now.day;
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
              widget.l10n.svc_monthlyUsage,
              style: widget.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight
                    ? AppColors.primaryLight.withValues(alpha: 0.5)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
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
                            widget.mealState.monthlyMealsUsed.toString(),
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
                            widget.mealState.remainingMonthlyMeals.toString(),
                            style: widget.theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            widget.l10n.svc_quota,
                            style: widget.theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            SVCMealState.maxMealsPerMonth.toString(),
                            style: widget.theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.mealState.isMonthlyLimitReached) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.l10n.svc_monthlyLimitReached,
                      style: widget.theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight
                    ? AppColors.blueLight.withValues(alpha: 0.5)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.l10n.svc_monthInfo,
                    style: widget.theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    widget.l10n.svc_currentMonth,
                    '${now.month}/${now.year}',
                  ),
                  _buildInfoRow(
                    widget.l10n.svc_daysElapsed,
                    '$daysPassedInMonth/$daysInMonth',
                  ),
                  _buildInfoRow(
                    widget.l10n.svc_avgPerDay,
                    widget.mealState.monthlyMealsUsed > 0
                        ? (widget.mealState.monthlyMealsUsed / daysPassedInMonth)
                            .toStringAsFixed(2)
                        : '0',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: widget.theme.textTheme.labelSmall?.copyWith(
              color: AppColors.grey,
            ),
          ),
          Text(
            value,
            style: widget.theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
