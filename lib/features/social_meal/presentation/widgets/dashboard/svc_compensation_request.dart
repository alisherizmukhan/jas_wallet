import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../domain/entities/compensation_request.dart';
import '../../../providers/svc_compensation_provider.dart';

/// Unified compensation request widget showing both Medical and Exam options.
/// 
/// User can click to select and submit compensation requests.
class SVCCompensationRequest extends ConsumerWidget {
  final ThemeData theme;
  final AppLocalizations l10n;

  const SVCCompensationRequest({
    required this.theme,
    required this.l10n,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Medical Absence Compensation
        _buildCompensationCard(
          context,
          ref,
          AppIcons.document,
          AppColors.errorLight,
          AppColors.red,
          l10n.svc_missedMealComp,
          l10n.svc_missedMealCompSubtitle,
          l10n.svc_submitRequest,
          CompensationRequestType.medical,
        ),
        const SizedBox(height: 12),
        // Exam Conflict Compensation
        _buildCompensationCard(
          context,
          ref,
          AppIcons.school,
          AppColors.orangeLight,
          AppColors.orange,
          l10n.svc_examMealComp,
          l10n.svc_examMealCompSubtitle,
          l10n.svc_submitRequest,
          CompensationRequestType.exam,
        ),
      ],
    );
  }

  Widget _buildCompensationCard(
    BuildContext context,
    WidgetRef ref,
    AppIconData icon,
    Color bgColor,
    Color iconColor,
    String title,
    String subtitle,
    String buttonLabel,
    CompensationRequestType type,
  ) {
    final isLight = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLight ? AppColors.borderGrey : AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLight ? bgColor : iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AppIcon(
                icon,
                size: 22,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _showCompensationForm(
              context,
              ref,
              type,
              title,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompensationForm(
    BuildContext context,
    WidgetRef ref,
    CompensationRequestType type,
    String title,
  ) {
    final isLight = theme.brightness == Brightness.light;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isLight ? AppColors.white : AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CompensationFormSheet(type: type, title: title),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compensation Form Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CompensationFormSheet extends ConsumerStatefulWidget {
  final CompensationRequestType type;
  final String title;

  const _CompensationFormSheet({
    required this.type,
    required this.title,
  });

  @override
  ConsumerState<_CompensationFormSheet> createState() =>
      _CompensationFormSheetState();
}

class _CompensationFormSheetState
    extends ConsumerState<_CompensationFormSheet> {
  DateTime? _selectedDate;
  String _selectedMealType = 'lunch';
  bool _documentAttached = false;
  bool _submitting = false;

  static const _mealTypes = ['breakfast', 'lunch', 'dinner'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;
    final isExam = widget.type == CompensationRequestType.exam;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isExam
                  ? l10n.svc_examMealCompSubtitle
                  : l10n.svc_missedMealCompSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 20),

            // Date picker
            Text(
              isExam ? l10n.svc_examDate : l10n.svc_mealDate,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isLight ? AppColors.white : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isLight ? AppColors.borderGrey : AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    AppIcon(
                      AppIcons.calendarMonth,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate == null
                          ? '— Select date —'
                          : '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _selectedDate == null ? AppColors.grey : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Meal type picker
            Text(
              isExam ? l10n.svc_missedMeal : l10n.svc_mealType,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: _mealTypes.map((mt) {
                final selected = _selectedMealType == mt;
                final label = mt == 'breakfast'
                    ? l10n.svc_breakfast
                    : mt == 'lunch'
                    ? l10n.svc_lunch
                    : l10n.svc_dinner;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMealType = mt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? (isLight ? AppColors.primaryLight : AppColors.primary.withValues(alpha: 0.16))
                              : (isLight ? AppColors.white : AppColors.surfaceDark),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : (isLight ? AppColors.borderGrey : AppColors.borderDark),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.grey,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Document upload
            Text(
              l10n.svc_uploadDocument,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _documentAttached = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _documentAttached
                      ? (isLight ? AppColors.lightGreen : AppColors.green.withValues(alpha: 0.16))
                      : (isLight ? AppColors.white : AppColors.surfaceDark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _documentAttached
                        ? AppColors.green
                        : (isLight ? AppColors.borderGrey : AppColors.borderDark),
                  ),
                ),
                child: Row(
                  children: [
                    AppIcon(
                      _documentAttached
                          ? AppIcons.checkCircle
                          : AppIcons.attach,
                      size: 18,
                      color: _documentAttached
                          ? AppColors.green
                          : AppColors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _documentAttached
                          ? l10n.svc_documentAttached
                          : l10n.svc_uploadDocument,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _documentAttached
                            ? AppColors.green
                            : AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() && !_submitting ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        l10n.svc_submitCompRequest,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() => _selectedDate != null && _documentAttached;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit()) return;
    setState(() => _submitting = true);

    final docName =
        '${widget.type.name}_doc_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await ref
        .read(svcCompensationProvider.notifier)
        .submitRequest(
          type: widget.type,
          mealDate: _selectedDate!,
          mealType: _selectedMealType,
          documentName: docName,
        );

    setState(() => _submitting = false);
    if (!mounted) return;
    Navigator.of(context).pop();
    ToastManager.showSuccess(
      context,
      AppLocalizations.of(context)!.svc_requestSubmitted,
    );
  }
}
