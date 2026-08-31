import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../config/orientation_config.dart';
import '../../domain/entities/bingo_board.dart';
import '../../domain/entities/bingo_tile.dart';
import '../../domain/entities/club_fair_club_rank.dart';
import '../../domain/entities/club_fair_stand_qr.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/orientation_challenge.dart';
import '../../domain/entities/orientation_dashboard.dart';
import '../../domain/entities/orientation_identity.dart';
import '../../domain/entities/orientation_schedule.dart';
import '../../domain/entities/orientation_progress.dart';
import '../../domain/entities/orientation_results.dart';
import '../../domain/entities/photo_mission.dart';
import '../../domain/entities/reward.dart';
import '../../domain/entities/streak.dart';
import '../../domain/entities/student_profile.dart';
import '../../domain/repositories/orientation_repository.dart';
import '../mock/orientation_catalog.dart';
import '../mock/mock_rewards.dart';

/// Local-only [OrientationRepository]. No backend exists yet — this
/// persists all mutable state in SharedPreferences and simulates network
/// latency, same pattern as
/// `GymRepositoryMockImpl` (`lib/features/gym/data/repositories/gym_repository_mock_impl.dart`).
/// Replace with a network-backed implementation of [OrientationRepository]
/// when the backend is ready; nothing above the repository layer changes.
class OrientationRepositoryMockImpl implements OrientationRepository {
  static const _keyTokens = 'orientation_tokens';
  static const _keyBingoCompletedTiles = 'orientation_bingo_completed_tiles';
  static const _keyBingoAwardedLines = 'orientation_bingo_awarded_lines';
  static const _keyBingoGrandAwarded = 'orientation_bingo_grand_awarded';
  static const _keyMissionStatuses = 'orientation_photo_mission_statuses';
  static const _keyPhotoQuestBonusAwarded = 'orientation_photo_quest_bonus_awarded';
  static const _keyStreakCurrent = 'orientation_streak_current';
  static const _keyStreakLongest = 'orientation_streak_longest';
  static const _keyLastActiveDate = 'orientation_last_active_date';
  static const _keyLeaderboardPrevRankPrefix = 'orientation_leaderboard_prev_rank_';
  static const _keyResetMarker = 'orientation_reset_marker';
  static const _keyTokensEarnedPeak = 'orientation_tokens_earned_peak';
  static const _keyRewardRedemptions = 'orientation_reward_redemptions';
  static const _keyTrack = 'orientation_track';
  static const _keySchool = 'orientation_school';
  static const _keyChallengeAnswers = 'orientation_challenge_answers';
  static const _keyChallengePaid = 'orientation_challenge_paid';
  static const _keyChallengeScansPrefix = 'orientation_challenge_scans_';

  static const _simulatedLatency = Duration(milliseconds: 600);

  // ── Token economy (per the brief's itemized table) ───────────────────────
  // Bingo line/grand bonuses live on BingoBoard so the board UI and this
  // payout logic can never drift apart.
  static const int _bingoLineBonus = BingoBoard.lineBonusTokens;
  static const int _bingoGrandBonus = BingoBoard.grandBonusTokens;
  static const int _photoQuestBonus = kPhotoQuestBonusTokens;
  static const int _streakBonus = 75;

  /// Total incoming students per the JTBD doc (1,000 undergrad + 500 FYP) —
  /// used only to give the local-only rank a realistic scale. Dead in the
  /// live app: [OrientationRepositoryHybridImpl] always overrides `rank` and
  /// `totalParticipants` with the real backend snapshot.
  static const int totalParticipants = 1500;

  /// Rough token ceiling used to translate a token balance into a plausible
  /// rank out of [totalParticipants] — purely a mock-data heuristic.
  static const int _rankTokenCeiling = 3000;

  // ── Reset-after-week-ends ─────────────────────────────────────────────────

  Future<void> _resetIfWeekEnded(SharedPreferences prefs) async {
    final marker = OrientationConfig.weekEnd.toIso8601String();
    final stored = prefs.getString(_keyResetMarker);
    final pastWeekEnd = DateTime.now().isAfter(OrientationConfig.weekEnd);
    if (pastWeekEnd && stored != marker) {
      for (final key in prefs.getKeys().where((k) => k.startsWith('orientation_'))) {
        await prefs.remove(key);
      }
      await prefs.setString(_keyResetMarker, marker);
    } else if (stored == null) {
      await prefs.setString(_keyResetMarker, marker);
    }
  }

  // ── Tokens ─────────────────────────────────────────────────────────────────

  Future<int> _readTokens(SharedPreferences prefs) async => prefs.getInt(_keyTokens) ?? 0;

  Future<int> _addTokens(SharedPreferences prefs, int amount) async {
    final updated = await _readTokens(prefs) + amount;
    await prefs.setInt(_keyTokens, updated);
    // Milestones track tokens *earned*, so spending must not lower them —
    // keep a monotonic peak that only credits can raise.
    if (amount > 0) {
      final peak = prefs.getInt(_keyTokensEarnedPeak) ?? 0;
      if (updated > peak) await prefs.setInt(_keyTokensEarnedPeak, updated);
    }
    return updated;
  }

  // ── Bingo ──────────────────────────────────────────────────────────────────

  /// tileId -> completedAt (ISO). The free space is implicit — it's baked
  /// into the tile data, not stored here.
  Map<String, String> _readBingoCompletions(SharedPreferences prefs) {
    final raw = prefs.getString(_keyBingoCompletedTiles);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeBingoCompletions(SharedPreferences prefs, Map<String, String> completions) async {
    await prefs.setString(_keyBingoCompletedTiles, jsonEncode(completions));
  }

  Future<BingoBoard> _buildBingoBoard(SharedPreferences prefs) async {
    final completions = _readBingoCompletions(prefs);
    final catalog = await OrientationCatalog.bingoTiles();
    final tiles = catalog.map((tile) {
      if (tile.isFreeSpace) return tile;
      final completedAt = completions[tile.id];
      if (completedAt == null) return tile;
      return tile.copyWith(state: BingoTileState.completed, completedAt: DateTime.tryParse(completedAt));
    }).toList();
    return BingoBoard(id: 'bingo_main', tiles: tiles);
  }

  /// Number of completed tiles in the "meet people" category — the closest
  /// honest stand-in for a friends-met counter now that the board, not a QR
  /// scanner, is how social activity gets recorded.
  Future<int> _explorationTilesCompleted(SharedPreferences prefs) async =>
      (await _buildBingoBoard(prefs))
          .tiles
          .where((t) => t.category == BingoTileCategory.exploration && t.isCompleted)
          .length;

  // ── Photo quests ───────────────────────────────────────────────────────────

  /// missionId -> `{status}|{photoPath}|{completedAtIso}`. Flat strings keep
  /// the persisted shape trivially forward-compatible with a real backend.
  Map<String, String> _readMissionStatuses(SharedPreferences prefs) {
    final raw = prefs.getString(_keyMissionStatuses);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeMissionStatuses(SharedPreferences prefs, Map<String, String> statuses) async {
    await prefs.setString(_keyMissionStatuses, jsonEncode(statuses));
  }

  Future<List<PhotoMission>> _buildPhotoMissions(SharedPreferences prefs) async {
    final statuses = _readMissionStatuses(prefs);
    final catalog = await OrientationCatalog.photoMissions();
    return catalog.map((mission) {
      final record = statuses[mission.id];
      if (record == null) return mission;

      final parts = record.split('|');
      final status = MissionStatus.values.firstWhere(
        (s) => s.name == parts.first,
        orElse: () => MissionStatus.available,
      );
      return mission.copyWith(
        status: status,
        submissionCount: 1,
        photoPath: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
        completedAt: parts.length > 2 ? DateTime.tryParse(parts[2]) : null,
      );
    }).toList();
  }

  Future<int> _completedMissionCount(SharedPreferences prefs) async =>
      (await _buildPhotoMissions(prefs)).where((m) => m.isCompleted).length;

  /// The signed-in student's own row for local-only surfaces (the mock
  /// leaderboard, the mock profile) — a fixed "You" placeholder, not a name
  /// pulled from the real signed-in profile, since neither local path is
  /// reachable once the backend is live (the hybrid repo sources both from
  /// the real account instead).
  StudentProfile _localStudent() => const StudentProfile(
        id: 'me',
        fullName: 'You',
        initials: 'ME',
        avatarColorIndex: 2,
        faculty: '',
        isFoundationYear: false,
        country: '',
        interests: [],
      );

  // ── Streak ─────────────────────────────────────────────────────────────────

  Streak _readStreak(SharedPreferences prefs) {
    return Streak(
      current: prefs.getInt(_keyStreakCurrent) ?? 0,
      longest: prefs.getInt(_keyStreakLongest) ?? 0,
    );
  }

  /// Extends the streak the first time the student completes anything on a
  /// new calendar day.
  ///
  /// It used to be driven by finishing a day's challenges, which no longer
  /// exist. Counting *days with any activity* is both the closest surviving
  /// meaning and a more honest one: the number now says how many days in a
  /// row the student actually opened Orientation Week and did something.
  ///
  /// Returns the streak bonus to award — 0 on the first day of a fresh
  /// streak, since there is nothing yet to have extended.
  Future<int> _touchStreak(SharedPreferences prefs) async {
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final lastKey = prefs.getString(_keyLastActiveDate);
    // Already counted today — activity is a day's worth, however much of it.
    if (lastKey == todayKey) return 0;

    final current = prefs.getInt(_keyStreakCurrent) ?? 0;
    final longest = prefs.getInt(_keyStreakLongest) ?? 0;
    final extendsStreak = lastKey == _dateKey(today.subtract(const Duration(days: 1)));
    final newCurrent = extendsStreak ? current + 1 : 1;

    await prefs.setInt(_keyStreakCurrent, newCurrent);
    await prefs.setInt(_keyStreakLongest, newCurrent > longest ? newCurrent : longest);
    await prefs.setString(_keyLastActiveDate, todayKey);

    return newCurrent > 1 ? _streakBonus : 0;
  }

  /// Calendar day, local time — never a timestamp, so two activities an hour
  /// apart either side of midnight count as two days and not as one.
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Dashboard ──────────────────────────────────────────────────────────────

  int _computeRank(int tokens) {
    final fraction = (tokens / _rankTokenCeiling).clamp(0.0, 1.0);
    final rank = (totalParticipants * (1 - fraction)).round();
    return rank.clamp(1, totalParticipants);
  }

  @override
  Future<OrientationDashboard> getDashboard() async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    await _resetIfWeekEnded(prefs);

    final tokens = await _readTokens(prefs);
    final board = await _buildBingoBoard(prefs);
    final currentDay = OrientationConfig.currentDay();

    return OrientationDashboard(
      currentDay: currentDay,
      totalDays: OrientationConfig.totalDays,
      tokens: tokens,
      rank: _computeRank(tokens),
      totalParticipants: totalParticipants,
      timeRemaining: OrientationConfig.timeRemaining(),
      bingoCompletedCount: board.completedTiles,
      bingoTotalCount: board.tiles.length,
      rewardsPreview: mockRewards().take(3).toList(),
      photoQuestsPreview: (await _buildPhotoMissions(prefs)).where((m) => !m.isCompleted).take(3).toList(),
      streak: _readStreak(prefs),
    );
  }

  @override
  Future<BingoBoard> getBingoBoard() async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    return _buildBingoBoard(prefs);
  }

  @override
  Future<PhotoMissionSubmitResult> submitMissionPhoto(String missionId, String localFilePath) async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();

    final before = await _buildPhotoMissions(prefs);
    final index = before.indexWhere((m) => m.id == missionId);
    if (index == -1) {
      return PhotoMissionSubmitResult.error('Mission not found.');
    }
    final mission = before[index];
    final wasCompleted = mission.isCompleted;
    if (!mission.canSubmit && !wasCompleted) {
      return PhotoMissionSubmitResult.error('This mission is not open for submissions.');
    }

    // No moderation backend exists yet, so the mock approves on submit —
    // `pendingReview` and `rejected` stay in the model (and stay renderable)
    // for when a real reviewer is wired in.
    final completedAt = DateTime.now();
    final statuses = _readMissionStatuses(prefs);
    statuses[missionId] = '${MissionStatus.completed.name}|$localFilePath|${completedAt.toIso8601String()}';
    await _writeMissionStatuses(prefs, statuses);

    final after = await _buildPhotoMissions(prefs);
    final allDone = after.every((m) => m.isCompleted);

    // The all-missions bonus is paid exactly once.
    var bonus = 0;
    if (allDone && !(prefs.getBool(_keyPhotoQuestBonusAwarded) ?? false)) {
      await prefs.setBool(_keyPhotoQuestBonusAwarded, true);
      bonus = _photoQuestBonus;
    }

    // Replacing the photo on a mission that already paid out swaps the image
    // without paying for it twice.
    final reward = PhotoQuestReward(
      missionTokens: wasCompleted ? 0 : mission.rewardTokens,
      bonusTokens: bonus,
      questCompleted: allDone,
    );
    await _addTokens(prefs, reward.totalTokens);

    return PhotoMissionSubmitResult.success(mission: after[index], reward: reward);
  }

  @override
  Future<PhotoMissionSubmitResult> deleteMissionPhoto(String missionId) async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();

    final before = await _buildPhotoMissions(prefs);
    final index = before.indexWhere((m) => m.id == missionId);
    if (index == -1) {
      return PhotoMissionSubmitResult.error('Mission not found.');
    }
    final mission = before[index];
    if (mission.photoPath == null && !mission.isCompleted) {
      return PhotoMissionSubmitResult.error('There is no photo to delete.');
    }

    final wasQuestComplete = before.every((m) => m.isCompleted);
    final statuses = _readMissionStatuses(prefs)..remove(missionId);
    await _writeMissionStatuses(prefs, statuses);

    // Deleting a submission takes back what it paid, so the balance always
    // matches what the student has actually completed. The all-missions
    // bonus is clawed back — and re-armed — for the same reason.
    var refund = mission.isCompleted ? -mission.rewardTokens : 0;
    if (wasQuestComplete && (prefs.getBool(_keyPhotoQuestBonusAwarded) ?? false)) {
      await prefs.setBool(_keyPhotoQuestBonusAwarded, false);
      refund -= _photoQuestBonus;
    }
    if (refund != 0) await _addTokens(prefs, refund);

    final after = await _buildPhotoMissions(prefs);
    return PhotoMissionSubmitResult.success(mission: after[index], reward: PhotoQuestReward.none);
  }

  @override
  Future<BingoTileResult> completeBingoTile(String tileId) async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();

    final before = await _buildBingoBoard(prefs);
    final index = before.tiles.indexWhere((t) => t.id == tileId);
    if (index == -1) {
      return BingoTileResult.error('Bingo tile not found.');
    }
    final tile = before.tiles[index];
    if (tile.isCompleted) {
      return BingoTileResult.error('This tile is already completed.');
    }
    if (!tile.isPlayable) {
      return BingoTileResult.error('This tile is locked.');
    }

    final completions = _readBingoCompletions(prefs)..[tileId] = DateTime.now().toIso8601String();
    await _writeBingoCompletions(prefs, completions);

    final after = await _buildBingoBoard(prefs);

    // Line bonuses are paid per line, once each: compare how many lines are
    // closed now against how many have already been paid for.
    final paidLines = prefs.getInt(_keyBingoAwardedLines) ?? 0;
    final newLines = (after.completedLines - paidLines).clamp(0, after.lines.length);
    final lineBonus = newLines * _bingoLineBonus;
    if (newLines > 0) {
      await prefs.setInt(_keyBingoAwardedLines, after.completedLines);
    }

    // Grand bonus for reaching the target line count — exactly once.
    var grandBonus = 0;
    if (after.isComplete && !(prefs.getBool(_keyBingoGrandAwarded) ?? false)) {
      await prefs.setBool(_keyBingoGrandAwarded, true);
      grandBonus = _bingoGrandBonus;
    }

    // Closing a square is activity, so it is what keeps a streak alive now
    // that there are no daily challenges to complete. Paid on top of the
    // tile's own reward, and only once per calendar day.
    final streakBonus = await _touchStreak(prefs);

    final reward = BingoReward(
      tileTokens: tile.rewardTokens,
      lineBonusTokens: lineBonus,
      grandBonusTokens: grandBonus + streakBonus,
      newlyCompletedLines: newLines,
      boardCompleted: after.isComplete,
    );
    await _addTokens(prefs, reward.totalTokens);

    return BingoTileResult.success(tile: after.tiles[index], reward: reward);
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({LeaderboardScope scope = LeaderboardScope.global}) async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    final tokens = await _readTokens(prefs);
    final me = _localStudent();

    // Local-only mode has no classmates to rank against — the live app
    // never reaches this path (`OrientationRepositoryHybridImpl.getLeaderboard`
    // always goes to the real backend board), so this is just "you", not a
    // cast of invented students.
    final withMe = <LeaderboardEntry>[
      LeaderboardEntry(rank: 0, student: me, tokens: tokens, isCurrentUser: true),
    ];

    final scoped = scope == LeaderboardScope.friends ? withMe.take(8).toList() : withMe;

    final prevKey = '$_keyLeaderboardPrevRankPrefix${scope.name}';
    final prevRaw = prefs.getString(prevKey);
    final prevRanks = prevRaw == null || prevRaw.isEmpty
        ? <String, int>{}
        : Map<String, int>.from(jsonDecode(prevRaw) as Map);

    final ranked = List<LeaderboardEntry>.generate(scoped.length, (i) {
      final e = scoped[i];
      return LeaderboardEntry(
        rank: i + 1,
        student: e.student,
        tokens: e.tokens,
        isCurrentUser: e.isCurrentUser,
        previousRank: prevRanks[e.student.id],
      );
    });

    final nextSnapshot = {for (final e in ranked) e.student.id: e.rank};
    await prefs.setString(prevKey, jsonEncode(nextSnapshot));

    return ranked;
  }

  @override
  Future<List<Reward>> getRewards() async {
    await Future.delayed(_simulatedLatency);
    return mockRewards();
  }

  @override
  Future<RedeemRewardResult> redeemReward(String rewardId) async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    final match = mockRewards().where((r) => r.id == rewardId);
    if (match.isEmpty) {
      return RedeemRewardResult.error('Reward not found.');
    }
    final selected = match.first;
    if (!selected.isRedeemable) {
      return RedeemRewardResult.error('This reward is not available.');
    }

    final tokens = await _readTokens(prefs);
    if (tokens < selected.priceTokens) {
      return RedeemRewardResult.error('Not enough tokens.');
    }

    final remaining = tokens - selected.priceTokens;
    // Spending never touches the earned-peak, so milestones stay unlocked.
    await prefs.setInt(_keyTokens, remaining);
    await _recordRedemption(prefs, selected);

    return RedeemRewardResult.success(reward: selected, remainingTokens: remaining);
  }

  // ── Reward history ─────────────────────────────────────────────────────────

  Future<void> _recordRedemption(SharedPreferences prefs, Reward reward) async {
    final entries = prefs.getStringList(_keyRewardRedemptions) ?? [];
    // Digital rewards (gift cards) arrive by email; physical rewards get a
    // short pickup code the student shows at the ADSL office.
    final isDigital = reward.category == RewardCategory.giftCards;
    final code = isDigital ? null : _collectionCode(reward.id, entries.length);
    final record = [
      reward.id,
      DateTime.now().toIso8601String(),
      '${reward.priceTokens}',
      code ?? '',
    ].join('|');
    // Newest first.
    await prefs.setStringList(_keyRewardRedemptions, [record, ...entries]);
  }

  String _collectionCode(String rewardId, int seq) {
    final prefix = rewardId.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final head = prefix.length >= 3 ? prefix.substring(0, 3) : prefix.padRight(3, 'X');
    return 'OW-$head-${(seq + 1).toString().padLeft(3, '0')}';
  }

  @override
  Future<List<RewardRedemption>> getRewardHistory() async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_keyRewardRedemptions) ?? const [];
    final catalog = {for (final r in mockRewards()) r.id: r};

    final history = <RewardRedemption>[];
    for (var i = 0; i < entries.length; i++) {
      final parts = entries[i].split('|');
      final reward = catalog[parts[0]];
      if (reward == null) continue;
      history.add(RewardRedemption(
        id: 'redemption_${entries.length - i}',
        reward: reward,
        redeemedAt: DateTime.tryParse(parts[1]) ?? DateTime.now(),
        spentTokens: int.tryParse(parts[2]) ?? reward.priceTokens,
        collectionCode: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
      ));
    }
    return history;
  }

  @override
  Future<List<RewardMilestone>> getRewardMilestones() async {
    await Future.delayed(_simulatedLatency);
    return mockRewardMilestones();
  }

  @override
  Future<int> getTokensEarnedTotal() async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    // The peak balance is the best mock proxy for lifetime tokens earned.
    return prefs.getInt(_keyTokensEarnedPeak) ?? await _readTokens(prefs);
  }

  @override
  Future<OrientationProgress> getProgress() async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    final tokens = await _readTokens(prefs);
    final board = await _buildBingoBoard(prefs);
    final visitedLocations = await _completedMissionCount(prefs);
    final friendsCount = await _explorationTilesCompleted(prefs);
    final challenges = await getChallenges();

    return OrientationProgress(
      visitedLocationsCount: visitedLocations,
      totalLocationsCount: (await OrientationCatalog.photoMissions()).length,
      completedChallengesCount: challenges.where((c) => c.isComplete).length,
      totalChallengesCount: challenges.length,
      completedTilesCount: board.completedTiles,
      totalTilesCount: board.tiles.length,
      placesDiscoveredCount: friendsCount,
      tokensEarned: tokens,
      bingoCompletionPercent: board.tiles.isEmpty ? 0 : board.completedTiles / board.tiles.length,
      streak: _readStreak(prefs),
    );
  }

  @override
  Future<List<PhotoMission>> getPhotoMissions() async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    return _buildPhotoMissions(prefs);
  }

  @override
  Future<({List<PhotoMission> missions, int bonusTokens})> getPhotoQuestBoard() async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    return (missions: await _buildPhotoMissions(prefs), bonusTokens: kPhotoQuestBonusTokens);
  }

  // ── Schedule ───────────────────────────────────────────────────────────────

  @override
  Future<OrientationSchedule> getSchedule() async {
    // No simulated latency: the timetable is a bundled asset and the Home page
    // renders it inline. Half a second of skeleton over a file that is already
    // in memory is a worse lie than no latency at all.
    return OrientationCatalog.schedule();
  }

  @override
  Future<StudentTrack?> getTrack() async {
    final prefs = await SharedPreferences.getInstance();
    return StudentTrackX.fromKey(prefs.getString(_keyTrack));
  }

  @override
  Future<void> setTrack(StudentTrack track) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTrack, track.key);
  }

  // ── Identity (peer QR) ─────────────────────────────────────────────────────

  @override
  Future<NuSchool?> getSchool() async {
    final prefs = await SharedPreferences.getInstance();
    return NuSchoolX.fromCode(prefs.getString(_keySchool));
  }

  @override
  Future<void> setSchool(NuSchool school) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySchool, school.code);
  }

  @override
  Future<OrientationIdentity?> getIdentity({
    required String studentId,
    required String displayName,
  }) async {
    final school = await getSchool();
    if (school == null) return null;
    return OrientationIdentity(
      studentId: studentId,
      displayName: displayName,
      school: school,
    );
  }

  // ── Challenges ─────────────────────────────────────────────────────────────

  Map<String, String> _readStringMap(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      // Corrupt local state degrades to "nothing answered" rather than taking
      // the whole page down on launch.
      return {};
    }
  }

  @override
  Future<List<OrientationChallenge>> getChallenges() async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    final answers = _readStringMap(prefs, _keyChallengeAnswers);
    return [
      for (final challenge in await OrientationCatalog.challenges())
        challenge.withAnswer(answers[challenge.id]),
    ];
  }

  Future<OrientationChallenge?> _challengeById(String id) async {
    for (final challenge in await OrientationCatalog.challenges()) {
      if (challenge.id == id) return challenge;
    }
    return null;
  }

  /// Pays [challenge] once, ever. Returns what was awarded.
  ///
  /// The paid set is kept separate from the answers map on purpose: editing an
  /// answer, or clearing and re-entering one, must never top a student up
  /// again, and deriving "have we paid" from "is there an answer" would let it.
  Future<int> _payChallengeOnce(
    SharedPreferences prefs,
    OrientationChallenge challenge,
  ) async {
    final paid = (prefs.getStringList(_keyChallengePaid) ?? const <String>[]).toSet();
    if (paid.contains(challenge.id)) return 0;

    await prefs.setStringList(_keyChallengePaid, [...paid, challenge.id]);
    final bonus = await _touchStreak(prefs);
    await _addTokens(prefs, challenge.rewardTokens + bonus);
    return challenge.rewardTokens + bonus;
  }

  @override
  Future<int> answerChallenge(String challengeId, String answer) async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();

    final challenge = await _challengeById(challengeId);
    if (challenge == null) return 0;

    final normalised = challenge.normaliseAnswer(answer);
    if (normalised == null) return 0;

    final answers = _readStringMap(prefs, _keyChallengeAnswers)
      ..[challengeId] = normalised;
    await prefs.setString(_keyChallengeAnswers, jsonEncode(answers));

    return _payChallengeOnce(prefs, challenge);
  }

  @override
  Future<void> clearChallengeAnswer(String challengeId) async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();
    final answers = _readStringMap(prefs, _keyChallengeAnswers)..remove(challengeId);
    await prefs.setString(_keyChallengeAnswers, jsonEncode(answers));
    // `_keyChallengePaid` is deliberately left alone — see _payChallengeOnce.
  }

  @override
  Future<List<OrientationIdentity>> getChallengeScans(String challengeId) async {
    final prefs = await SharedPreferences.getInstance();
    return _readScans(prefs, challengeId);
  }

  List<OrientationIdentity> _readScans(SharedPreferences prefs, String challengeId) {
    final raw = prefs.getStringList('$_keyChallengeScansPrefix$challengeId') ?? const [];
    // Corrupt rows are dropped rather than thrown on — a scan list that fails
    // to parse must not stop a student from scanning anyone else.
    return [for (final entry in raw) ?OrientationIdentity.decode(entry)];
  }

  @override
  Future<ScanOutcome> submitChallengeScan({
    required String challengeId,
    required OrientationIdentity me,
    required String scannedRaw,
  }) async {
    await Future.delayed(_simulatedLatency);
    final prefs = await SharedPreferences.getInstance();

    final challenge = await _challengeById(challengeId);
    final rule = challenge?.rule;
    if (challenge == null || rule == null) return const ScanUnrecognised();

    // Not one of our codes. A student will point the camera at every QR on
    // campus; none of those should produce anything but a polite "not ours".
    final them = OrientationIdentity.decode(scannedRaw);
    if (them == null) return const ScanUnrecognised();

    if (them.studentId == me.studentId) return const ScanSelf();

    final seen = _readScans(prefs, challengeId);
    if (seen.any((s) => s.studentId == them.studentId)) return ScanDuplicate(them);

    if (!rule.isSatisfiedBy(me, them)) {
      return ScanRejected(them, rule.rejectionReason(them));
    }

    // Recorded before the payout, so a crash between the two leaves a scan
    // that did not pay rather than a payout with nothing behind it.
    await prefs.setStringList(
      '$_keyChallengeScansPrefix$challengeId',
      [...seen.map((s) => s.encode()), them.encode()],
    );

    final answers = _readStringMap(prefs, _keyChallengeAnswers)
      ..[challengeId] = them.displayName;
    await prefs.setString(_keyChallengeAnswers, jsonEncode(answers));

    return ScanAccepted(them, await _payChallengeOnce(prefs, challenge));
  }

  @override
  Future<ClubScanResult> scanClubQr(String scannedPayload) async {
    await Future.delayed(_simulatedLatency);
    return ClubScanResult(
      clubId: scannedPayload,
      clubName: scannedPayload,
      tokensAwarded: 0,
      bingoLineTokens: 0,
      bingoGrandTokens: 0,
      alreadyCompleted: false,
      tokensBalance: 0,
    );
  }

  @override
  Future<ClubFairStandQrBundle> getClubStandQrs() async {
    await Future.delayed(_simulatedLatency);
    return const ClubFairStandQrBundle(isRep: false, qrs: []);
  }

  @override
  Future<ClubFairClubRanking> getClubRanking() async {
    await Future.delayed(_simulatedLatency);
    return const ClubFairClubRanking(totalScans: 0, clubs: []);
  }
}
