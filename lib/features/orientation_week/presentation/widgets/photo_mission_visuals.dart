import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/photo_mission.dart';
import '../theme/orientation_brand.dart';

/// Presentation mapping for the pure-Dart Photo Quest enums.
///
/// [PhotoMission] carries semantic enums rather than icons or colours so the
/// domain layer never imports Flutter — and so a backend can ship a new set
/// of missions without a code change here.
abstract class PhotoMissionVisuals {
  static AppIconData icon(MissionIcon icon) => switch (icon) {
        MissionIcon.landmark => AppIcons.landmark,
        MissionIcon.building => AppIcons.building,
        MissionIcon.coffee => AppIcons.coffee,
        MissionIcon.trees => AppIcons.trees,
        MissionIcon.palette => AppIcons.palette,
        MissionIcon.megaphone => AppIcons.megaphone,
        MissionIcon.sunset => AppIcons.sunset,
        MissionIcon.book => AppIcons.book,
        MissionIcon.utensils => AppIcons.utensils,
        MissionIcon.compass => AppIcons.map,
        MissionIcon.camera => AppIcons.camera,
      };

  /// Category accents from the curated design.md palette — the glyph tint over
  /// a soft same-colour chip, so the grid reads rich but harmonious.
  ///
  /// Not accentPink (gold) for any category: [PhotoMissionCard] also paints
  /// this colour as its location caption's *text*, and gold text fails
  /// contrast on white/soft-tint backgrounds.
  static Color accent(MissionCategory category) => switch (category) {
        MissionCategory.landmark => OrientationBrand.accentCobalt,
        MissionCategory.art => OrientationBrand.accentCobalt,
        MissionCategory.facility => OrientationBrand.accentTeal,
        MissionCategory.architecture => OrientationBrand.accentCobalt,
        MissionCategory.study => OrientationBrand.accentTeal,
        MissionCategory.nature => OrientationBrand.accentTeal,
        MissionCategory.food => OrientationBrand.accentOrange,
        MissionCategory.event => OrientationBrand.accentOrange,
        MissionCategory.sky => OrientationBrand.accentTeal,
      };

  /// Difficulty accent, matching the filter tabs' camera glyphs.
  static Color difficultyColor(MissionDifficulty difficulty) => switch (difficulty) {
        MissionDifficulty.easy => AppColors.success,
        MissionDifficulty.medium => AppColors.orange,
        MissionDifficulty.hard => const Color(0xFFEC4899),
      };
}
