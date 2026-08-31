import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../providers/salto_student_card_provider.dart';

class CardPalette {
  const CardPalette({
    required this.gradient,
    required this.shadowColor,
    required this.trailingIcon,
  });

  final List<Color> gradient;
  final Color shadowColor;
  final AppIconData trailingIcon;
}

CardPalette cardPaletteFor(SaltoStudentCardDesign design) {
  switch (design) {
    case SaltoStudentCardDesign.classicGold:
      return const CardPalette(
        gradient: [Color(0xFFE0AA3E), Color(0xFFD08B24), Color(0xFFB86B1A)],
        shadowColor: Color(0xFFC4811F),
        trailingIcon: AppIcons.security,
      );
    case SaltoStudentCardDesign.blueOrbit:
      return const CardPalette(
        gradient: [Color(0xFF2E6BFF), Color(0xFF1B3EA1), Color(0xFF17214B)],
        shadowColor: Color(0xFF1B3EA1),
        trailingIcon: AppIcons.target,
      );
    case SaltoStudentCardDesign.emeraldWave:
      return const CardPalette(
        gradient: [Color(0xFF0F7A67), Color(0xFF0D4B5A), Color(0xFF0A2F36)],
        shadowColor: Color(0xFF0D4B5A),
        trailingIcon: AppIcons.statistics,
      );
    case SaltoStudentCardDesign.sunsetBlaze:
      return const CardPalette(
        gradient: [Color(0xFFFF8A5C), Color(0xFFEF5A37), Color(0xFF8D2D1E)],
        shadowColor: Color(0xFFB7442C),
        trailingIcon: AppIcons.sun,
      );
    case SaltoStudentCardDesign.arcticFrost:
      return const CardPalette(
        gradient: [Color(0xFF95D4F0), Color(0xFF5F88C8), Color(0xFF334D8A)],
        shadowColor: Color(0xFF4A69AA),
        trailingIcon: AppIcons.info,
      );
    case SaltoStudentCardDesign.carbonNight:
      return const CardPalette(
        gradient: [Color(0xFF444A56), Color(0xFF262C35), Color(0xFF141820)],
        shadowColor: Color(0xFF232B36),
        trailingIcon: AppIcons.moon,
      );
    case SaltoStudentCardDesign.custom:
      return const CardPalette(
        gradient: [Color(0xFF364256), Color(0xFF212A38), Color(0xFF10151C)],
        shadowColor: Color(0xFF1C2737),
        trailingIcon: AppIcons.sparkles,
      );
    case SaltoStudentCardDesign.nuDefault:
    case SaltoStudentCardDesign.nuGsb:
    case SaltoStudentCardDesign.nuNusom:
    case SaltoStudentCardDesign.nuSeds:
    case SaltoStudentCardDesign.nuSmg:
    case SaltoStudentCardDesign.nuSsh:
      return const CardPalette(
        gradient: [Color(0xFF003366), Color(0xFF002244), Color(0xFF001122)],
        shadowColor: Color(0xFF002244),
        trailingIcon: AppIcons.school,
      );
  }
}

class AvatarFallback extends StatelessWidget {
  const AvatarFallback({super.key, required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black.withValues(alpha: 0.24),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
    );
  }
}

String cardInitials(String firstName, String lastName) {
  final first = firstName.trim().isEmpty ? '' : firstName.trim()[0];
  final last = lastName.trim().isEmpty ? '' : lastName.trim()[0];
  final initials = '$first$last'.toUpperCase();
  return initials.isEmpty ? '?' : initials;
}
