import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'tutorial_slide.dart';

abstract class TutorialContent {
  static List<TutorialSlide> svcMeal(AppLocalizations l10n) => [
    TutorialSlide(
      title: l10n.tutorial_svcMeal_slide1_title,
      body: l10n.tutorial_svcMeal_slide1_body,
      imagePath: 'assets/tutorials/meal1.webp',
      gradientBegin: const Color(0xFF065F46),
      gradientEnd: const Color(0xFF10B981),
    ),
    TutorialSlide(
      title: l10n.tutorial_svcMeal_slide2_title,
      body: l10n.tutorial_svcMeal_slide2_body,
      imagePath: 'assets/tutorials/meal2.webp',
      gradientBegin: const Color(0xFF047857),
      gradientEnd: const Color(0xFF34D399),
    ),
    TutorialSlide(
      title: l10n.tutorial_svcMeal_slide3_title,
      body: l10n.tutorial_svcMeal_slide3_body,
      imagePath: 'assets/tutorials/meal3.webp',
      gradientBegin: const Color(0xFF10B981),
      gradientEnd: const Color(0xFF6EE7B7),
    ),
  ];

  static List<TutorialSlide> saltoAccess(AppLocalizations l10n) => [
    TutorialSlide(
      title: l10n.tutorial_salto_slide1_title,
      body: l10n.tutorial_salto_slide1_body,
      imagePath: 'assets/tutorials/salto1.webp',
      gradientBegin: const Color(0xFF003399),
      gradientEnd: const Color(0xFF0066FF),
    ),
    TutorialSlide(
      title: l10n.tutorial_salto_slide2_title,
      body: l10n.tutorial_salto_slide2_body,
      imagePath: 'assets/tutorials/salto2.webp',
      gradientBegin: const Color(0xFF0055DD),
      gradientEnd: const Color(0xFF00AAFF),
    ),
    TutorialSlide(
      title: l10n.tutorial_salto_slide3_title,
      body: l10n.tutorial_salto_slide3_body,
      imagePath: 'assets/tutorials/salto3.webp',
      gradientBegin: const Color(0xFF0066FF),
      gradientEnd: const Color(0xFF00DDFF),
    ),
  ];

  static List<TutorialSlide> referral(AppLocalizations l10n) => [
    TutorialSlide(
      title: l10n.tutorial_referral_slide1_title,
      body: l10n.tutorial_referral_slide1_body,
      imagePath: 'assets/tutorials/referral1.webp',
      gradientBegin: const Color(0xFF92400E),
      gradientEnd: const Color(0xFFF59E0B),
    ),
    TutorialSlide(
      title: l10n.tutorial_referral_slide2_title,
      body: l10n.tutorial_referral_slide2_body,
      imagePath: 'assets/tutorials/referral2.webp',
      gradientBegin: const Color(0xFFD97706),
      gradientEnd: const Color(0xFFFB923C),
    ),
    TutorialSlide(
      title: l10n.tutorial_referral_slide3_title,
      body: l10n.tutorial_referral_slide3_body,
      imagePath: 'assets/tutorials/referral3.webp',
      gradientBegin: const Color(0xFFB45309),
      gradientEnd: const Color(0xFFFCD34D),
    ),
  ];

  static List<TutorialSlide> profile(AppLocalizations l10n) => [
    TutorialSlide(
      title: l10n.tutorial_profile_slide1_title,
      body: l10n.tutorial_profile_slide1_body,
      imagePath: 'assets/tutorials/digitalID1.webp',
      gradientBegin: const Color(0xFF5B21B6),
      gradientEnd: const Color(0xFF8B5CF6),
    ),
    TutorialSlide(
      title: l10n.tutorial_profile_slide2_title,
      body: l10n.tutorial_profile_slide2_body,
      imagePath: 'assets/tutorials/digitalID2.webp',
      gradientBegin: const Color(0xFF6D28D9),
      gradientEnd: const Color(0xFFA78BFA),
    ),
    TutorialSlide(
      title: l10n.tutorial_profile_slide3_title,
      body: l10n.tutorial_profile_slide3_body,
      imagePath: 'assets/tutorials/digitalID3.webp',
      gradientBegin: const Color(0xFF7C3AED),
      gradientEnd: const Color(0xFFC084FC),
    ),
  ];
}
