import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jaswallet_app/features/orientation_week/domain/entities/bingo_board.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/bingo_tile.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/widgets/bingo_board_grid.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/widgets/bingo_tile_view.dart';

import '../../helpers/test_app.dart';
import '../../helpers/orientation_catalog_fixture.dart';

const _size = BingoBoard.size;
const _tileCount = _size * _size;
const _freeIndex = _tileCount ~/ 2;

BingoBoard _board({int completedCount = 0}) {
  return BingoBoard(
    id: 'test',
    tiles: List.generate(_tileCount, (i) {
      return BingoTile(
        id: 'tile_$i',
        title: 'Task $i',
        description: 'Do task $i',
        category: BingoTileCategory.exploration,
        icon: BingoTileIcon.explore,
        rewardTokens: 25,
        state: i == _freeIndex
            ? BingoTileState.freeSpace
            : i < completedCount
                ? BingoTileState.completed
                : BingoTileState.available,
      );
    }),
  );
}

Widget _host(Widget child) => buildTestApp(router: testRouter(child: Scaffold(body: child)));

void main() {
  // The JSON catalogue, read off disk — rootBundle would hang here.
  setUp(seedOrientationCatalog);
  testWidgets('renders one tile per board square', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(BingoBoardGrid(board: _board(), processingTileId: null, onTileTap: (_) {})),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BingoTileView), findsNWidgets(_tileCount));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the centre square renders as the free space, not a task', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(BingoBoardGrid(board: _board(), processingTileId: null, onTileTap: (_) {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Task $_freeIndex'), findsNothing);
    // "FREE SPACE" is packed one word per line, so match the first word.
    expect(find.text('FREE'), findsOneWidget);
  });

  testWidgets('completed tiles fade out instead of showing a check badge', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(BingoBoardGrid(board: _board(completedCount: 3), processingTileId: null, onTileTap: (_) {})),
    );
    await tester.pumpAndSettle();

    // No check badges anywhere — completed cells recede instead.
    final checks = find.byWidgetPredicate((w) => w is AppIcon && w.icon == AppIcons.check);
    expect(checks, findsNothing);

    // The completed cells are dimmed (opacity < 1) via AnimatedOpacity.
    final faded = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity)).where((o) => o.opacity < 1);
    expect(faded.length, 3);
  });

  testWidgets('a processing tile shows a spinner in place of its badge', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final board = _board();
    await tester.pumpWidget(
      _host(BingoBoardGrid(board: board, processingTileId: board.tiles.first.id, onTileTap: (_) {})),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('tapping a task square reports that tile', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    BingoTile? tapped;
    final board = _board();
    await tester.pumpWidget(
      _host(BingoBoardGrid(board: board, processingTileId: null, onTileTap: (t) => tapped = t)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BingoTileView).first);
    await tester.pumpAndSettle();

    expect(tapped, isNotNull);
    expect(tapped!.id, board.tiles.first.id);
  });

  testWidgets('the free space is inert', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    BingoTile? tapped;
    await tester.pumpWidget(
      _host(BingoBoardGrid(board: _board(), processingTileId: null, onTileTap: (t) => tapped = t)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BingoTileView).at(_freeIndex));
    await tester.pumpAndSettle();

    expect(tapped, isNull);
  });

  group('BingoTileLabel.packLines', () {
    test('puts each word of a two-word title on its own line', () {
      expect(BingoTileLabel.packLines('Read Board'), ['Read', 'Board']);
      expect(BingoTileLabel.packLines('Explore Campus'), ['Explore', 'Campus']);
      expect(BingoTileLabel.packLines('FREE SPACE'), ['FREE', 'SPACE']);
    });

    test('a single word stays on one line', () {
      expect(BingoTileLabel.packLines('Salto'), ['Salto']);
    });

    test('never exceeds maxLines — the overflow folds onto the last line', () {
      final lines = BingoTileLabel.packLines('Use Meal Plan');
      expect(lines.length, lessThanOrEqualTo(2));
      expect(lines, ['Use', 'Meal Plan']);
      expect(lines.join(' '), 'Use Meal Plan');
    });
  });
}
