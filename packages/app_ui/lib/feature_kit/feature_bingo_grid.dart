import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../tokens/app_colors.dart';
import 'feature_components.dart';
import 'feature_style.dart';
import 'pressable_scale.dart';

/// One square of a bingo board, flattened to what the grid needs to draw.
///
/// Deliberately not either feature's own tile entity: Orientation Week's
/// squares are hand-marked tasks with categories and lock states, Club Fair's
/// are claims about the roster evaluated automatically. Mapping both onto this
/// is what lets the two boards be *the same widget* rather than two widgets
/// that were carefully kept looking alike.
class FeatureBingoCell {
  const FeatureBingoCell({
    required this.id,
    required this.label,
    required this.accent,
    this.icon,
    this.isCompleted = false,
    this.isLocked = false,
    this.isFreeSpace = false,
  });

  final String id;

  /// Kept short — two words at most. See [FeatureBingoCellLabel].
  final String label;

  /// The glyph tint, and the cell's background at low alpha.
  final Color accent;

  /// Null on a free space, which carries its label alone.
  final AppIconData? icon;

  final bool isCompleted;
  final bool isLocked;
  final bool isFreeSpace;
}

/// The bingo board, laid out inside a white card.
///
/// Column count and cell order come from the caller rather than being
/// hard-coded, so a board of a different size renders without touching this
/// widget. Each completed line is struck through with a single cobalt line
/// drawn over the grid.
///
/// A completed cell isn't stamped with a check: it fades back and shrinks
/// slightly, so it reads as "done and out of the way" while the winning line
/// is what announces the result.
class FeatureBingoGrid extends StatelessWidget {
  const FeatureBingoGrid({
    super.key,
    required this.size,
    required this.cells,
    required this.completedLines,
    this.processingCellId,
    this.onCellTap,
    this.accent,
  });

  /// Cells per row. `cells.length` must be `size * size`.
  final int size;

  /// Row-major order.
  final List<FeatureBingoCell> cells;

  /// Index lists for the lines that are closed — one strike drawn per entry.
  final List<List<int>> completedLines;

  /// This cell's completion is in flight.
  final String? processingCellId;

  /// Null makes the whole board read-only, which is right for a board whose
  /// squares are evaluated rather than tapped.
  final void Function(FeatureBingoCell cell)? onCellTap;

  /// Overrides the shared [FeatureStyle.accent] emphasis colour (winning-line
  /// strike, free-space glyph/background, processing spinner) for this board
  /// only — null keeps the default (used by every caller that doesn't opt
  /// in, e.g. Club Fair).
  final Color? accent;

  static const double _gap = 6;
  static const double _pad = 9;

  /// Cells on at least one closed line.
  Set<int> get _highlighted => {for (final line in completedLines) ...line};

  @override
  Widget build(BuildContext context) {
    final highlighted = _highlighted;

    return FeatureCard(
      padding: const EdgeInsets.all(_pad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - _gap * (size - 1)) / size;
          // Slightly taller than wide: room for the glyph plus two lines of
          // caption without the caption having to scale on most titles.
          final cellHeight = cellWidth * 1.34;
          final boardHeight = cellHeight * size + _gap * (size - 1);

          return SizedBox(
            height: boardHeight,
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var row = 0; row < size; row++) ...[
                      if (row > 0) const SizedBox(height: _gap),
                      Row(
                        children: [
                          for (var col = 0; col < size; col++) ...[
                            if (col > 0) const SizedBox(width: _gap),
                            SizedBox(
                              width: cellWidth,
                              height: cellHeight,
                              child: _cellAt(row * size + col, highlighted),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
                // The winning-line strikethroughs sit above the cells.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _BingoLinePainter(
                        completedLines: completedLines,
                        size: size,
                        cellWidth: cellWidth,
                        cellHeight: cellHeight,
                        gap: _gap,
                        color: accent ?? FeatureStyle.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cellAt(int index, Set<int> highlighted) {
    final cell = cells[index];
    final tap = onCellTap;
    return FeatureBingoCellView(
      cell: cell,
      isInCompletedLine: highlighted.contains(index),
      isProcessing: processingCellId == cell.id,
      onTap: (tap == null || cell.isFreeSpace) ? null : () => tap(cell),
      accent: accent,
    );
  }
}

/// One square. Every cell renders at the same fixed icon and text size, so the
/// board reads as a uniform grid rather than as sixteen differently-scaled
/// captions.
class FeatureBingoCellView extends StatelessWidget {
  const FeatureBingoCellView({
    super.key,
    required this.cell,
    required this.isInCompletedLine,
    required this.isProcessing,
    this.onTap,
    this.accent,
  });

  final FeatureBingoCell cell;

  /// Part of at least one closed line. The line itself is drawn by the board;
  /// this only nudges the completed cell's styling.
  final bool isInCompletedLine;

  final bool isProcessing;
  final VoidCallback? onTap;

  /// Overrides [FeatureStyle.accent] for the free-space glyph/background and
  /// the processing spinner — null keeps the default.
  final Color? accent;

  static const double iconSize = 20;
  static const TextStyle labelStyle = TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.1,
    color: AppColors.black,
  );

  @override
  Widget build(BuildContext context) {
    final done = cell.isCompleted && !cell.isFreeSpace;
    final glyphColor = cell.isLocked ? FeatureStyle.stone : cell.accent;
    final resolvedAccent = accent ?? FeatureStyle.accent;

    final content = cell.isFreeSpace
        ? FeatureBingoCellLabel(
            text: cell.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.2,
              color: resolvedAccent,
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (cell.icon != null) ...[
                AppIcon(cell.icon!, size: iconSize, color: glyphColor),
                const SizedBox(height: 5),
              ],
              FeatureBingoCellLabel(
                text: cell.label,
                style: labelStyle.copyWith(
                  color: cell.isLocked ? FeatureStyle.stone : AppColors.black,
                ),
              ),
            ],
          );

    final inner = Stack(
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
              child: CircularProgressIndicator(strokeWidth: 2, color: resolvedAccent),
            ),
          )
        else if (cell.isLocked)
          Positioned(
            top: -1,
            right: -1,
            child: AppIcon(AppIcons.lock, size: 13, color: FeatureStyle.stone),
          ),
      ],
    );

    // Completed cells recede: dimmer and a touch smaller, no badge.
    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: _background,
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

    final tap = onTap;
    return tap == null ? decorated : PressableScale(onTap: tap, child: decorated);
  }

  Color get _background {
    if (cell.isFreeSpace) return (accent ?? FeatureStyle.accent).withValues(alpha: 0.14);
    if (cell.isLocked) return FeatureStyle.surfaceSoft;
    if (cell.isCompleted) return cell.accent.withValues(alpha: 0.05);
    return cell.accent.withValues(alpha: 0.07);
  }
}

/// A cell caption at a single fixed size, one whole word per line, centred.
///
/// Labels are short enough that each word fits its line at
/// [FeatureBingoCellView.labelStyle] without scaling, so every cell's text is
/// the same size. Words are never split mid-word.
class FeatureBingoCellLabel extends StatelessWidget {
  const FeatureBingoCellLabel({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 2,
  });

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
      children: [
        for (final line in lines)
          Text(line, textAlign: TextAlign.center, maxLines: 1, style: style),
      ],
    );
  }
}

/// Draws one line through each completed row / column / diagonal, from the
/// centre of its first cell to the centre of its last.
class _BingoLinePainter extends CustomPainter {
  _BingoLinePainter({
    required this.completedLines,
    required this.size,
    required this.cellWidth,
    required this.cellHeight,
    required this.gap,
    required this.color,
  });

  final List<List<int>> completedLines;
  final int size;
  final double cellWidth;
  final double cellHeight;
  final double gap;
  final Color color;

  Offset _center(int index) {
    final row = index ~/ size;
    final col = index % size;
    return Offset(
      col * (cellWidth + gap) + cellWidth / 2,
      row * (cellHeight + gap) + cellHeight / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final indices in completedLines) {
      if (indices.isEmpty) continue;
      canvas.drawLine(_center(indices.first), _center(indices.last), paint);
    }
  }

  @override
  bool shouldRepaint(_BingoLinePainter old) =>
      old.completedLines.length != completedLines.length ||
      old.cellWidth != cellWidth ||
      old.cellHeight != cellHeight;
}
