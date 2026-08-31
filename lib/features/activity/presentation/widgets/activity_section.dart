import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_ui/app_ui.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_activity_entity.dart';
import '../../providers/user_activity_provider.dart';

/// Reusable Activity section widget that displays user activities.
/// Can be embedded in My Level, Profile, Activity page, etc.
class ActivitySection extends ConsumerStatefulWidget {
  const ActivitySection({
    super.key,
    this.maxItems,
    this.showExpandButton = true,
    this.showAddButton = false,
    this.showHeader = true,
    this.onAddTap,
    this.onEditTap,
  });

  /// Maximum items to show initially. If null, shows all.
  final int? maxItems;
  
  /// Whether to show expand/collapse button.
  final bool showExpandButton;
  
  /// Whether to show the "Add Activity" button.
  final bool showAddButton;
  
  /// Whether to show the section header.
  final bool showHeader;
  
  /// Callback when add button is tapped.
  final VoidCallback? onAddTap;
  
  /// Callback when edit button is tapped.
  final VoidCallback? onEditTap;

  @override
  ConsumerState<ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends ConsumerState<ActivitySection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    final activitiesRaw = ref.watch(userActivityListProvider);
    final activities = List<UserActivityEntity>.from(activitiesRaw)
        ..sort((a, b) => b.date.compareTo(a.date));
    final displayActivities = _isExpanded || widget.maxItems == null
        ? activities
        : activities.take(widget.maxItems ?? 2).toList();

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
          // Header row - always show when showHeader is true
          if (widget.showHeader)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.gamification_activity,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
                if (widget.showAddButton)
                  GestureDetector(
                    onTap: widget.onEditTap ?? () => context.push(AppRoutes.activity),
                    child: const AppIcon(
                      AppIcons.add,
                      size: 20,
                      color: AppColors.grey,
                    ),
                  ),
              ],
            ),

          if (widget.showHeader) const SizedBox(height: 16),

          // Empty state
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  l10n.social_nothingFound,
                  style: const TextStyle(color: AppColors.grey),
                ),
              ),
            ),

          // Activity items
          ...displayActivities.map((activity) => _buildActivityItem(activity)),

          // Expand/Collapse button
          if (widget.showExpandButton && activities.length > (widget.maxItems ?? 2))
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
      ),
    );
  }

  Widget _buildActivityItem(UserActivityEntity activity) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: () {
        // Navigate to view/edit activity (only if own profile - showAddButton)
        if (widget.showAddButton) {
          context.push('${AppRoutes.editUserActivity}?id=${activity.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLight ? AppColors.borderGrey : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: activity.imageUrls.isNotEmpty
                  ? _buildActivityImage(activity.imageUrls.first)
                  : _buildImagePlaceholder(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showAddButton)
              AppIcon(
                AppIcons.edit,
                size: 20,
                color: AppColors.grey,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityImage(String imagePath) {
    final provider = getImageProvider(imagePath);
    if (provider == null) return _buildImagePlaceholder();
    return Image(
      image: provider,
      width: 80,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
    );
  }
  
  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppIcon(
        AppIcons.image,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}
