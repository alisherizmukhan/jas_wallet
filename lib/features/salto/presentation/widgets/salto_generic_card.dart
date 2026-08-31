import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/image_utils.dart';
import '../providers/salto_student_card_provider.dart';
import 'salto_card_palette.dart';

class GenericStudentCard extends StatelessWidget {
  const GenericStudentCard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.studentId,
    required this.design,
    this.avatarUrl,
    this.customDesignImagePath,
  });

  final String firstName;
  final String lastName;
  final String studentId;
  final SaltoStudentCardDesign design;
  final String? avatarUrl;
  final String? customDesignImagePath;

  @override
  Widget build(BuildContext context) {
    final palette = cardPaletteFor(design);
    final effectiveFirstName = firstName.trim().isEmpty ? 'Student' : firstName;
    final effectiveLastName = lastName.trim().isEmpty ? '' : lastName;
    final customBackgroundImage =
        (design == SaltoStudentCardDesign.custom &&
            (customDesignImagePath?.trim().isNotEmpty ?? false))
        ? getImageProvider(customDesignImagePath)
        : null;
    final hasCustomBackground = customBackgroundImage != null;

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: hasCustomBackground
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E2630), Color(0xFF10151C)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette.gradient,
                ),
          image: hasCustomBackground
              ? DecorationImage(
                  image: customBackgroundImage,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  colorFilter: ColorFilter.mode(
                    AppColors.black.withValues(alpha: 0.36),
                    BlendMode.darken,
                  ),
                )
              : null,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.shadowColor.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              DesignOverlay(design: design),
              Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight =
                        constraints.maxHeight < 130 ||
                        constraints.maxWidth < 250;
                    final topFontSize = isTight ? 8.5 : 10.0;
                    final middleSpacing = isTight ? 6.0 : 10.0;
                    final idFont = isTight ? 11.0 : 13.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NAZARBAYEV\nUNIVERSITY',
                              textScaler: MediaQuery.textScalerOf(
                                context,
                              ).clamp(maxScaleFactor: 1.3),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: topFontSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: middleSpacing),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, middleConstraints) {
                              final photoHeight = middleConstraints.maxHeight
                                  .clamp(56.0, 84.0)
                                  .toDouble();
                              final photoWidth = (photoHeight * 0.81)
                                  .clamp(45.0, 68.0)
                                  .toDouble();
                              final nameFontSize =
                                  middleConstraints.maxHeight < 66
                                  ? 16.0
                                  : 20.0;

                              return Row(
                                children: [
                                  Container(
                                    width: photoWidth,
                                    height: photoHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.55,
                                        ),
                                        width: 1.6,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image(
                                        image: getAvatarImageProvider(
                                          avatarUrl,
                                        ),
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                AvatarFallback(
                                                  initials: cardInitials(
                                                    firstName,
                                                    lastName,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          effectiveFirstName,
                                          textScaler: MediaQuery.textScalerOf(
                                            context,
                                          ).clamp(maxScaleFactor: 1.3),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: nameFontSize,
                                            fontWeight: FontWeight.w800,
                                            height: 1.05,
                                          ),
                                        ),
                                        if (effectiveLastName.isNotEmpty)
                                          Text(
                                            effectiveLastName,
                                            textScaler: MediaQuery.textScalerOf(
                                              context,
                                            ).clamp(maxScaleFactor: 1.3),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.white,
                                              fontSize: nameFontSize,
                                              fontWeight: FontWeight.w800,
                                              height: 1.05,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(height: middleSpacing),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                'ID $studentId',
                                textScaler: MediaQuery.textScalerOf(
                                  context,
                                ).clamp(maxScaleFactor: 1.3),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: idFont,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DesignOverlay extends StatelessWidget {
  const DesignOverlay({super.key, required this.design});

  final SaltoStudentCardDesign design;

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case SaltoStudentCardDesign.classicGold:
        return Positioned(
          right: -28,
          top: -18,
          child: Transform.rotate(
            angle: -0.2,
            child: AppIcon(
              AppIcons.sparkles,
              size: 150,
              color: AppColors.white.withValues(alpha: 0.08),
            ),
          ),
        );
      case SaltoStudentCardDesign.blueOrbit:
        return Stack(
          children: [
            Positioned(
              right: -36,
              top: 10,
              child: Transform.rotate(
                angle: -0.55,
                child: Container(
                  width: 170,
                  height: 48,
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: -44,
              bottom: -2,
              child: Transform.rotate(
                angle: -0.55,
                child: Container(
                  width: 180,
                  height: 28,
                  color: AppColors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ],
        );
      case SaltoStudentCardDesign.emeraldWave:
        return Stack(
          children: [
            Positioned(
              right: -20,
              top: -26,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 12,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.17),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
        );
      case SaltoStudentCardDesign.sunsetBlaze:
        return Stack(
          children: [
            Positioned(
              right: -38,
              top: -30,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: -20,
              child: Container(
                width: 95,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        );
      case SaltoStudentCardDesign.arcticFrost:
        return Stack(
          children: [
            Positioned(
              right: -22,
              top: -16,
              child: Transform.rotate(
                angle: 0.25,
                child: Container(
                  width: 148,
                  height: 38,
                  color: AppColors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              right: -12,
              bottom: 10,
              child: Transform.rotate(
                angle: 0.25,
                child: Container(
                  width: 124,
                  height: 24,
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        );
      case SaltoStudentCardDesign.carbonNight:
        return Positioned(
          right: -30,
          top: -24,
          child: AppIcon(
            AppIcons.gem,
            size: 160,
            color: AppColors.white.withValues(alpha: 0.08),
          ),
        );
      case SaltoStudentCardDesign.custom:
      case SaltoStudentCardDesign.nuDefault:
      case SaltoStudentCardDesign.nuGsb:
      case SaltoStudentCardDesign.nuNusom:
      case SaltoStudentCardDesign.nuSeds:
      case SaltoStudentCardDesign.nuSmg:
      case SaltoStudentCardDesign.nuSsh:
        return const SizedBox.shrink();
    }
  }
}

class DesignPreviewChip extends StatelessWidget {
  const DesignPreviewChip({
    super.key,
    required this.design,
    required this.isSelected,
    this.onTap,
  });

  final SaltoStudentCardDesign design;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isNu = design.isNuDesign;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 52,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isNu
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cardPaletteFor(design).gradient,
                ),
          border: Border.all(
            color: isSelected ? AppColors.white : AppColors.borderGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 8 : 9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isNu)
                Image.asset(
                  design.nuBackgroundAsset!,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              if (isSelected)
                const Center(
                  child: AppIcon(
                    AppIcons.check,
                    size: 14,
                    color: AppColors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
