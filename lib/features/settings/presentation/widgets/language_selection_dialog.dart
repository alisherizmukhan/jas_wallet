import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import '../../../../l10n/app_localizations.dart';

/// Language selection dialog.
class LanguageSelectionDialog extends StatelessWidget {
  final String currentLocale;
  final void Function(String locale) onLanguageSelected;

  const LanguageSelectionDialog({
    super.key,
    required this.currentLocale,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.splash_selectLanguage,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            _LanguageButton(
              flag: '🇰🇿',
              label: l10n.language_nameKazakh,
              isSelected: currentLocale == 'kk',
              onTap: () => _selectLanguage(context, 'kk'),
            ),
            const SizedBox(height: 12),
            
            _LanguageButton(
              flag: '🇷🇺',
              label: l10n.language_nameRussian,
              isSelected: currentLocale == 'ru',
              onTap: () => _selectLanguage(context, 'ru'),
            ),
            const SizedBox(height: 12),
            
            _LanguageButton(
              flag: '🇬🇧',
              label: l10n.language_nameEnglish,
              isSelected: currentLocale == 'en',
              onTap: () => _selectLanguage(context, 'en'),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(vertical: 14),
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
              Text(
                flag,
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: 10),
                AppIcon(AppIcons.checkCircle, color: AppColors.primary, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
