import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/utils/image_picker_service.dart';
import '../../../profile_editing/presentation/widgets/avatar_picker_sheet.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../providers/salto_student_card_provider.dart';
import 'salto_student_card_widget.dart';

class SaltoStudentCardDetailsSection extends ConsumerWidget {
  const SaltoStudentCardDetailsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final cardState = ref.watch(saltoStudentCardProvider);
    final cardNotifier = ref.read(saltoStudentCardProvider.notifier);
    final user = userAsync.valueOrNull;

    if (userAsync.isLoading && user == null) {
      return const Center(child: AppLoader());
    }

    if (user == null) {
      return const SizedBox.shrink();
    }

    final studentId = (user.studentId?.trim().isNotEmpty ?? false)
        ? user.studentId!.trim()
        : user.id;

    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaltoStudentCard(
          firstName: user.firstName,
          lastName: user.lastName,
          studentId: studentId,
          avatarUrl: user.avatarUrl,
          design: cardState.selectedDesign,
          customDesignImagePath: cardState.customDesignImagePath,
          isNuStudent: (user.email?.trim().toLowerCase().endsWith('@nu.edu.kz') ?? false),
        ),
        const SizedBox(height: 20),
        DetailsGroupCard(
          title: _profileInfoTitle(context),
          child: Column(
            children: [
              UserInfoRow(
                label: l10n.hub_saltoCard,
                value: studentId,
              ),
              UserInfoRow(
                label: l10n.auth_username,
                value: user.displayUsername,
              ),
              UserInfoRow(
                label: l10n.auth_email,
                value: user.email ?? '-',
              ),
              UserInfoRow(
                label: l10n.auth_phone,
                value: user.phone ?? '-',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DetailsGroupCard(
          title: _appearanceTitle(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppearanceOptionTile(
                title: _photoBlockTitle(context),
                subtitle: _photoBlockSubtitle(context),
                actionLabel: _editPhotoTitle(context),
                onAction: () => _showAvatarPicker(context, ref),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Divider(
                  height: 1,
                  color: isLight
                      ? AppColors.borderGrey
                      : AppColors.borderDark.withValues(alpha: 0.5),
                ),
              ),
              AppearanceOptionTile(
                title: _cardBlockTitle(context),
                subtitle: _cardDesignDisclaimer(context),
                actionLabel: _cardDesignActionTitle(context),
                onAction: cardState.isLoaded
                    ? () => _showCardDesignPicker(
                        context,
                        ref,
                        firstName: user.firstName,
                        lastName: user.lastName,
                        studentId: studentId,
                        avatarUrl: user.avatarUrl,
                        currentDesign: cardState.selectedDesign,
                      )
                    : null,
                secondaryActionLabel:
                    (cardState.selectedDesign ==
                                SaltoStudentCardDesign.custom &&
                            (cardState.customDesignImagePath
                                    ?.trim()
                                    .isNotEmpty ??
                                false))
                        ? _resetCardDesignTitle(context)
                        : null,
                onSecondaryAction: cardState.isLoaded
                    ? () => cardNotifier.clearCustomDesign()
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCardDesignPicker(
    BuildContext context,
    WidgetRef ref, {
    required String firstName,
    required String lastName,
    required String studentId,
    required String? avatarUrl,
    required SaltoStudentCardDesign currentDesign,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return CardDesignPickerSheet(
          title: _cardDesignActionTitle(context),
          galleryLabel: AppLocalizations.of(
            context,
          )!.editProfile_chooseFromGallery,
          cameraLabel: AppLocalizations.of(context)!.editProfile_takePhoto,
          templatesLabel: AppLocalizations.of(
            context,
          )!.editProfile_avatarTemplates,
          onGallerySelected: () async {
            Navigator.pop(sheetContext);
            await _pickAndCropCardDesign(
              context: context,
              ref: ref,
              picker: () => ImagePickerService().pickFromGallery(),
            );
          },
          onCameraSelected: () async {
            Navigator.pop(sheetContext);
            await _pickAndCropCardDesign(
              context: context,
              ref: ref,
              picker: () => ImagePickerService().pickFromCamera(
                preferredCameraDevice: CameraDevice.rear,
              ),
            );
          },
          onTemplatesSelected: () {
            Navigator.pop(sheetContext);
            final email = ref.read(userProvider).valueOrNull?.email;
            final isNu = email != null &&
                email.trim().toLowerCase().endsWith('@nu.edu.kz');
            _showCardTemplatePicker(
              context,
              ref,
              firstName: firstName,
              lastName: lastName,
              studentId: studentId,
              avatarUrl: avatarUrl,
              currentDesign: currentDesign,
              isNuStudent: isNu,
            );
          },
        );
      },
    );
  }

  void _showCardTemplatePicker(
    BuildContext context,
    WidgetRef ref, {
    required String firstName,
    required String lastName,
    required String studentId,
    required String? avatarUrl,
    required SaltoStudentCardDesign currentDesign,
    required bool isNuStudent,
  }) {
    final initialDesign = currentDesign == SaltoStudentCardDesign.custom
        ? (isNuStudent
            ? SaltoStudentCardDesign.nuDefault
            : SaltoStudentCardDesign.classicGold)
        : currentDesign;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return CardTemplatePickerSheet(
          title: _templatesTitle(context),
          saveLabel: _saveTitle(context),
          firstName: firstName,
          lastName: lastName,
          studentId: studentId,
          avatarUrl: avatarUrl,
          initialDesign: initialDesign,
          isNuStudent: isNuStudent,
          onSave: (design) async {
            await ref
                .read(saltoStudentCardProvider.notifier)
                .selectDesign(design);
            if (sheetContext.mounted) {
              Navigator.pop(sheetContext);
            }
          },
        );
      },
    );
  }

  Future<void> _pickAndCropCardDesign({
    required BuildContext context,
    required WidgetRef ref,
    required Future<ImagePickResult> Function() picker,
  }) async {
    final picked = await picker();
    if (!context.mounted) return;

    if (!picked.isSuccess || picked.path == null) {
      if (picked.error != null && picked.error!.isNotEmpty) {
        _showAvatarError(context);
      }
      return;
    }

    final cropped = await ImagePickerService().cropCardImage(picked.path!);
    if (!context.mounted) return;

    if (cropped.isSuccess && cropped.path != null) {
      await ref
          .read(saltoStudentCardProvider.notifier)
          .selectCustomDesign(cropped.path!);
      if (context.mounted) {
        AppToast.showSuccess(context, _cardDesignUpdatedTitle(context));
      }
      return;
    }

    if (cropped.error != null && cropped.error!.isNotEmpty) {
      _showAvatarError(context);
    }
  }

  void _showAvatarPicker(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(userProvider).valueOrNull;
    final hasAvatar = currentUser?.avatarUrl?.trim().isNotEmpty ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return AvatarPickerSheet(
          onCameraSelected: () async {
            Navigator.pop(sheetContext);
            await _pickAndCropAvatar(
              context: context,
              ref: ref,
              picker: () => ImagePickerService().pickFromCamera(
                preferredCameraDevice: CameraDevice.front,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 85,
              ),
            );
          },
          onGallerySelected: () async {
            Navigator.pop(sheetContext);
            await _pickAndCropAvatar(
              context: context,
              ref: ref,
              picker: () => ImagePickerService().pickFromGallery(
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 85,
              ),
            );
          },
          onRemoveSelected: hasAvatar
              ? () async {
                  Navigator.pop(sheetContext);
                  try {
                    await ref.read(userProvider.notifier).deleteAvatar();
                    if (context.mounted) {
                      AppToast.showSuccess(context, _avatarDeletedTitle(context));
                    }
                  } catch (_) {
                    if (!context.mounted) return;
                    _showAvatarError(context);
                  }
                }
              : null,
        );
      },
    );
  }

  Future<void> _pickAndCropAvatar({
    required BuildContext context,
    required WidgetRef ref,
    required Future<ImagePickResult> Function() picker,
  }) async {
    final picked = await picker();

    if (!context.mounted) return;
    if (!picked.isSuccess || picked.path == null) {
      if (picked.error != null && picked.error!.isNotEmpty) {
        _showAvatarError(context);
      }
      return;
    }

    final cropped = await ImagePickerService().cropImage(picked.path!);
    if (!context.mounted) return;

    if (cropped.isSuccess && cropped.path != null) {
      try {
        await ref.read(userProvider.notifier).updateAvatar(cropped.path!);
        if (context.mounted) {
          AppToast.showSuccess(context, _avatarUpdatedTitle(context));
        }
      } catch (e) {
        if (!context.mounted) return;
        _showAvatarError(context);
      }
      return;
    }

    if (cropped.error != null && cropped.error!.isNotEmpty) {
      _showAvatarError(context);
    }
  }

  void _showAvatarError(BuildContext context) {
    AppToast.showError(context, _avatarErrorTitle(context));
  }

  String _language(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  String _editPhotoTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Изменить фото профиля';
      case 'kk':
        return 'Профиль фотосын өзгерту';
      default:
        return 'Edit profile photo';
    }
  }

  String _cardDesignActionTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Выбрать свой дизайн карты';
      case 'kk':
        return 'Картаның өз дизайнын таңдау';
      default:
        return 'Choose your own card design';
    }
  }

  String _profileInfoTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Профиль';
      case 'kk':
        return 'Профиль';
      default:
        return 'Profile';
    }
  }

  String _appearanceTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Внешний вид';
      case 'kk':
        return 'Көрініс';
      default:
        return 'Appearance';
    }
  }

  String _photoBlockTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Фото профиля';
      case 'kk':
        return 'Профиль фотосы';
      default:
        return 'Profile photo';
    }
  }

  String _photoBlockSubtitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Обновите фото, которое отображается на карте и в вашем профиле.';
      case 'kk':
        return 'Картада және профильде көрсетілетін фотоны жаңартыңыз.';
      default:
        return 'Update the photo shown on your card and profile.';
    }
  }

  String _cardBlockTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Дизайн карты';
      case 'kk':
        return 'Карта дизайны';
      default:
        return 'Card design';
    }
  }

  String _resetCardDesignTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Сбросить свой дизайн';
      case 'kk':
        return 'Өз дизайнын өшіру';
      default:
        return 'Reset custom design';
    }
  }

  String _cardDesignDisclaimer(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Это меняет только дизайн карты в приложении. Физическая карта не изменится.';
      case 'kk':
        return 'Бұл тек қосымшадағы карта дизайнын өзгертеді. Физикалық карта өзгермейді.';
      default:
        return 'This changes only the card design in the app. It does not change your physical card.';
    }
  }

  String _templatesTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Шаблоны';
      case 'kk':
        return 'Үлгілер';
      default:
        return 'Templates';
    }
  }

  String _saveTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Сохранить';
      case 'kk':
        return 'Сақтау';
      default:
        return 'Save';
    }
  }

  String _avatarErrorTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Не удалось выбрать изображение';
      case 'kk':
        return 'Суретті таңдау мүмкін болмады';
      default:
        return 'Failed to pick image';
    }
  }

  String _avatarUpdatedTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Фото профиля обновлено';
      case 'kk':
        return 'Профиль фотосы жаңартылды';
      default:
        return 'Profile photo updated';
    }
  }

  String _avatarDeletedTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Фото профиля удалено';
      case 'kk':
        return 'Профиль фотосы жойылды';
      default:
        return 'Profile photo removed';
    }
  }

  String _cardDesignUpdatedTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Дизайн карты обновлён';
      case 'kk':
        return 'Карта дизайны жаңартылды';
      default:
        return 'Card design updated';
    }
  }
}

class DetailsGroupCard extends StatelessWidget {
  const DetailsGroupCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? AppColors.borderGrey
              : AppColors.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class AppearanceOptionTile extends StatelessWidget {
  const AppearanceOptionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: AppColors.primary, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (secondaryActionLabel != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onSecondaryAction,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.grey,
                side: BorderSide(color: AppColors.grey.withValues(alpha: 0.4), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                secondaryActionLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UserInfoRow extends StatelessWidget {
  const UserInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final displayValue = value.trim().isEmpty ? '-' : value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayValue,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: isLight
                ? AppColors.borderGrey
                : AppColors.borderDark.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

class CardDesignPickerSheet extends StatelessWidget {
  const CardDesignPickerSheet({
    super.key,
    required this.title,
    required this.galleryLabel,
    required this.cameraLabel,
    required this.templatesLabel,
    required this.onGallerySelected,
    required this.onCameraSelected,
    required this.onTemplatesSelected,
  });

  final String title;
  final String galleryLabel;
  final String cameraLabel;
  final String templatesLabel;
  final VoidCallback onGallerySelected;
  final VoidCallback onCameraSelected;
  final VoidCallback onTemplatesSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetIconOption(
                icon: AppIcons.gallery,
                label: galleryLabel,
                onTap: onGallerySelected,
              ),
              _SheetIconOption(
                icon: AppIcons.camera,
                label: cameraLabel,
                onTap: onCameraSelected,
              ),
              _SheetIconOption(
                icon: AppIcons.avatarIcon,
                label: templatesLabel,
                onTap: onTemplatesSelected,
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _SheetIconOption extends StatelessWidget {
  const _SheetIconOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final AppIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                child: AppIcon(icon, size: 24, color: AppColors.primary),
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
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.grey,
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

class CardTemplatePickerSheet extends StatefulWidget {
  const CardTemplatePickerSheet({
    super.key,
    required this.title,
    required this.saveLabel,
    required this.firstName,
    required this.lastName,
    required this.studentId,
    required this.avatarUrl,
    required this.initialDesign,
    required this.onSave,
    this.isNuStudent = false,
  });

  final String title;
  final String saveLabel;
  final String firstName;
  final String lastName;
  final String studentId;
  final String? avatarUrl;
  final SaltoStudentCardDesign initialDesign;
  final Future<void> Function(SaltoStudentCardDesign design) onSave;
  final bool isNuStudent;

  @override
  State<CardTemplatePickerSheet> createState() =>
      _CardTemplatePickerSheetState();
}

class _CardTemplatePickerSheetState extends State<CardTemplatePickerSheet> {
  late SaltoStudentCardDesign _selectedDesign;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDesign = widget.initialDesign;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Center(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SaltoStudentCard(
                firstName: widget.firstName,
                lastName: widget.lastName,
                studentId: widget.studentId,
                avatarUrl: widget.avatarUrl,
                design: _selectedDesign,
                isNuStudent: widget.isNuStudent,
              ),
              const SizedBox(height: 16),
              SaltoCardDesignSelector(
                selectedDesign: _selectedDesign,
                onSelect: (design) => setState(() => _selectedDesign = design),
                isNuStudent: widget.isNuStudent,
              ),
              const SizedBox(height: 18),
              AppPrimaryButton(
                text: widget.saveLabel,
                isLoading: _isSaving,
                onPressed: () async {
                  setState(() => _isSaving = true);
                  await widget.onSave(_selectedDesign);
                  if (mounted) {
                    setState(() => _isSaving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
