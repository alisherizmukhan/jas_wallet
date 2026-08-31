import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaswallet_app/features/orientation_week/data/mock/orientation_catalog.dart';
import 'package:jaswallet_app/features/orientation_week/data/repositories/orientation_repository_mock_impl.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/bingo_board.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/leaderboard_entry.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/photo_mission.dart';

import '../../helpers/orientation_catalog_fixture.dart';

void main() {
  // The JSON catalogue, read off disk — rootBundle would hang here.
  setUp(seedOrientationCatalog);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('OrientationRepositoryMockImpl.getDashboard', () {
    test('starts a fresh install with zero tokens, level 1, and an unplayed bingo board', () async {
      final repo = OrientationRepositoryMockImpl();
      final dashboard = await repo.getDashboard();

      expect(dashboard.tokens, 0);
      expect(dashboard.bingoTotalCount, BingoBoard.size * BingoBoard.size);
      // No free space on a 4x4 board — nothing is played until the student
      // plays it.
      expect(dashboard.bingoCompletedCount, 0);
      expect(dashboard.level, 1);
      expect(dashboard.streak.current, 0);
      expect(dashboard.currentDay, greaterThanOrEqualTo(1));
      expect(dashboard.totalDays, 7);
    });
  });

  group('OrientationRepositoryMockImpl.getBingoBoard', () {
    test('returns the full 4×4 board, every square playable', () async {
      final repo = OrientationRepositoryMockImpl();
      final board = await repo.getBingoBoard();

      expect(board.tiles.length, BingoBoard.size * BingoBoard.size);
      expect(board.tiles.map((t) => t.id).toSet().length, board.tiles.length, reason: 'no duplicate tile ids');
      expect(board.tiles.where((t) => t.isFreeSpace), isEmpty);
      expect(board.completedLines, 0);
    });

    test('completions persist across loads', () async {
      final repo = OrientationRepositoryMockImpl();
      await repo.completeBingoTile('bingo_turcha');

      final reloaded = await repo.getBingoBoard();
      expect(reloaded.tiles.firstWhere((t) => t.id == 'bingo_turcha').isCompleted, isTrue);
      expect(reloaded.completedTiles, 1);
    });
  });

  group('OrientationRepositoryMockImpl.completeBingoTile', () {
    test('awards the tile\'s tokens and marks it completed', () async {
      final repo = OrientationRepositoryMockImpl();
      final result = await repo.completeBingoTile('bingo_turcha');

      expect(result.isSuccess, isTrue);
      expect(result.tile?.isCompleted, isTrue);
      expect(result.reward.tileTokens, kBingoTileReward);
      expect(result.reward.newlyCompletedLines, 0);
      expect(result.tokensAwarded, kBingoTileReward);

      final dashboard = await repo.getDashboard();
      expect(dashboard.tokens, kBingoTileReward);
    });

    test('rejects an unknown tile id', () async {
      final repo = OrientationRepositoryMockImpl();
      expect((await repo.completeBingoTile('not_a_tile')).isSuccess, isFalse);
    });

    test('rejects completing the same tile twice', () async {
      final repo = OrientationRepositoryMockImpl();
      await repo.completeBingoTile('bingo_turcha');
      final second = await repo.completeBingoTile('bingo_turcha');

      expect(second.isSuccess, isFalse);
      expect(second.errorMessage, isNotNull);
    });

    test('pays the line bonus exactly once, on the tile that closes the line', () async {
      final repo = OrientationRepositoryMockImpl();

      for (final id in _topRowIds.take(_topRowIds.length - 1)) {
        final mid = await repo.completeBingoTile(id);
        expect(mid.reward.newlyCompletedLines, 0);
        expect(mid.tokensAwarded, kBingoTileReward);
      }

      final closing = await repo.completeBingoTile(_topRowIds.last);
      expect(closing.reward.newlyCompletedLines, 1);
      expect(closing.reward.lineBonusTokens, BingoBoard.lineBonusTokens);
      expect(closing.reward.boardCompleted, isFalse);
      expect(closing.tokensAwarded, kBingoTileReward + BingoBoard.lineBonusTokens);
    });

    test('pays the grand bonus once when the target line count is reached', () async {
      final repo = OrientationRepositoryMockImpl();
      final board = await repo.getBingoBoard();

      var grandPayouts = 0;
      for (final tile in board.tiles.where((t) => t.isPlayable)) {
        final result = await repo.completeBingoTile(tile.id);
        if (result.reward.grandBonusTokens > 0) grandPayouts++;
      }

      expect(grandPayouts, 1);
      expect((await repo.getBingoBoard()).isComplete, isTrue);
    });
  });

  group('OrientationRepositoryMockImpl.getLeaderboard', () {
    test('inserts the current user and sorts entries by tokens descending', () async {
      final repo = OrientationRepositoryMockImpl();
      final entries = await repo.getLeaderboard(scope: LeaderboardScope.global);

      expect(entries.where((e) => e.isCurrentUser).length, 1);
      for (var i = 1; i < entries.length; i++) {
        expect(entries[i - 1].tokens, greaterThanOrEqualTo(entries[i].tokens));
      }
      expect(entries.first.rank, 1);
      expect(entries.last.rank, entries.length);
    });

    test('first load has no rank movement; a later load compares against the snapshot', () async {
      final repo = OrientationRepositoryMockImpl();
      final first = await repo.getLeaderboard(scope: LeaderboardScope.global);
      expect(first.every((e) => e.previousRank == null), isTrue);

      final second = await repo.getLeaderboard(scope: LeaderboardScope.global);
      final me = second.firstWhere((e) => e.isCurrentUser);
      expect(me.previousRank, isNotNull);
      expect(me.rankDelta, 0, reason: 'nothing changed between the two loads');
    });

    test('school scope only returns students matching the current user\'s faculty', () async {
      final repo = OrientationRepositoryMockImpl();
      final entries = await repo.getLeaderboard(scope: LeaderboardScope.school);
      expect(entries.where((e) => !e.isCurrentUser).every((e) => e.student.faculty == 'SEDS'), isTrue);
    });
  });

  group('OrientationRepositoryMockImpl.redeemReward', () {
    test('fails when the student does not have enough tokens', () async {
      final repo = OrientationRepositoryMockImpl();
      final reward = (await repo.getRewards()).first;

      final result = await repo.redeemReward(reward.id);

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('spends tokens, records history, and keeps the earned peak', () async {
      final repo = OrientationRepositoryMockImpl();
      final cheapest = (await repo.getRewards()).reduce((a, b) => a.priceTokens <= b.priceTokens ? a : b);

      // Earn enough to afford the cheapest reward by playing the whole board.
      final board = await repo.getBingoBoard();
      for (final tile in board.tiles.where((t) => t.isPlayable)) {
        if ((await repo.getDashboard()).tokens >= cheapest.priceTokens) break;
        await repo.completeBingoTile(tile.id);
      }
      final earned = (await repo.getDashboard()).tokens;
      expect(earned, greaterThanOrEqualTo(cheapest.priceTokens));
      final beforePeak = await repo.getTokensEarnedTotal();

      final result = await repo.redeemReward(cheapest.id);
      expect(result.isSuccess, isTrue);
      expect(result.remainingTokens, earned - cheapest.priceTokens);

      // Spending does not lower the milestone (earned) peak.
      expect(await repo.getTokensEarnedTotal(), beforePeak);

      final history = await repo.getRewardHistory();
      expect(history.first.reward.id, cheapest.id);
      expect(history.first.spentTokens, cheapest.priceTokens);
    });
  });

  group('OrientationRepositoryMockImpl.getPhotoMissions', () {
    test('returns every mission as available by default', () async {
      final repo = OrientationRepositoryMockImpl();
      final missions = await repo.getPhotoMissions();

      expect(missions, isNotEmpty);
      expect(missions.every((m) => m.status == MissionStatus.available), isTrue);
      expect(missions.map((m) => m.id).toSet().length, missions.length, reason: 'no duplicate ids');
    });

    test('submitting a photo completes that mission and awards its tokens', () async {
      final repo = OrientationRepositoryMockImpl();
      final mission = (await repo.getPhotoMissions()).first;

      final result = await repo.submitMissionPhoto(mission.id, '/fake/path.jpg');
      expect(result.isSuccess, isTrue);
      expect(result.reward.missionTokens, mission.rewardTokens);
      expect(result.reward.questCompleted, isFalse);

      final refreshed = await repo.getPhotoMissions();
      final updated = refreshed.firstWhere((m) => m.id == mission.id);
      expect(updated.status, MissionStatus.completed);
      expect(updated.photoPath, '/fake/path.jpg');
      expect((await repo.getDashboard()).tokens, mission.rewardTokens);
    });

    test('resubmitting replaces the photo without paying twice', () async {
      final repo = OrientationRepositoryMockImpl();
      final mission = (await repo.getPhotoMissions()).first;

      await repo.submitMissionPhoto(mission.id, '/fake/a.jpg');
      final second = await repo.submitMissionPhoto(mission.id, '/fake/b.jpg');

      expect(second.isSuccess, isTrue);
      expect(second.reward.totalTokens, 0);

      final refreshed = await repo.getPhotoMissions();
      expect(refreshed.firstWhere((m) => m.id == mission.id).photoPath, '/fake/b.jpg');
      expect((await repo.getDashboard()).tokens, mission.rewardTokens, reason: 'paid exactly once');
    });

    test('deleting a photo reopens the mission and takes its tokens back', () async {
      final repo = OrientationRepositoryMockImpl();
      final mission = (await repo.getPhotoMissions()).first;

      await repo.submitMissionPhoto(mission.id, '/fake/a.jpg');
      expect((await repo.getDashboard()).tokens, mission.rewardTokens);

      final deleted = await repo.deleteMissionPhoto(mission.id);
      expect(deleted.isSuccess, isTrue);

      final refreshed = await repo.getPhotoMissions();
      final reopened = refreshed.firstWhere((m) => m.id == mission.id);
      expect(reopened.status, MissionStatus.available);
      expect(reopened.photoPath, isNull);
      expect((await repo.getDashboard()).tokens, 0);
    });

    test('deleting after the quest was finished claws back the bonus too', () async {
      final repo = OrientationRepositoryMockImpl();
      final missions = await repo.getPhotoMissions();
      for (final m in missions) {
        await repo.submitMissionPhoto(m.id, '/fake/${m.id}.jpg');
      }
      final full = (await repo.getDashboard()).tokens;

      final removed = missions.last;
      await repo.deleteMissionPhoto(removed.id);

      expect((await repo.getDashboard()).tokens, full - removed.rewardTokens - kPhotoQuestBonusTokens);

      // Re-completing pays the bonus again, exactly once.
      final again = await repo.submitMissionPhoto(removed.id, '/fake/again.jpg');
      expect(again.reward.bonusTokens, kPhotoQuestBonusTokens);
      expect((await repo.getDashboard()).tokens, full);
    });

    test('rejects deleting a mission that has no photo', () async {
      final repo = OrientationRepositoryMockImpl();
      final missionId = (await repo.getPhotoMissions()).first.id;
      expect((await repo.deleteMissionPhoto(missionId)).isSuccess, isFalse);
    });

    test('rejects an unknown mission id', () async {
      final repo = OrientationRepositoryMockImpl();
      expect((await repo.submitMissionPhoto('not_a_mission', '/fake/a.jpg')).isSuccess, isFalse);
    });

    test('pays the all-missions bonus exactly once, on the last mission', () async {
      final repo = OrientationRepositoryMockImpl();
      final missions = await repo.getPhotoMissions();

      var bonusPayouts = 0;
      for (final m in missions) {
        final result = await repo.submitMissionPhoto(m.id, '/fake/${m.id}.jpg');
        if (result.reward.bonusTokens > 0) {
          bonusPayouts++;
          expect(result.reward.questCompleted, isTrue);
        }
      }

      expect(bonusPayouts, 1);
    });
  });

}

/// The board's top row — four playable squares that close exactly one line
/// and no column or diagonal, which makes it the cleanest line-bonus fixture.
const _topRowIds = ['bingo_turcha', 'bingo_picnic', 'bingo_four_schools', 'bingo_engineering'];
