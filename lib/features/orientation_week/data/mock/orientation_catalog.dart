import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/bingo_tile.dart';
import '../../domain/entities/orientation_challenge.dart';
import '../../domain/entities/orientation_identity.dart';
import '../../domain/entities/orientation_schedule.dart';
import '../../domain/entities/photo_mission.dart';
import '../models/photo_quest_api_mapper.dart';

/// Reward for completing any single Bingo tile.
///
/// The economy constants stay in Dart while the *tasks* live in JSON: what a
/// square pays is a rule the repository and the reward sheets are written
/// around, not content someone edits between two Orientation Weeks.
const int kBingoTileReward = 25;

/// One-time payout for finishing every Photo Quest mission on the board.
const int kPhotoQuestBonusTokens = 400;

/// The week's content — Bingo squares and Photo Quest missions —
/// read from JSON in `assets/data/orientation/` rather than compiled in.
///
/// Editing next year's tasks is then a matter of editing two data files:
/// no Dart change, no rebuild of anything but the asset bundle, and the same
/// files can be handed to whoever runs Orientation Week without teaching them
/// Dart syntax first.
///
/// Each file is decoded once and the resulting list kept, so a hundred
/// callers during one dashboard load share a single parse, and concurrent
/// first callers share one in-flight read rather than racing to decode twice.
///
/// A malformed file throws. That is deliberate: a silent fallback to an empty
/// board would ship an Orientation Week with no tasks in it and look like a
/// backend outage, where a hard failure on the very first load is caught long
/// before anyone installs it.
abstract class OrientationCatalog {
  static const String bingoAsset = 'assets/data/orientation/bingo.json';
  static const String photoQuestsAsset = 'assets/data/orientation/photo_quests.json';
  static const String challengesAsset = 'assets/data/orientation/challenges.json';
  static const String scheduleAsset = 'assets/data/orientation/schedule.json';

  static final _bingoTiles = _CatalogFile(bingoAsset, 'tiles', _bingoTileFromJson);
  static final _photoMissions =
      _CatalogFile(photoQuestsAsset, 'missions', photoMissionFromApi);
  static final _challenges =
      _CatalogFile(challengesAsset, 'challenges', _challengeFromJson);
  static final _schedule = _ScheduleFile(scheduleAsset);


  /// The 16 Bingo squares in board order.
  static Future<List<BingoTile>> bingoTiles() => _bingoTiles.read();

  /// The Photo Quest missions, all `available` — the live backend supplies
  /// the real per-student status.
  static Future<List<PhotoMission>> photoMissions() => _photoMissions.read();

  /// The Challenges, all unanswered — the repository overlays what this
  /// student stored.
  static Future<List<OrientationChallenge>> challenges() => _challenges.read();

  /// The week's timetable, both tracks. Filtering to one track is the caller's
  /// job, so the same parse serves a student who switches.
  static Future<OrientationSchedule> schedule() => _schedule.read();

  /// Fills the cache from JSON the caller already has in hand, instead of
  /// reading the asset bundle.
  ///
  /// Widget tests need this. Reading an asset is real I/O, and the clock
  /// inside `testWidgets` is a fake one that never advances real I/O — a
  /// first load reached from inside a pump simply hangs until the test times
  /// out. A test reads the same three files off disk synchronously (see
  /// `test/helpers/orientation_catalog_fixture.dart`) and seeds them here.
  ///
  /// The parsing under test is identical either way: same files, same
  /// mappers — only the bytes arrive by a different road.
  @visibleForTesting
  static void seedFromJson({
    required String bingo,
    required String photoQuests,
    required String challenges,
    required String schedule,
  }) {
    _bingoTiles.seed(bingo);
    _photoMissions.seed(photoQuests);
    _challenges.seed(challenges);
    _schedule.seed(schedule);
  }

  /// Drops the cache, so the next read goes back to the bundle.
  @visibleForTesting
  static void resetCache() {
    _bingoTiles.reset();
    _photoMissions.reset();
    _challenges.reset();
    _schedule.reset();
  }
}

/// The timetable file, cached the same way and for the same reason as
/// [_CatalogFile] — but its shape is a list of days each holding a list of
/// sessions, not one flat array, so it gets its own reader rather than
/// contorting the generic one.
class _ScheduleFile {
  _ScheduleFile(this.asset);

  final String asset;

  OrientationSchedule? _cache;
  Future<OrientationSchedule>? _inFlight;

  Future<OrientationSchedule> read() async {
    final cached = _cache;
    if (cached != null) return cached;
    return _cache = await (_inFlight ??= _readAsset());
  }

  void seed(String raw) {
    _cache = _parse(raw);
    _inFlight = null;
  }

  void reset() {
    _cache = null;
    _inFlight = null;
  }

  Future<OrientationSchedule> _readAsset() async =>
      _parse(await rootBundle.loadString(asset));

  OrientationSchedule _parse(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final days = decoded['days'] as List<dynamic>?;
    if (days == null) {
      throw StateError('$asset is missing its "days" array');
    }

    return OrientationSchedule(
      days: [
        for (final entry in days) _dayFromJson(entry as Map<String, dynamic>),
      ],
    );
  }
}

ScheduleDay _dayFromJson(Map<String, dynamic> json) {
  final date = DateTime.parse(json['date'] as String);
  final day = DateTime(date.year, date.month, date.day);

  final sessions = [
    for (final entry in json['sessions'] as List<dynamic>? ?? const [])
      _sessionFromJson(entry as Map<String, dynamic>, day),
  ]..sort((a, b) {
      final byStart = a.startMinutes.compareTo(b.startMinutes);
      if (byStart != 0) return byStart;
      // Shared sessions lead their slot: at 08:00 the whole cohort is doing
      // the same thing, and burying it under a track-specific row makes the
      // day read as if it did not apply.
      if (a.isForBothTracks != b.isForBothTracks) return a.isForBothTracks ? -1 : 1;
      return a.title.compareTo(b.title);
    });

  return ScheduleDay(
    date: day,
    label: json['label'] as String? ?? '',
    sessions: sessions,
  );
}

ScheduleSession _sessionFromJson(Map<String, dynamic> json, DateTime day) {
  return ScheduleSession(
    id: json['id'] as String,
    date: day,
    title: json['title'] as String,
    startMinutes: ScheduleSession.parseMinutes(json['starts'] as String?),
    endMinutes: ScheduleSession.parseMinutes(json['ends'] as String?),
    importance: SessionImportanceX.fromKey(json['importance'] as String?),
    // 'all' and anything unrecognised both mean "shown to everyone", which is
    // the safe direction to fail in: a student sees one extra row rather than
    // missing a mandatory session.
    track: StudentTrackX.fromKey(json['track'] as String?),
    place: json['place'] as String?,
    note: json['note'] as String?,
    link: json['link'] as String?,
    linkLabel: json['link_label'] as String?,
  );
}

OrientationChallenge _challengeFromJson(Map<String, dynamic> json) {
  return OrientationChallenge(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    kind: ChallengeKindX.fromKey(json['kind'] as String?),
    rewardTokens: (json['reward_tokens'] as num?)?.toInt() ?? 100,
    rule: QrScanRuleX.fromKey(json['rule'] as String?),
    iconKey: json['icon'] as String?,
    prompt: json['prompt'] as String?,
    hint: json['hint'] as String?,
    multiline: json['multiline'] as bool? ?? false,
    link: json['link'] as String?,
    linkLabel: json['link_label'] as String?,
    verifyNote: json['verify_note'] as String?,
  );
}

/// One JSON file and the list decoded from it.
///
/// What is cached is the finished **list**, never the `Future` that produced
/// it. A `Future` remembers the zone it was created in and runs its
/// continuations there — seed one from a test's `setUp` and every `await`
/// inside `testWidgets` waits on a callback queued in a zone the fake clock
/// never drains, which looks exactly like a page stuck on its skeleton.
/// Returning a cached list from an `async` method instead completes in
/// whichever zone asked, which is the only behaviour that works everywhere.
class _CatalogFile<T> {
  _CatalogFile(this.asset, this.key, this.fromJson);

  final String asset;
  final String key;
  final T Function(Map<String, dynamic>) fromJson;

  List<T>? _cache;
  Future<List<T>>? _inFlight;

  Future<List<T>> read() async {
    final cached = _cache;
    if (cached != null) return cached;
    return _cache = await (_inFlight ??= _readAsset());
  }

  void seed(String raw) {
    _cache = _parse(raw);
    _inFlight = null;
  }

  void reset() {
    _cache = null;
    _inFlight = null;
  }

  Future<List<T>> _readAsset() async => _parse(await rootBundle.loadString(asset));

  List<T> _parse(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final entries = decoded[key] as List<dynamic>?;
    if (entries == null) {
      throw StateError('$asset is missing its "$key" array');
    }
    return entries.map((e) => fromJson(e as Map<String, dynamic>)).toList(growable: false);
  }
}


BingoTile _bingoTileFromJson(Map<String, dynamic> json) {
  return BingoTile(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    category: _bingoCategory(json['category'] as String?),
    icon: _bingoIcon(json['icon'] as String?),
    rewardTokens: (json['reward_tokens'] as num?)?.toInt() ?? kBingoTileReward,
    state: _bingoState(json['state'] as String?),
    verification: _bingoVerification(json['verification'] as String?),
    link: json['link'] as String?,
    linkLabel: json['link_label'] as String?,
  );
}

// Every one of these falls back to the commonest value rather than throwing:
// a typo'd icon name should cost one glyph, not the whole board. A typo'd
// *id* or a missing title still throws above, because those are structural.



BingoTileCategory _bingoCategory(String? raw) => switch (raw) {
      'exploration' => BingoTileCategory.exploration,
      'activity' => BingoTileCategory.activity,
      'food' => BingoTileCategory.food,
      'academic' => BingoTileCategory.academic,
      'reward' => BingoTileCategory.reward,
      _ => BingoTileCategory.campus,
    };

BingoTileIcon _bingoIcon(String? raw) => switch (raw) {
      'camera' => BingoTileIcon.camera,
      'message' => BingoTileIcon.message,
      'location' => BingoTileIcon.location,
      'clipboard' => BingoTileIcon.clipboard,
      'book' => BingoTileIcon.book,
      'utensils' => BingoTileIcon.utensils,
      'door' => BingoTileIcon.door,
      'explore' => BingoTileIcon.explore,
      'graduation' => BingoTileIcon.graduation,
      'schedule' => BingoTileIcon.schedule,
      'send' => BingoTileIcon.send,
      'megaphone' => BingoTileIcon.megaphone,
      'token' => BingoTileIcon.token,
      'trophy' => BingoTileIcon.trophy,
      'map' => BingoTileIcon.map,
      'bowl' => BingoTileIcon.bowl,
      'gift' => BingoTileIcon.gift,
      'heart' => BingoTileIcon.heart,
      'qrCode' => BingoTileIcon.qrCode,
      'flag' => BingoTileIcon.flag,
      _ => BingoTileIcon.calendar,
    };

BingoTileState _bingoState(String? raw) => switch (raw) {
      'free_space' => BingoTileState.freeSpace,
      'locked' => BingoTileState.locked,
      'special' => BingoTileState.special,
      // `completed` is deliberately unreachable: the file describes the board,
      // never one student's progress through it.
      _ => BingoTileState.available,
    };

BingoVerification _bingoVerification(String? raw) => switch (raw) {
      'auto' => BingoVerification.auto,
      'qr_scan' => BingoVerification.qrScan,
      _ => BingoVerification.manual,
    };
