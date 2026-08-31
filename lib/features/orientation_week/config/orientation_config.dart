import '../../../core/services/orientation_trusted_clock.dart';

/// Orientation Week scheduling constants — mirrors the shape of
/// `lib/features/sos/config/sos_config.dart` for feature-local config.
///
/// Club Fair 2026 — Sunday 23 Aug through Thursday 27 Aug (Astana).
abstract class OrientationConfig {
  static final DateTime weekStart = DateTime(2026, 8, 23);
  static final DateTime weekEnd = DateTime(2026, 8, 27, 23, 59, 59);

  static const int totalDays = 5;

  /// Feature flag for the Hub entry point. Flip to `false` to hide
  /// Orientation Week without removing code, e.g. outside the pilot cohort.
  static const bool isEnabled = true;

  /// Astana is a fixed UTC+5 offset — no DST — so the close date can be
  /// pinned to an exact instant rather than "whatever the device's time
  /// zone happens to say".
  static const Duration _astanaOffset = Duration(hours: 5);

  /// [utc] rendered as Astana wall-clock time, for display only — every
  /// comparison ([isClosed], [closeDateUtc]) stays in UTC internally. Takes
  /// any [DateTime] (converts to UTC first) so a caller can't pass a
  /// device-local value and get a silently double-shifted result.
  static DateTime toAstana(DateTime utc) => utc.toUtc().add(_astanaOffset);

  /// How long after [weekEnd]'s calendar date the feature stays reachable
  /// before it locks for good — covers last-minute prize claims etc.
  /// Prize-claim window after Thursday: locks the following Thursday.
  static const Duration closeGracePeriod = Duration(days: 7);

  /// The instant, in UTC, at which Orientation Week becomes permanently
  /// unavailable: 00:00 Astana time, [closeGracePeriod] after [weekEnd]'s
  /// calendar date.
  static DateTime get closeDateUtc {
    final closeDay = DateTime(weekEnd.year, weekEnd.month, weekEnd.day).add(closeGracePeriod);
    return DateTime.utc(closeDay.year, closeDay.month, closeDay.day).subtract(_astanaOffset);
  }

  /// True once the feature has locked. Backed by [OrientationTrustedClock]
  /// rather than the device clock directly, so rewinding the device's date
  /// can't be used to keep the section open (or reopen it) past this point.
  ///
  /// Once true, nothing in Orientation Week should read from the network —
  /// see `OrientationClosedPage` and the router's `/orientation*` redirect.
  static bool get isClosed => !OrientationTrustedClock.instance.now().isBefore(closeDateUtc);

  /// Current day of the week, clamped to `1..totalDays` so the UI never
  /// shows "Day 0" or "Day 9" before/after the actual window.
  static int currentDay([DateTime? now]) {
    final today = now ?? DateTime.now();
    final elapsed = today.difference(weekStart).inDays + 1;
    return elapsed.clamp(1, totalDays);
  }

  static Duration timeRemaining([DateTime? now]) {
    final today = now ?? DateTime.now();
    final remaining = weekEnd.difference(today);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
