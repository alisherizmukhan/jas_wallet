import 'package:flutter_test/flutter_test.dart';

import 'package:jaswallet_app/features/orientation_week/data/mock/orientation_catalog.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/bingo_board.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/bingo_tile.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/photo_mission.dart';

import '../../helpers/orientation_catalog_fixture.dart';

/// The week's content now lives in `assets/data/orientation/*.json`, edited by
/// hand between Orientation Weeks. That is the point of moving it out of Dart
/// — and also the risk: a trailing comma or a renamed enum value no longer
/// fails to compile, it fails at runtime in a student's hands.
///
/// These parse the real shipped files through the real mappers and assert the
/// invariants the feature is built on. A bad edit fails here instead.
void main() {
  setUp(seedOrientationCatalog);

  group('bingo.json', () {
    test('fills the 4x4 board exactly, with no free space', () async {
      final tiles = await OrientationCatalog.bingoTiles();

      expect(tiles, hasLength(BingoBoard.size * BingoBoard.size));
      expect(tiles.where((t) => t.isFreeSpace), isEmpty,
          reason: 'every one of the sixteen squares is a task a student does');
      expect(tiles.map((t) => t.id).toSet(), hasLength(tiles.length), reason: 'duplicate tile id');
    });

    test('pays the standard tile reward on every square', () async {
      for (final tile in await OrientationCatalog.bingoTiles()) {
        expect(tile.rewardTokens, kBingoTileReward, reason: tile.id);
      }
    });

    test('carries the two follow squares, each with a profile to open', () async {
      final linked = (await OrientationCatalog.bingoTiles()).where((t) => t.link != null).toList();

      expect(linked.map((t) => t.id), containsAll(['bingo_follow_adsl', 'bingo_follow_impact']));
      for (final tile in linked) {
        expect(tile.link, startsWith('https://'), reason: tile.id);
        expect(tile.linkLabel, startsWith('@'), reason: tile.id);
      }
    });

    test('gives the board a winnable shape', () async {
      // targetLines must be reachable: closing every square closes all ten
      // lines, so anything above ten would make the grand bonus impossible.
      expect(BingoBoard.targetLines, lessThanOrEqualTo(BingoBoard.lineIndices.length));
      expect(BingoBoard.lineIndices, hasLength(10));
    });

    test('ships no tile already played', () async {
      final tiles = await OrientationCatalog.bingoTiles();
      expect(tiles.where((t) => t.state == BingoTileState.completed), isEmpty);
    });

    test('every square is self-marked — scanning lives in Challenges', () async {
      // The board used to carry `qr_scan` squares. Peer and supervisor scans
      // moved to Challenges, where there is room to say what a scan has to
      // satisfy and to report why one did not count. What is left here is the
      // set of tasks a student genuinely can just tap once, which is the only
      // thing a 4x4 grid can honestly represent.
      final kinds = (await OrientationCatalog.bingoTiles()).map((t) => t.verification).toSet();
      expect(kinds, {BingoVerification.manual});
    });

    test('no square duplicates a challenge or a photo quest', () async {
      // One task, one home. A square that repeats a challenge makes the same
      // job look like two and pays for it twice.
      final tiles = await OrientationCatalog.bingoTiles();
      final challengeTitles = {
        for (final c in await OrientationCatalog.challenges()) c.title.toLowerCase(),
      };
      final questTitles = {
        for (final m in await OrientationCatalog.photoMissions()) m.title.toLowerCase(),
      };

      for (final tile in tiles) {
        final title = tile.title.toLowerCase();
        expect(challengeTitles, isNot(contains(title)), reason: tile.id);
        expect(questTitles, isNot(contains(title)), reason: tile.id);
      }
    });
  });

  group('photo_quests.json', () {
    test('parses through the same mapper the live API uses', () async {
      final missions = await OrientationCatalog.photoMissions();

      expect(missions, isNotEmpty);
      expect(missions.map((m) => m.id).toSet(), hasLength(missions.length));
      for (final m in missions) {
        expect(m.status, MissionStatus.available, reason: '${m.id} — the server owns status');
        expect(m.rewardTokens, greaterThan(0), reason: m.id);
        expect(m.requirements, isNotEmpty,
            reason: '${m.id} has no stated requirements, so nothing to judge a photo against');
      }
    });

    test('every mission says where to take it', () async {
      // The card and the detail header both lead with the place. A mission
      // without one renders a title and a description and leaves a first-year
      // student to guess which building.
      for (final m in await OrientationCatalog.photoMissions()) {
        expect(m.location, isNotNull, reason: '${m.id} has no location');
        expect(m.location, isNotEmpty, reason: m.id);
      }
    });
  });

  test('a file missing its array is rejected, naming the key', () {
    // Parsing is eager, so a bad edit throws where it was made rather than
    // on whoever happens to read the list first.
    expect(
      () => OrientationCatalog.seedFromJson(
        bingo: '{"tile": []}',
        photoQuests: '{"missions": []}',
        challenges: '{"challenges": []}',
        schedule: '{"days": []}',
      ),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('tiles'))),
    );
  });

  test('a schedule missing its days array is rejected, naming the key', () {
    expect(
      () => OrientationCatalog.seedFromJson(
        bingo: '{"tiles": []}',
        photoQuests: '{"missions": []}',
        challenges: '{"challenges": []}',
        schedule: '{"day": []}',
      ),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('days'))),
    );
  });
}
