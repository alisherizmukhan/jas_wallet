import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// ADSL brand palette (assets/BrandBook__ADSL_02.pdf), scoped to Orientation
/// Week only — FeatureStyle's own defaults stay untouched because Club Fair
/// shares the same design tokens and must not be re-themed by this.
///
/// Maroon, navy and teal are all low-luminance colours — they read fine as
/// dark text/icons on the brand book's own white pages, but that exact same
/// darkness makes them nearly invisible against this feature's dark-mode
/// surfaces (~#1A1A1A–#242424): a navy `#1F2A44` icon on a `#242424` card is
/// two very-dark colours on top of each other. [FeatureStyle]'s own neutrals
/// solve this by swapping to a different value per theme; these three do the
/// same — brightened, same hue family, in dark mode — while [accentOrange]
/// and [accentPink] (gold) are already light enough to read on both surfaces
/// and stay fixed. This is the same thing every real dark-mode system does
/// (iOS/Material both ship a brighter tone of a brand colour for dark mode,
/// not the literal light-mode value) — it is not a departure from "brand
/// colours everywhere", it is what makes them actually visible everywhere.
abstract class OrientationBrand {
  static bool get _isDark => FeatureStyle.isDark;

  /// ADSL maroon — this feature's single emphasis colour, replacing the
  /// shared cobalt/violet FeatureStyle.accent for Orientation Week only.
  static Color get accent => _isDark ? const Color(0xFFE06158) : const Color(0xFF800000);

  /// ADSL navy.
  static Color get accentCobalt => _isDark ? const Color(0xFF8CA3D6) : const Color(0xFF1F2A44);

  /// ADSL teal.
  static Color get accentTeal => _isDark ? const Color(0xFF2EDBBB) : const Color(0xFF006B5B);

  /// ADSL orange — already light enough to read on a dark surface, fixed
  /// across both themes.
  static const accentOrange = Color(0xFFFF6B00);

  /// ADSL gold — same reasoning as [accentOrange].
  static const accentPink = Color(0xFFFFD700);

  static const cream = Color(0xFFF8F5F2);
  static const ink = Color(0xFF1A1A1A);
}
