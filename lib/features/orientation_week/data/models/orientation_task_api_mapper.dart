import '../../domain/entities/bingo_board.dart';
import '../../domain/entities/bingo_tile.dart';
import '../../domain/entities/club_fair_club_rank.dart';
import '../../domain/entities/club_fair_schedule.dart';
import '../../domain/entities/club_fair_stand_qr.dart';
import '../../domain/entities/orientation_challenge.dart';
import '../../domain/entities/orientation_dashboard.dart';
import '../../domain/entities/orientation_identity.dart';
import '../../domain/entities/orientation_results.dart';
import '../../domain/entities/photo_mission.dart';
import '../../domain/entities/streak.dart';
import '../../config/orientation_config.dart';

/// Maps the unified Orientation task API (`GET /orientation/tasks`,
/// `GET /orientation/bingo`) onto the app's existing entities.
///
/// The server stores every text in en/ru/kk; the mapper picks the one for the
/// app's current language so the rest of the feature keeps working with plain
/// strings.

String pickLocalizedText(Object? raw, String languageCode) {
  if (raw is! Map) return '';
  final map = Map<String, dynamic>.from(raw);
  final value = map[languageCode] ?? map['en'] ?? map.values.firstOrNull;
  return value?.toString() ?? '';
}

/// Kinds the Tasks tab can host, including Club Fair photos.
bool isChallengeApiKind(String kind) => true;

ChallengeKind challengeKindFromApi(String kind, [Map<String, dynamic>? config]) {
  if (kind == 'handle' && config?['verification'] == 'telegram_bot') {
    return ChallengeKind.telegramBot;
  }
  return switch (kind) {
      'peer_qr' => ChallengeKind.qrScan,
      // A venue poster is still "point the camera at a code" — the scanner
      // page is shared and the server decides whether the payload counts.
      'venue_qr' => ChallengeKind.qrScan,
      'text' => ChallengeKind.text,
      'name' => ChallengeKind.name,
      'handle' => ChallengeKind.handle,
      'referral' => ChallengeKind.referral,
      'photo' => ChallengeKind.photo,
      _ => ChallengeKind.text,
    };
}

/// What the student stored, for prefill and for the "Your answer: …" line.
String? storedAnswerFromApiTask(Map<String, dynamic> task) {
  if (task['status'] != 'completed') return null;
  final payload = task['payload'];
  if (payload is! Map) return '✓';
  final map = Map<String, dynamic>.from(payload);
  final value = map['answer'] ?? map['name'] ?? map['handle'] ?? map['peer_name'];
  if (value != null && value.toString().trim().isNotEmpty) {
    return value.toString();
  }
  // Peer/venue/referral/telegram completions carry no typed text — any
  // non-empty marker keeps `isComplete` true without inventing an answer.
  return '✓';
}

OrientationChallenge challengeFromApiTask(
  Map<String, dynamic> task,
  String languageCode,
) {
  final config = task['config'] is Map
      ? Map<String, dynamic>.from(task['config'] as Map)
      : const <String, dynamic>{};
  final prompt = pickLocalizedText(config['prompt'], languageCode);

  return OrientationChallenge(
    id: task['id'] as String,
    title: pickLocalizedText(task['title'], languageCode),
    description: pickLocalizedText(task['description'], languageCode),
    kind: challengeKindFromApi(task['kind'] as String? ?? 'text', config),
    rewardTokens: (task['reward_tokens'] as num?)?.toInt() ?? 0,
    rule: QrScanRuleX.fromKey(config['rule'] as String?),
    iconKey: task['icon'] as String?,
    prompt: prompt.isEmpty ? null : prompt,
    multiline: config['multiline'] == true,
    link: config['link'] as String?,
    linkLabel: config['link_label'] as String?,
    answer: storedAnswerFromApiTask(task),
    apiKind: task['kind'] as String?,
    visibleFrom: DateTime.tryParse(task['visible_from']?.toString() ?? ''),
    groupKey: groupFromApiTask(task),
  );
}

String groupFromApiTask(Map<String, dynamic> task) {
  final raw = task['group']?.toString().trim();
  if (raw != null && raw.isNotEmpty) return raw;
  final kind = task['kind'] as String? ?? '';
  if (kind == 'photo') return 'photo';
  if (kind == 'venue_qr' || kind == 'peer_qr') return 'qr';
  final from = task['visible_from']?.toString();
  if (from != null && from.isNotEmpty) return 'today';
  return 'general';
}

// ── Bingo ────────────────────────────────────────────────────────────────────

BingoTileCategory bingoCategoryFromApi(String? category) => switch (category) {
      'study' || 'academic' => BingoTileCategory.academic,
      'food' => BingoTileCategory.food,
      'facility' || 'landmark' || 'building' => BingoTileCategory.campus,
      'event' || 'activity' || 'networking' => BingoTileCategory.activity,
      'social' => BingoTileCategory.reward,
      _ => BingoTileCategory.exploration,
    };

BingoTileIcon bingoIconFromApi(String? icon) => switch (icon) {
      'book' || 'lightbulb' => BingoTileIcon.book,
      'coffee' || 'utensils' => BingoTileIcon.utensils,
      'compass' || 'globe' => BingoTileIcon.explore,
      'landmark' || 'flag' => BingoTileIcon.flag,
      'camera' || 'sunset' => BingoTileIcon.camera,
      'trees' || 'map' => BingoTileIcon.map,
      'building' => BingoTileIcon.door,
      'megaphone' => BingoTileIcon.megaphone,
      'qrCode' => BingoTileIcon.qrCode,
      'heart' => BingoTileIcon.heart,
      'users' || 'message' => BingoTileIcon.message,
      'location' => BingoTileIcon.location,
      'send' || 'instagram' || 'share' => BingoTileIcon.send,
      'graduation' => BingoTileIcon.graduation,
      'trophy' => BingoTileIcon.trophy,
      'gift' => BingoTileIcon.gift,
      _ => BingoTileIcon.explore,
    };

BingoTile bingoTileFromApiCell(Map<String, dynamic> cell, String languageCode) {
  if (cell['club'] is Map) {
    return bingoTileFromClubFairCell(cell, languageCode);
  }
  final task = Map<String, dynamic>.from(cell['task'] as Map);
  final config = task['config'] is Map
      ? Map<String, dynamic>.from(task['config'] as Map)
      : const <String, dynamic>{};
  final completed = task['status'] == 'completed';

  return BingoTile(
    id: task['id'] as String,
    title: pickLocalizedText(task['title'], languageCode),
    description: pickLocalizedText(task['description'], languageCode),
    category: bingoCategoryFromApi(task['category'] as String?),
    icon: bingoIconFromApi(task['icon'] as String?),
    rewardTokens: (task['reward_tokens'] as num?)?.toInt() ?? 0,
    state: completed ? BingoTileState.completed : BingoTileState.available,
    // Server tiles are never self-marked: each one completes through its own
    // task mechanic (Challenges input, peer/venue scan, Photo Quest camera).
    verification: BingoVerification.auto,
    taskKind: task['kind'] as String?,
    link: config['link'] as String?,
    linkLabel: config['link_label'] as String?,
    completedAt: DateTime.tryParse(task['completed_at']?.toString() ?? ''),
  );
}

BingoBoard bingoBoardFromApi(Map<String, dynamic> json, String languageCode) {
  final cellsJson = (json['cells'] as List<dynamic>? ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList()
    ..sort((a, b) =>
        ((a['position'] as num?)?.toInt() ?? 0).compareTo((b['position'] as num?)?.toInt() ?? 0));

  return BingoBoard(
    id: 'club-fair-bingo',
    tiles: [for (final cell in cellsJson) bingoTileFromApiCell(cell, languageCode)],
  );
}

BingoTile bingoTileFromClubFairCell(Map<String, dynamic> cell, String languageCode) {
  final club = Map<String, dynamic>.from(cell['club'] as Map);
  final scanned = club['scanned'] == true;
  final slot = club['slot'] as String? ?? '';
  final standDate = club['stand_date']?.toString() ?? '';
  final slotLabel = switch (slot) {
    'morning' => '11:00–14:00',
    'afternoon' => '15:00–18:00',
    'always' => 'All week',
    _ => slot,
  };
  final when = [
    if (standDate.isNotEmpty) standDate,
    slotLabel,
    'NU Atrium',
  ].join(' · ');

  return BingoTile(
    id: club['id'] as String,
    title: pickLocalizedText(club['name'], languageCode),
    description: when,
    category: BingoTileCategory.activity,
    icon: BingoTileIcon.qrCode,
    rewardTokens: (club['reward_tokens'] as num?)?.toInt() ?? 0,
    state: scanned ? BingoTileState.completed : BingoTileState.available,
    verification: BingoVerification.qrScan,
    taskKind: 'club_qr',
  );
}

String? clubIdFromClubQrPayload(String raw) {
  const prefix = 'jasaim-club:';
  final trimmed = raw.trim();
  if (!trimmed.startsWith(prefix)) return null;
  final rest = trimmed.substring(prefix.length);
  final parts = rest.split(':');
  if (parts.length != 4) return null;
  final clubId = parts[0];
  return clubId.isEmpty ? null : clubId;
}

ClubFairClubItem clubFairClubFromApi(Map<String, dynamic> json, String languageCode) {
  return ClubFairClubItem(
    id: json['id'] as String? ?? '',
    name: pickLocalizedText(json['name'], languageCode),
    standDate: DateTime.tryParse(json['stand_date']?.toString() ?? ''),
    slot: json['slot'] as String? ?? '',
    inQuest: json['in_quest'] == true,
    scanned: json['scanned'] == true,
    qrLive: json['qr_live'] == true,
    rewardTokens: (json['reward_tokens'] as num?)?.toInt() ?? 0,
  );
}

List<ClubFairSlotGroup> clubFairSlotsFromApi(List<dynamic>? raw, String languageCode) {
  return (raw ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .map(
        (slot) => ClubFairSlotGroup(
          standDate: DateTime.tryParse(slot['stand_date']?.toString() ?? ''),
          slot: slot['slot'] as String? ?? '',
          clubs: (slot['clubs'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((c) => clubFairClubFromApi(Map<String, dynamic>.from(c), languageCode))
              .toList(growable: false),
        ),
      )
      .toList(growable: false);
}

OrientationDashboard dashboardFromClubFairHome(
  Map<String, dynamic> json,
  String languageCode,
) {
  final progress = json['progress'] is Map
      ? Map<String, dynamic>.from(json['progress'] as Map)
      : const <String, dynamic>{};
  final end = DateTime.tryParse(json['quest_end']?.toString() ?? '');
  final now = DateTime.tryParse(json['now']?.toString() ?? '') ?? DateTime.now();
  final remaining = end == null ? Duration.zero : end.difference(now);
  return OrientationDashboard(
    currentDay: OrientationConfig.currentDay(now),
    totalDays: OrientationConfig.totalDays,
    tokens: (json['tokens_balance'] as num?)?.toInt() ?? 0,
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    totalParticipants: (json['total_participants'] as num?)?.toInt() ?? 0,
    timeRemaining: remaining.isNegative ? Duration.zero : remaining,
    bingoCompletedCount: 0,
    bingoTotalCount: 16,
    rewardsPreview: const [],
    photoQuestsPreview: const [],
    streak: const Streak(current: 0, longest: 0),
    clubsScanned: (progress['clubs_scanned'] as num?)?.toInt() ?? 0,
    clubsTotal: (progress['clubs_total'] as num?)?.toInt() ?? 0,
    clubScanTokens: (progress['club_scan_tokens'] as num?)?.toInt() ?? 0,
    tasksCompleted: (progress['tasks_completed'] as num?)?.toInt() ?? 0,
    tasksTotal: (progress['tasks_total'] as num?)?.toInt() ?? 0,
    isRep: json['is_rep'] == true,
    slots: clubFairSlotsFromApi(json['slots'] as List<dynamic>?, languageCode),
  );
}

ClubFairStandQrBundle clubFairStandQrFromApi(
  Map<String, dynamic> json,
  String languageCode,
) {
  return ClubFairStandQrBundle(
    isRep: json['is_rep'] == true,
    qrs: (json['qrs'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map((row) {
          final clubJson = row['club'] is Map
              ? Map<String, dynamic>.from(row['club'] as Map)
              : const <String, dynamic>{};
          return ClubFairStandQr(
            club: clubFairClubFromApi(clubJson, languageCode),
            live: row['live'] == true,
            payload: row['payload'] as String?,
            stepSeconds: (row['step_seconds'] as num?)?.toInt(),
            windowStart: DateTime.tryParse(row['window_start']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
            windowEnd: DateTime.tryParse(row['window_end']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
          );
        })
        .toList(growable: false),
  );
}

ClubFairClubRanking clubFairClubRankingFromApi(
  Map<String, dynamic> json,
  String languageCode,
) {
  return ClubFairClubRanking(
    totalScans: (json['total_scans'] as num?)?.toInt() ?? 0,
    clubs: (json['clubs'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(
          (row) => ClubFairClubRank(
            rank: (row['rank'] as num?)?.toInt() ?? 0,
            id: row['id'] as String? ?? '',
            name: pickLocalizedText(row['name'], languageCode),
            scans: (row['scans'] as num?)?.toInt() ?? 0,
            slot: row['slot'] as String? ?? '',
            standDate: DateTime.tryParse(row['stand_date']?.toString() ?? ''),
          ),
        )
        .toList(growable: false),
  );
}

ClubScanResult clubScanResultFromApi(Map<String, dynamic> json, String languageCode) {
  final club = json['club'] is Map
      ? Map<String, dynamic>.from(json['club'] as Map)
      : const <String, dynamic>{};
  return ClubScanResult(
    clubId: club['id'] as String? ?? '',
    clubName: pickLocalizedText(club['name'], languageCode),
    tokensAwarded: (json['tokens_awarded'] as num?)?.toInt() ?? 0,
    bingoLineTokens: (json['bingo_line_tokens'] as num?)?.toInt() ?? 0,
    bingoGrandTokens: (json['bingo_grand_tokens'] as num?)?.toInt() ?? 0,
    alreadyCompleted: json['already_completed'] == true,
    tokensBalance: (json['tokens_balance'] as num?)?.toInt() ?? 0,
  );
}

PhotoMission photoMissionFromChallenge(OrientationChallenge challenge) {
  return PhotoMission(
    id: challenge.id,
    title: challenge.title,
    description: challenge.description,
    difficulty: MissionDifficulty.medium,
    category: MissionCategory.event,
    icon: MissionIcon.camera,
    rewardTokens: challenge.rewardTokens,
    status: challenge.isComplete ? MissionStatus.completed : MissionStatus.available,
  );
}
