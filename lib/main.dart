import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_ui/app_ui.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/analytics/analytics.dart';
import 'core/providers/auth_provider.dart'
    show AuthState, AuthStatus, authProvider, authStorageServiceProvider;
import 'features/notifications/presentation/providers/notification_provider.dart'
    show notificationSettingsProvider;
import 'core/theme/theme_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/localization/supported_locales.dart';
import 'core/routing/app_router.dart';
import 'core/services/app_lifecycle_service.dart';
import 'core/services/app_preload_service.dart';
import 'core/services/avatar_cache_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/fcm_token_sync_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/orientation_trusted_clock.dart';
import 'core/utils/image_picker_service.dart';
import 'features/app_update/presentation/providers/app_update_provider.dart';
import 'features/app_update/presentation/widgets/app_update_gate.dart';
import 'features/auth/referral_code/data/pending_referral_service.dart';
import 'features/orientation_week/presentation/widgets/photo_quest_watcher_gate.dart';
import 'features/referral/presentation/providers/referral_provider.dart';
import 'package:dio/dio.dart';
import 'core/utils/image_utils.dart';
import 'features/pin/presentation/widgets/pin_unlock_overlay.dart';
import 'features/social_meal/providers/svc_meal_provider.dart';
import 'features/tutorial/data/tutorial_service.dart';
import 'features/user/presentation/providers/user_provider.dart';
import 'firebase_options.dart';

/// Drives the Sentry screenshot sampling decision in `main()` below.
final _screenshotSampleRandom = Random();

// ──────────────────────────────────────────────────────────────────────────────
//
// STARTUP ARCHITECTURE (revised)
// ──────────────────────────────────────────────────────────────────────────────
//
// OLD (broken):
//   ensureInitialized()
//   await dotenv.load()
//   await Future.wait([Firebase.init, Analytics.init])  ← blocked 1–3 s
//   await SentryFlutter.init(appRunner: _bootstrapApp)  ← blocked ~200 ms
//   _bootstrapApp() { preserve(); runApp(); }           ← preserve() TOO LATE
//
// FIXED:
//   ensureInitialized()
//   preserve()                          ← IMMEDIATELY, no async gap
//   Firebase.initializeApp()            ← ~tens of ms, see note below
//   FirebaseMessaging.onBackgroundMessage(...) ← must precede runApp()
//   await dotenv.load()                 ← <5 ms, safe
//   unawaited(Analytics.init)           ← background
//   Sentry wraps runApp() if DSN set    ← ~200 ms (prod only)
//   runApp()
//   [post-frame] FCM permissions/token + LocalNotifications ← never block UI
//
// Critical-path time: still low tens of ms in debug / ~200 ms in release
// with Sentry — Firebase.initializeApp() alone was never the 1.3–5 s culprit
// in the old flow above; that came from bundling it with Analytics.init in
// one Future.wait. Firebase.init + onBackgroundMessage moved back ahead of
// runApp() because FCM background delivery depends on it: the handler must
// be registered natively before the app can ever be killed, or any push
// that arrives while the app isn't running never reaches
// firebaseMessagingBackgroundHandler (see fcm_service.dart) — Play Services
// still auto-displays messages that carry a `notification` block, but
// data-only messages (the category we use for SVC/events, since routing
// needs `message.data`) silently vanish. Deferring this to a post-first-frame
// callback left a real window on a killed cold start, which reproduced as
// SVC/events pushes only ever "arriving" once the user next opened the app.
//
// ──────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── 1b. Firebase + FCM background handler — must precede runApp() ────────
  // See the FIXED architecture note above for why this can't be deferred
  // like the rest of Firebase/FCM setup below.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {}

  // ── 2. Load .env (reads from asset bundle, sub-millisecond) ──────────────
  await dotenv.load(fileName: '.env');

  // ── 3. Prime SharedPreferences and resolve initial theme/locale ───────────
  // Reading prefs here (a) primes the SharedPreferences cache so all
  // subsequent calls are instant, and (b) lets us inject the correct
  // theme/locale into ProviderScope before the first build — eliminating
  // the 1-frame flash where dark-mode/non-English users saw the wrong state.
  final prefs = await SharedPreferences.getInstance();
  TutorialService.instance.init(prefs);
  OrientationTrustedClock.instance.init(prefs);
  // Fire-and-forget, after init() so it can only move the ratchet forward —
  // never blocks startup, but starts the real-time check as early as
  // possible rather than waiting on whatever business API call goes first.
  unawaited(OrientationTrustedClock.instance.primeFromServer());
  final savedThemeIndex = prefs.getInt('theme_mode');
  final savedLocaleCode = prefs.getString('app_locale');
  final initialTheme = savedThemeIndex != null
      ? ThemeMode.values[savedThemeIndex]
      : ThemeMode.light;
  final initialLocale = savedLocaleCode != null
      ? SupportedLocales.findByCode(savedLocaleCode)
      : null;

  // ── 4. Analytics — background, never blocks UI ────────────────────────────
  // trackAppOpened fires once init() completes (chained in the background).
  // Mixpanel queues the event; it is flushed to the server within seconds
  // even if init takes longer than the first frame.
  unawaited(
    AnalyticsService.instance.init().then((_) {
      AnalyticsService.instance.trackAppOpened(isColdStart: true);
    }),
  );

  // ── 5. Launch app ─────────────────────────────────────────────────────────
  // Sentry wraps runApp() in an error-capture zone when a DSN is supplied.
  // With Firebase off the critical path this is the only remaining overhead
  // in production builds (~200 ms).
  final providerOverrides = <Override>[
    themeProvider.overrideWith((ref) => ThemeNotifier(initialTheme)),
    if (initialLocale != null)
      localeProvider.overrideWith((ref) => LocaleNotifier(initialLocale)),
  ];

  final appWidget = ProviderScope(overrides: providerOverrides, child: const JasWalletApp());

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
        options.attachScreenshot = true;
        // Crash screenshots keep shipping for diagnostics (attachScreenshot
        // stays true — do not disable), but sensitive on-screen content is
        // redacted before upload rather than the whole screenshot being
        // suppressed: maskAllText covers any rendered name/ID/label text
        // (SALTO card, profile, PIN screen copy), maskAllImages covers
        // avatars and the SALTO card's photo/artwork. Both require the
        // SentryWidget wrapper below — without it, capture happens but
        // masking silently doesn't apply.
        //
        // Fatal crashes always keep their screenshot (highest diagnostic
        // value); every other captured error is sampled down to ~30% so the
        // per-event screenshot-encode + upload cost doesn't scale 1:1 with
        // every handled exception at higher concurrent-user volumes.
        options.beforeCaptureScreenshot = (event, hint, debounce) {
          if (event.level == SentryLevel.fatal) return true;
          return _screenshotSampleRandom.nextDouble() < 0.3;
        };
        // ignore: experimental_member_use
        options.experimental.privacy.maskAllText = true;
        // ignore: experimental_member_use
        options.experimental.privacy.maskAllImages = true;
        options.environment = const String.fromEnvironment(
          'APP_ENV',
          defaultValue: 'production',
        );
      },
      appRunner: () {
        // ignore: experimental_member_use
        runApp(SentryWidget(child: appWidget));
      },
    );
  } else {
    runApp(appWidget);
  }
}

/// Submits a referral code entered during onboarding once the session is ready.
///
/// Runs after authentication so a code stashed by [PendingReferralService]
/// (when the redeem failed at entry time) is retried, then cleared on a
/// terminal outcome (applied / self / unknown / already-applied).
Future<void> _redeemPendingReferral(WidgetRef ref) async {
  try {
    final code = await PendingReferralService.get();
    if (code == null || code.isEmpty) return;
    await ref.read(referralRepositoryProvider).redeemCode(code: code);
    await PendingReferralService.clear();
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    if (status == 400 || status == 404 || status == 409) {
      await PendingReferralService.clear();
    }
    // Transient (network/401): keep pending for the next auth event.
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// App widget
// ─────────────────────────────────────────────────────────────────────────────

/// Main application widget.
/// Integrates theme, localization, and routing using Riverpod.
class JasWalletApp extends ConsumerStatefulWidget {
  const JasWalletApp({super.key});

  @override
  ConsumerState<JasWalletApp> createState() => _JasWalletAppState();
}

class _JasWalletAppState extends ConsumerState<JasWalletApp> {
  @override
  void initState() {
    super.initState();
    // All background services start after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeInBackground();
    });
  }

  // ── Background initialisation ──────────────────────────────────────────────

  /// Heavy initialisation runs AFTER the first frame so it never delays the
  /// auth → first-screen transition.
  ///
  /// Order constraints:
  ///   Firebase.initializeApp() already completed in main() (must precede
  ///     runApp() — see the FIXED architecture note up top), so FCMService
  ///     only needs to wait on LocalNotificationService here.
  ///   LocalNotificationService must complete before FCMService
  ///     (FCMService pipes local notification taps into its deep-link stream).
  ///   Everything else is independent and can run in parallel.
  Future<void> _initializeInBackground() async {
    try {
      await LocalNotificationService.instance.initialize();
    } catch (_) {}

    // In-app update check (Firebase Remote Config) — needs Firebase ready
    // first, so this is the earliest safe point in the startup flow. Fully
    // independent of everything else below; never awaited so it can't delay
    // FCM/other init even on a slow network.
    unawaited(ref.read(appUpdateStateProvider.notifier).check());

    // FCMService requires both Firebase and LocalNotifications to be ready.
    try {
      final authStorage = ref.read(authStorageServiceProvider);
      await FCMService.instance.initialize(
        authStorage: authStorage,
        onTokenSaved: (token) async {
          final auth = ref.read(authProvider);
          if (auth.status == AuthStatus.authenticated) {
            await ref.read(fcmTokenSyncServiceProvider).syncToken(token);
          }
        },
      );
    } catch (_) {}

    // Remaining tasks are fully independent — fire and forget.
    unawaited(ImagePickerService().primeLostData());
    unawaited(_precacheSvgs());
    unawaited(_preloadCachedAvatarPath());
  }

  /// Precache only the three brand SVG assets that still exist.
  /// All other icons are Lucide-backed (AppIcon widget) — no file I/O needed.
  Future<void> _precacheSvgs() async {
    const brandSvgs = [
      'assets/logo.svg',
      'assets/icons/token.svg',
      'assets/icons/bonus.svg',
    ];
    for (final path in brandSvgs) {
      try {
        final loader = SvgAssetLoader(path);
        await svg.cache.putIfAbsent(
          loader.cacheKey(null),
          () => loader.loadBytes(null),
        );
      } catch (_) {}
    }
  }

  Future<void> _preloadCachedAvatarPath() async {
    try {
      final avatarCache = AvatarCacheService();
      final cachedPath = await avatarCache.getCachedAvatarPath();
      if (cachedPath != null) {
        setCachedAvatarPath(cachedPath);
        final file = File(cachedPath);
        if (file.existsSync() && mounted) {
          precacheImage(FileImage(file), context);
        }
      }
    } catch (_) {}
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(appLifecycleServiceProvider);
    ref.watch(userProvider.notifier);
    ref.watch(appPreloadServiceProvider);

    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      final becameAuthenticated = next.status == AuthStatus.authenticated &&
          prev?.status != AuthStatus.authenticated;
      if (becameAuthenticated) {
        unawaited(ref.read(fcmTokenSyncServiceProvider).syncCurrentToken());
        unawaited(
          ref.read(notificationSettingsProvider.notifier).syncTopicSubscriptions(),
        );
        unawaited(_redeemPendingReferral(ref));
      }
    });

    ref.listen(userProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user == null || user.id.isEmpty) return;
      if (prev?.valueOrNull?.id == user.id) return;
      AnalyticsService.instance.syncUserProfile(
        displayName: user.fullName,
        email: user.email,
        userId: user.id,
        role: user.role.name,
      );
    });

    ref.listen(svcMealProvider, (prev, next) {
      if (!next.isLoaded) return;
      if (prev?.isMember == next.isMember) return;
      AnalyticsService.instance.setUserProperty(
        AnalyticsUserProperties.isSvcMember,
        next.isMember,
      );
    });

    return MaterialApp.router(
      title: 'Jas Wallet',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 280),
      themeAnimationCurve: Curves.easeInOut,

      locale: locale,
      supportedLocales: SupportedLocales.all,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: router,

      builder: (context, child) {
        // FeatureStyle (Orientation Week / Club Fair's design tokens) reads
        // its neutrals as bare static properties with no BuildContext in
        // reach, so it can't watch Theme.of(context) itself — this keeps its
        // ambient brightness flag current on every build instead.
        FeatureStyle.updateBrightness(Theme.of(context).brightness);
        // PhotoQuestWatcherGate sits inside the update/PIN gates so it never
        // polls behind a blocking screen, but still spans every route — a
        // moderation verdict has to reach the student wherever they are.
        return AppUpdateGate(
          child: PinUnlockOverlay(
            child: PhotoQuestWatcherGate(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
