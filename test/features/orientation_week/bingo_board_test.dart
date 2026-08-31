import 'package:flutter_test/flutter_test.dart';

import 'package:jaswallet_app/features/orientation_week/domain/entities/bingo_board.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/bingo_tile.dart';

const _size = BingoBoard.size;

BingoTile _tile(int index, {required bool completed}) {
  return BingoTile(
    id: 'tile_$index',
    title: 'Task $index',
    description: 'Do task $index',
    category: BingoTileCategory.exploration,
    icon: BingoTileIcon.explore,
    rewardTokens: 25,
    state: completed ? BingoTileState.completed : BingoTileState.available,
  );
}

/// A board where exactly [completedIndexes] are played. There is no free
/// space on a 4x4 board — every square is a task.
BingoBoard _board(Set<int> completedIndexes) {
  return BingoBoard(
    id: 'test',
    tiles: List.generate(_size * _size, (i) => _tile(i, completed: completedIndexes.contains(i))),
  );
}

/// Index set for row [row].
Set<int> _row(int row) => {for (var c = 0; c < _size; c++) row * _size + c};

/// Index set for column [col].
Set<int> _col(int col) => {for (var r = 0; r < _size; r++) r * _size + col};

void main() {
  group('BingoBoard.lineIndices', () {
    test('is 4 rows + 4 columns + 2 diagonals', () {
      expect(BingoBoard.lineIndices.length, _size * 2 + 2);
      expect(BingoBoard.lineIndices.every((l) => l.length == _size), isTrue);
    });

    test('covers both diagonals', () {
      expect(BingoBoard.lineIndices, anyElement(orderedEquals([0, 5, 10, 15])));
      expect(BingoBoard.lineIndices, anyElement(orderedEquals([3, 6, 9, 12])));
    });
  });

  group('BingoBoard progress', () {
    test('a fresh board has nothing played', () {
      final board = _board({});
      expect(board.completedTiles, 0);
      expect(board.completedLines, 0);
      expect(board.isComplete, isFalse);
      expect(board.progress.lineProgress, 0);
    });

    test('a full row counts as one line', () {
      expect(_board(_row(0)).completedLines, 1);
    });

    test('a full column counts as one line', () {
      expect(_board(_col(0)).completedLines, 1);
    });

    test('every line takes all four of its squares', () {
      final short = _row(2)..remove(_row(2).first);
      expect(short, hasLength(_size - 1));
      expect(_board(short).completedLines, 0);
    });

    test('both diagonals count independently', () {
      final bothDiagonals = {0, 5, 10, 15, 3, 6, 9, 12};
      expect(_board(bothDiagonals).completedLines, 2);
    });

    test('lineProgress is the completed/target ratio', () {
      final board = _board({..._row(0), ..._row(1)});
      expect(board.completedLines, 2);
      expect(board.progress.lineProgress, closeTo(2 / BingoBoard.targetLines, 0.0001));
    });

    test('lineProgress is clamped to 1 once past the target', () {
      final everyTile = {for (var i = 0; i < _size * _size; i++) i};
      expect(_board(everyTile).progress.lineProgress, 1);
    });

    test('completedLineIndices returns every tile on a closed line', () {
      expect(_board(_row(0)).completedLineIndices, _row(0));
    });

    test('a fully played board closes every line and is complete', () {
      final everyTile = {for (var i = 0; i < _size * _size; i++) i};
      final board = _board(everyTile);
      expect(board.completedTiles, _size * _size);
      expect(board.completedLines, _size * 2 + 2);
      expect(board.isComplete, isTrue);
    });

    test('three closed lines is short of the target', () {
      final board = _board({..._row(0), ..._row(1), ..._row(2)});
      // Three rows closed; row 3 is untouched, so no column or diagonal does.
      expect(board.completedLines, 3);
      expect(board.isComplete, isFalse);
    });

    test('closing the target number of lines completes the board', () {
      final board = _board({..._row(0), ..._row(1), ..._row(2), ..._row(3)});
      // All four rows closed also closes all four columns and both diagonals.
      expect(board.completedLines, BingoBoard.lineIndices.length);
      expect(board.isComplete, isTrue);
    });
  });

  group('BingoTile', () {
    test('copyWith only overrides the provided fields', () {
      final original = _tile(0, completed: false);
      final at = DateTime(2026, 7, 24);
      final done = original.copyWith(state: BingoTileState.completed, completedAt: at);

      expect(done.id, original.id);
      expect(done.title, original.title);
      expect(done.rewardTokens, original.rewardTokens);
      expect(done.isCompleted, isTrue);
      expect(done.completedAt, at);
    });

    test('a locked tile is neither completed nor playable', () {
      final locked = _tile(0, completed: false).copyWith(state: BingoTileState.locked);
      expect(locked.isLocked, isTrue);
      expect(locked.isCompleted, isFalse);
      expect(locked.isPlayable, isFalse);
    });
  });

  group('BingoReward', () {
    test('totalTokens sums the tile, line and grand payouts', () {
      const reward = BingoReward(
        tileTokens: 25,
        lineBonusTokens: 200,
        grandBonusTokens: 500,
        newlyCompletedLines: 2,
        boardCompleted: true,
      );
      expect(reward.totalTokens, 725);
    });

    test('none pays nothing', () {
      expect(BingoReward.none.totalTokens, 0);
      expect(BingoReward.none.boardCompleted, isFalse);
    });
  });
}
