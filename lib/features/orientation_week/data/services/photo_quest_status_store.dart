import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/photo_mission.dart';

/// Remembers the verification status each mission had the last time the app
/// looked at it.
///
/// A moderator can approve a photo hours after it was submitted, quite
/// possibly while the app is closed. Without a persisted snapshot the app has
/// nothing to compare the fresh server state against on next launch, so the
/// decision would either be announced on every single start or never at all.
/// Persisting the last-seen status makes each transition fire exactly once.
class PhotoQuestStatusStore {
  const PhotoQuestStatusStore();

  static const _key = 'orientation_pq_last_seen_status_v1';

  /// Mission id → the status this device has already reacted to. Empty on a
  /// first run, which the watcher treats as "record, announce nothing".
  Future<Map<String, MissionStatus>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const {};

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};

      final result = <String, MissionStatus>{};
      for (final entry in decoded.entries) {
        final status = _statusByName(entry.value);
        if (status != null) result[entry.key.toString()] = status;
      }
      return result;
    } catch (_) {
      // A corrupt snapshot must not break Photo Quest — the worst case of
      // starting over is one missed announcement, never a crash.
      return const {};
    }
  }

  Future<void> write(Map<String, MissionStatus> statuses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, String>{
        for (final entry in statuses.entries) entry.key: entry.value.name,
      };
      await prefs.setString(_key, jsonEncode(encoded));
    } catch (_) {}
  }

  /// Called on sign-out — the next student on this device must not inherit
  /// the previous one's snapshot.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  static MissionStatus? _statusByName(Object? raw) {
    if (raw is! String) return null;
    for (final status in MissionStatus.values) {
      if (status.name == raw) return status;
    }
    return null;
  }
}
