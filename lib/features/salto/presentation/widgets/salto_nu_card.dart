import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/image_utils.dart';
import '../providers/salto_student_card_provider.dart';
import 'salto_card_palette.dart';

class NuStudentCard extends StatelessWidget {
  const NuStudentCard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.studentId,
    required this.design,
    this.avatarUrl,
  });

  final String firstName;
  final String lastName;
  final String studentId;
  final SaltoStudentCardDesign design;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final effectiveFirstName = firstName.trim().isEmpty ? 'Student' : firstName;
    final effectiveLastName = lastName.trim().isEmpty ? '' : lastName;
    final bgAsset = design.nuBackgroundAsset!;

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC4811F).withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                bgAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight =
                        constraints.maxHeight < 130 ||
                        constraints.maxWidth < 250;
                    final logoHeight = isTight ? 20.0 : 28.0;
                    final idFont = isTight ? 12.0 : 15.0;

                    return Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Image.asset(
                              'assets/nu_card_templates/NU_horizontal_1.png',
                              height: logoHeight,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, middleConstraints) {
                              final photoHeight = middleConstraints.maxHeight
                                  .clamp(72.0, 110.0)
                                  .toDouble();
                              final photoWidth = (photoHeight * 0.81)
                                  .clamp(58.0, 89.0)
                                  .toDouble();
                              final nameFontSize =
                                  middleConstraints.maxHeight < 66
                                  ? 18.0
                                  : 22.0;

                              return Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Container(
                                        width: photoWidth,
                                        height: photoHeight,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.55,
                                            ),
                                            width: 1.6,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                    ),
                                  ),
                                  Positioned(
                                    left: photoWidth + 14,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            effectiveFirstName,
                                            // Clamped rather than disabled — the
                                            // card's fixed-aspect layout can't
                                            // absorb unlimited growth, but a
                                            // modest cap still lets low-vision
                                            // users benefit from larger system
                                            // text instead of none at all.
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
                                          const SizedBox(height: 4),
                                          if (effectiveLastName.isNotEmpty)
                                            Text(
                                              effectiveLastName,
                                              // Clamped rather than disabled — the
                                              // card's fixed-aspect layout can't
                                              // absorb unlimited growth, but a
                                              // modest cap still lets low-vision
                                              // users benefit from larger system
                                              // text instead of none at all.
                                              textScaler:
                                                  MediaQuery.textScalerOf(
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
                                          const SizedBox(height: 6),
                                          Text(
                                            'ID $studentId',
                                            // Clamped rather than disabled — the
                                            // card's fixed-aspect layout can't
                                            // absorb unlimited growth, but a
                                            // modest cap still lets low-vision
                                            // users benefit from larger system
                                            // text instead of none at all.
                                            textScaler: MediaQuery.textScalerOf(
                                              context,
                                            ).clamp(maxScaleFactor: 1.3),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                              fontSize: idFont,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight = constraints.maxWidth < 250;
                    final foundationLogoSize = isTight ? 12.0 : 16.0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/nu_card_templates/impact_foundation/nu_impact_foundation_logo.png',
                          height: foundationLogoSize,
                          filterQuality: FilterQuality.high,
                        ),
                        Image.asset(
                          'assets/nu_card_templates/BFlab_white_logo.png',
                          height: foundationLogoSize,
                          filterQuality: FilterQuality.high,
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

class NuCustomStudentCard extends StatelessWidget {
  const NuCustomStudentCard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.studentId,
    this.avatarUrl,
    this.customDesignImagePath,
  });

  final String firstName;
  final String lastName;
  final String studentId;
  final String? avatarUrl;
  final String? customDesignImagePath;

  @override
  Widget build(BuildContext context) {
    final effectiveFirstName = firstName.trim().isEmpty ? 'Student' : firstName;
    final effectiveLastName = lastName.trim().isEmpty ? '' : lastName;
    final customBackgroundImage =
        (customDesignImagePath?.trim().isNotEmpty ?? false)
        ? getImageProvider(customDesignImagePath)
        : null;
    final hasCustomBackground = customBackgroundImage != null;

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF003366), Color(0xFF002244)],
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
              color: const Color(0xFF002244).withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight =
                        constraints.maxHeight < 130 ||
                        constraints.maxWidth < 250;
                    final logoHeight = isTight ? 20.0 : 28.0;
                    final idFont = isTight ? 12.0 : 15.0;

                    return Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Image.asset(
                              'assets/nu_card_templates/NU_horizontal_1.png',
                              height: logoHeight,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, middleConstraints) {
                              final photoHeight = middleConstraints.maxHeight
                                  .clamp(72.0, 110.0)
                                  .toDouble();
                              final photoWidth = (photoHeight * 0.81)
                                  .clamp(58.0, 89.0)
                                  .toDouble();
                              final nameFontSize =
                                  middleConstraints.maxHeight < 66
                                  ? 18.0
                                  : 22.0;

                              return Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Container(
                                        width: photoWidth,
                                        height: photoHeight,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.55,
                                            ),
                                            width: 1.6,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                    ),
                                  ),
                                  Positioned(
                                    left: photoWidth + 14,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            effectiveFirstName,
                                            // Clamped rather than disabled — the
                                            // card's fixed-aspect layout can't
                                            // absorb unlimited growth, but a
                                            // modest cap still lets low-vision
                                            // users benefit from larger system
                                            // text instead of none at all.
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
                                          const SizedBox(height: 4),
                                          if (effectiveLastName.isNotEmpty)
                                            Text(
                                              effectiveLastName,
                                              // Clamped rather than disabled — the
                                              // card's fixed-aspect layout can't
                                              // absorb unlimited growth, but a
                                              // modest cap still lets low-vision
                                              // users benefit from larger system
                                              // text instead of none at all.
                                              textScaler:
                                                  MediaQuery.textScalerOf(
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
                                          const SizedBox(height: 6),
                                          Text(
                                            'ID $studentId',
                                            // Clamped rather than disabled — the
                                            // card's fixed-aspect layout can't
                                            // absorb unlimited growth, but a
                                            // modest cap still lets low-vision
                                            // users benefit from larger system
                                            // text instead of none at all.
                                            textScaler: MediaQuery.textScalerOf(
                                              context,
                                            ).clamp(maxScaleFactor: 1.3),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                              fontSize: idFont,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight = constraints.maxWidth < 250;
                    final foundationLogoSize = isTight ? 12.0 : 16.0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/nu_card_templates/impact_foundation/nu_impact_foundation_logo.png',
                          height: foundationLogoSize,
                          filterQuality: FilterQuality.high,
                        ),
                        Image.asset(
                          'assets/nu_card_templates/BFlab_white_logo.png',
                          height: foundationLogoSize,
                          filterQuality: FilterQuality.high,
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
