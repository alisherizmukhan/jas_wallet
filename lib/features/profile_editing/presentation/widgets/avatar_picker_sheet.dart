import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

/// Bottom sheet for avatar picker options (camera, gallery, delete).
class AvatarPickerSheet extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;
  final VoidCallback? onRemoveSelected;

  const AvatarPickerSheet({
    super.key,
    required this.onCameraSelected,
    required this.onGallerySelected,
    this.onRemoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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

          const SizedBox(height: 24),

          Center(
            child: Text(
              AppLocalizations.of(context)!.editProfile_profilePhoto,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gallery option
              _PickerOption(
                icon: AppIcons.gallery,
                label: AppLocalizations.of(
                  context,
                )!.editProfile_chooseFromGallery,
                onTap: onGallerySelected,
              ),

              // Camera option
              _PickerOption(
                icon: AppIcons.camera,
                label: AppLocalizations.of(context)!.editProfile_takePhoto,
                onTap: onCameraSelected,
              ),

              // Delete avatar option (replaces templates option)
              _PickerOption(
                icon: AppIcons.delete,
                label: AppLocalizations.of(context)!.common_delete,
                onTap: onRemoveSelected,
                iconColor: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final AppIconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color iconColor;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLight ? AppColors.secondary : AppColors.surfaceDark,
                border: Border.all(
                  color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                ),
              ),
              child: Center(
                child: AppIcon(
                  icon,
                  size: 24,
                  color: isEnabled ? iconColor : AppColors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isEnabled
                      ? AppColors.grey
                      : AppColors.grey.withValues(alpha: 0.65),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with avatar templates grid.
class AvatarTemplatesSheet extends StatelessWidget {
  final Function(String) onAvatarSelected;

  const AvatarTemplatesSheet({super.key, required this.onAvatarSelected});

  static const List<String> _avatarPaths = [
    'assets/avatars/1.png',
    'assets/avatars/2.png',
    'assets/avatars/3.png',
    'assets/avatars/4.png',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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

          const SizedBox(height: 24),

          Text(
            AppLocalizations.of(context)!.editProfile_avatars,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),

          const SizedBox(height: 24),

          // Avatar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _avatarPaths.length,
            itemBuilder: (context, index) {
              final path = _avatarPaths[index];
              return GestureDetector(
                onTap: () => onAvatarSelected(path),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary,
                    border: Border.all(
                      color: AppColors.grey.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      path,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
