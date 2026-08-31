import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../user/presentation/providers/user_provider.dart';

/// Reusable widget to display About Me section in profile
class AboutMeSection extends ConsumerStatefulWidget {
  const AboutMeSection({
    super.key,
    this.isOwnProfile = false,
    this.onEditTap,
    this.maxLines = 3,
  });

  /// Whether to show edit button
  final bool isOwnProfile;
  
  /// Callback when edit button is tapped
  final VoidCallback? onEditTap;
  
  /// Maximum lines to show when collapsed
  final int maxLines;

  @override
  ConsumerState<AboutMeSection> createState() => _AboutMeSectionState();
}

class _AboutMeSectionState extends ConsumerState<AboutMeSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final content = ref.watch(userProvider.select((u) => u.valueOrNull?.bio ?? ''));

    final hasContent = content.isNotEmpty;
    // Show expand button if content is long (more than ~150 chars or has multiple lines)
    final needsExpand = hasContent && (content.length > 150 || content.split('\n').length > widget.maxLines);

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
                l10n.profile_aboutMe,
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
          Text(
            hasContent ? content : l10n.profile_addAboutMe,
            style: TextStyle(
              fontSize: 14,
              color: hasContent
                  ? (theme.textTheme.bodyMedium?.color ?? AppColors.textColor)
                  : AppColors.grey,
            ),
            maxLines: _isExpanded ? null : widget.maxLines,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
          ),
          // Expand/Collapse button
          if (needsExpand)
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
}
