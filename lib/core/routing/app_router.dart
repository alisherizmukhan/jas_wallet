import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_navigation_observer.dart';
import '../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

// Features imports
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/welcome/presentation/pages/welcome_page.dart';
import '../../features/auth/login/presentation/pages/login_page.dart';
import '../../features/auth/registration/presentation/pages/registration_page.dart';
import '../../features/auth/registration/presentation/pages/personal_data_consent_page.dart';
import '../../features/auth/profile_creation/presentation/pages/profile_creation_page.dart';
import '../../features/verification/presentation/pages/verification_page.dart';
import '../../features/forgot_password/presentation/pages/forgot_password_page.dart';
import '../../features/forgot_password/presentation/pages/reset_password_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/pages/notification_category_page.dart';
import '../../features/notifications/presentation/pages/notifications_settings_page.dart';
import '../../features/notifications/domain/entities/notification_item.dart';
import '../../features/profile_editing/presentation/pages/edit_profile_page.dart';
import '../../features/my_profile/presentation/pages/my_profile_page.dart';
import '../../features/security/presentation/pages/security_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';



// Activity import
import '../../features/activity/presentation/pages/activity_page.dart';

// Help & About imports
import '../../features/help/presentation/pages/help_page.dart';
import '../../features/settings/presentation/pages/about_app_page.dart';
import '../../features/settings/presentation/pages/privacy_policy_page.dart';

// Profile Section Feature imports
import '../../features/about_me/presentation/pages/edit_about_me_page.dart';
import '../../features/experience/presentation/pages/edit_experience_page.dart';
import '../../features/skills/presentation/pages/edit_skills_page.dart';
import '../../features/academy/presentation/pages/edit_academy_page.dart';
import '../../features/activity/presentation/pages/edit_user_activity_page.dart';



// SOS imports
import '../../features/sos/presentation/pages/sos_form_page.dart';

// Social Meal Program imports
import '../../features/social_meal/presentation/pages/svc_dashboard_page.dart';
import '../../features/social_meal/presentation/pages/svc_qr_scan_page.dart';
import '../../features/social_meal/presentation/pages/svc_success_page.dart';
import '../../features/social_meal/presentation/pages/svc_meal_calendar_page.dart';
import '../../features/social_meal/presentation/pages/svc_meal_history_page.dart';
import '../../features/social_meal/presentation/pages/svc_streak_page.dart';

// Tutorials imports


// Events imports
import '../../features/events/domain/entities/event.dart';
import '../../features/events/presentation/pages/event_details_loader_page.dart';
import '../../features/events/presentation/pages/event_details_page.dart';

// Weather & Exchange imports
import '../../features/weather/domain/entities/weather_data.dart';
import '../../features/weather/presentation/pages/weather_details_page.dart';
import '../../features/exchange/domain/entities/exchange_data.dart';

import '../../features/exchange/presentation/pages/exchange_details_page.dart';

// Share & Referral imports
import '../../features/share/presentation/pages/share_page.dart';
import '../../features/referral/presentation/pages/referral_page.dart';
import '../../features/referral/presentation/pages/contest_page.dart';

// Shells imports
import '../../shells/bottom_navigation/bottom_nav_shell.dart';
import '../../shells/home/home_page.dart';
import '../../shells/hub/hub_page.dart';
import '../../features/salto/presentation/pages/salto_activation_page.dart';
import '../../features/auth/referral_code/presentation/pages/referral_code_entry_page.dart';
import '../../features/salto/presentation/pages/salto_access_page.dart';
import '../../features/salto/presentation/pages/salto_student_card_page.dart';
import '../../features/salto/presentation/pages/access_stats_page.dart';

// Orientation Week imports
import '../../features/orientation_week/presentation/shell/orientation_nav_shell.dart';
import '../../features/orientation_week/presentation/pages/challenge_scan_page.dart';
import '../../features/orientation_week/config/orientation_config.dart';
import '../../features/orientation_week/presentation/pages/orientation_closed_page.dart';
import '../../features/orientation_week/presentation/pages/orientation_freshmen_notice_page.dart';
import '../../features/orientation_week/presentation/pages/orientation_challenges_page.dart';
import '../../features/orientation_week/presentation/pages/orientation_my_qr_page.dart';
import '../../features/orientation_week/presentation/pages/orientation_club_stand_qr_page.dart';
import '../../features/orientation_week/presentation/pages/orientation_overview_page.dart';
import '../../features/orientation_week/presentation/pages/orientation_schedule_page.dart';
import '../../features/orientation_week/presentation/pages/networking_bingo_page.dart';
import '../../features/orientation_week/presentation/pages/photo_quest_detail_page.dart';
import '../../features/orientation_week/domain/entities/photo_mission.dart';
import '../../features/orientation_week/presentation/pages/leaderboard_page.dart';
import '../../features/orientation_week/presentation/pages/club_fair_club_ranking_page.dart';
import '../../features/orientation_week/presentation/pages/rewards_page.dart';
import '../../features/orientation_week/presentation/pages/reward_detail_page.dart';
import '../../features/orientation_week/presentation/pages/reward_history_page.dart';
import '../../features/orientation_week/domain/entities/reward.dart';

// Auth session flow imports
import '../../features/language_selection/presentation/pages/language_selection_page.dart';
import '../../features/pin/presentation/pages/pin_create_page.dart';
import '../../features/pin/presentation/pages/pin_verify_page.dart';
import '../../features/biometrics/presentation/pages/biometric_setup_page.dart';

/// Route paths constants.
abstract class AppRoutes {
  // Auth flow
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String registration = '/registration';
  static const String personalDataConsent = '/personal-data-consent';
  static const String verification = '/verification';
  static const String profileCreation = '/profile-creation';
  static const String referralCodeEntry = '/referral-code-entry';
  static const String saltoActivation = '/salto-activation';
  static const String saltoStudentCard = '/salto-student-card';
  static const String accessStats = '/access-stats';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Auth session flow
  static const String languageSelection = '/language-selection';
  static const String pinCreate = '/pin-create';
  static const String pinVerify = '/pin-verify';
  static const String biometricSetup = '/biometric-setup';

  // Main app (bottom navigation)
  static const String home = '/home';
  static const String hub = '/hub';
  static const String access = '/access';
  static const String profile = '/profile';

  // Nested routes
  static const String notifications = '/notifications';
  static const String notificationsSettings = '/notifications/settings';
  static const String notificationsCategory = '/notifications/category';
  static const String settings = '/settings';
  static const String myProfile = '/my-profile';
  static const String editProfile = '/profile/edit';
  static const String editPhone = '/profile/edit/phone';
  static const String security = '/security';

  // Activity
  static const String activity = '/activity';

  // Help & About
  static const String help = '/help';
  static const String aboutApp = '/about-app';
  static const String privacyPolicy = '/privacy-policy';

  // SOS (Emergency Contacts)
  static const String sosForm = '/sos';

  // Orientation Week
  static const String orientationWeek = '/orientation';
  static const String orientationChallenges = '/orientation/challenges';
  static const String orientationBingo = '/orientation/bingo';
  static const String orientationPhotoQuests = '/orientation/photo-quests';
  static const String orientationSchedule = '/orientation/schedule';
  static const String orientationMyQr = '/orientation/my-qr';
  static const String orientationClubStandQr = '/orientation/club-qr';
  static const String orientationChallengeScan = '/orientation/challenges/scan';

  /// The challenge whose rule the scanner evaluates. In the URL rather than in
  /// `extra` for the same reason every other detail route is — `extra` does not
  /// survive the OS restoring the app on top of a page.
  static String orientationChallengeScanFor(String challengeId) =>
      '$orientationChallengeScan?id=$challengeId';
  static const String orientationPhotoQuestDetail = '/orientation/photo-quests/detail';
  static const String orientationLeaderboard = '/orientation/leaderboard';
  static const String orientationClubRanking = '/orientation/club-ranking';
  static const String orientationRewards = '/orientation/rewards';
  static const String orientationRewardDetail = '/orientation/rewards/detail';
  static const String orientationRewardHistory = '/orientation/rewards/history';

  /// Deliberately outside the `/orientation` path tree — see the router's
  /// top-level redirect, which sends every `/orientation*` route here once
  /// the feature is closed. Matching the prefix would redirect this page to
  /// itself.
  static const String orientationClosed = '/orientation-closed';

  /// Same reasoning as [orientationClosed] — pushed from the Hub tap
  /// handler, not part of the `/orientation` shell.
  static const String orientationFreshmenNotice = '/orientation-freshmen-notice';

  // Social Meal Program (SVC)
  static const String svcDashboard = '/svc';
  static const String svcQrScan = '/svc/qr-scan';
  static const String svcSuccess = '/svc/success';
  static const String svcCalendar = '/svc/calendar';
  static const String svcStreak = '/svc/streak';
  static const String svcHistory = '/svc/history';

  // Profile Sections (Features)
  static const String editAboutMe = '/profile/about-me';
  static const String editExperience = '/profile/experience';
  static const String editSkills = '/profile/skills';
  static const String editAcademy = '/profile/academy';
  static const String editUserActivity = '/profile/user-activity';

  // Tutorials


  // Events
  static const String eventDetails = '/events/detail';

  // Weather & Exchange
  static const String weatherDetails = '/weather/details';
  static const String exchangeDetails = '/exchange/details';

  // Share & Referral
  static const String shareApp = '/share-app';
  static const String referral = '/referral';
  static const String contest = '/contest';

}

/// Listenable adapter so GoRouter refreshes when [AuthState] changes.
class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// Routes that belong to the unauthenticated / onboarding flow.
const _publicRoutes = <String>{
  AppRoutes.languageSelection,
  AppRoutes.onboarding,
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.registration,
  AppRoutes.personalDataConsent,
  AppRoutes.verification,
  AppRoutes.profileCreation,
  AppRoutes.referralCodeEntry,
  AppRoutes.saltoActivation,
  AppRoutes.forgotPassword,
  AppRoutes.resetPassword,
};

/// Routes that belong to the session/PIN/biometric setup flow.
const _sessionRoutes = <String>{
  AppRoutes.pinCreate,
  AppRoutes.pinVerify,
  AppRoutes.biometricSetup,
};

/// Redirect guard for a route whose subject travels in `extra`.
///
/// `extra` is in-memory only — it does not survive the OS restoring the app
/// after evicting it from the background. Lock the screen on a detail page,
/// come back later, and the route is rebuilt with the path intact and `extra`
/// null, so casting it threw a type error straight onto the screen.
///
/// Returns null (stay put) when the subject is the expected type, and
/// [fallback] — the list the page was opened from — when it isn't.
String? detailExtraGuard<T>(Object? extra, String fallback) =>
    extra is T ? null : fallback;

/// Riverpod provider for the app router.
final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthNotifierListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authListenable,
    observers: [AnalyticsNavigationObserver.instance],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentPath = state.matchedLocation;

      // While auth is still resolving, hold on welcome.
      if (authState.status == AuthStatus.appStarting ||
          authState.status == AuthStatus.unknown) {
        return currentPath == AppRoutes.welcome ? null : AppRoutes.welcome;
      }

      // First launch → language selection
      if (authState.status == AuthStatus.firstLaunch) {
        return currentPath == AppRoutes.languageSelection
            ? null
            : AppRoutes.languageSelection;
      }

      // Needs onboarding → force onboarding
      if (authState.status == AuthStatus.needsOnboarding) {
        return currentPath == AppRoutes.onboarding
            ? null
            : AppRoutes.onboarding;
      }

      // Unauthenticated → allow public routes, redirect protected → welcome
      if (authState.status == AuthStatus.unauthenticated) {
        if (_publicRoutes.contains(currentPath)) return null;
        return AppRoutes.welcome;
      }

      // Needs PIN setup → force PIN creation
      if (authState.status == AuthStatus.needsPinSetup) {
        return currentPath == AppRoutes.pinCreate ? null : AppRoutes.pinCreate;
      }

      // Needs biometric setup prompt
      if (authState.status == AuthStatus.needsBiometricSetup) {
        return currentPath == AppRoutes.biometricSetup
            ? null
            : AppRoutes.biometricSetup;
      }

      // Needs local auth (PIN/biometric) to unlock.
      // PinUnlockOverlay handles the PIN UI as a foreground layer over the shell —
      // route to home so the shell is fully mounted beneath the overlay.
      if (authState.status == AuthStatus.needsLocalAuth) {
        if (_publicRoutes.contains(currentPath) ||
            _sessionRoutes.contains(currentPath)) {
          return AppRoutes.home;
        }
        return null; // stay on current route; overlay covers it
      }

      // Authenticated → redirect away from auth/session screens → home
      if (authState.status == AuthStatus.authenticated) {
        if (_publicRoutes.contains(currentPath) ||
            _sessionRoutes.contains(currentPath)) {
          return AppRoutes.home;
        }

        // Orientation Week has locked for the season — every route under
        // `/orientation` (the shell, challenges, bingo, rewards, a deep
        // link into a specific reward…) bounces to the static closed page
        // instead, so nothing under there ever builds and nothing calls
        // its repository. The closed page itself and the Hub are excluded
        // so this can't loop.
        final isOrientationRoute = currentPath == AppRoutes.orientationWeek ||
            currentPath.startsWith('${AppRoutes.orientationWeek}/');
        if (isOrientationRoute && OrientationConfig.isClosed) {
          return AppRoutes.orientationClosed;
        }

        return null; // allow navigation to any protected route
      }

      return null;
    },
    routes: [
      // ─────────────────────────────────────────────────────────────────────────
      // AUTH FLOW ROUTES
      // ─────────────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.languageSelection,
        name: 'languageSelection',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 1000),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: const LanguageSelectionPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.pinCreate,
        name: 'pinCreate',
        builder: (context, state) => const PinCreatePage(),
      ),
      GoRoute(
        path: AppRoutes.pinVerify,
        name: 'pinVerify',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 1000),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: const PinVerifyPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.biometricSetup,
        name: 'biometricSetup',
        builder: (context, state) => const BiometricSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LoginPage(initialLogin: extra?['initialLogin'] as String?);
        },
      ),
      GoRoute(
        path: AppRoutes.registration,
        name: 'registration',
        builder: (context, state) => const RegistrationPage(),
      ),
      GoRoute(
        path: AppRoutes.personalDataConsent,
        name: 'personalDataConsent',
        builder: (context, state) => const PersonalDataConsentPage(),
      ),
      GoRoute(
        path: AppRoutes.verification,
        name: 'verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VerificationPage(
            destination: extra?['destination'] as String? ?? '',
            isPhone: extra?['isPhone'] as bool? ?? true,
            flow: extra?['flow'] as String? ?? 'registration',
            onVerified: extra?['onVerified'] as VoidCallback?,
            onVerifiedWithCode:
                extra?['onVerifiedWithCode'] as void Function(String)?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profileCreation,
        name: 'profileCreation',
        builder: (context, state) => const ProfileCreationPage(),
      ),
      GoRoute(
        path: AppRoutes.referralCodeEntry,
        name: 'referralCodeEntry',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ReferralCodeEntryPage(userId: extra?['userId'] as String? ?? '');
        },
      ),
      GoRoute(
        path: AppRoutes.saltoActivation,
        name: 'saltoActivation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SaltoActivationPage(userId: extra?['userId'] as String? ?? '');
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ResetPasswordPage(
            email: extra?['email'] as String? ?? '',
            code: extra?['code'] as String? ?? '',
          );
        },
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // MAIN APP WITH BOTTOM NAVIGATION (STATEFUL SHELL — IndexedStack)
      // 3 tabs stay mounted; switching tabs never rebuilds pages.
      // Tabs: Home | Access | Hub
      // Profile and Notifications are push routes accessed from the Home AppBar.
      // ─────────────────────────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            BottomNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.access,
                name: 'access',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SaltoAccessPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.hub,
                name: 'hub',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HubPage()),
              ),
            ],
          ),
        ],
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // PUSH ROUTES — accessible from Home AppBar (outside bottom nav shell)
      // ─────────────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const SettingsPage(),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // NESTED ROUTES (OUTSIDE BOTTOM NAV)
      // ─────────────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.accessStats,
        name: 'accessStats',
        builder: (context, state) => const AccessStatsPage(),
      ),
      GoRoute(
        path: AppRoutes.notificationsSettings,
        name: 'notificationsSettings',
        builder: (context, state) => const NotificationsSettingsPage(),
      ),
      GoRoute(
        path: '${AppRoutes.notificationsCategory}/:category',
        name: 'notificationsCategory',
        builder: (context, state) {
          final categoryName = state.pathParameters['category'];
          final parsed = NotificationCategory.values.where(
            (c) => c.name == categoryName,
          );
          final category =
              parsed.isEmpty ? NotificationCategory.general : parsed.first;
          return NotificationCategoryPage(
            sectionCategory: category,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myProfile,
        name: 'myProfile',
        builder: (context, state) => const MyProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.saltoStudentCard,
        name: 'saltoStudentCard',
        builder: (context, state) => const SaltoStudentCardPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.security,
        name: 'security',
        builder: (context, state) => const SecurityPage(),
      ),
      // ─────────────────────────────────────────────────────────────────────────
      // ACTIVITY ROUTE
      // ─────────────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.activity,
        name: 'activity',
        builder: (context, state) => const ActivityPage(),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // HELP & ABOUT ROUTES
      // ─────────────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.help,
        name: 'help',
        builder: (context, state) => const HelpPage(),
      ),
      GoRoute(
        path: AppRoutes.aboutApp,
        name: 'aboutApp',
        builder: (context, state) => const AboutAppPage(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),

      // ─────────────────────────────────────────────────────────────────────────
      // ─────────────────────────────────────────────────────────────────────────
      // SOS ROUTES
      // ─────────────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.sosForm,
        name: 'sosForm',
        builder: (context, state) => const SosFormPage(),
      ),
      // ─────────────────────────────────────────────────────────────────────────
      // ORIENTATION WEEK — pushed from Hub as its own StatefulShellRoute so
      // the four tabs (Overview · Bingo · Photo Quest · Rewards)
      // share one persistent bottom nav and keep their own state, exactly
      // like the main app's Home/Access/Hub shell. Every other Orientation
      // page (scanner, progress, achievements, leaderboard, detail pages…)
      // stays a flat push route below, so it covers the nav bar when opened.
      // ─────────────────────────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            OrientationNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.orientationWeek,
              name: 'orientationWeek',
              pageBuilder: (context, state) => const NoTransitionPage(child: OrientationOverviewPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.orientationChallenges,
              name: 'orientationChallenges',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: OrientationChallengesPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.orientationBingo,
              name: 'orientationBingo',
              pageBuilder: (context, state) => const NoTransitionPage(child: NetworkingBingoPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.orientationRewards,
              name: 'orientationRewards',
              pageBuilder: (context, state) => const NoTransitionPage(child: RewardsPage()),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.orientationLeaderboard,
        name: 'orientationLeaderboard',
        builder: (context, state) => const LeaderboardPage(),
      ),
      GoRoute(
        path: AppRoutes.orientationClubRanking,
        name: 'orientationClubRanking',
        builder: (context, state) => const ClubFairClubRankingPage(),
      ),
      GoRoute(
        path: AppRoutes.orientationSchedule,
        name: 'orientationSchedule',
        builder: (context, state) => const OrientationSchedulePage(),
      ),
      GoRoute(
        path: AppRoutes.orientationMyQr,
        name: 'orientationMyQr',
        builder: (context, state) => const OrientationMyQrPage(),
      ),
      GoRoute(
        path: AppRoutes.orientationClubStandQr,
        name: 'orientationClubStandQr',
        builder: (context, state) => const OrientationClubStandQrPage(),
      ),
      GoRoute(
        path: AppRoutes.orientationChallengeScan,
        name: 'orientationChallengeScan',
        // No challenge, no rule to evaluate — step back to the list rather
        // than opening a camera that cannot credit anything.
        redirect: (context, state) => (state.uri.queryParameters['id'] ?? '').isEmpty
            ? AppRoutes.orientationChallenges
            : null,
        builder: (context, state) =>
            ChallengeScanPage(challengeId: state.uri.queryParameters['id']!),
      ),
      // Both of these carry their subject in `extra`, so both need
      // [detailExtraGuard] to survive the app being restored on a detail page.
      GoRoute(
        path: AppRoutes.orientationPhotoQuestDetail,
        name: 'orientationPhotoQuestDetail',
        redirect: (context, state) =>
            detailExtraGuard<PhotoMission>(state.extra, AppRoutes.orientationChallenges),
        builder: (context, state) => PhotoQuestDetailPage(mission: state.extra as PhotoMission),
      ),
      GoRoute(
        path: AppRoutes.orientationPhotoQuests,
        name: 'orientationPhotoQuests',
        redirect: (context, state) => AppRoutes.orientationChallenges,
      ),
      GoRoute(
        path: AppRoutes.orientationRewardDetail,
        name: 'orientationRewardDetail',
        redirect: (context, state) =>
            detailExtraGuard<Reward>(state.extra, AppRoutes.orientationRewards),
        builder: (context, state) => RewardDetailPage(reward: state.extra as Reward),
      ),
      GoRoute(
        path: AppRoutes.orientationRewardHistory,
        name: 'orientationRewardHistory',
        builder: (context, state) => const RewardHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.orientationClosed,
        name: 'orientationClosed',
        builder: (context, state) => const OrientationClosedPage(),
      ),
      GoRoute(
        path: AppRoutes.orientationFreshmenNotice,
        name: 'orientationFreshmenNotice',
        builder: (context, state) => const OrientationFreshmenNoticePage(),
      ),
      // ─────────────────────────────────────────────────────────────────────────
      // SOCIAL MEAL PROGRAM (SVC) ROUTES
      // ─────────────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.svcDashboard,
        name: 'svcDashboard',
        builder: (context, state) => const SVCDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.svcQrScan,
        name: 'svcQrScan',
        builder: (context, state) => const SVCQrScanPage(),
      ),
      GoRoute(
        path: AppRoutes.svcSuccess,
        name: 'svcSuccess',
        builder: (context, state) => const SVCSuccessPage(),
      ),
      GoRoute(
        path: AppRoutes.svcCalendar,
        name: 'svcCalendar',
        builder: (context, state) => const SVCMealCalendarPage(),
      ),
      GoRoute(
        path: AppRoutes.svcStreak,
        name: 'svcStreak',
        builder: (context, state) => const SVCStreakPage(),
      ),
      GoRoute(
        path: AppRoutes.svcHistory,
        name: 'svcHistory',
        builder: (context, state) => const SVCMealHistoryPage(),
      ),
      // ─────────────────────────────────────────────────────────────────────────
      // PROFILE SECTION EDIT ROUTES
      // ─────────────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.editAboutMe,
        name: 'editAboutMe',
        builder: (context, state) => const EditAboutMePage(),
      ),
      GoRoute(
        path: AppRoutes.editExperience,
        name: 'editExperience',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return EditExperiencePage(experienceId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.editSkills,
        name: 'editSkills',
        builder: (context, state) => const EditSkillsPage(),
      ),
      GoRoute(
        path: AppRoutes.editAcademy,
        name: 'editAcademy',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return EditAcademyPage(academyId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.editUserActivity,
        name: 'editUserActivity',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return EditUserActivityPage(activityId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.eventDetails,
        name: 'eventDetails',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is NuEvent) return EventDetailsPage(event: extra);
          // Notification deep link: only the event URL travels through the
          // route (?link=…); resolve it against the loaded events list.
          return EventDetailsLoaderPage(
            link: state.uri.queryParameters['link'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.weatherDetails,
        name: 'weatherDetails',
        builder: (context, state) {
          final data = state.extra as WeatherData;
          return WeatherDetailsPage(data: data);
        },
      ),
      GoRoute(
        path: AppRoutes.exchangeDetails,
        name: 'exchangeDetails',
        builder: (context, state) {
          final data = state.extra as ExchangeData;
          return ExchangeDetailsPage(data: data);
        },
      ),

      // ── Share & Referral ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.shareApp,
        name: 'shareApp',
        builder: (context, state) => const SharePage(),
      ),
      GoRoute(
        path: AppRoutes.referral,
        name: 'referral',
        builder: (context, state) => const ReferralPage(),
      ),
      GoRoute(
        path: AppRoutes.contest,
        name: 'contest',
        builder: (context, state) => const ContestPage(),
      ),
    ],
    errorBuilder: (context, state) {
      // Track navigation errors so invalid deep links / bad routes are visible.
      // Using the singleton directly — no Riverpod ref needed here.
      AnalyticsNavigationObserver.instance;
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        body: Center(child: Text(l10n.common_routeNotFound(state.uri.toString()))),
      );
    },
  );
});
