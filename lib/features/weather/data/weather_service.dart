import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/entities/weather_data.dart';

/// Fetches weather data from Open-Meteo API.
/// Singleton with in-memory caching — fetches once per session.
class WeatherService {
  WeatherService._();

  @visibleForTesting
  WeatherService.forTesting() : this._();

  static final instance = WeatherService._();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Astana coordinates
  static const _lat = 51.1694;
  static const _lon = 71.4491;

  WeatherData? _cache;
  Future<WeatherData>? _pending;

  Future<WeatherData> fetchWeather() {
    if (_cache != null) return Future.value(_cache);
    return _pending ??= _fetch().then((data) {
      _cache = data;
      _pending = null;
      return data;
    }).catchError((Object e) {
      _pending = null;
      throw e;
    });
  }

  Future<WeatherData> _fetch() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': _lat,
        'longitude': _lon,
        'current':
            'temperature_2m,weather_code,wind_speed_10m,apparent_temperature,'
            'relative_humidity_2m,surface_pressure,precipitation,uv_index',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,'
            'precipitation_sum,wind_speed_10m_max,uv_index_max,'
            'sunrise,sunset',
        'timezone': 'Asia/Almaty',
        'forecast_days': 7,
      },
    );

    final json = response.data!;
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final dates = (daily['time'] as List).cast<String>();
    final maxTemps = (daily['temperature_2m_max'] as List).cast<num>();
    final minTemps = (daily['temperature_2m_min'] as List).cast<num>();
    final codes = (daily['weather_code'] as List).cast<int>();
    final precipSums = (daily['precipitation_sum'] as List?)?.cast<num>();
    final windMaxes = (daily['wind_speed_10m_max'] as List?)?.cast<num>();
    final uvMaxes = (daily['uv_index_max'] as List?)?.cast<num>();
    final sunrises = (daily['sunrise'] as List?)?.cast<String>();
    final sunsets = (daily['sunset'] as List?)?.cast<String>();

    final forecast = <DailyForecast>[];
    for (var i = 0; i < dates.length; i++) {
      forecast.add(DailyForecast(
        date: DateTime.parse(dates[i]),
        max: maxTemps[i].toDouble(),
        min: minTemps[i].toDouble(),
        weatherCode: codes[i],
        condition: mapWeatherCode(codes[i]),
        precipitationSum: precipSums?[i].toDouble(),
        windSpeedMax: windMaxes?[i].toDouble(),
        uvIndexMax: uvMaxes?[i].toDouble(),
        sunrise: sunrises?[i],
        sunset: sunsets?[i],
      ));
    }

    final currentCode = (current['weather_code'] as num).toInt();

    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: currentCode,
      condition: mapWeatherCode(currentCode),
      forecast: forecast,
      apparentTemperature:
          (current['apparent_temperature'] as num?)?.toDouble(),
      humidity: (current['relative_humidity_2m'] as num?)?.toInt(),
      pressure: (current['surface_pressure'] as num?)?.toDouble(),
      precipitation: (current['precipitation'] as num?)?.toDouble(),
      uvIndex: (current['uv_index'] as num?)?.toDouble(),
    );
  }

  void refresh() {
    _cache = null;
    _pending = null;
  }

  /// Maps WMO weather interpretation codes to human-readable strings.
  static String mapWeatherCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Fog';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Unknown';
  }

  /// Maps WMO weather code to an emoji icon for display.
  static String weatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 57) return '🌦️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌧️';
    if (code <= 86) return '🌨️';
    if (code >= 95) return '⛈️';
    return '🌡️';
  }
}
