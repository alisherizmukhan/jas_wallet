import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/weather/data/weather_service.dart';

void main() {
  // ── WeatherService.mapWeatherCode ─────────────────────────────────────────

  group('WeatherService.mapWeatherCode', () {
    test('code 0 → Clear', () {
      expect(WeatherService.mapWeatherCode(0), 'Clear');
    });

    test('codes 1–3 → Partly cloudy', () {
      expect(WeatherService.mapWeatherCode(1), 'Partly cloudy');
      expect(WeatherService.mapWeatherCode(2), 'Partly cloudy');
      expect(WeatherService.mapWeatherCode(3), 'Partly cloudy');
    });

    test('codes 4–48 → Fog', () {
      expect(WeatherService.mapWeatherCode(4), 'Fog');
      expect(WeatherService.mapWeatherCode(45), 'Fog');
      expect(WeatherService.mapWeatherCode(48), 'Fog');
    });

    test('codes 49–57 → Drizzle', () {
      expect(WeatherService.mapWeatherCode(49), 'Drizzle');
      expect(WeatherService.mapWeatherCode(51), 'Drizzle');
      expect(WeatherService.mapWeatherCode(57), 'Drizzle');
    });

    test('codes 58–67 → Rain', () {
      expect(WeatherService.mapWeatherCode(58), 'Rain');
      expect(WeatherService.mapWeatherCode(61), 'Rain');
      expect(WeatherService.mapWeatherCode(67), 'Rain');
    });

    test('codes 68–77 → Snow', () {
      expect(WeatherService.mapWeatherCode(68), 'Snow');
      expect(WeatherService.mapWeatherCode(71), 'Snow');
      expect(WeatherService.mapWeatherCode(77), 'Snow');
    });

    test('codes 78–82 → Rain showers', () {
      expect(WeatherService.mapWeatherCode(78), 'Rain showers');
      expect(WeatherService.mapWeatherCode(80), 'Rain showers');
      expect(WeatherService.mapWeatherCode(82), 'Rain showers');
    });

    test('codes 83–86 → Snow showers', () {
      expect(WeatherService.mapWeatherCode(83), 'Snow showers');
      expect(WeatherService.mapWeatherCode(86), 'Snow showers');
    });

    test('codes ≥95 → Thunderstorm', () {
      expect(WeatherService.mapWeatherCode(95), 'Thunderstorm');
      expect(WeatherService.mapWeatherCode(99), 'Thunderstorm');
    });

    test('code 87–94 falls through to Unknown', () {
      // Gaps in WMO spec between snow showers (86) and thunderstorm (95)
      expect(WeatherService.mapWeatherCode(90), 'Unknown');
    });
  });

  // ── WeatherService.weatherIcon ────────────────────────────────────────────

  group('WeatherService.weatherIcon', () {
    test('code 0 → ☀️', () {
      expect(WeatherService.weatherIcon(0), '☀️');
    });

    test('codes 1–3 → ⛅', () {
      expect(WeatherService.weatherIcon(1), '⛅');
      expect(WeatherService.weatherIcon(3), '⛅');
    });

    test('codes 4–48 → 🌫️', () {
      expect(WeatherService.weatherIcon(45), '🌫️');
    });

    test('codes 49–57 → 🌦️', () {
      expect(WeatherService.weatherIcon(51), '🌦️');
    });

    test('codes 58–67 → 🌧️', () {
      expect(WeatherService.weatherIcon(61), '🌧️');
    });

    test('codes 68–77 → ❄️', () {
      expect(WeatherService.weatherIcon(71), '❄️');
    });

    test('codes 78–82 → 🌧️', () {
      expect(WeatherService.weatherIcon(80), '🌧️');
    });

    test('codes 83–86 → 🌨️', () {
      expect(WeatherService.weatherIcon(85), '🌨️');
    });

    test('codes ≥95 → ⛈️', () {
      expect(WeatherService.weatherIcon(95), '⛈️');
    });

    test('gap code → 🌡️ fallback', () {
      expect(WeatherService.weatherIcon(90), '🌡️');
    });
  });

  // ── mapWeatherCode and weatherIcon agree on code 0 ────────────────────────

  group('WeatherService code/icon consistency', () {
    test('Clear code produces Clear condition and sun icon', () {
      expect(WeatherService.mapWeatherCode(0), 'Clear');
      expect(WeatherService.weatherIcon(0), '☀️');
    });

    test('Thunderstorm code produces matching condition and icon', () {
      expect(WeatherService.mapWeatherCode(95), 'Thunderstorm');
      expect(WeatherService.weatherIcon(95), '⛈️');
    });
  });
}
