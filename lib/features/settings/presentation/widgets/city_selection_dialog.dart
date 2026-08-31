import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import '../../../../l10n/app_localizations.dart';

/// City selection dialog - fullscreen bottom sheet with search.
class CitySelectionDialog extends StatefulWidget {
  final String? selectedCity;
  final void Function(String city)? onCitySelected;

  const CitySelectionDialog({
    super.key,
    this.selectedCity,
    this.onCitySelected,
  });

  @override
  State<CitySelectionDialog> createState() => _CitySelectionDialogState();
}

class _CitySelectionDialogState extends State<CitySelectionDialog> {
  String _astanaLabel(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Astana';
      case 'ru':
      case 'kk':
      default:
        return 'Астана';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final astana = _astanaLabel(context);
    final isSelected = widget.selectedCity == astana;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.settings_selectCity,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCityTile(
                city: astana,
                isSelected: isSelected,
                onTap: () {
                  widget.onCitySelected?.call(astana);
                  Navigator.pop(context, astana);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCityTile({
    required String city,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? (isLight
                  ? AppColors.primaryLight
                  : AppColors.primary.withValues(alpha: 0.15))
            : (isLight ? AppColors.fieldBackground : AppColors.borderDark),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          city,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: null,
          ),
        ),
        trailing: isSelected
            ? AppIcon(AppIcons.checkCircle, color: AppColors.primary)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
