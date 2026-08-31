import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../features/events/presentation/providers/events_provider.dart';
import '../../features/exchange/presentation/providers/exchange_provider.dart';
import '../../features/home_widgets/presentation/providers/home_widgets_provider.dart';
import '../../features/salto/presentation/providers/salto_provider.dart';
import '../../features/salto/presentation/providers/salto_student_card_provider.dart';
import '../../features/social_meal/providers/svc_meal_provider.dart';
import '../../features/stories/data/story_service.dart';
import '../../features/stories/presentation/providers/stories_provider.dart';
import '../../features/weather/presentation/providers/weather_provider.dart';

class AppPreloadService {
  AppPreloadService(this._ref);

  final Ref _ref;

  bool _didWarmLocalState = false;
  bool _isWarmingAuthenticatedState = false;
  String? _warmedForUserId;

  Future<void> warmLocalState() async {
    if (_didWarmLocalState) return;
    _didWarmLocalState = true;

    // Initialize story service in background - don't await
    unawaited(StoryService.instance.init());

    // Initialize local/home aggregators early so first tab render is instant.
    _ref.read(homeWidgetsProvider);
    _ref.read(saltoStudentCardProvider);
  }

  void handleAuthState(AuthState authState) {
    if (authState.status == AuthStatus.unauthenticated ||
        authState.status == AuthStatus.firstLaunch ||
        authState.status == AuthStatus.needsOnboarding) {
      _warmedForUserId = null;
    }

    if (authState.status != AuthStatus.authenticated) {
      return;
    }

    final userId = authState.userId?.trim();
    final warmKey = (userId != null && userId.isNotEmpty)
        ? userId
        : '__authenticated__';

    if (_warmedForUserId == warmKey || _isWarmingAuthenticatedState) {
      return;
    }

    _warmedForUserId = warmKey;
    unawaited(_warmAuthenticatedState());
  }

  Future<void> _warmAuthenticatedState() async {
    if (_isWarmingAuthenticatedState) return;
    _isWarmingAuthenticatedState = true;

    try {
      await warmLocalState();

      // Warm data actually visible on Home. Profile-resume aggregates
      // (about me, experience, skills, academy, activities → 5 backend GETs)
      // are intentionally NOT warmed here anymore: their notifiers are lazy
      // and load on the first Profile/Dashboard open, which is the first
      // place that data is visible. Warming them at every app start made
      // every cold launch pay for screens the user may never visit.
      _ref.read(storiesProvider);
      _ref.read(storyOrganizationsProvider);
      _ref.read(eventsProvider);
      _ref.read(weatherProvider);
      _ref.read(exchangeProvider);

      // Restore cached SVC membership flag instantly, then refresh if stale.
      final svcNotifier = _ref.read(svcMealProvider.notifier);
      await svcNotifier.restoreFromCache();
      unawaited(svcNotifier.loadState());

      // Warm SALTO key in background to reduce first unlock latency.
      unawaited(_warmSaltoDigitalKey());
    } finally {
      _isWarmingAuthenticatedState = false;
    }
  }

  Future<void> _warmSaltoDigitalKey() async {
    try {
      // Use the CACHED status only — never await a network call here.
      // If cache is absent (expired or first launch), proceed with prewarm anyway;
      // the key fetch fails gracefully with 404 for non-SALTO users.
      final cachedStatus = await _ref
          .read(saltoRepositoryProvider)
          .getCachedMobileStatus();
      if (cachedStatus != null &&
          (!cachedStatus.mobileAccessEnabled || cachedStatus.activationRequired)) {
        return;
      }

      // Key manager handles validation + lazy refresh in the background.
      _ref.read(saltoKeyManagerProvider).prewarm();
    } catch (_) {
      // SALTO warmup is best-effort and must never affect app startup.
    }
  }
}

final appPreloadServiceProvider = Provider<AppPreloadService>((ref) {
  final service = AppPreloadService(ref);

  unawaited(service.warmLocalState());

  ref.listen<AuthState>(authProvider, (previous, next) {
    service.handleAuthState(next);
  });

  service.handleAuthState(ref.read(authProvider));

  return service;
});
