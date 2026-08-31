import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/profile_api_exception.dart';
import '../../../../core/localization/profile_errors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/academy_entity.dart';
import '../../providers/academy_provider.dart';

/// Reusable widget to display Academy section in profile
class AcademySection extends ConsumerStatefulWidget {
  const AcademySection({
    super.key,
    this.userId,
    this.isOwnProfile = false,
    this.onEditTap,
    this.maxItems = 2,
  });

  /// If null, shows current user's academy
  final String? userId;

  /// Whether to show edit button
  final bool isOwnProfile;

  /// Callback when edit button is tapped
  final VoidCallback? onEditTap;

  /// Maximum items to show
  final int maxItems;

  @override
  ConsumerState<AcademySection> createState() => _AcademySectionState();
}

class _AcademySectionState extends ConsumerState<AcademySection> {
  bool _isExpanded = false;

  String _loadErrorMessage(Object error, AppLocalizations l10n) {
    if (error is ProfileApiException) {
      return profileApiUserMessage(
        error,
        l10n,
        serverFallback: l10n.resume_educationLoadFailed,
      );
    }
    return l10n.resume_educationLoadFailed;
  }

  List<AcademyEntity> _sorted(List<AcademyEntity> raw) {
    final academies = List<AcademyEntity>.from(raw);
    academies.sort((a, b) {
      final bDate = DateTime(b.startYear, b.startMonth ?? 1);
      final aDate = DateTime(a.startYear, a.startMonth ?? 1);
      return bDate.compareTo(aDate);
    });
    return academies;
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
                l10n.profile_academy,
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
          const SizedBox(height: 16),
          if (widget.userId == null)
            _buildOwnProfileContent(context, l10n, isLight)
          else
            _buildOtherUserContent(l10n, isLight),
        ],
      ),
    );
  }

  Widget _buildOwnProfileContent(
    BuildContext context,
    AppLocalizations l10n,
    bool isLight,
  ) {
    final async = ref.watch(academyListProvider);
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
              ref.read(academyListProvider.notifier).refresh();
            },
            child: Text(l10n.common_retry),
          ),
        ],
      ),
      data: (list) => _buildAcademyList(l10n, isLight, list),
    );
  }

  Widget _buildOtherUserContent(AppLocalizations l10n, bool isLight) {
    final asyncData = ref.watch(userAcademyProvider(widget.userId!));
    final academies = _sorted(asyncData.valueOrNull ?? []);
    return _buildAcademyList(l10n, isLight, academies);
  }

  Widget _buildAcademyList(
    AppLocalizations l10n,
    bool isLight,
    List<AcademyEntity> academies,
  ) {
    final sorted = _sorted(academies);
    final hasContent = sorted.isNotEmpty;
    final displayAcademies =
        _isExpanded ? sorted : sorted.take(widget.maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasContent)
          Text(
            l10n.resume_addEducation,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
            ),
          )
        else
          ...displayAcademies.map(
            (academy) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAcademyItem(academy),
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
                    _isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown,
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

  Widget _buildAcademyItem(AcademyEntity academy) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

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
            AppIcons.school,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                academy.institutionName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                academy.degreeDisplayLabel(l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                academy.specialization,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
              Text(
                academy.dateRangeDisplay(locale, l10n.resume_present),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
              if (academy.gpa != null)
                Text(
                  'GPA: ${academy.gpa}',
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
                'editAcademy',
                queryParameters: {'id': academy.id},
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
