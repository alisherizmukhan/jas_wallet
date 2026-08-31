/// One booth on the Club Fair programme (atrium schedule).
class ClubFairClubItem {
  const ClubFairClubItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.inQuest,
    required this.scanned,
    required this.qrLive,
    required this.rewardTokens,
    this.standDate,
  });

  final String id;
  final String name;
  final DateTime? standDate;
  final String slot;
  final bool inQuest;
  final bool scanned;
  final bool qrLive;
  final int rewardTokens;
}

/// Clubs sharing one day + time block (morning 11–14 / afternoon 15–18 / always).
class ClubFairSlotGroup {
  const ClubFairSlotGroup({
    required this.slot,
    required this.clubs,
    this.standDate,
  });

  final DateTime? standDate;
  final String slot;
  final List<ClubFairClubItem> clubs;
}
