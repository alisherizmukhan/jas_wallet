/// Time range filter for access statistics.
enum AccessStatsPeriod { today, week, month, allTime }

/// Computed access statistics for a given period.
class AccessStats {
  const AccessStats({
    required this.period,
    required this.total,
    required this.timestamps,
  });

  final AccessStatsPeriod period;
  final int total;
  final List<DateTime> timestamps;

  factory AccessStats.empty(AccessStatsPeriod period) =>
      AccessStats(period: period, total: 0, timestamps: const []);
}
