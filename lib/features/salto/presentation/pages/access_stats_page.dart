import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/access_stats.dart';
import '../providers/access_stats_provider.dart';

// ── Page ──────────────────────────────────────────────────────────────────────

class AccessStatsPage extends ConsumerStatefulWidget {
  const AccessStatsPage({super.key});

  @override
  ConsumerState<AccessStatsPage> createState() => _AccessStatsPageState();
}

class _AccessStatsPageState extends ConsumerState<AccessStatsPage> {
  @override
  void initState() {
    super.initState();
    // Always show all-time history — no period filter needed in this view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accessStatsPeriodProvider.notifier).state =
          AccessStatsPeriod.allTime;
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(accessStatsProvider);
    await ref.read(accessStatsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final statsAsync = ref.watch(accessStatsProvider);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: _t(lang, en: 'Access History', ru: 'История доступа', kk: 'Кіру тарихы'),
        showBackButton: true,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.access);
          }
        },
        showDivider: false,
      ),
      body: statsAsync.when(
        loading: () => _SkeletonLoader(isLight: isLight),
        error: (e, _) => _ErrorState(lang: lang),
        data: (stats) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: stats.timestamps.isEmpty
              ? _EmptyState(lang: lang)
              : _HistoryBody(stats: stats, isLight: isLight, lang: lang),
        ),
      ),
    );
  }

  static String _t(
    String lang, {
    required String en,
    required String ru,
    required String kk,
  }) {
    if (lang == 'ru') return ru;
    if (lang == 'kk') return kk;
    return en;
  }
}

// ── History body ──────────────────────────────────────────────────────────────

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({
    required this.stats,
    required this.isLight,
    required this.lang,
  });

  final AccessStats stats;
  final bool isLight;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = stats.timestamps.length;

    // Sort descending (most recent first), group by day
    final sorted = List<DateTime>.from(stats.timestamps)
      ..sort((a, b) => b.compareTo(a));
    final groups = _groupByDay(sorted);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _CounterBadge(
              total: total,
              lang: lang,
              isLight: isLight,
              theme: theme,
            ),
          ),
        ),

        SliverToBoxAdapter(child: const SizedBox(height: 28)),

        // Day-grouped timeline
        for (final group in groups) ...[
          SliverToBoxAdapter(
            child: _DayHeader(
              label: _dayLabel(group.key),
              count: group.value.length,
              isLight: isLight,
              theme: theme,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _AccessTimelineEntry(
                timestamp: group.value[i],
                isFirst: i == 0,
                isLast: i == group.value.length - 1,
                isLight: isLight,
                theme: theme,
              ),
              childCount: group.value.length,
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  List<MapEntry<DateTime, List<DateTime>>> _groupByDay(List<DateTime> times) {
    final map = <String, List<DateTime>>{};
    final keyMap = <String, DateTime>{};
    for (final t in times) {
      final key = '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(t);
      keyMap.putIfAbsent(key, () => DateTime(t.year, t.month, t.day));
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys.map((k) => MapEntry(keyMap[k]!, map[k]!)).toList();
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayOnly = DateTime(day.year, day.month, day.day);

    if (dayOnly == today) {
      if (lang == 'ru') return 'Сегодня';
      if (lang == 'kk') return 'Бүгін';
      return 'Today';
    }
    if (dayOnly == yesterday) {
      if (lang == 'ru') return 'Вчера';
      if (lang == 'kk') return 'Кеше';
      return 'Yesterday';
    }
    return DateFormat('d MMMM', lang == 'ru' ? 'ru' : 'en').format(day);
  }
}

// ── Counter badge ─────────────────────────────────────────────────────────────

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({
    required this.total,
    required this.lang,
    required this.isLight,
    required this.theme,
  });

  final int total;
  final String lang;
  final bool isLight;
  final ThemeData theme;

  String get _subtitle {
    if (lang == 'ru') return 'раз открыт турникет';
    if (lang == 'kk') return 'рет турникет ашылды';
    return 'turnstile opens';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.80),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const AppIcon(
              AppIcons.lockOpen,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Day header ────────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.label,
    required this.count,
    required this.isLight,
    required this.theme,
  });

  final String label;
  final int count;
  final bool isLight;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.grey,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline entry ────────────────────────────────────────────────────────────

class _AccessTimelineEntry extends StatelessWidget {
  const _AccessTimelineEntry({
    required this.timestamp,
    required this.isFirst,
    required this.isLast,
    required this.isLight,
    required this.theme,
  });

  final DateTime timestamp;
  final bool isFirst;
  final bool isLast;
  final bool isLight;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(timestamp);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Timeline column ────────────────────────────────────────────
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  // Top connector line
                  if (!isFirst)
                    Container(
                      width: 1.5,
                      height: 12,
                      color: AppColors.grey.withValues(alpha: 0.18),
                    ),
                  // Dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isLight
                                ? const Color(0xFFF9F9FF)
                                : const Color(0xFF1F1F1F))
                            .withValues(alpha: 1),
                        width: 2,
                      ),
                    ),
                  ),
                  // Bottom connector line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        color: AppColors.grey.withValues(alpha: 0.18),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLight
                        ? AppColors.fieldBackground
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.14),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          timeStr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              AppIcons.check,
                              size: 11,
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Granted',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final shimmerColor = isLight
        ? AppColors.fieldBackground
        : const Color(0xFF2C2C2E);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Counter badge skeleton
          _Shimmer(
            width: double.infinity,
            height: 108,
            radius: 20,
            color: shimmerColor,
          ),
          const SizedBox(height: 28),
          // Day header skeleton
          _Shimmer(width: 80, height: 14, radius: 4, color: shimmerColor),
          const SizedBox(height: 12),
          for (var i = 0; i < 5; i++) ...[
            _Shimmer(
              width: double.infinity,
              height: 52,
              radius: 12,
              color: shimmerColor,
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.4 + 0.3 * _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = lang == 'ru'
        ? 'Нет записей о входе'
        : lang == 'kk'
            ? 'Кіру жазбалары жоқ'
            : 'No access entries yet';
    final sub = lang == 'ru'
        ? 'Здесь появится история ваших\nприпусков на территорию кампуса'
        : lang == 'kk'
            ? 'Мұнда кампус аумағына\nкіру тарихы пайда болады'
            : 'Your campus access history\nwill appear here';

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon(
                      AppIcons.lockOpen,
                      size: 36,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final label = lang == 'ru'
        ? 'Не удалось загрузить статистику'
        : lang == 'kk'
            ? 'Статистиканы жүктеу мүмкін болмады'
            : 'Could not load statistics';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}
