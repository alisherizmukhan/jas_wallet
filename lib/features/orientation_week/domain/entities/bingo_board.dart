import 'bingo_tile.dart';

/// One of the 10 winning lines on a 4×4 board (4 rows, 4 columns, 2
/// diagonals), plus whether it is currently complete.
class BingoLine {
  const BingoLine({required this.indices, required this.isComplete});

  /// Tile indices making up the line, in board order.
  final List<int> indices;
  final bool isComplete;
}

/// Aggregate counters for the progress card.
class BingoProgress {
  const BingoProgress({
    required this.completedLines,
    required this.targetLines,
    required this.completedTiles,
    required this.totalTiles,
  });

  final int completedLines;
  final int targetLines;
  final int completedTiles;
  final int totalTiles;

  /// 0–1, clamped, for the progress bar.
  double get lineProgress => targetLines == 0 ? 0 : (completedLines / targetLines).clamp(0, 1).toDouble();

  bool get isComplete => completedLines >= targetLines;
}

/// What a single tile completion paid out.
class BingoReward {
  const BingoReward({
    required this.tileTokens,
    required this.lineBonusTokens,
    required this.grandBonusTokens,
    required this.newlyCompletedLines,
    required this.boardCompleted,
  });

  static const BingoReward none = BingoReward(
    tileTokens: 0,
    lineBonusTokens: 0,
    grandBonusTokens: 0,
    newlyCompletedLines: 0,
    boardCompleted: false,
  );

  /// Tokens for the tile itself.
  final int tileTokens;

  /// Bonus for any lines this completion closed.
  final int lineBonusTokens;

  /// One-time bonus for reaching [BingoBoard.targetLines].
  final int grandBonusTokens;

  final int newlyCompletedLines;
  final bool boardCompleted;

  int get totalTokens => tileTokens + lineBonusTokens + grandBonusTokens;
}

/// The 4×4 Bingo board.
///
/// Four by four, not five by five: sixteen squares fit a phone at a size
/// where each one can carry a legible icon *and* its title, where twenty-five
/// forced both down to a size that read as a grid of grey blocks. It also
/// makes the board finishable inside one Orientation Week.
///
/// Line detection is derived here rather than stored, so the board can never
/// disagree with its own tiles. There is no free space — every one of the
/// sixteen squares is a task a student actually does.
class BingoBoard {
  const BingoBoard({required this.id, required this.tiles});

  static const int size = 4;

  /// Lines the player must close to win the grand bonus. Four of the ten
  /// available — enough to need real coverage of the board, short of needing
  /// nearly all of it.
  static const int targetLines = 4;

  /// Awarded once per newly completed line.
  static const int lineBonusTokens = 50;

  /// One-time payout for reaching [targetLines].
  static const int grandBonusTokens = 200;

  final String id;

  /// Exactly `size * size` tiles in row-major order.
  final List<BingoTile> tiles;

  /// All 10 winning lines: 4 rows, 4 columns, 2 diagonals.
  static List<List<int>> get lineIndices {
    final lines = <List<int>>[];
    for (var r = 0; r < size; r++) {
      lines.add([for (var c = 0; c < size; c++) r * size + c]);
    }
    for (var c = 0; c < size; c++) {
      lines.add([for (var r = 0; r < size; r++) r * size + c]);
    }
    lines.add([for (var i = 0; i < size; i++) i * size + i]);
    lines.add([for (var i = 0; i < size; i++) i * size + (size - 1 - i)]);
    return lines;
  }

  List<BingoLine> get lines => [
        for (final indices in lineIndices)
          BingoLine(indices: indices, isComplete: indices.every((i) => tiles[i].isCompleted)),
      ];

  int get completedLines => lines.where((l) => l.isComplete).length;

  int get completedTiles => tiles.where((t) => t.isCompleted).length;

  /// Indices belonging to at least one completed line — used to highlight
  /// winning lines on the board.
  Set<int> get completedLineIndices => {
        for (final line in lines)
          if (line.isComplete) ...line.indices,
      };

  BingoProgress get progress => BingoProgress(
        completedLines: completedLines,
        targetLines: targetLines,
        completedTiles: completedTiles,
        totalTiles: tiles.length,
      );

  bool get isComplete => completedLines >= targetLines;

  BingoBoard copyWith({List<BingoTile>? tiles}) => BingoBoard(id: id, tiles: tiles ?? this.tiles);
}
