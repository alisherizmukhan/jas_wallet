import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/profile_api_exception.dart';
import '../../../../core/localization/profile_errors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/skill_entity.dart';
import '../../providers/skills_provider.dart';

/// Reusable widget to display Skills section in profile
class SkillsSection extends ConsumerStatefulWidget {
  const SkillsSection({
    super.key,
    this.userId,
    this.isOwnProfile = false,
    this.onEditTap,
    this.maxItems = 6,
  });

  /// If null, shows current user's skills
  final String? userId;

  /// Whether to show edit button
  final bool isOwnProfile;

  /// Callback when edit button is tapped
  final VoidCallback? onEditTap;

  /// Maximum skills to show when collapsed
  final int maxItems;

  @override
  ConsumerState<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends ConsumerState<SkillsSection> {
  bool _isExpanded = false;

  String _loadErrorMessage(Object error, AppLocalizations l10n) {
    if (error is ProfileApiException) {
      return profileApiUserMessage(
        error,
        l10n,
        serverFallback: l10n.profile_skillsLoadFailed,
      );
    }
    return l10n.profile_skillsLoadFailed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? AppColors.borderGrey : AppColors.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.profile_skills,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
              const Spacer(),
              if (widget.isOwnProfile)
                GestureDetector(
                  onTap: widget.onEditTap,
                  child: const AppIcon(
                    AppIcons.edit,
                    size: 20,
                    color: AppColors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.userId == null)
            _buildOwnProfileContent(context, l10n, isLight)
          else
            _buildOtherUserContent(l10n),
        ],
      ),
    );
  }

  Widget _buildOwnProfileContent(
    BuildContext context,
    AppLocalizations l10n,
    bool isLight,
  ) {
    final async = ref.watch(skillsListProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (err, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loadErrorMessage(err, l10n),
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: isLight ? AppColors.textColor : AppColors.textColorDark,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(skillsListProvider.notifier).refresh();
            },
            child: Text(l10n.common_retry),
          ),
        ],
      ),
      data: (skills) => _buildSkillsList(l10n, skills),
    );
  }

  Widget _buildOtherUserContent(AppLocalizations l10n) {
    final asyncData = ref.watch(userSkillsProvider(widget.userId!));
    final skills = asyncData.valueOrNull ?? [];
    return _buildSkillsList(l10n, skills);
  }

  Widget _buildSkillsList(
    AppLocalizations l10n,
    List<SkillEntity> skills,
  ) {
    final hasContent = skills.isNotEmpty;
    final displaySkills =
        _isExpanded ? skills : skills.take(widget.maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasContent)
          Text(
            l10n.resume_addSkills,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: displaySkills
                .map(
                  (skill) => Text(
                    '${skill.name}  •',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                )
                .toList(),
          ),
        if (skills.length > widget.maxItems)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    _isExpanded
                        ? l10n.gamification_collapse
                        : l10n.gamification_expand,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  AppIcon(
                    _isExpanded
                        ? AppIcons.chevronUp
                        : AppIcons.chevronDown,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
