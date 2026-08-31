/// One quest club in the global unique-scan ranking.
class ClubFairClubRank {
  const ClubFairClubRank({
    required this.rank,
    required this.id,
    required this.name,
    required this.scans,
    required this.slot,
    this.standDate,
  });

  final int rank;
  final String id;
  final String name;
  final int scans;
  final String slot;
  final DateTime? standDate;
}

class ClubFairClubRanking {
  const ClubFairClubRanking({
    required this.totalScans,
    required this.clubs,
  });

  final int totalScans;
  final List<ClubFairClubRank> clubs;
}
