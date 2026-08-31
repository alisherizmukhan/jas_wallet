import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/weather_service.dart';
import '../../domain/entities/weather_data.dart';
import '../providers/weather_provider.dart';

/// Compact weather card for the home page.
///
/// Loads from persistent cache instantly (offline-first) then background-refreshes.
/// Shows a skeleton shimmer on first load, a retry button if no data available.
class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weatherProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: () {
        final data = state.valueOrNull;
        if (data != null) {
          context.push(AppRoutes.weatherDetails, extra: data);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLight ? AppColors.white : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: state.when(
          loading: () => const SizedBox(
            height: 100,
            child: _WeatherSkeleton(),
          ),
          error: (_, _) => _noDataWidget(context, ref),
          data: (data) => data != null
              ? _dataWidget(data, isLight, context)
              : _noDataWidget(context, ref),
        ),
      ),
    );
  }

  Widget _noDataWidget(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.weather_noData,
            style: const TextStyle(fontSize: 13, color: AppColors.grey),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => ref.read(weatherProvider.notifier).refresh(),
            icon: AppIcon(AppIcons.refresh, size: 14, color: AppColors.grey),
            label: Text(
              l10n.common_retry,
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataWidget(WeatherData data, bool isLight, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              WeatherService.weatherIcon(data.weatherCode),
              style: const TextStyle(fontSize: 28),
            ),
            const Spacer(),
            Text(
              AppLocalizations.of(context)!.weather_astana,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isLight ? AppColors.grey : AppColors.textDisabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${data.temperature.round()}°',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: isLight ? AppColors.textColor : AppColors.textColorDark,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.condition,
          style: TextStyle(
            fontSize: 13,
            color: isLight ? AppColors.grey : AppColors.textDisabled,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AppIcon(AppIcons.wind, size: 14, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(
              '${data.windSpeed.round()} km/h',
              style: TextStyle(
                fontSize: 12,
                color: isLight ? AppColors.grey : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Animated skeleton shimmer — matches weather card layout ──────────────────

class _WeatherSkeleton extends StatefulWidget {
  const _WeatherSkeleton();

  @override
  State<_WeatherSkeleton> createState() => _WeatherSkeletonState();
}

class _WeatherSkeletonState extends State<_WeatherSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final alpha = 0.05 + 0.09 * _anim.value;
        final base = isLight
            ? Colors.black.withValues(alpha: alpha)
            : Colors.white.withValues(alpha: alpha);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji placeholder
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            // Temperature placeholder
            Container(
              width: 64,
              height: 26,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            // Condition text placeholder
            Container(
              width: 96,
              height: 12,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            // Wind placeholder
            Container(
              width: 72,
              height: 10,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        );
      },
    );
  }
}
