import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_ui/app_ui.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/routing/app_router.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/utils/image_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../features/orientation_week/config/orientation_config.dart';
import '../../features/events/presentation/providers/events_provider.dart';
import '../../features/exchange/presentation/providers/exchange_provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../features/stories/presentation/providers/stories_provider.dart';
import '../../features/stories/presentation/widgets/stories_bar.dart';
import '../../features/home_widgets/presentation/providers/home_widgets_provider.dart';
import '../../features/home_widgets/domain/entities/home_widget_item.dart';
import '../../features/home_widgets/presentation/widgets/widgets_management_sheet.dart';
import '../../features/salto/presentation/widgets/salto_student_card_widget.dart';
import '../../features/events/presentation/widgets/events_section.dart';
import '../../features/weather/presentation/providers/weather_provider.dart';
import '../../features/weather/presentation/widgets/weather_card.dart';
import '../../features/exchange/presentation/widgets/exchange_card.dart';
import '../../features/user/presentation/providers/user_provider.dart';

/// Home page — Revolut-style layout.
/// UI composition only — all business logic lives in providers.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {

  /// Floor between resume-triggered story checks. [StoriesNotifier.
  /// checkForUpdates] already no-ops once its own ~12h cache TTL is fresh,
  /// but that TTL boundary is crossed only once per day — this short local
  /// floor avoids re-entering the notifier's check on every single resume
  /// during a burst of rapid app-switching, mirroring the same
  /// last-checked-at throttle pattern AppLifecycleService already applies
  /// to its own background user refresh.
  static const _storiesCheckThrottle = Duration(seconds: 90);
  DateTime? _lastStoriesCheckAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final lastCheckAt = _lastStoriesCheckAt;
      final now = DateTime.now();
      if (lastCheckAt != null && now.difference(lastCheckAt) < _storiesCheckThrottle) {
        return;
      }
      _lastStoriesCheckAt = now;
      ref.read(storiesProvider.notifier).checkForUpdates();
    }
  }

  Future<void> _refreshHome() async {
    final connected = await ConnectivityService.isConnected();
    if (!connected) {
      if (mounted) {
        AppToast.showError(
          context,
          AppLocalizations.of(context)!.profile_errorNetwork,
        );
      }
      return;
    }
    await Future.wait([
      ref.read(storiesProvider.notifier).refresh(showLoading: false).catchError((_) {}),
      ref.read(storyOrganizationsProvider.notifier).refresh(showLoading: false).catchError((_) {}),
      ref.read(eventsProvider.notifier).refresh().catchError((_) {}),
      ref.read(weatherProvider.notifier).refresh().catchError((_) {}),
      ref.read(exchangeProvider.notifier).refresh().catchError((_) {}),
    ]);
  }

  Widget? _buildSection(String id) {
    switch (id) {
      case HomeWidgetIds.stories:
        return const RepaintBoundary(child: StoriesBar());
      case HomeWidgetIds.saltoCard:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: HomeSpacing.screenH),
          child: SaltoStudentCardSection(),
        );
      case HomeWidgetIds.events:
        return const RepaintBoundary(child: EventsSection());
      case HomeWidgetIds.weather:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: HomeSpacing.screenH),
          child: WeatherCard(),
        );
      case HomeWidgetIds.exchange:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: HomeSpacing.screenH),
          child: ExchangeCard(),
        );
      default:
        return null;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppAppBar(
        title: l10n.appName,
        showDivider: false,
        leadingWidth: 56,
        leading: GestureDetector(
          onTap: () => context.push(AppRoutes.profile),
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Center(child: _AvatarLeading()),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => WidgetsManagementSheet.show(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(child: _WidgetsAction()),
            ),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.notifications),
            child: const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: _BellAction()),
            ),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final widgetsList = ref.watch(homeWidgetsProvider).valueOrNull ?? [];

          final ordered = widgetsList
              .where((w) =>
                  w.isVisible && !HomeWidgetIds.isAnyFintechSubWidget(w.id))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          final showWeather = widgetsList
              .any((w) => w.id == HomeWidgetIds.weather && w.isVisible);
          final showExchange = widgetsList
              .any((w) => w.id == HomeWidgetIds.exchange && w.isVisible);

          // Build section widgets in order, collapsing weather+exchange into
          // one side-by-side row at the position of whichever appears first.
          final sections = <Widget>[];
          bool weatherExchangeAdded = false;
          bool bannerAdded = false;
          for (final w in ordered) {
            if (w.id == HomeWidgetIds.weather ||
                w.id == HomeWidgetIds.exchange) {
              if (!weatherExchangeAdded) {
                weatherExchangeAdded = true;
                sections.add(Padding(
                  padding: const EdgeInsets.fromLTRB(
                      HomeSpacing.screenH, HomeSpacing.sectionGap, HomeSpacing.screenH, 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showWeather)
                          const Expanded(child: WeatherCard()),
                        if (showWeather && showExchange)
                          const SizedBox(width: HomeSpacing.itemGap),
                        if (showExchange)
                          const Expanded(child: ExchangeCard()),
                      ],
                    ),
                  ),
                ));
              }
            } else {
              final section = _buildSection(w.id);
              if (section != null) {
                if (w.id == HomeWidgetIds.stories) {
                  final hasStories =
                      ref.watch(userStoriesProvider).isNotEmpty;
                  final canPublish = ref.watch(storyCanPublishProvider);
                  if (hasStories || canPublish) {
                    sections.add(Padding(
                      // 12 px matches hub-page banner top gap (same first-item alignment)
                      padding: const EdgeInsets.only(top: 12),
                      child: section,
                    ));
                    // Banner always follows stories
                    sections.add(const Padding(
                      padding: EdgeInsets.only(top: HomeSpacing.sectionGap),
                      child: _HomeBannerCarousel(),
                    ));
                    bannerAdded = true;
                  }
                } else {
                  sections.add(Padding(
                    padding:
                        const EdgeInsets.only(top: HomeSpacing.sectionGap),
                    child: section,
                  ));
                }
              }
            }
          }

          return RefreshIndicator(
            onRefresh: _refreshHome,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner at top only when stories widget is hidden.
                  // 12 px matches the hub-page banner top gap so both tabs look
                  // visually aligned right after the AppBar.
                  if (!bannerAdded)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: _HomeBannerCarousel(),
                    ),
                  ...sections,
                  const SizedBox(height: HomeSpacing.sectionGap + 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Home banner carousel ──────────────────────────────────────────────────────

class _BannerSlide {
  const _BannerSlide({required this.id, required this.asset});

  final String id;
  final String asset;
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel();

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel>
    with WidgetsBindingObserver {
  static const _autoPlay = Duration(seconds: 5);
  static const _aspect = 2560 / 1086;

  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  List<_BannerSlide> _slides(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final contest = switch (lang) {
      'en' => 'assets/banners/contest_en.webp',
      'kk' => 'assets/banners/contest_kk.webp',
      _ => 'assets/banners/contest_ru.webp',
    };
    return [
      _BannerSlide(id: 'contest', asset: contest),
      const _BannerSlide(id: 'club_fair', asset: 'assets/banners/club_fair.webp'),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _schedule();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _schedule();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    final slides = _slides(context);
    if (slides.length < 2) return;
    _timer = Timer(_autoPlay, _advance);
  }

  void _advance() {
    if (!mounted) return;
    final slides = _slides(context);
    if (slides.length < 2 || !_controller.hasClients) {
      _schedule();
      return;
    }
    final next = (_index + 1) % slides.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _schedule();
  }

  void _openSlide(String id) {
    AnalyticsService.instance.trackHomeBannerTapped(bannerName: id);
    if (id == 'contest') {
      context.push(AppRoutes.contest);
      return;
    }
    if (OrientationConfig.isClosed) {
      context.push(AppRoutes.orientationClosed);
      return;
    }
    context.push(AppRoutes.orientationWeek);
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides(context);
    final width = MediaQuery.sizeOf(context).width - HomeSpacing.screenH * 2;
    final cacheWidth =
        (width * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, 1600);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeSpacing.screenH),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: _aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _timer?.cancel();
                  } else if (notification is ScrollEndNotification) {
                    _schedule();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return GestureDetector(
                      onTap: () => _openSlide(slide.id),
                      child: Image.asset(
                        slide.asset,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        cacheWidth: cacheWidth,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
              ),
              if (slides.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < slides.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _index ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: i == _index ? 0.95 : 0.45,
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets management action ─────────────────────────────────────────────────

class _WidgetsAction extends StatelessWidget {
  const _WidgetsAction();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Center(
        child: AppIcon(
          AppIcons.hub,
          size: 22,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ── Avatar leading widget ─────────────────────────────────────────────────────

class _AvatarLeading extends ConsumerWidget {
  const _AvatarLeading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Scoped to just the 2 fields this avatar renders — an unrelated
    // profile-field change elsewhere no longer rebuilds this app-bar icon.
    final identity = ref.watch(
      userProvider.select(
        (s) => (initials: s.valueOrNull?.initials, avatarUrl: s.valueOrNull?.avatarUrl),
      ),
    );
    final initials = identity.initials ?? '?';
    final avatarPath = identity.avatarUrl;
    final theme = Theme.of(context);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarPath != null
            ? Image(
                image: getAvatarImageProvider(
                  avatarPath,
                  cacheWidth: (34 * MediaQuery.of(context).devicePixelRatio).round(),
                ),
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) =>
                    _Initials(initials: initials, theme: theme),
              )
            : _Initials(initials: initials, theme: theme),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.theme});
  final String initials;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Bell action widget ────────────────────────────────────────────────────────

class _BellAction extends ConsumerWidget {
  const _BellAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    final iconColor = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: AppIcon(AppIcons.notification, size: 24, color: iconColor)),
          if (unreadCount > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
