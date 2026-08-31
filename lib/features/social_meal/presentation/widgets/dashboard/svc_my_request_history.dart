import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../domain/entities/compensation_request.dart';
import '../../../providers/svc_compensation_provider.dart';

/// My request history widget showing all compensation requests.
class SVCMyRequestHistory extends ConsumerWidget {
  final ThemeData theme;
  final AppLocalizations l10n;

  const SVCMyRequestHistory({
    required this.theme,
    required this.l10n,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = theme.brightness == Brightness.light;
    final compensationState = ref.watch(svcCompensationProvider);
    final myRequests = compensationState.myRequests
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLight ? AppColors.borderGrey : AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                AppIcon(
                  AppIcons.history,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.svc_requestHistory,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          if (myRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  l10n.svc_noRequestsYet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ),
            )
          else
            ...myRequests.map((r) => _buildRequestItem(context, ref, r)),
        ],
      ),
    );
  }

  Widget _buildRequestItem(
    BuildContext context,
    WidgetRef ref,
    CompensationRequest r,
  ) {
    final isLight = theme.brightness == Brightness.light;
    final isExam = r.type == CompensationRequestType.exam;
    final dateStr =
        '${r.mealDate.day.toString().padLeft(2, '0')}.${r.mealDate.month.toString().padLeft(2, '0')}.${r.mealDate.year}';

    Color statusColor;
    Color statusBg;
    String statusLabel;
    switch (r.status) {
      case CompensationStatus.approved:
        statusColor = AppColors.green;
        statusBg = AppColors.lightGreen;
        statusLabel = l10n.svc_statusApproved;
      case CompensationStatus.rejected:
        statusColor = AppColors.red;
        statusBg = AppColors.errorLight;
        statusLabel = l10n.svc_statusRejected;
      case CompensationStatus.pending:
        statusColor = AppColors.orange;
        statusBg = AppColors.orangeLight;
        statusLabel = l10n.svc_statusPending;
    }

    return GestureDetector(
      onTap: r.status == CompensationStatus.approved
          ? () => _showApprovedReceipt(context, r)
          : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isExam
                        ? (isLight ? AppColors.orangeLight : AppColors.orange.withValues(alpha: 0.16))
                        : (isLight ? AppColors.errorLight : AppColors.red.withValues(alpha: 0.16)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: AppIcon(
                      isExam ? AppIcons.school : AppIcons.document,
                      size: 18,
                      color: isExam ? AppColors.orange : AppColors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isExam ? l10n.svc_reqTypeExam : l10n.svc_reqTypeMedical,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$dateStr · ${_mealTypeLabel(r.mealType)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ),
    );
  }

  String _mealTypeLabel(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return l10n.svc_breakfast;
      case 'lunch':
        return l10n.svc_lunch;
      case 'dinner':
        return l10n.svc_dinner;
      default:
        return mealType;
    }
  }

  void _showApprovedReceipt(BuildContext context, CompensationRequest r) {
    final isLight = theme.brightness == Brightness.light;
    final dateStr =
        '${r.mealDate.day.toString().padLeft(2, '0')}.${r.mealDate.month.toString().padLeft(2, '0')}.${r.mealDate.year}';
    final isExam = r.type == CompensationRequestType.exam;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isLight ? AppColors.white : AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isLight ? AppColors.lightGreen : AppColors.green.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: AppIcon(
                      AppIcons.checkCircle,
                      size: 32,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.svc_statusApproved,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                isExam ? l10n.svc_reqTypeExam : l10n.svc_reqTypeMedical,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight ? AppColors.white : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isLight ? AppColors.borderGrey : AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.svc_mealDateLabel, style: theme.textTheme.labelMedium),
                      Text(
                        dateStr,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.svc_mealTypeLabel, style: theme.textTheme.labelMedium),
                      Text(
                        _mealTypeLabel(r.mealType),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight ? AppColors.lightGreen : AppColors.green.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'You can now visit the cafeteria',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your meal is ready to be picked up',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Close',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
