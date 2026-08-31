import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/skill_entity.dart';
import '../../providers/skills_provider.dart';

/// Edit Skills page - polished input with chip suggestions
class EditSkillsPage extends ConsumerStatefulWidget {
  const EditSkillsPage({super.key});

  @override
  ConsumerState<EditSkillsPage> createState() => _EditSkillsPageState();
}

class _EditSkillsPageState extends ConsumerState<EditSkillsPage> {
  late TextEditingController _searchController;
  late List<SkillEntity> _selectedSkills;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedSkills = List.from(ref.read(skillsListProvider).valueOrNull ?? []);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _save() {
    final notifier = ref.read(skillsListProvider.notifier);
    AppToast.showSuccess(context, AppLocalizations.of(context)!.common_saved);
    context.pop();
    notifier.setSkills(_selectedSkills).ignore();
  }

  void _addSkill(SkillEntity skill) {
    if (!_selectedSkills.contains(skill)) {
      setState(() {
        _selectedSkills.add(skill);
        _searchController.clear();
        _searchQuery = '';
      });
    }
  }

  void _removeSkill(SkillEntity skill) {
    setState(() {
      _selectedSkills.removeWhere((s) => s.id == skill.id);
    });
  }

  void _addCustomSkill() {
    if (_searchQuery.isNotEmpty) {
      final newSkill = SkillEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _searchQuery,
      );
      _addSkill(newSkill);
    }
  }

  List<SkillEntity> get _filteredSuggestions {
    if (_searchQuery.isEmpty) return SkillEntity.suggestions;
    return SkillEntity.suggestions.where((s) => 
      s.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
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
        title: l10n.profile_skills,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search input
                  Container(
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.white : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
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
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      onSubmitted: (_) => _addCustomSkill(),
                      decoration: InputDecoration(
                        hintText: l10n.resume_addSkills,
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: AppColors.grey,
                        ),
                        prefixIcon: AppIcon(
                          AppIcons.search,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: _addCustomSkill,
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const AppIcon(
                                    AppIcons.add,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        color: isLight
                            ? AppColors.textColor
                            : AppColors.textPrimaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selected skills
                  if (_selectedSkills.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          l10n.profile_skills,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isLight
                                ? AppColors.textColor
                                : AppColors.textPrimaryDark,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_selectedSkills.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedSkills.map((skill) => _buildSkillChip(
                        skill,
                        isSelected: true,
                        onTap: () => _removeSkill(skill),
                      )).toList(),
                    ),
                    const SizedBox(height: 28),
                    Divider(
                      color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Suggestions header
                  Text(
                    l10n.common_suggestions,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isLight
                          ? AppColors.textColor
                          : AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Suggestion chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filteredSuggestions
                        .where((s) => !_selectedSkills.contains(s))
                        .map((skill) => _buildSkillChip(
                          skill,
                          isSelected: false,
                          onTap: () => _addSkill(skill),
                        ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          
          // Save button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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

  Widget _buildSkillChip(SkillEntity skill, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight
                    ? AppColors.primaryLight
                    : AppColors.primary.withValues(alpha: 0.16))
              : (isLight ? AppColors.white : AppColors.surfaceDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isLight ? AppColors.borderGrey : AppColors.borderDark),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              skill.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : (isLight ? AppColors.textColor : AppColors.textColorDark),
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 6),
              AppIcon(
                AppIcons.close,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
