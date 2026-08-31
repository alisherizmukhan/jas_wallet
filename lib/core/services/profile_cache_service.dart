import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight SharedPreferences-based cache for profile resume sections.
///
/// Each section stores its data as a JSON-encoded string list.
/// On successful API fetch, call [save]. On network failure, call [load].
class ProfileCacheService {
  ProfileCacheService._();

  static const _prefix = 'profile_cache_';

  static String _key(String section) => '$_prefix$section';
  static String _atKey(String section) => '$_prefix${section}_at';

  // ─── User profile (single object) ────────────────────────────────────

  static const _userKey = '${_prefix}user';

  /// Persist the current user profile as a JSON map.
  static Future<void> saveUser(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userJson));
  }

  /// Load the previously cached user profile, or `null` if absent.
  static Future<Map<String, dynamic>?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─── Section lists ───────────────────────────────────────────────────

  /// Persist a list of JSON-encodable maps, timestamped for TTL freshness
  /// checks via [loadEntry].
  static Future<void> save(
    String section,
    List<Map<String, dynamic>> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(section), jsonEncode(items));
    await prefs.setString(_atKey(section), DateTime.now().toIso8601String());
  }

  /// Load the previously cached list, or `null` if nothing was stored.
  /// Age-agnostic — used as an offline fallback on network failure.
  static Future<List<Map<String, dynamic>>?> load(String section) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(section));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  /// Stale-inclusive read with a freshness flag, for stale-while-revalidate
  /// callers: render [items] immediately, and only re-fetch from the network
  /// when `isFresh` is false. Returns `null` only when nothing is cached yet.
  static Future<({List<Map<String, dynamic>> items, bool isFresh})?> loadEntry(
    String section,
    Duration ttl,
  ) async {
    final items = await load(section);
    if (items == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final atStr = prefs.getString(_atKey(section));
    final storedAt = atStr != null ? DateTime.tryParse(atStr) : null;
    final isFresh =
        storedAt != null && DateTime.now().difference(storedAt) <= ttl;
    return (items: items, isFresh: isFresh);
  }

  /// Remove cached data for a section.
  static Future<void> clear(String section) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(section));
    await prefs.remove(_atKey(section));
  }

  /// Clear all profile cache sections (e.g. on logout).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
