class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.min,
    required this.max,
    required this.condition,
    required this.weatherCode,
    this.precipitationSum,
    this.windSpeedMax,
    this.uvIndexMax,
    this.sunrise,
    this.sunset,
  });

  final DateTime date;
  final double min;
  final double max;
  final String condition;
  final int weatherCode;
  final double? precipitationSum;
  final double? windSpeedMax;
  final double? uvIndexMax;
  final String? sunrise;
  final String? sunset;
}

class WeatherData {
  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.windSpeed,
    required this.weatherCode,
    required this.forecast,
    this.apparentTemperature,
    this.humidity,
    this.pressure,
    this.uvIndex,
    this.visibility,
    this.precipitation,
  });

  final double temperature;
  final String condition;
  final double windSpeed;
  final int weatherCode;
  final List<DailyForecast> forecast;
  final double? apparentTemperature;
  final int? humidity;
  final double? pressure;
  final double? uvIndex;
  final double? visibility;
  final double? precipitation;
}
