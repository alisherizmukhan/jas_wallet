import 'orientation_identity.dart';

/// How a challenge is completed. This decides the entire interaction — which
/// sheet opens, what is stored, and what "done" means.
enum ChallengeKind {
  /// Scan another student's Orientation QR code.
  qrScan,

  /// A free-text answer — a year, a fact, a club name.
  text,

  /// The name of a student they met. Same input as [text]; kept separate so
  /// the prompt and the stored label read correctly.
  name,

  /// An Instagram handle, normalised to @lowercase on save.
  handle,

  /// Opens the Orientation Telegram bot (deep link). Membership is checked
  /// server-side — nothing to type in the app.
  telegramBot,

  /// Done outside the app; the button opens a link.
  link,

  /// Opens the app's own referral screen. Nothing to store.
  referral,

  /// Opens the Photo Quest camera for this Club Fair mission.
  photo,
}

extension ChallengeKindX on ChallengeKind {
  static ChallengeKind fromKey(String? raw) => switch (raw) {
        'qr_scan' => ChallengeKind.qrScan,
        'text' => ChallengeKind.text,
        'name' => ChallengeKind.name,
        'handle' => ChallengeKind.handle,
        'telegram_bot' => ChallengeKind.telegramBot,
        'link' => ChallengeKind.link,
        'referral' => ChallengeKind.referral,
        'photo' => ChallengeKind.photo,
        _ => ChallengeKind.text,
      };

  /// True where completing the challenge stores something the student typed
  /// or scanned — which is also where an answer can be edited afterwards.
  bool get storesAnswer =>
      this != ChallengeKind.link &&
      this != ChallengeKind.referral &&
      this != ChallengeKind.telegramBot;
}

/// One Orientation Week challenge.
///
/// These are the tasks that could not be a Bingo square or a Photo Quest,
/// because completing them means *entering something*: a scan, a year, a
/// name, a handle.
class OrientationChallenge {
  const OrientationChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.rewardTokens,
    this.rule,
    this.iconKey,
    this.prompt,
    this.hint,
    this.multiline = false,
    this.link,
    this.linkLabel,
    this.verifyNote,
    this.answer,
    this.apiKind,
    this.visibleFrom,
    this.groupKey,
  });

  final String id;
  final String title;
  final String description;
  final ChallengeKind kind;
  final int rewardTokens;

  /// [ChallengeKind.qrScan] only — what a scanned student has to satisfy.
  final QrScanRule? rule;

  /// Name from `AppIcons`, resolved by the presentation layer.
  final String? iconKey;

  /// The input's label ("Year NU was founded").
  final String? prompt;

  /// Placeholder text ("e.g. 2010").
  final String? hint;

  /// A fact needs room; a year does not.
  final bool multiline;

  final String? link;
  final String? linkLabel;

  /// The honest statement of what will and will not be checked, shown under
  /// the input. Everything typed into a challenge is verified by a person at
  /// the prize desk, not by the app — saying so up front is the difference
  /// between a task and a trick.
  final String? verifyNote;

  /// What the student stored, overlaid per student by the repository. Null
  /// means the challenge is still open.
  final String? answer;

  /// Server kind (`text`, `handle`, `venue_qr`, `photo`, …).
  final String? apiKind;

  /// When this daily task became visible. Null = always-on.
  final DateTime? visibleFrom;

  /// Filter chip key from the API (`general`, `today`, `photo`, `qr`, …).
  /// Unknown keys still render as chips so a new type does not need an app release.
  final String? groupKey;

  bool get isComplete => answer != null && answer!.isNotEmpty;

  String get group {
    final raw = groupKey?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    if (kind == ChallengeKind.photo) return 'photo';
    if (kind == ChallengeKind.qrScan) return 'qr';
    if (visibleFrom != null) return 'today';
    return 'general';
  }

  ClubFairTaskGroup get taskGroup => switch (group) {
        'photo' => ClubFairTaskGroup.photo,
        'qr' => ClubFairTaskGroup.qr,
        'today' => ClubFairTaskGroup.today,
        'clubs' => ClubFairTaskGroup.clubs,
        _ => ClubFairTaskGroup.general,
      };

  OrientationChallenge withAnswer(String? value) => OrientationChallenge(
        id: id,
        title: title,
        description: description,
        kind: kind,
        rewardTokens: rewardTokens,
        rule: rule,
        iconKey: iconKey,
        prompt: prompt,
        hint: hint,
        multiline: multiline,
        link: link,
        linkLabel: linkLabel,
        verifyNote: verifyNote,
        answer: value,
        apiKind: apiKind,
        visibleFrom: visibleFrom,
        groupKey: groupKey,
      );

  /// Normalises what gets stored so two students who typed the same thing
  /// differently are not recorded differently.
  ///
  /// Handles lose a leading `@` and their case; everything else is trimmed and
  /// has its internal whitespace collapsed. Returns null for an empty answer,
  /// which is what reopens a challenge.
  String? normaliseAnswer(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return null;
    if (kind != ChallengeKind.handle) return trimmed;

    final handle = trimmed.replaceAll(RegExp(r'^@+'), '').toLowerCase();
    return handle.isEmpty ? null : '@$handle';
  }
}

/// Progress across the challenge list.
class ChallengeProgress {
  const ChallengeProgress({
    required this.completed,
    required this.total,
    required this.tokensEarned,
    required this.tokensAvailable,
  });

  factory ChallengeProgress.from(List<OrientationChallenge> challenges) {
    var earned = 0;
    var available = 0;
    for (final challenge in challenges) {
      available += challenge.rewardTokens;
      if (challenge.isComplete) earned += challenge.rewardTokens;
    }
    return ChallengeProgress(
      completed: challenges.where((c) => c.isComplete).length,
      total: challenges.length,
      tokensEarned: earned,
      tokensAvailable: available,
    );
  }

  final int completed;
  final int total;
  final int tokensEarned;
  final int tokensAvailable;

  int get remaining => total - completed;

  double get fraction => total == 0 ? 0 : (completed / total).clamp(0, 1).toDouble();
}

/// How Club Fair tasks are grouped on the Tasks tab.
enum ClubFairTaskGroup { general, today, clubs, photo, qr }
