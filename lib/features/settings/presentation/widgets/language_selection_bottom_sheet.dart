import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import '../../../../l10n/app_localizations.dart';

/// Language selection bottom sheet.
class LanguageSelectionBottomSheet extends StatelessWidget {
  final String currentLocale;
  final void Function(String locale) onLanguageSelected;

  const LanguageSelectionBottomSheet({
    super.key,
    required this.currentLocale,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                l10n.splash_selectLanguage,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              _LanguageButton(
                flag: '🇰🇿',
                label: l10n.language_nameKazakh,
                isSelected: currentLocale == 'kk',
                onTap: () => _selectLanguage(context, 'kk'),
              ),
              const SizedBox(height: 8),

              _LanguageButton(
                flag: '🇷🇺',
                label: l10n.language_nameRussian,
                isSelected: currentLocale == 'ru',
                onTap: () => _selectLanguage(context, 'ru'),
              ),
              const SizedBox(height: 8),

              _LanguageButton(
                flag: '🇬🇧',
                label: l10n.language_nameEnglish,
                isSelected: currentLocale == 'en',
                onTap: () => _selectLanguage(context, 'en'),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, String locale) {
    onLanguageSelected(locale);
    Navigator.pop(context);
  }
}

/// Language selection button.
class _LanguageButton extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Material(
      color: isSelected
          ? (isLight
                ? AppColors.primaryLight
                : AppColors.primary.withValues(alpha: 0.15))
          : (isLight ? AppColors.fieldBackground : AppColors.borderDark),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.grey.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
