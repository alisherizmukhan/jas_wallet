// ignore_for_file: empty_catches
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/home_cache_service.dart';
import '../../data/weather_service.dart';
import '../../domain/entities/weather_data.dart';

// ─── Testable service provider ────────────────────────────────────────────────

final weatherServiceProvider = Provider<WeatherService>(
  (ref) => WeatherService.instance,
);

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// State is nullable: [null] means no data available (offline + no cache).
class WeatherNotifier extends StateNotifier<AsyncValue<WeatherData?>> {
  WeatherNotifier(this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  final WeatherService _service;
  bool _isFetching = false;

  Future<void> _init() async {
    // 1. Load from persistent cache — instant, no network.
    // loadWeatherJson returns null past the TTL, so non-null == fresh.
    final json = await HomeCacheService.loadWeatherJson();
    if (!mounted) return;
    if (json != null) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        state = AsyncValue.data(_fromJson(map));
        // 2. Fresh cache — skip the startup fetch entirely; the next fetch
        // happens when the TTL lapses or the user pulls to refresh.
        return;
      } catch (e) {
      }
    }

    // 3. No fresh cache: background network refresh.
    unawaited(_fetch(fromInit: true));
  }

  Future<void> _fetch({bool fromInit = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      _service.refresh(); // clear in-memory singleton cache
      final data = await _service.fetchWeather();
      if (!mounted) return;
      await HomeCacheService.saveWeatherJson(jsonEncode(_toJson(data)));
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (!mounted) return;
      if (state is AsyncLoading) {
        // No cached data available — surface error so card can show retry.
        state = AsyncValue.error(e, st);
      }
      // else: stale cache remains visible — network failure is silent in UI.
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => _fetch();

  // ─── JSON helpers ──────────────────────────────────────────────────────

  static Map<String, dynamic> _toJson(WeatherData w) => {
        'temperature': w.temperature,
        'windSpeed': w.windSpeed,
        'weatherCode': w.weatherCode,
        'condition': w.condition,
        'forecast': w.forecast.map(_forecastToJson).toList(),
        if (w.apparentTemperature != null)
          'apparentTemperature': w.apparentTemperature,
        if (w.humidity != null) 'humidity': w.humidity,
        if (w.pressure != null) 'pressure': w.pressure,
        if (w.uvIndex != null) 'uvIndex': w.uvIndex,
        if (w.precipitation != null) 'precipitation': w.precipitation,
      };

  static WeatherData _fromJson(Map<String, dynamic> j) => WeatherData(
        temperature: (j['temperature'] as num).toDouble(),
        windSpeed: (j['windSpeed'] as num).toDouble(),
        weatherCode: (j['weatherCode'] as num).toInt(),
        condition: j['condition'] as String,
        forecast: (j['forecast'] as List<dynamic>)
            .map((e) => _forecastFromJson(e as Map<String, dynamic>))
            .toList(),
        apparentTemperature:
            (j['apparentTemperature'] as num?)?.toDouble(),
        humidity: (j['humidity'] as num?)?.toInt(),
        pressure: (j['pressure'] as num?)?.toDouble(),
        uvIndex: (j['uvIndex'] as num?)?.toDouble(),
        precipitation: (j['precipitation'] as num?)?.toDouble(),
      );

  static Map<String, dynamic> _forecastToJson(DailyForecast f) => {
        'date': f.date.toIso8601String(),
        'min': f.min,
        'max': f.max,
        'condition': f.condition,
        'weatherCode': f.weatherCode,
        if (f.precipitationSum != null) 'precipitationSum': f.precipitationSum,
        if (f.windSpeedMax != null) 'windSpeedMax': f.windSpeedMax,
        if (f.uvIndexMax != null) 'uvIndexMax': f.uvIndexMax,
        if (f.sunrise != null) 'sunrise': f.sunrise,
        if (f.sunset != null) 'sunset': f.sunset,
      };

  static DailyForecast _forecastFromJson(Map<String, dynamic> j) =>
      DailyForecast(
        date: DateTime.parse(j['date'] as String),
        min: (j['min'] as num).toDouble(),
        max: (j['max'] as num).toDouble(),
        condition: j['condition'] as String,
        weatherCode: (j['weatherCode'] as num).toInt(),
        precipitationSum: (j['precipitationSum'] as num?)?.toDouble(),
        windSpeedMax: (j['windSpeedMax'] as num?)?.toDouble(),
        uvIndexMax: (j['uvIndexMax'] as num?)?.toDouble(),
        sunrise: j['sunrise'] as String?,
        sunset: j['sunset'] as String?,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, AsyncValue<WeatherData?>>(
  (ref) => WeatherNotifier(ref.watch(weatherServiceProvider)),
);
