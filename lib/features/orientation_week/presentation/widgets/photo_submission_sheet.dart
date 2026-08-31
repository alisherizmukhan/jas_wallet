import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/utils/image_picker_service.dart';
import '../../domain/entities/photo_mission.dart';
import '../theme/orientation_brand.dart';

/// What the student chose in [showPhotoSubmissionSheet].
sealed class PhotoSubmissionChoice {
  const PhotoSubmissionChoice();
}

/// Send [path] in for the mission (a first submission or a replacement).
class SubmitPhoto extends PhotoSubmissionChoice {
  const SubmitPhoto(this.path);

  final String path;
}

/// Remove the mission's existing photo.
class DeletePhoto extends PhotoSubmissionChoice {
  const DeletePhoto();
}

/// The photo source picker for one mission.
///
/// Deliberately options-only, with no preview pane: Take Photo / Delete.
///
/// There is intentionally **no gallery option** — a mission photo has to be
/// taken on the spot for the quest to mean anything, so picking an existing
/// image from the camera roll is not offered at all. Take Photo resolves
/// immediately with the captured path; Delete resolves with [DeletePhoto]
/// and is enabled only when the mission already has a photo.
///
/// Resolves `null` if the sheet is dismissed.
Future<PhotoSubmissionChoice?> showPhotoSubmissionSheet(BuildContext context, PhotoMission mission) {
  return AppBottomSheet.show<PhotoSubmissionChoice>(
    context: context,
    title: mission.title,
    centerTitle: true,
    child: _PhotoSubmissionSheetContent(mission: mission),
  );
}

class _PhotoSubmissionSheetContent extends StatefulWidget {
  const _PhotoSubmissionSheetContent({required this.mission});

  final PhotoMission mission;

  @override
  State<_PhotoSubmissionSheetContent> createState() => _PhotoSubmissionSheetContentState();
}

class _PhotoSubmissionSheetContentState extends State<_PhotoSubmissionSheetContent> {
  bool _isPicking = false;

  Future<void> _pick() async {
    setState(() => _isPicking = true);
    final result = await ImagePickerService().pickFromCamera(
      // CV verify needs the camera original — do not resize or re-encode.
      imageQuality: 100,
    );
    if (!mounted) return;
    setState(() => _isPicking = false);

    if (result.isSuccess && result.path != null) {
      Navigator.of(context).pop(SubmitPhoto(result.path!));
    } else if (result.error != null) {
      AppToast.showError(context, result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final path = widget.mission.photoPath;
    // Backend-verified photos are https URLs — deletion is not supported yet.
    final canDelete = path != null &&
        !path.startsWith('http://') &&
        !path.startsWith('https://');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.mission.description,
          textAlign: TextAlign.center,
          style: FeatureStyle.caption.copyWith(color: FeatureStyle.mute, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: OrientationBrand.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Token artwork keeps its own colours — never tinted.
                const AppIcon(AppIcons.tokenAdsl, size: 16),
                const SizedBox(width: 5),
                Text(
                  '+${widget.mission.rewardTokens}',
                  style: FeatureStyle.caption.copyWith(
                    color: OrientationBrand.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        if (_isPicking)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: OrientationBrand.accent),
              ),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SourceOption(
                icon: AppIcons.camera,
                label: l10n.orientation_pq_take_photo,
                onTap: _pick,
              ),
              _SourceOption(
                icon: AppIcons.delete,
                label: l10n.common_delete,
                iconColor: AppColors.error,
                onTap: canDelete ? () => Navigator.of(context).pop(const DeletePhoto()) : null,
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// One circular source option, matching the profile avatar picker's styling.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final AppIconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final resolvedIconColor = iconColor ?? OrientationBrand.accent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FeatureStyle.surfaceSoft,
              ),
              child: Center(
                child: AppIcon(icon, size: 22, color: isEnabled ? resolvedIconColor : FeatureStyle.stone),
              ),
            ),
            const SizedBox(height: 8),
            // One whole word per line, scaled down rather than broken.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final word in label.split(' '))
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      word,
                      textAlign: TextAlign.center,
                      style: FeatureStyle.tiny.copyWith(
                        color: isEnabled ? FeatureStyle.mute : FeatureStyle.stone,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
