import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

/// Gender picker bottom sheet with radio selection.
/// Uses String values: 'male', 'female', 'other'
class GenderPickerSheet extends StatefulWidget {
  final String? selectedGender;
  final Function(String) onGenderSelected;

  const GenderPickerSheet({
    super.key,
    this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  State<GenderPickerSheet> createState() => _GenderPickerSheetState();
}

class _GenderPickerSheetState extends State<GenderPickerSheet> {
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.selectedGender;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bottomPadding =
        16 +
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.editProfile_gender,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _GenderOption(
              label: l10n.editProfile_male,
              isSelected: _selectedGender == 'male',
              isLight: isLight,
              onTap: () => setState(() => _selectedGender = 'male'),
            ),
            const SizedBox(height: 10),
            _GenderOption(
              label: l10n.editProfile_female,
              isSelected: _selectedGender == 'female',
              isLight: isLight,
              onTap: () => setState(() => _selectedGender = 'female'),
            ),
            const SizedBox(height: 10),
            _GenderOption(
              label: l10n.editProfile_other,
              isSelected: _selectedGender == 'other',
              isLight: isLight,
              onTap: () => setState(() => _selectedGender = 'other'),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              text: l10n.common_save,
              isEnabled: _selectedGender != null,
              onPressed: _selectedGender != null
                  ? () => widget.onGenderSelected(_selectedGender!)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLight;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.isSelected,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primaryLight.withValues(alpha: 0.35)
          : (isLight ? AppColors.fieldBackground : AppColors.borderDark),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.8)
                  : (isLight ? AppColors.borderGrey : AppColors.borderDark),
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
