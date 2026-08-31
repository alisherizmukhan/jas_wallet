import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/profile_api_exception.dart';
import '../../../../core/localization/profile_errors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/experience_entity.dart';
import '../../providers/experience_provider.dart';

/// Edit Experience page - form for work experience
class EditExperiencePage extends ConsumerStatefulWidget {
  const EditExperiencePage({super.key, this.experienceId});
  
  /// If null, creating new experience. If provided, editing existing.
  final String? experienceId;

  @override
  ConsumerState<EditExperiencePage> createState() => _EditExperiencePageState();
}

class _EditExperiencePageState extends ConsumerState<EditExperiencePage> {
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  int? _startYear;
  int? _startMonth;
  int? _endYear;
  int? _endMonth;
  bool _isCurrentJob = false;
  bool _busy = false;
  bool _hydrated = false;

  bool get _isValid => 
    _companyController.text.isNotEmpty && 
    _positionController.text.isNotEmpty &&
    _startYear != null &&
    (_isCurrentJob || _endYear != null);

  final _years = List.generate(20, (i) => DateTime.now().year - i);

  List<String> _localizedMonths(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return List.generate(12, (i) => DateFormat.MMMM(locale).format(DateTime(2000, i + 1)));
  }

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController();
    _positionController = TextEditingController();
    
    // If editing, load existing data. The list may not be loaded yet on a
    // cold start / deep link — build() hydrates again once it arrives.
    if (widget.experienceId != null) {
      _hydrateFrom(ref.read(experienceListProvider).valueOrNull);
    }
  }

  /// Populates the form from the loaded list. Safe to call multiple times:
  /// only fills once and never clobbers edits the user already started.
  void _hydrateFrom(List<ExperienceEntity>? experiences) {
    if (_hydrated || experiences == null) return;
    final existing =
        experiences.where((e) => e.id == widget.experienceId).firstOrNull;
    if (existing == null) return;
    if (_companyController.text.isNotEmpty ||
        _positionController.text.isNotEmpty) {
      return;
    }
    _companyController.text = existing.companyName;
    _positionController.text = existing.position;
    _startYear = existing.startYear;
    _startMonth = existing.startMonth;
    _endYear = existing.endYear;
    _endMonth = existing.endMonth;
    _isCurrentJob = existing.isCurrentJob;
    _hydrated = true;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_isValid || _busy) return;

    final uid = ref.read(userProvider).valueOrNull?.id ?? '';
    final experience = ExperienceEntity(
      id: widget.experienceId ?? '',
      userId: uid,
      companyName: _companyController.text.trim(),
      position: _positionController.text.trim(),
      startYear: _startYear!,
      startMonth: _startMonth,
      endYear: _isCurrentJob ? null : _endYear,
      endMonth: _isCurrentJob ? null : _endMonth,
      isCurrentJob: _isCurrentJob,
      createdAt: DateTime.now(),
    );

    final notifier = ref.read(experienceListProvider.notifier);
    if (mounted && context.mounted) {
      AppToast.showSuccess(context, AppLocalizations.of(context)!.common_saved);
    }
    if (mounted && context.mounted) context.pop();
    if (widget.experienceId != null) {
      notifier.update(experience.copyWith(id: widget.experienceId!)).ignore();
    } else {
      notifier.add(experience).ignore();
    }
  }

  Future<void> _delete() async {
    if (widget.experienceId == null || _busy) return;
    // Pop immediately — provider removes from list and rolls back on error
    if (mounted && context.mounted) context.pop();
    try {
      await ref.read(experienceListProvider.notifier).remove(widget.experienceId!);
    } catch (e) {
      // provider already rolled back; page is gone so no toast
      if (mounted && context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        final msg = e is ProfileApiException
            ? profileApiUserMessage(
                e,
                l10n,
                serverFallback: l10n.profile_experienceDeleteFailed,
              )
            : l10n.profile_experienceDeleteFailed;
        AppToast.showError(context, msg);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hydrate once the list arrives (handles cold-start / deep-link races where
    // the provider was still loading during initState).
    if (widget.experienceId != null && !_hydrated) {
      _hydrateFrom(ref.watch(experienceListProvider).valueOrNull);
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        showBackButton: true,
        title: l10n.resume_workExperience,
        actions: widget.experienceId != null
            ? [
                IconButton(
                  tooltip: l10n.common_delete,
                  onPressed: _delete,
                  icon: const AppIcon(AppIcons.delete, color: Colors.red),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basic Info Card ──
                  _buildSectionCard(
                    isLight: isLight,
                    children: [
                      // Company name field
                      _buildInputField(
                        controller: _companyController,
                        label: l10n.resume_companyName,
                        placeholder: l10n.resume_companyName,
                        icon: AppIcons.briefcase,
                      ),
                      const SizedBox(height: 16),
                      
                      // Position field
                      _buildInputField(
                        controller: _positionController,
                        label: l10n.resume_position,
                        placeholder: l10n.resume_position,
                        icon: AppIcons.briefcase,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // ── Date Range Card ──
                  _buildSectionCard(
                    isLight: isLight,
                    children: [
                      _buildSectionLabel(l10n.resume_startDate, isLight),
                      const SizedBox(height: 10),
                      
                      // Start date row
                      Row(
                        children: [
                          Expanded(
                            child: Builder(builder: (context) {
                              final months = _localizedMonths(context);
                              return _buildDropdown(
                                value: _startMonth != null ? months[_startMonth! - 1] : null,
                                hint: l10n.gamification_month,
                                items: months,
                                onChanged: (v) => setState(() => _startMonth = v != null ? months.indexOf(v) + 1 : null),
                              );
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              value: _startYear?.toString(),
                              hint: l10n.gamification_year,
                              items: _years.map((y) => y.toString()).toList(),
                              onChanged: (v) => setState(() => _startYear = int.tryParse(v ?? '')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      // Current job checkbox
                      GestureDetector(
                        onTap: () => setState(() => _isCurrentJob = !_isCurrentJob),
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
                                    color: _isCurrentJob ? AppColors.primary : AppColors.grey,
                                    width: 2,
                                  ),
                                  color: _isCurrentJob ? AppColors.primary : Colors.transparent,
                                ),
                                child: _isCurrentJob
                                    ? const AppIcon(AppIcons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.resume_currentlyWorkingHere,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _isCurrentJob
                                      ? AppColors.primary
                                      : (isLight ? AppColors.textColor : AppColors.textColorDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // End date row (if not current job)
                      if (!_isCurrentJob) ...[
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
                                  onChanged: (v) => setState(() => _endMonth = v != null ? months.indexOf(v) + 1 : null),
                                );
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                value: _endYear?.toString(),
                                hint: l10n.gamification_year,
                                items: _years.map((y) => y.toString()).toList(),
                                onChanged: (v) => setState(() => _endYear = int.tryParse(v ?? '')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isValid && !_busy) ? _save : null,
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
                  style: TextStyle(
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
    AppIconData? icon,
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
            children: [
              if (icon != null) ...[
                AppIcon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => setState(() {}),
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
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
