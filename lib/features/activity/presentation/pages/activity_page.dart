import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_ui/app_ui.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_activity_entity.dart';
import '../../providers/user_activity_provider.dart';

/// Activity page showing user's volunteer/participation activities.
class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key});

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final activities = ref.watch(userActivityListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: l10n.gamification_activity,
        showBackButton: true,
      ),
      body: Builder(
        builder: (context) {
          final displayActivities = _isExpanded 
              ? activities 
              : activities.take(2).toList();
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.white : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.gamification_activity,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isLight
                                    ? AppColors.black
                                    : AppColors.textPrimaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Empty state
                        if (activities.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
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
                        if (activities.length > 2)
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
                  ),
                ),
              ),
              
              // Add activity button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(AppRoutes.editUserActivity);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppIcon(AppIcons.addCircle, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(l10n.gamification_addActivity),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityItem(UserActivityEntity activity) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: () {
        // Navigate to view/edit activity
        context.push('${AppRoutes.editUserActivity}?id=${activity.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLight ? AppColors.white : AppColors.surfaceDark,
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
                      color: isLight
                          ? AppColors.textColor
                          : AppColors.textPrimaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                  if (activity.description != null && activity.description!.isNotEmpty) ...[  
                    const SizedBox(height: 2),
                    Text(
                      activity.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            AppIcon(AppIcons.chevronRight, color: AppColors.grey),
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
