import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../data/repositories/social_meal_repository_impl.dart';
import '../../../providers/svc_confirmation_provider.dart';
import '../../../providers/svc_meal_provider.dart';

/// Tomorrow's meal confirmation card.
/// 
/// Allows users to confirm which meals they want tomorrow.
class SVCTomorrowConfirmationCard extends ConsumerStatefulWidget {
  const SVCTomorrowConfirmationCard({super.key});

  @override
  ConsumerState<SVCTomorrowConfirmationCard> createState() =>
      _SVCTomorrowConfirmationCardState();
}

class _SVCTomorrowConfirmationCardState
    extends ConsumerState<SVCTomorrowConfirmationCard> {
  bool _breakfast = true;
  bool _lunch = true;
  bool _dinner = true;
  bool _synced = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;
    final confirmState = ref.watch(svcConfirmationProvider);
    final mealState = ref.watch(svcMealProvider);

    // Sync local toggles from provider on first successful load
    if (!_synced && confirmState.isLoaded) {
      final saved = confirmState.myConfirmation;
      _breakfast = saved?.breakfast ?? true;
      _lunch = saved?.lunch ?? true;
      _dinner = saved?.dinner ?? true;
      _synced = true;
    }

    final isPastCutoff = confirmState.isConfirmationClosed;
    final weeklyLimitReached = mealState.isWeeklyLimitReached;
    final hasSaved = confirmState.myConfirmation != null;
    final targetDate =
        confirmState.targetMealDate ??
        DateTime.now().add(const Duration(days: 1));
    final dateStr = _formatDate(targetDate);
    final disabled = isPastCutoff || weeklyLimitReached || confirmState.isSaving;

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLight ? AppColors.borderGrey : AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLight ? AppColors.primaryLight : AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: AppIcon(
                      AppIcons.event,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.svc_tomorrowConfirmation,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasSaved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.lightGreen : AppColors.green.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.svc_confirmSavedBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Cutoff note ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              isPastCutoff
                  ? _deadlinePassedText(confirmState.confirmationCutoffAt)
                  : _cutoffText(confirmState.confirmationCutoffAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isPastCutoff ? AppColors.red : AppColors.orange,
              ),
            ),
          ),

          if (weeklyLimitReached)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: Text(
                l10n.svc_weeklyLimitWarning,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.red,
                ),
              ),
            ),

          // ── Meal toggles ───────────────────────────────────────────
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  visualDensity: VisualDensity.compact,
                  title: Text(l10n.svc_breakfast),
                  subtitle: null,
                  value: _breakfast,
                  onChanged: disabled
                      ? null
                      : (v) => setState(() => _breakfast = v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  visualDensity: VisualDensity.compact,
                  title: Text(l10n.svc_lunch),
                  subtitle: null,
                  value: _lunch,
                  onChanged: disabled
                      ? null
                      : (v) => setState(() => _lunch = v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  visualDensity: VisualDensity.compact,
                  title: Text(l10n.svc_dinner),
                  subtitle: null,
                  value: _dinner,
                  onChanged: disabled
                      ? null
                      : (v) => setState(() => _dinner = v),
                ),
              ],
            ),
          ),

          // ── Save button ────────────────────────────────────────────
          if (!disabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: confirmState.isSaving ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: confirmState.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          l10n.svc_confirmSubmit,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    try {
      await ref
          .read(svcConfirmationProvider.notifier)
          .saveConfirmation(
            breakfast: _breakfast,
            lunch: _lunch,
            dinner: _dinner,
          );
      if (!mounted) return;
      ToastManager.showSuccess(
        context,
        AppLocalizations.of(context)!.svc_confirmSaved,
      );
    } catch (e) {
      if (!mounted) return;
      ToastManager.showError(context, _userFacingErrorMessage(e));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '23:59';
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _cutoffText(DateTime? cutoffAt) {
    final time = _formatTime(cutoffAt);
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return 'Подтверждение доступно до $time сегодня';
      case 'kk':
        return 'Растау бүгін $time-ге дейін ашық';
      default:
        return 'Confirmation is available until $time today';
    }
  }

  String _deadlinePassedText(DateTime? cutoffAt) {
    final time = _formatTime(cutoffAt);
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return 'Срок подтверждения истек - форма закрыта после $time';
      case 'kk':
        return 'Растау мерзімі өтті - форма $time-ден кейін жабық';
      default:
        return 'Deadline passed - confirmation closed after $time';
    }
  }

  String _userFacingErrorMessage(Object error) {
    if (error is SocialMealRepositoryException) {
      return error.message;
    }

    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return 'Не удалось сохранить выбор питания. Попробуйте еще раз.';
      case 'kk':
        return 'Тамақтану таңдауын сақтау мүмкін болмады. Қайта көріңіз.';
      default:
        return 'Could not save the meal selection. Please try again.';
    }
  }
}
