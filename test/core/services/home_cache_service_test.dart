import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/home_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── Events ────────────────────────────────────────────────────────────────

  group('HomeCacheService — events', () {
    test('returns null when nothing has been saved', () async {
      expect(await HomeCacheService.loadEventsJson(), isNull);
    });

    test('round-trips a JSON string', () async {
      const json = '[{"title":"Test","date":"Mon","venue":"Hall"}]';
      await HomeCacheService.saveEventsJson(json);
      expect(await HomeCacheService.loadEventsJson(), equals(json));
    });

    test('overwrites previous value', () async {
      await HomeCacheService.saveEventsJson('["old"]');
      await HomeCacheService.saveEventsJson('["new"]');
      expect(await HomeCacheService.loadEventsJson(), equals('["new"]'));
    });

    test('returns null when stored JSON is corrupt', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('home_cache_events_json', '{not valid json}}');
      await prefs.setString(
          'home_cache_events_at', DateTime.now().toIso8601String());
      expect(await HomeCacheService.loadEventsJson(), isNull);
    });

    test('returns null after TTL expires', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('home_cache_events_json', '[]');
      await prefs.setString(
        'home_cache_events_at',
        DateTime.now()
            .subtract(HomeCacheService.eventsTtl + const Duration(seconds: 1))
            .toIso8601String(),
      );
      expect(await HomeCacheService.loadEventsJson(), isNull);
    });

    test('returns data when within TTL', () async {
      const json = '[]';
      await HomeCacheService.saveEventsJson(json);
      expect(await HomeCacheService.loadEventsJson(), equals(json));
    });
  });

  // ── Weather ───────────────────────────────────────────────────────────────

  group('HomeCacheService — weather', () {
    test('returns null when nothing has been saved', () async {
      expect(await HomeCacheService.loadWeatherJson(), isNull);
    });

    test('round-trips a JSON string', () async {
      const json = '{"temperature":20.0,"windSpeed":5.0,"weatherCode":0}';
      await HomeCacheService.saveWeatherJson(json);
      expect(await HomeCacheService.loadWeatherJson(), equals(json));
    });

    test('returns null after TTL expires', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('home_cache_weather_json', '{}');
      await prefs.setString(
        'home_cache_weather_at',
        DateTime.now()
            .subtract(HomeCacheService.weatherTtl + const Duration(seconds: 1))
            .toIso8601String(),
      );
      expect(await HomeCacheService.loadWeatherJson(), isNull);
    });
  });

  // ── Exchange ──────────────────────────────────────────────────────────────

  group('HomeCacheService — exchange', () {
    test('returns null when nothing has been saved', () async {
      expect(await HomeCacheService.loadExchangeJson(), isNull);
    });

    test('round-trips a JSON string', () async {
      const json = '{"usdToKzt":450.0,"eurToKzt":490.0}';
      await HomeCacheService.saveExchangeJson(json);
      expect(await HomeCacheService.loadExchangeJson(), equals(json));
    });

    test('returns null after TTL expires', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('home_cache_exchange_json', '{}');
      await prefs.setString(
        'home_cache_exchange_at',
        DateTime.now()
            .subtract(
                HomeCacheService.exchangeTtl + const Duration(seconds: 1))
            .toIso8601String(),
      );
      expect(await HomeCacheService.loadExchangeJson(), isNull);
    });
  });

  // ── Stories ───────────────────────────────────────────────────────────────

  group('HomeCacheService — stories', () {
    test('returns null when nothing has been saved', () async {
      expect(await HomeCacheService.loadStoriesJson(), isNull);
    });

    test('round-trips a JSON string', () async {
      const json = '[{"id":"s-1","authorId":"org","authorName":"Org",'
          '"mediaUrl":"https://x.com/a.jpg","mediaType":"image",'
          '"createdAt":"2025-01-01T00:00:00.000","expiresAt":"2025-12-31T00:00:00.000",'
          '"isViewed":false,"textOverlays":[],"drawings":[],"duration":7,'
          '"isAsset":false}]';
      await HomeCacheService.saveStoriesJson(json);
      expect(await HomeCacheService.loadStoriesJson(), equals(json));
    });

    test('returns null after TTL expires', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('home_cache_stories_json', '[]');
      await prefs.setString(
        'home_cache_stories_at',
        DateTime.now()
            .subtract(HomeCacheService.storiesTtl + const Duration(seconds: 1))
            .toIso8601String(),
      );
      expect(await HomeCacheService.loadStoriesJson(), isNull);
    });

    test('returns data when within TTL', () async {
      const json = '[]';
      await HomeCacheService.saveStoriesJson(json);
      expect(await HomeCacheService.loadStoriesJson(), equals(json));
    });
  });

  // ── clearAll ──────────────────────────────────────────────────────────────

  group('HomeCacheService.clearAll', () {
    test('removes events, weather, exchange, and stories cache', () async {
      await HomeCacheService.saveEventsJson('[]');
      await HomeCacheService.saveWeatherJson('{}');
      await HomeCacheService.saveExchangeJson('{}');
      await HomeCacheService.saveStoriesJson('[]');

      await HomeCacheService.clearAll();

      expect(await HomeCacheService.loadEventsJson(), isNull);
      expect(await HomeCacheService.loadWeatherJson(), isNull);
      expect(await HomeCacheService.loadExchangeJson(), isNull);
      expect(await HomeCacheService.loadStoriesJson(), isNull);
    });

    test('does not affect non-home SharedPreferences keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('some_other_key', true);
      await HomeCacheService.saveEventsJson('[]');

      await HomeCacheService.clearAll();

      // Unrelated key must survive.
      expect(prefs.getBool('some_other_key'), isTrue);
    });

    test('is safe to call when cache is already empty', () async {
      expect(() async => HomeCacheService.clearAll(), returnsNormally);
    });
  });
}
