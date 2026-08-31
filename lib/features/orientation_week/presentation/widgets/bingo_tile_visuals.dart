import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/bingo_tile.dart';
import '../theme/orientation_brand.dart';

/// Presentation mapping for the pure-Dart Bingo enums.
///
/// [BingoTile] deliberately carries semantic enums rather than icons or
/// colours so the domain layer never imports Flutter. Everything visual
/// about a tile is resolved here, which also means a backend can ship a
/// completely different board (new titles, new icons, new categories) and
/// the UI keeps working without a code change.
abstract class BingoTileVisuals {
  static AppIconData icon(BingoTileIcon icon) => switch (icon) {
        BingoTileIcon.calendar => AppIcons.calendar,
        BingoTileIcon.camera => AppIcons.camera,
        BingoTileIcon.message => AppIcons.chat,
        BingoTileIcon.location => AppIcons.location,
        BingoTileIcon.clipboard => AppIcons.document,
        BingoTileIcon.book => AppIcons.book,
        BingoTileIcon.utensils => AppIcons.utensils,
        BingoTileIcon.door => AppIcons.doorOpen,
        BingoTileIcon.explore => AppIcons.map,
        BingoTileIcon.graduation => AppIcons.school,
        BingoTileIcon.schedule => AppIcons.calendarCheck,
        BingoTileIcon.send => AppIcons.send,
        BingoTileIcon.megaphone => AppIcons.megaphone,
        BingoTileIcon.token => AppIcons.star,
        BingoTileIcon.trophy => AppIcons.trophy,
        BingoTileIcon.map => AppIcons.map,
        BingoTileIcon.bowl => AppIcons.bowl,
        BingoTileIcon.gift => AppIcons.gift,
        BingoTileIcon.heart => AppIcons.heart,
        BingoTileIcon.qrCode => AppIcons.qrCode,
        BingoTileIcon.flag => AppIcons.flag,
      };

  /// Category accents drawn from the curated design.md palette — colourful
  /// but harmonious, applied as the glyph tint over a soft same-colour chip so
  /// the board reads rich rather than mono. Never a full-surface colour.
  static Color accent(BingoTileCategory category) => switch (category) {
        BingoTileCategory.exploration => OrientationBrand.accentCobalt,
        BingoTileCategory.campus => OrientationBrand.accentTeal,
        BingoTileCategory.activity => OrientationBrand.accentTeal,
        BingoTileCategory.academic => OrientationBrand.accentCobalt,
        BingoTileCategory.food => OrientationBrand.accentOrange,
        BingoTileCategory.reward => OrientationBrand.accentPink,
      };
}
