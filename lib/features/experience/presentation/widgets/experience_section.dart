import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/profile_api_exception.dart';
import '../../../../core/localization/profile_errors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/experience_entity.dart';
import '../../providers/experience_provider.dart';

/// Reusable widget to display Experience section in profile
class ExperienceSection extends ConsumerStatefulWidget {
  const ExperienceSection({
    super.key,
    this.userId,
    this.isOwnProfile = false,
    this.onEditTap,
    this.maxItems = 2,
  });

  /// If null, shows current user's experience
  final String? userId;

  /// Whether to show edit button
  final bool isOwnProfile;

  /// Callback when edit button is tapped
  final VoidCallback? onEditTap;

  /// Maximum items to show before collapse
  final int maxItems;

  @override
  ConsumerState<ExperienceSection> createState() => _ExperienceSectionState();
}

class _ExperienceSectionState extends ConsumerState<ExperienceSection> {
  bool _isExpanded = false;

  String _loadErrorMessage(Object error, AppLocalizations l10n) {
    if (error is ProfileApiException) {
      return profileApiUserMessage(
        error,
        l10n,
        serverFallback: l10n.profile_experienceLoadFailed,
      );
    }
    return l10n.profile_experienceLoadFailed;
  }

  List<ExperienceEntity> _sorted(List<ExperienceEntity> raw) {
    final experiences = List<ExperienceEntity>.from(raw)
      ..sort((a, b) {
        final bDate = DateTime(b.startYear, b.startMonth ?? 1);
        final aDate = DateTime(a.startYear, a.startMonth ?? 1);
        return bDate.compareTo(aDate);
      });
    return experiences;
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
                l10n.profile_workExperience,
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
                    AppIcons.add,
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
            _buildOtherUserContent(context, l10n),
        ],
      ),
    );
  }

  Widget _buildOwnProfileContent(
    BuildContext context,
    AppLocalizations l10n,
    bool isLight,
  ) {
    final async = ref.watch(experienceListProvider);
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
              ref.read(experienceListProvider.notifier).refresh();
            },
            child: Text(l10n.common_retry),
          ),
        ],
      ),
      data: (list) => _buildExperienceList(context, l10n, list),
    );
  }

  Widget _buildOtherUserContent(BuildContext context, AppLocalizations l10n) {
    final asyncData = ref.watch(userExperienceProvider(widget.userId!));
    final experiences = _sorted(asyncData.valueOrNull ?? []);
    return _buildExperienceList(context, l10n, experiences);
  }

  Widget _buildExperienceList(
    BuildContext context,
    AppLocalizations l10n,
    List<ExperienceEntity> experiences,
  ) {
    final sorted = _sorted(experiences);
    final hasContent = sorted.isNotEmpty;
    final displayExperiences =
        _isExpanded ? sorted : sorted.take(widget.maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasContent)
          Text(
            l10n.resume_addWorkExperience,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
            ),
          )
        else
          ...displayExperiences.map(
            (exp) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExperienceItem(context, exp),
            ),
          ),
        if (sorted.length > widget.maxItems)
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

  Widget _buildExperienceItem(BuildContext context, ExperienceEntity experience) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AppIcon(
            AppIcons.briefcase,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                experience.companyName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                experience.position,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
              Text(
                experience.dateRangeDisplay(locale, l10n.resume_present),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
        if (widget.isOwnProfile) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              context.pushNamed(
                'editExperience',
                queryParameters: {'id': experience.id},
              );
            },
            child: const AppIcon(
              AppIcons.edit,
              size: 20,
              color: AppColors.grey,
            ),
          ),
        ],
      ],
    );
  }
}
