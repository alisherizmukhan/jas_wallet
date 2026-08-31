import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Single-slot offline queue for a profile PUT payload that failed to reach
/// the backend due to a connectivity error.
///
/// Only the most recent failed attempt is kept — later edits always
/// supersede earlier ones, so there is never a reason to replay more than
/// one queued write. A successful sync (manual retry or the automatic
/// reconnect flush) clears the slot; the app never surfaces a "queued"
/// state in the UI, this is purely a best-effort backstop so a save that
/// failed only because the network blipped isn't lost if the user doesn't
/// notice the error toast or backgrounds the app before retrying.
class ProfilePendingEditService {
  ProfilePendingEditService._();

  static const _payloadKey = 'profile_pending_edit_payload';
  static const _atKey = 'profile_pending_edit_at';

  /// Queued edits older than this are considered abandoned and discarded
  /// rather than silently resurfacing a long-stale change.
  static const maxAge = Duration(hours: 24);

  static Future<void> save(Map<String, dynamic> payload) async {
    if (payload.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_payloadKey, jsonEncode(payload));
    await prefs.setString(_atKey, DateTime.now().toIso8601String());
  }

  /// Returns the queued payload, or `null` if none is pending or it has
  /// expired (an expired entry is also cleared).
  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_payloadKey);
    final atStr = prefs.getString(_atKey);
    if (raw == null || raw.isEmpty || atStr == null) return null;

    final storedAt = DateTime.tryParse(atStr);
    if (storedAt == null || DateTime.now().difference(storedAt) > maxAge) {
      await clear();
      return null;
    }

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_payloadKey);
    await prefs.remove(_atKey);
  }
}
