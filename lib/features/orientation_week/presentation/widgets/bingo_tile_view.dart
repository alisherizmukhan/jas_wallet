import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/bingo_tile.dart';
import 'bingo_tile_visuals.dart';
import '../theme/orientation_brand.dart';

/// One square of the Bingo board.
///
/// Every cell renders at the same fixed icon and text size — titles are kept
/// short (see `mock_bingo.dart`) and packed one word per line, so nothing
/// scales per-tile and the board reads as a uniform grid.
///
/// A completed cell isn't stamped with a check: it fades back and shrinks
/// slightly, so it reads as "done and out of the way" while the winning line
/// is drawn over the board itself (see `bingo_board_grid.dart`).
class BingoTileView extends StatelessWidget {
  const BingoTileView({
    super.key,
    required this.tile,
    required this.isInCompletedLine,
    required this.isProcessing,
    this.onTap,
  });

  final BingoTile tile;

  /// Part of at least one closed line. The line itself is drawn by the board;
  /// this only nudges the completed cell's styling.
  final bool isInCompletedLine;

  /// This tile's completion is in flight.
  final bool isProcessing;

  final VoidCallback? onTap;

  static const double iconSize = 20;
  static TextStyle get labelStyle => TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.1,
    color: FeatureStyle.ink,
  );

  @override
  Widget build(BuildContext context) {
    final accent = BingoTileVisuals.accent(tile.category);
    final done = tile.isCompleted && !tile.isFreeSpace;

    final Widget content = tile.isFreeSpace
        ? _FreeSpaceContent(accent: OrientationBrand.accent)
        : _TaskContent(tile: tile);

    Widget inner = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: Center(child: content)),
        if (isProcessing)
          Positioned(
            top: -1,
            right: -1,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: OrientationBrand.accent),
            ),
          )
        else if (tile.isLocked)
          Positioned(top: -1, right: -1, child: AppIcon(AppIcons.lock, size: 13, color: FeatureStyle.stone)),
      ],
    );

    // Completed cells recede: dimmer and a touch smaller, no badge.
    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: _background(accent),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedScale(
        scale: done ? 0.9 : 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: done ? 0.4 : 1,
          duration: const Duration(milliseconds: 260),
          child: inner,
        ),
      ),
    );

    if (onTap == null) return decorated;
    return PressableScale(onTap: onTap!, child: decorated);
  }

  Color _background(Color accent) {
    if (tile.isFreeSpace) return OrientationBrand.accent.withValues(alpha: 0.14);
    if (tile.isLocked) return FeatureStyle.surfaceSoft;
    if (tile.isCompleted) return accent.withValues(alpha: 0.05);
    return accent.withValues(alpha: 0.07);
  }
}

class _TaskContent extends StatelessWidget {
  const _TaskContent({required this.tile});

  final BingoTile tile;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BingoTileLabel(
          text: tile.title,
          maxLines: 4,
          style: BingoTileView.labelStyle.copyWith(
            fontSize: 8.5,
            height: 1.15,
            color: tile.isLocked ? FeatureStyle.stone : FeatureStyle.ink,
          ),
        ),
      ],
    );
  }
}

class _FreeSpaceContent extends StatelessWidget {
  const _FreeSpaceContent({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BingoTileLabel(
      text: l10n.orientation_bingo_free_space,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.2,
        color: accent,
      ),
    );
  }
}

/// A tile caption at a single fixed size, one whole word per line, centred.
///
/// Titles are short enough (see `mock_bingo.dart`) that each word fits its
/// line at [BingoTileView.labelStyle] without scaling, so every cell's text
/// is the same size. Words are never split mid-word.
class BingoTileLabel extends StatelessWidget {
  const BingoTileLabel({super.key, required this.text, required this.style, this.maxLines = 2});

  final String text;
  final TextStyle style;
  final int maxLines;

  /// Packs whole words into at most [maxLines] lines, preferring one word per
  /// line; any overflow beyond the last line is appended to it.
  static List<String> packLines(String text, {int maxLines = 2}) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    if (words.length <= maxLines) return words;

    // More words than lines: keep the first (maxLines-1) words on their own
    // lines and fold the rest onto the final line.
    final lines = words.take(maxLines - 1).toList();
    lines.add(words.skip(maxLines - 1).join(' '));
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final lines = packLines(text, maxLines: maxLines);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final line in lines)
          Text(line, textAlign: TextAlign.center, maxLines: 1, style: style),
      ],
    );
  }
}
