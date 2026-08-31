import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/weather_service.dart';
import '../../domain/entities/weather_data.dart';

class WeatherDetailsPage extends StatelessWidget {
  const WeatherDetailsPage({super.key, required this.data});

  final WeatherData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppAppBar(
        title: l10n.weather_title,
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),

          // ── Current conditions hero ────────────────────────────────────
          _CurrentHero(data: data, isLight: isLight),
          const SizedBox(height: 16),

          // ── Detail stats grid ──────────────────────────────────────────
          _StatsGrid(data: data, isLight: isLight),
          const SizedBox(height: 24),

          // ── Sunrise / Sunset ───────────────────────────────────────────
          if (data.forecast.isNotEmpty &&
              data.forecast.first.sunrise != null) ...[
            _SunriseSunsetRow(
              sunrise: data.forecast.first.sunrise!,
              sunset: data.forecast.first.sunset ?? '--',
              isLight: isLight,
            ),
            const SizedBox(height: 24),
          ],

          // ── Forecast header ────────────────────────────────────────────
          Text(
            l10n.weather_forecast7day,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isLight ? AppColors.textColor : AppColors.textColorDark,
            ),
          ),
          const SizedBox(height: 12),

          // ── Forecast list ──────────────────────────────────────────────
          ...data.forecast.map(
            (day) => _ForecastTile(day: day, isLight: isLight),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CURRENT HERO
// ═══════════════════════════════════════════════════════════════════════════════

class _CurrentHero extends StatelessWidget {
  const _CurrentHero({required this.data, required this.isLight});

  final WeatherData data;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final isDaytime = hour >= 6 && hour < 20;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDaytime
              ? isLight
                  ? [const Color(0xFF4A90D9), const Color(0xFF74B9FF)]
                  : [const Color(0xFF1A3A5C), const Color(0xFF2E6B9E)]
              : isLight
                  ? [const Color(0xFF2C3E6B), const Color(0xFF4A5D8F)]
                  : [const Color(0xFF0D1B2A), const Color(0xFF1B2838)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(AppIcons.location, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                l10n.weather_astana,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            WeatherService.weatherIcon(data.weatherCode),
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 8),
          Text(
            '${data.temperature.round()}°',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.condition,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          if (data.apparentTemperature != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.weather_feelsLike(data.apparentTemperature!.round().toString()),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ],
          if (data.forecast.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'H: ${data.forecast.first.max.round()}°  L: ${data.forecast.first.min.round()}°',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATS GRID
// ═══════════════════════════════════════════════════════════════════════════════

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data, required this.isLight});

  final WeatherData data;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _StatTile(
          icon: AppIcons.wind,
          label: l10n.weather_wind,
          value: '${data.windSpeed.round()} km/h',
          isLight: isLight,
        ),
        if (data.humidity != null)
          _StatTile(
            icon: AppIcons.info,
            label: l10n.weather_humidity,
            value: '${data.humidity}%',
            isLight: isLight,
          ),
        if (data.pressure != null)
          _StatTile(
            icon: AppIcons.statistics,
            label: l10n.weather_pressure,
            value: '${data.pressure!.round()} hPa',
            isLight: isLight,
          ),
        if (data.uvIndex != null)
          _StatTile(
            icon: AppIcons.sun,
            label: l10n.weather_uvIndex,
            value: _uvDescription(data.uvIndex!, l10n),
            isLight: isLight,
          ),
        if (data.precipitation != null)
          _StatTile(
            icon: AppIcons.warning,
            label: l10n.weather_precipitation,
            value: '${data.precipitation!} mm',
            isLight: isLight,
          ),
      ],
    );
  }

  String _uvDescription(double uv, AppLocalizations l10n) {
    final rounded = uv.round();
    if (rounded <= 2) return '$rounded (${l10n.weather_uvLow})';
    if (rounded <= 5) return '$rounded (${l10n.weather_uvModerate})';
    if (rounded <= 7) return '$rounded (${l10n.weather_uvHigh})';
    if (rounded <= 10) return '$rounded (${l10n.weather_uvVeryHigh})';
    return '$rounded (${l10n.weather_uvExtreme})';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isLight,
  });

  final AppIconData icon;
  final String label;
  final String value;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? AppColors.borderGrey : AppColors.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 16, color: AppColors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isLight ? AppColors.grey : AppColors.textDisabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isLight ? AppColors.textColor : AppColors.textColorDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUNRISE / SUNSET
// ═══════════════════════════════════════════════════════════════════════════════

class _SunriseSunsetRow extends StatelessWidget {
  const _SunriseSunsetRow({
    required this.sunrise,
    required this.sunset,
    required this.isLight,
  });

  final String sunrise;
  final String sunset;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String formatTime(String iso) {
      try {
        final dt = DateTime.parse(iso);
        return DateFormat('HH:mm').format(dt);
      } catch (_) {
        return iso;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? AppColors.borderGrey : AppColors.borderDark,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                AppIcon(AppIcons.sun, size: 22, color: Colors.orange.shade600),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weather_sunrise,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isLight ? AppColors.grey : AppColors.textDisabled,
                      ),
                    ),
                    Text(
                      formatTime(sunrise),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isLight ? AppColors.textColor : AppColors.textColorDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: isLight ? AppColors.borderGrey : AppColors.borderDark,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.weather_sunset,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isLight ? AppColors.grey : AppColors.textDisabled,
                      ),
                    ),
                    Text(
                      formatTime(sunset),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isLight ? AppColors.textColor : AppColors.textColorDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                AppIcon(AppIcons.moon, size: 22, color: Colors.indigo.shade300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORECAST TILE — ENHANCED
// ═══════════════════════════════════════════════════════════════════════════════

class _ForecastTile extends StatelessWidget {
  const _ForecastTile({required this.day, required this.isLight});

  final DailyForecast day;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabel = DateFormat('EEE, MMM d').format(day.date);
    final isToday = _isToday(day.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.4)
              : isLight
                  ? AppColors.borderGrey
                  : AppColors.borderDark,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── Top row: date + icon + temp range ──
          Row(
            children: [
              Text(
                WeatherService.weatherIcon(day.weatherCode),
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? l10n.weather_today : dayLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isToday ? FontWeight.w600 : FontWeight.w500,
                        color: isLight ? AppColors.textColor : AppColors.textColorDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.condition,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isLight ? AppColors.grey : AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${day.max.round()}°',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isLight ? AppColors.textColor : AppColors.textColorDark,
                    ),
                  ),
                  Text(
                    '${day.min.round()}°',
                    style: TextStyle(
                      fontSize: 14,
                      color: isLight ? AppColors.grey : AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Bottom row: extra details ──
          if (day.precipitationSum != null ||
              day.windSpeedMax != null ||
              day.uvIndexMax != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (day.windSpeedMax != null)
                  _MiniStat(
                    icon: AppIcons.wind,
                    value: '${day.windSpeedMax!.round()} km/h',
                    isLight: isLight,
                  ),
                if (day.precipitationSum != null) ...[
                  if (day.windSpeedMax != null) const SizedBox(width: 16),
                  _MiniStat(
                    icon: AppIcons.info,
                    value: '${day.precipitationSum!} mm',
                    isLight: isLight,
                  ),
                ],
                if (day.uvIndexMax != null) ...[
                  if (day.windSpeedMax != null ||
                      day.precipitationSum != null)
                    const SizedBox(width: 16),
                  _MiniStat(
                    icon: AppIcons.sun,
                    value: 'UV ${day.uvIndexMax!.round()}',
                    isLight: isLight,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.isLight,
  });

  final AppIconData icon;
  final String value;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 14, color: AppColors.grey),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: isLight ? AppColors.grey : AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}
