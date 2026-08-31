/// Pastel tint applied to a tile's background. Kept as a semantic enum so
/// this pure-Dart entity never imports Flutter — the presentation layer maps
/// each value to a colour.
enum BingoTileCategory { exploration, activity, campus, food, academic, reward }

/// The glyph a tile shows. An enum rather than an icon object for the same
/// reason — `bingo_tile_visuals.dart` maps these to `AppIcons`.
enum BingoTileIcon {
  calendar,
  camera,
  message,
  location,
  clipboard,
  book,
  utensils,
  door,
  explore,
  graduation,
  schedule,
  send,
  megaphone,
  token,
  trophy,
  map,
  bowl,
  gift,
  heart,
  qrCode,
  flag,
}

/// Lifecycle of a single tile.
///
/// [freeSpace] is the board's centre square: it always counts as complete
/// and is never tappable. [locked] tiles are dimmed and inert (reserved for
/// prerequisite-gated tiles); [special] marks a highlighted tile.
enum BingoTileState { locked, available, completed, special, freeSpace }

/// How a tile gets marked complete.
///
/// [auto] tiles are detected by the system as the student earns tokens or
/// uses campus services — they can't be self-marked, only observed.
/// [qrScan] tiles need a supervisor's confirmation: the student scans the QR
/// code the supervisor holds. [manual] tiles are on the honour system — the
/// student marks them done themselves.
enum BingoVerification { auto, qrScan, manual }

/// One square on the Bingo board.
class BingoTile {
  const BingoTile({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.rewardTokens,
    required this.state,
    this.verification = BingoVerification.manual,
    this.taskKind,
    this.completedAt,
    this.link,
    this.linkLabel,
  });

  final String id;
  final String title;
  final String description;
  final BingoTileCategory category;
  final BingoTileIcon icon;
  final int rewardTokens;
  final BingoTileState state;

  /// How this tile is confirmed complete.
  final BingoVerification verification;

  /// Server task kind behind this square (`photo`, `text`, `peer_qr`, …).
  /// Null on the local mock board. When set, the square is completed through
  /// its own task flow — the Challenges sheet or the Photo Quest camera —
  /// never self-marked here.
  final String? taskKind;

  /// A server square that opens its task flow when tapped.
  bool get opensTaskFlow => taskKind != null && taskKind != 'photo';

  /// A server square whose task is a Photo Quest mission.
  bool get isPhotoTask => taskKind == 'photo';

  /// Where the square is carried out, when that is somewhere outside the app
  /// — an Instagram profile to follow. Null for anything done on campus.
  final String? link;

  /// What to call [link] on the button that opens it ("@adsl_nu").
  final String? linkLabel;

  final DateTime? completedAt;

  /// The free space always counts toward lines without being played.
  bool get isCompleted => state == BingoTileState.completed || state == BingoTileState.freeSpace;

  bool get isFreeSpace => state == BingoTileState.freeSpace;

  bool get isLocked => state == BingoTileState.locked;

  /// Only an un-played, unlocked tile can be completed by the player.
  bool get isPlayable => state == BingoTileState.available || state == BingoTileState.special;

  /// Auto tiles are observed by the system, so tapping them can't complete
  /// them — the sheet just explains they're tracked automatically.
  bool get isAutoTracked => verification == BingoVerification.auto;

  BingoTile copyWith({BingoTileState? state, DateTime? completedAt}) {
    return BingoTile(
      id: id,
      title: title,
      description: description,
      category: category,
      icon: icon,
      rewardTokens: rewardTokens,
      state: state ?? this.state,
      verification: verification,
      taskKind: taskKind,
      completedAt: completedAt ?? this.completedAt,
      link: link,
      linkLabel: linkLabel,
    );
  }
}
