import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';


import '../../domain/entities/bingo_board.dart';
import '../../domain/entities/bingo_tile.dart';
import 'bingo_tile_view.dart';
import '../theme/orientation_brand.dart';

/// The 4×4 board, laid out inside a white card.
///
/// Column count and tile order come from [BingoBoard] rather than being
/// hard-coded here, so a future board of a different size or with different
/// tasks renders without touching this widget. Each completed line is struck
/// through with a single purple line drawn over the grid.
class BingoBoardGrid extends StatelessWidget {
  const BingoBoardGrid({
    super.key,
    required this.board,
    required this.processingTileId,
    required this.onTileTap,
  });

  final BingoBoard board;
  final String? processingTileId;
  final void Function(BingoTile tile) onTileTap;

  static const double _gap = 6;
  static const double _pad = 9;

  @override
  Widget build(BuildContext context) {
    final size = BingoBoard.size;
    final highlighted = board.completedLineIndices;

    return FeatureCard(
      padding: const EdgeInsets.all(_pad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - _gap * (size - 1)) / size;
          // Slightly taller than wide: room for the glyph plus two lines of
          // caption without the caption having to scale on most titles.
          final tileHeight = tileWidth * 1.34;
          final boardHeight = tileHeight * size + _gap * (size - 1);

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
                              width: tileWidth,
                              height: tileHeight,
                              child: _tileAt(row * size + col, highlighted),
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
                        completedLines: board.lines.where((l) => l.isComplete).toList(),
                        size: size,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        gap: _gap,
                        color: OrientationBrand.accent,
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

  Widget _tileAt(int index, Set<int> highlighted) {
    final tile = board.tiles[index];
    return BingoTileView(
      tile: tile,
      isInCompletedLine: highlighted.contains(index),
      isProcessing: processingTileId == tile.id,
      onTap: tile.isFreeSpace ? null : () => onTileTap(tile),
    );
  }
}

/// Draws one line through each completed row / column / diagonal, from the
/// centre of its first cell to the centre of its last cell. Animates in as
/// lines are closed.
class _BingoLinePainter extends CustomPainter {
  _BingoLinePainter({
    required this.completedLines,
    required this.size,
    required this.tileWidth,
    required this.tileHeight,
    required this.gap,
    required this.color,
  });

  final List<BingoLine> completedLines;
  final int size;
  final double tileWidth;
  final double tileHeight;
  final double gap;
  final Color color;

  Offset _center(int index) {
    final row = index ~/ size;
    final col = index % size;
    return Offset(
      col * (tileWidth + gap) + tileWidth / 2,
      row * (tileHeight + gap) + tileHeight / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in completedLines) {
      final indices = line.indices;
      if (indices.isEmpty) continue;
      final start = _center(indices.first);
      final end = _center(indices.last);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_BingoLinePainter old) =>
      old.completedLines.length != completedLines.length ||
      old.tileWidth != tileWidth ||
      old.tileHeight != tileHeight;
}
