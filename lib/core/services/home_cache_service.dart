import 'dart:convert';
import 'dart:math' show Random;

import 'package:shared_preferences/shared_preferences.dart';

/// A cached JSON payload plus its freshness relative to the feature's TTL.
///
/// Stale entries are still returned so the UI can render instantly and
/// offline — the TTL gates *refreshing*, never *displaying*.
class CacheEntry {
  const CacheEntry({required this.json, required this.isFresh});

  final String json;
  final bool isFresh;
}

/// Generic SharedPreferences-backed JSON cache with TTL for Home features.
///
/// Stores raw JSON strings — serialization is the responsibility of each
/// feature provider. This keeps the service free of feature dependencies
/// and safely placed in the core layer.
///
/// Two read styles:
///  • `loadXJson()` — returns null when past TTL (legacy behaviour).
///  • `loadXEntry()` — returns stale data too, flagged via [CacheEntry.isFresh],
///    for stale-while-revalidate consumers.
///
/// Call [clearAll] on logout to prevent stale data leaking across accounts.
class HomeCacheService {
  HomeCacheService._();

  static const _prefix = 'home_cache_';

  // ─── Keys ────────────────────────────────────────────────────────────

  static const _keyEventsJson = '${_prefix}events_json';
  static const _keyEventsAt = '${_prefix}events_at';
  static const _keyWeatherJson = '${_prefix}weather_json';
  static const _keyWeatherAt = '${_prefix}weather_at';
  static const _keyExchangeJson = '${_prefix}exchange_json';
  static const _keyExchangeAt = '${_prefix}exchange_at';

  // ─── TTLs ─────────────────────────────────────────────────────────────

  static const eventsTtl = Duration(hours: 6);
  static const weatherTtl = Duration(hours: 1);
  static const exchangeTtl = Duration(hours: 1);

  // ─── Events ──────────────────────────────────────────────────────────

  static Future<String?> loadEventsJson() =>
      _load(_keyEventsJson, _keyEventsAt, eventsTtl);

  static Future<void> saveEventsJson(String json) =>
      _save(_keyEventsJson, _keyEventsAt, json);

  // ─── Weather ─────────────────────────────────────────────────────────

  static Future<String?> loadWeatherJson() =>
      _load(_keyWeatherJson, _keyWeatherAt, weatherTtl);

  static Future<void> saveWeatherJson(String json) =>
      _save(_keyWeatherJson, _keyWeatherAt, json);

  // ─── Exchange ─────────────────────────────────────────────────────────

  static Future<String?> loadExchangeJson() =>
      _load(_keyExchangeJson, _keyExchangeAt, exchangeTtl);

  static Future<void> saveExchangeJson(String json) =>
      _save(_keyExchangeJson, _keyExchangeAt, json);

  // ─── Stories ──────────────────────────────────────────────────────────

  static const _keyStoriesJson = '${_prefix}stories_json';
  static const _keyStoriesAt = '${_prefix}stories_at';

  /// Stories are long-lived university announcements; urgent ones arrive via
  /// push. The TTL only gates the silent background refresh — stale stories
  /// keep rendering instantly (see [loadStoriesEntry]).
  ///
  /// Jittered ±30 min, chosen once per app session (not per read — the value
  /// is cached after first access), so a campus-wide broadcast push that
  /// wakes many devices at once doesn't also line every device's TTL
  /// boundary up on the same instant.
  static final storiesTtl =
      const Duration(hours: 12) + Duration(seconds: Random().nextInt(3601) - 1800);

  static Future<String?> loadStoriesJson() =>
      _load(_keyStoriesJson, _keyStoriesAt, storiesTtl);

  /// Stale-inclusive read for the stories SWR flow.
  static Future<CacheEntry?> loadStoriesEntry() =>
      _loadEntry(_keyStoriesJson, _keyStoriesAt, storiesTtl);

  static Future<void> saveStoriesJson(String json) =>
      _save(_keyStoriesJson, _keyStoriesAt, json);

  // ─── Story publisher organizations ────────────────────────────────────

  static const _keyStoryOrgsJson = '${_prefix}story_orgs_json';
  static const _keyStoryOrgsAt = '${_prefix}story_orgs_at';

  /// Which organizations the user can publish for changes very rarely
  /// (staff/club-admin membership).
  static const storyOrgsTtl = Duration(hours: 24);

  static Future<CacheEntry?> loadStoryOrgsEntry() =>
      _loadEntry(_keyStoryOrgsJson, _keyStoryOrgsAt, storyOrgsTtl);

  static Future<void> saveStoryOrgsJson(String json) =>
      _save(_keyStoryOrgsJson, _keyStoryOrgsAt, json);

  // ─── Logout cleanup ───────────────────────────────────────────────────

  /// Remove all home feature caches. Call on every logout path.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // ─── Internal helpers ─────────────────────────────────────────────────

  static Future<String?> _load(
    String jsonKey,
    String atKey,
    Duration ttl,
  ) async {
    final entry = await _loadEntry(jsonKey, atKey, ttl);
    return (entry != null && entry.isFresh) ? entry.json : null;
  }

  static Future<CacheEntry?> _loadEntry(
    String jsonKey,
    String atKey,
    Duration ttl,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(jsonKey);
      final atStr = prefs.getString(atKey);
      if (raw == null || raw.isEmpty || atStr == null) return null;

      final storedAt = DateTime.tryParse(atStr);
      if (storedAt == null) return null;

      // Quick parse validation — don't return corrupt JSON.
      jsonDecode(raw);
      return CacheEntry(
        json: raw,
        isFresh: DateTime.now().difference(storedAt) <= ttl,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _save(
    String jsonKey,
    String atKey,
    String json,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(jsonKey, json);
    await prefs.setString(atKey, DateTime.now().toIso8601String());
  }
}
