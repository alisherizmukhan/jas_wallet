import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../data/repositories/access_log_repository.dart';
import '../../domain/access_attempt_log.dart';
import '../../domain/access_stats.dart';

/// Scoped to the current user so a second account on a shared device never
/// reads or writes a previous user's access history.
final accessLogRepositoryProvider = Provider<AccessLogRepository>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.userId));
  return AccessLogRepository(userId: userId);
});

/// Holds the current period selection.
///
/// autoDispose: this is scoped to the dedicated Access Stats page — once the
/// user leaves it, there's no reason to keep the selection (or the stats
/// providers below that depend on it) alive for the rest of the app session.
final accessStatsPeriodProvider = StateProvider.autoDispose<AccessStatsPeriod>(
  (ref) => AccessStatsPeriod.today,
);

/// Loads access log and computes stats for the selected period.
final accessStatsProvider = FutureProvider.autoDispose<AccessStats>((ref) async {
  final period = ref.watch(accessStatsPeriodProvider);
  final repo = ref.read(accessLogRepositoryProvider);
  final all = await repo.getAll();

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  late final DateTime cutoff;
  switch (period) {
    case AccessStatsPeriod.today:
      cutoff = startOfDay;
      break;
    case AccessStatsPeriod.week:
      cutoff = startOfDay.subtract(Duration(days: now.weekday - 1));
      break;
    case AccessStatsPeriod.month:
      cutoff = DateTime(now.year, now.month, 1);
      break;
    case AccessStatsPeriod.allTime:
      cutoff = DateTime(2000);
      break;
  }

  final filtered = all.where((dt) => !dt.isBefore(cutoff)).toList();

  return AccessStats(
    period: period,
    total: filtered.length,
    timestamps: filtered,
  );
});

/// Total access count (all time) — used for gamification badge on access page.
final totalAccessCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.read(accessLogRepositoryProvider);
  final all = await repo.getAll();
  return all.length;
});

/// All attempt logs (every try, with detailed logs) for the selected period.
final accessAttemptsProvider =
    FutureProvider.autoDispose<List<AccessAttemptLog>>((ref) async {
  final period = ref.watch(accessStatsPeriodProvider);
  final repo = ref.read(accessLogRepositoryProvider);
  final all = await repo.getAllAttempts();

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  late final DateTime cutoff;
  switch (period) {
    case AccessStatsPeriod.today:
      cutoff = startOfDay;
      break;
    case AccessStatsPeriod.week:
      cutoff = startOfDay.subtract(Duration(days: now.weekday - 1));
      break;
    case AccessStatsPeriod.month:
      cutoff = DateTime(now.year, now.month, 1);
      break;
    case AccessStatsPeriod.allTime:
      cutoff = DateTime(2000);
      break;
  }

  return all.where((a) => !a.timestamp.isBefore(cutoff)).toList();
});
