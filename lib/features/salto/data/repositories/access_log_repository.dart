import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/access_attempt_log.dart';

/// Persists successful turnstile access timestamps in SharedPreferences.
///
/// Each entry is stored as an ISO-8601 string in a JSON list.
/// Old entries beyond [_retentionDays] are pruned on every write.
///
/// Storage keys are scoped per [userId] when one is supplied, so a second
/// account on a shared device never sees a previous user's access history.
/// The legacy unscoped keys (used before per-user scoping existed) are still
/// read/written when [userId] is null, and are always included when clearing
/// so no cross-account data can be left behind after a login/logout cycle.
class AccessLogRepository {
  AccessLogRepository({this.userId});

  /// The currently authenticated user's ID, or null if unauthenticated /
  /// not yet known. When non-null, storage keys are namespaced by it.
  final String? userId;

  static const _legacyKey = 'salto_access_log';
  static const _legacyAttemptsKey = 'salto_access_attempts';
  static const _retentionDays = 90;

  String get _key => userId == null ? _legacyKey : '${_legacyKey}_$userId';
  String get _attemptsKey =>
      userId == null ? _legacyAttemptsKey : '${_legacyAttemptsKey}_$userId';

  Future<List<DateTime>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .map((s) => DateTime.tryParse(s))
        .whereType<DateTime>()
        .toList()
      ..sort();
  }

  Future<void> recordAccess([DateTime? timestamp]) async {
    final now = timestamp ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    raw.add(now.toIso8601String());

    // Prune entries older than retention window.
    final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));
    final pruned = raw.where((s) {
      final dt = DateTime.tryParse(s);
      return dt != null && dt.isAfter(cutoff);
    }).toList();

    await prefs.setStringList(_key, pruned);
  }

  // ── Attempt Log (every try, not just successes) ───────────────────────

  Future<List<AccessAttemptLog>> getAllAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attemptsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final all = AccessAttemptLog.decodeList(raw);
      all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return all;
    } catch (_) {
      return const [];
    }
  }

  Future<void> recordAttempt(AccessAttemptLog attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attemptsKey);
    List<AccessAttemptLog> all;
    try {
      all = (raw != null && raw.isNotEmpty)
          ? AccessAttemptLog.decodeList(raw)
          : [];
    } catch (_) {
      all = [];
    }

    all.add(attempt);

    // Prune entries older than retention window.
    final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));
    all.removeWhere((a) => a.timestamp.isBefore(cutoff));

    await prefs.setString(_attemptsKey, AccessAttemptLog.encodeList(all));
  }

  /// Clears every access log entry reachable from this instance: the
  /// (possibly per-user-scoped) success log and attempt log for [userId],
  /// plus the legacy unscoped keys so no data from before per-user scoping
  /// existed survives a logout/account-deletion cycle.
  Future<void> clearAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey);
    await prefs.remove(_key);
    await prefs.remove(_legacyAttemptsKey);
    await prefs.remove(_legacyKey);
  }
}
