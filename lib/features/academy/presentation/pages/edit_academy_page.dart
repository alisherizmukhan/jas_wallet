import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/profile_api_exception.dart';
import '../../../../core/localization/profile_errors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/academy_entity.dart';
import '../../providers/academy_provider.dart';

/// Edit Academy page — education entry synced with backend.
class EditAcademyPage extends ConsumerStatefulWidget {
  const EditAcademyPage({super.key, this.academyId});

  /// If null, creating new entry. If provided, editing existing.
  final String? academyId;

  @override
  ConsumerState<EditAcademyPage> createState() => _EditAcademyPageState();
}

class _EditAcademyPageState extends ConsumerState<EditAcademyPage> {
  static const List<String> _degreeKeys = [
    'bachelor',
    'master',
    'doctoral',
    'associate',
    'certificate',
    'other',
  ];

  late TextEditingController _nameController;
  late TextEditingController _degreeOtherController;
  late TextEditingController _specializationController;
  late TextEditingController _gpaController;
  late TextEditingController _descriptionController;

  String _selectedDegreeKey = 'bachelor';
  int? _startYear;
  int? _startMonth;
  int? _endYear;
  int? _endMonth;
  bool _isCurrentlyStudying = false;

  bool get _isValid {
    final otherOk =
        _selectedDegreeKey != 'other' || _degreeOtherController.text.trim().isNotEmpty;
    return _nameController.text.trim().isNotEmpty &&
        _specializationController.text.trim().isNotEmpty &&
        _startYear != null &&
        otherOk &&
        (_isCurrentlyStudying || _endYear != null);
  }

  final _years = List.generate(20, (i) => DateTime.now().year - i);

  List<String> _localizedMonths(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return List.generate(
      12,
      (i) => DateFormat.MMMM(locale).format(DateTime(2000, i + 1)),
    );
  }

  String _degreeMenuLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'bachelor':
        return l10n.resume_degreeBachelor;
      case 'master':
        return l10n.resume_degreeMaster;
      case 'doctoral':
        return l10n.resume_degreeDoctoral;
      case 'associate':
        return l10n.resume_degreeAssociate;
      case 'certificate':
        return l10n.resume_degreeCertificate;
      case 'other':
        return l10n.resume_degreeOther;
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _degreeOtherController = TextEditingController();
    _specializationController = TextEditingController();
    _gpaController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.academyId != null) {
      final academies = ref.read(academyListProvider);
      final existing =
          academies.valueOrNull?.where((e) => e.id == widget.academyId).firstOrNull;
      if (existing != null) {
        _nameController.text = existing.institutionName;
        _specializationController.text = existing.specialization;
        _gpaController.text = existing.gpa != null ? existing.gpa!.toStringAsFixed(2) : '';
        _descriptionController.text = existing.description ?? '';
        _startYear = existing.startYear;
        _startMonth = existing.startMonth;
        _endYear = existing.endYear;
        _endMonth = existing.endMonth;
        _isCurrentlyStudying = existing.isCurrentlyStudying;
        if (_degreeKeys.contains(existing.degreeKind)) {
          _selectedDegreeKey = existing.degreeKind;
        } else {
          _selectedDegreeKey = 'other';
        }
        _degreeOtherController.text = existing.degreeOther ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _degreeOtherController.dispose();
    _specializationController.dispose();
    _gpaController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_isValid) return;

    final uid = ref.read(userProvider).valueOrNull?.id ?? '';
    final kind = _selectedDegreeKey;
    final academy = AcademyEntity(
      id: widget.academyId ?? '',
      userId: uid,
      institutionName: _nameController.text.trim(),
      degreeKind: kind,
      degreeOther: kind == 'other' ? _degreeOtherController.text.trim() : null,
      specialization: _specializationController.text.trim(),
      startYear: _startYear!,
      startMonth: _startMonth,
      endYear: _isCurrentlyStudying ? null : _endYear,
      endMonth: _isCurrentlyStudying ? null : _endMonth,
      isCurrentlyStudying: _isCurrentlyStudying,
      gpa: double.tryParse(_gpaController.text.replaceAll(',', '.')),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      createdAt: DateTime.now(),
    );

    final notifier = ref.read(academyListProvider.notifier);
    // Toast before pop — optimistic (provider handles rollback on failure)
    if (mounted && context.mounted) {
      AppToast.showSuccess(context, AppLocalizations.of(context)!.common_saved);
    }
    if (mounted && context.mounted) context.pop();
    if (widget.academyId != null) {
      notifier.update(academy.copyWith(id: widget.academyId!)).ignore();
    } else {
      notifier.add(academy).ignore();
    }
  }

  Future<void> _delete() async {
    if (widget.academyId == null) return;
    // Pop immediately — provider removes from list and rolls back on error
    if (mounted && context.mounted) context.pop();
    try {
      await ref.read(academyListProvider.notifier).remove(widget.academyId!);
    } catch (e) {
      if (mounted && context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        final message = e is ProfileApiException
            ? profileApiUserMessage(e, l10n, serverFallback: l10n.resume_educationDeleteFailed)
            : l10n.resume_educationDeleteFailed;
        AppToast.showError(context, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        showBackButton: true,
        title: l10n.profile_academy,
        actions: [
          if (widget.academyId != null)
            IconButton(
              tooltip: l10n.common_delete,
              onPressed: _delete,
              icon: const AppIcon(AppIcons.delete, color: Colors.red),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    isLight: isLight,
                    children: [
                      _buildInputField(
                        controller: _nameController,
                        label: l10n.resume_universityName,
                        placeholder: l10n.resume_universityName,
                        icon: AppIcons.school,
                      ),
                      const SizedBox(height: 16),
                      _buildDegreeField(l10n, isLight),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _specializationController,
                        label: l10n.resume_facultyName,
                        placeholder: l10n.resume_facultyName,
                        icon: AppIcons.book,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isLight: isLight,
                    children: [
                      _buildSectionLabel(l10n.resume_startDate, isLight),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Builder(builder: (context) {
                              final months = _localizedMonths(context);
                              return _buildDropdown(
                                value: _startMonth != null ? months[_startMonth! - 1] : null,
                                hint: l10n.gamification_month,
                                items: months,
                                onChanged: (v) => setState(
                                  () => _startMonth = v != null ? months.indexOf(v) + 1 : null,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              value: _startYear?.toString(),
                              hint: l10n.gamification_year,
                              items: _years.map((y) => y.toString()).toList(),
                              onChanged: (v) =>
                                  setState(() => _startYear = int.tryParse(v ?? '')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => setState(() => _isCurrentlyStudying = !_isCurrentlyStudying),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: _isCurrentlyStudying
                                        ? AppColors.primary
                                        : AppColors.grey,
                                    width: 2,
                                  ),
                                  color: _isCurrentlyStudying
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                                child: _isCurrentlyStudying
                                    ? const AppIcon(AppIcons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.resume_present,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _isCurrentlyStudying
                                      ? AppColors.primary
                                      : (isLight ? AppColors.textColor : AppColors.textColorDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!_isCurrentlyStudying) ...[
                        const SizedBox(height: 14),
                        _buildSectionLabel(l10n.resume_endDate, isLight),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Builder(builder: (context) {
                                final months = _localizedMonths(context);
                                return _buildDropdown(
                                  value: _endMonth != null ? months[_endMonth! - 1] : null,
                                  hint: l10n.gamification_month,
                                  items: months,
                                  onChanged: (v) => setState(
                                    () => _endMonth = v != null ? months.indexOf(v) + 1 : null,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                value: _endYear?.toString(),
                                hint: l10n.gamification_year,
                                items: _years.map((y) => y.toString()).toList(),
                                onChanged: (v) =>
                                    setState(() => _endYear = int.tryParse(v ?? '')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isLight: isLight,
                    children: [
                      _buildInputField(
                        controller: _gpaController,
                        label: l10n.resume_gpa,
                        placeholder: '0.00 - 4.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        icon: AppIcons.trending,
                        inputFormatters: [_GpaInputFormatter()],
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _descriptionController,
                        label: l10n.resume_description,
                        placeholder: l10n.resume_description,
                        icon: AppIcons.document,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    isLight: isLight,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppIcon(AppIcons.info, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.resume_academySkillsNote,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: isLight ? AppColors.textColor : AppColors.textColorDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isValid ? () => _save() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isValid ? AppColors.primary : AppColors.secondary,
                  foregroundColor: _isValid ? Colors.white : AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.common_save,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDegreeField(AppLocalizations l10n, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(AppIcons.sparkles, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              l10n.resume_degree,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isLight ? AppColors.textColor : AppColors.textColorDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildDropdown(
          value: _degreeMenuLabel(_selectedDegreeKey, l10n),
          hint: l10n.resume_degree,
          items: _degreeKeys.map((k) => _degreeMenuLabel(k, l10n)).toList(),
          onChanged: (v) {
            if (v == null) return;
            final idx = _degreeKeys.indexWhere((k) => _degreeMenuLabel(k, l10n) == v);
            if (idx >= 0) {
              setState(() => _selectedDegreeKey = _degreeKeys[idx]);
            }
          },
        ),
        if (_selectedDegreeKey == 'other') ...[
          const SizedBox(height: 12),
          _buildInputField(
            controller: _degreeOtherController,
            label: l10n.resume_degreeOtherSpecify,
            placeholder: l10n.resume_degreeOtherSpecify,
            icon: AppIcons.edit,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionCard({required bool isLight, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight ? AppColors.borderGrey : AppColors.borderDark,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isLight) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.grey,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    AppIconData? icon,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hasContent = controller.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLight ? AppColors.borderGrey : AppColors.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasContent)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ),
          Row(
            crossAxisAlignment:
                maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
                  child: AppIcon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => setState(() {}),
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  inputFormatters: inputFormatters,
                  decoration: InputDecoration(
                    hintText: hasContent ? null : placeholder,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
                    ),
                    filled: true,
                    fillColor: isLight ? AppColors.white : AppColors.surfaceDark,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: isLight ? AppColors.textColor : AppColors.textColorDark,
                  ),
                ),
              ),
              if (hasContent)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isLight
                          ? AppColors.grey.withValues(alpha: 0.2)
                          : AppColors.borderDark,
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(
                      AppIcons.close,
                      size: 14,
                      color: AppColors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLight ? AppColors.borderGrey : AppColors.borderDark,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isLight ? AppColors.white : AppColors.surfaceDark,
          style: TextStyle(
            color: isLight ? AppColors.textColor : AppColors.textColorDark,
          ),
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          isExpanded: true,
          icon: AppIcon(AppIcons.chevronDown, color: AppColors.primary),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Auto-formats GPA as X.XX: typing "400" produces "4.00", "367" → "3.67".
class _GpaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
        composing: TextRange.empty,
      );
    }

    // Cap at 3 digits (X.XX)
    final capped = digits.length > 3 ? digits.substring(0, 3) : digits;

    // Format: 1 digit → "X", 2 → "X.Y", 3 → "X.YZ"
    final String formatted;
    if (capped.length == 1) {
      formatted = capped;
    } else if (capped.length == 2) {
      formatted = '${capped[0]}.${capped[1]}';
    } else {
      formatted = '${capped[0]}.${capped.substring(1)}';
    }

    // Integer part must be 0–4
    final intPart = int.tryParse(formatted.split('.').first) ?? 0;
    if (intPart > 4) return oldValue;

    // When integer part is 4, decimal must be 00 (GPA max = 4.00)
    final parts = formatted.split('.');
    if (intPart == 4 && parts.length > 1 && parts[1].isNotEmpty) {
      if (int.parse(parts[1].padRight(2, '0')) > 0) return oldValue;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}
