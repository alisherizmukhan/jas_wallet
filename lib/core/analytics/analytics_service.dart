// ignore_for_file: use_null_aware_elements, empty_catches
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import 'analytics_events.dart';
import 'analytics_properties.dart';
import 'analytics_user_properties.dart';

/// App environment tag attached to every event as a super property.
const _kAppEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');

/// App version tag attached to every event as a super property.
const _kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0',
);

/// App build number.
const _kBuildNumber = String.fromEnvironment('BUILD_NUMBER', defaultValue: '1');

/// Central analytics facade. All Mixpanel calls go through here.
///
/// Screens and widgets MUST NOT call [Mixpanel] directly — always use
/// [AnalyticsService.instance] or the Riverpod [analyticsServiceProvider].
///
/// The service degrades gracefully to a no-op when [_kMixpanelToken] is
/// empty (e.g. local development without a token).
class AnalyticsService {
  AnalyticsService._();

  /// Application-wide singleton. Initialized once in [init].
  static final AnalyticsService instance = AnalyticsService._();

  Mixpanel? _mixpanel;
  bool _initialized = false;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Call once from [main] before [runApp], right after Firebase init.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  /// All errors are swallowed so analytics never prevents app launch.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Prefer a build-time --dart-define — unlike .env (which pubspec.yaml
    // bundles as a plain, unzip-and-read asset file inside the shipped
    // APK/IPA), a dart-define value is compiled into the binary and never
    // ships as a separately-extractable file. Falls back to the .env value
    // so existing build pipelines that haven't switched to --dart-define
    // yet keep working unchanged; falls back to empty string (no-op mode,
    // no crash, no data sent) if neither is set, e.g. in tests.
    const dartDefineToken = String.fromEnvironment('MIXPANEL_TOKEN');
    final token = dartDefineToken.isNotEmpty
        ? dartDefineToken
        : () {
            try {
              return dotenv.env['MIXPANEL_TOKEN'] ?? '';
            } catch (_) {
              return '';
            }
          }();
    if (token.isEmpty) {
      return;
    }

    try {
      final mixpanel = await Mixpanel.init(
        token,
        trackAutomaticEvents: false,
      );

      mixpanel.setServerURL('https://api-eu.mixpanel.com');

      _mixpanel = mixpanel;
      if (kDebugMode) {
        _mixpanel?.setLoggingEnabled(true);
      }
      await _registerSuperProperties();
    } catch (_) {
    }
  }

  /// Re-registers super properties. Call after locale or theme changes.
  Future<void> _registerSuperProperties() async {
    _mixpanel?.registerSuperProperties({
      AnalyticsProperties.platform: Platform.isIOS ? 'ios' : 'android',
      AnalyticsProperties.appVersion: _kAppVersion,
      AnalyticsProperties.buildNumber: _kBuildNumber,
      AnalyticsProperties.environment: _kAppEnv,
    });
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  void _track(String event, [Map<String, dynamic>? properties]) {
    try {
      _mixpanel?.track(event, properties: properties);
    } catch (e) {
    }
  }

  void _timeEvent(String event) {
    try {
      _mixpanel?.timeEvent(event);
    } catch (e) {
    }
  }

  /// Sanctioned escape hatch for feature-scoped analytics facades (e.g.
  /// `SaltoAnalytics`) whose event catalog is too large to live directly on
  /// this class. [Mixpanel] itself stays private to this file either way —
  /// every event still passes through here, so "all analytics go through
  /// AnalyticsService" holds even for feature facades.
  ///
  /// Prefer a dedicated `trackXxx` method above for anything that isn't
  /// owned by a feature-specific facade.
  void trackEvent(String event, [Map<String, dynamic>? properties]) {
    _track(event, properties);
  }

  // ── User identity ──────────────────────────────────────────────────────────

  /// Call after successful login or registration. Ties all future events to
  /// this [userId] in Mixpanel and flushes any anonymous events.
  void identify(String userId) {
    try {
      _mixpanel?.identify(userId);
    } catch (e) {
    }
  }

  /// Call on logout. Disassociates the device from the previous user so that
  /// subsequent events are anonymous until the next [identify] call.
  void reset() {
    try {
      _mixpanel?.reset();
    } catch (e) {
    }
  }

  /// Set a single People profile property. NEVER store passwords, PINs,
  /// tokens, or any sensitive credential data here.
  void setUserProperty(String key, dynamic value) {
    if (value == null) return;
    try {
      _mixpanel?.getPeople().set(key, value);
    } catch (e) {
    }
  }

  /// Set multiple People profile properties at once.
  ///
  /// The Mixpanel Flutter SDK only supports single-property [People.set] calls;
  /// this method batches them in a loop for convenience.
  void setUserProperties(Map<String, dynamic> properties) {
    if (properties.isEmpty) return;
    try {
      final people = _mixpanel?.getPeople();
      if (people == null) return;
      properties.forEach((key, value) {
        if (value != null) people.set(key, value);
      });
    } catch (e) {
    }
  }

  /// Update the [locale] super property so every subsequent event carries it.
  void updateLocale(String locale) {
    try {
      _mixpanel?.registerSuperProperties({AnalyticsProperties.locale: locale});
      setUserProperty(AnalyticsUserProperties.language, locale);
    } catch (e) {
    }
  }

  /// Update the [themeMode] super property.
  void updateThemeMode(String themeMode) {
    try {
      _mixpanel?.registerSuperProperties({
        AnalyticsProperties.themeMode: themeMode,
      });
      setUserProperty(AnalyticsUserProperties.themePreference, themeMode);
    } catch (e) {
    }
  }

  /// Sync user profile data to Mixpanel People. Safe — no sensitive fields.
  void syncUserProfile({
    String? displayName,
    String? email,
    String? userId,
    String? role,
    String? faculty,
    String? language,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    bool? isSvcMember,
  }) {
    final props = <String, dynamic>{};
    if (displayName != null) props[AnalyticsUserProperties.name] = displayName;
    if (email != null) props[AnalyticsUserProperties.email] = email;
    if (userId != null) props[AnalyticsUserProperties.userId] = userId;
    if (role != null) props[AnalyticsUserProperties.role] = role;
    if (faculty != null) props[AnalyticsUserProperties.faculty] = faculty;
    if (language != null) props[AnalyticsUserProperties.language] = language;
    if (notificationsEnabled != null) {
      props[AnalyticsUserProperties.notificationsEnabled] =
          notificationsEnabled;
    }
    if (biometricEnabled != null) {
      props[AnalyticsUserProperties.biometricEnabled] = biometricEnabled;
    }
    if (isSvcMember != null) {
      props[AnalyticsUserProperties.isSvcMember] = isSvcMember;
    }
    props[AnalyticsUserProperties.appVersion] = _kAppVersion;
    props[AnalyticsUserProperties.platform] = Platform.isIOS
        ? 'ios'
        : 'android';
    if (props.isNotEmpty) setUserProperties(props);
  }

  /// Flush queued events to Mixpanel immediately.
  ///
  /// Call on app background / termination and after critical funnel events
  /// (login, purchase, etc.) to ensure they are not lost.
  void flush() {
    try {
      _mixpanel?.flush();
    } catch (e) {
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TYPE-SAFE TRACK METHODS
  // ─────────────────────────────────────────────────────────────────────────────

  // ── App lifecycle ─────────────────────────────────────────────────────────

  void trackAppOpened({bool isColdStart = true}) {
    _track(AnalyticsEvents.appOpened, {'is_cold_start': isColdStart});
    if (isColdStart) _timeEvent(AnalyticsEvents.coldStartCompleted);
  }

  void trackColdStartCompleted() {
    _track(AnalyticsEvents.coldStartCompleted);
  }

  void trackAppForegrounded({int? backgroundDurationSeconds}) {
    _track(AnalyticsEvents.appForegrounded, {
      if (backgroundDurationSeconds != null)
        AnalyticsProperties.durationSeconds: backgroundDurationSeconds,
    });
  }

  void trackAppBackgrounded() {
    _track(AnalyticsEvents.appBackgrounded);
    flush();
  }

  void trackSessionRestored() {
    _track(AnalyticsEvents.sessionRestored);
  }

  // ── Onboarding & language ─────────────────────────────────────────────────

  void trackLanguageSelected(String languageCode) {
    _track(AnalyticsEvents.languageSelected, {
      AnalyticsProperties.languageCode: languageCode,
    });
    updateLocale(languageCode);
  }

  void trackOnboardingStarted() {
    _track(AnalyticsEvents.onboardingStarted);
    _timeEvent(AnalyticsEvents.onboardingCompleted);
  }

  void trackOnboardingStepCompleted({
    required int step,
    required int totalSteps,
    int? timeSpentMs,
  }) {
    _track(AnalyticsEvents.onboardingStepCompleted, {
      AnalyticsProperties.onboardingStep: step,
      AnalyticsProperties.onboardingTotalSteps: totalSteps,
      if (timeSpentMs != null) 'time_spent_ms': timeSpentMs,
    });
  }

  void trackOnboardingStepViewed({
    required int step,
    required int totalSteps,
    required String navigationMethod,
    int? timeSpentOnPreviousMs,
  }) {
    _track(AnalyticsEvents.onboardingStepViewed, {
      AnalyticsProperties.onboardingStep: step,
      AnalyticsProperties.onboardingTotalSteps: totalSteps,
      'navigation_method': navigationMethod,
      if (timeSpentOnPreviousMs != null)
        'time_spent_on_previous_ms': timeSpentOnPreviousMs,
    });
  }

  void trackOnboardingNextClicked({required int fromStep}) {
    _track(AnalyticsEvents.onboardingNextClicked, {
      AnalyticsProperties.onboardingStep: fromStep,
    });
  }

  void trackOnboardingBackClicked({required int fromStep}) {
    _track(AnalyticsEvents.onboardingBackClicked, {
      AnalyticsProperties.onboardingStep: fromStep,
    });
  }

  void trackOnboardingSwiped({
    required int fromStep,
    required int toStep,
    required String direction,
  }) {
    _track(AnalyticsEvents.onboardingSwiped, {
      'from_step': fromStep,
      'to_step': toStep,
      'direction': direction,
    });
  }

  void trackOnboardingAbandoned({
    required int atStep,
    required int totalSteps,
  }) {
    _track(AnalyticsEvents.onboardingAbandoned, {
      AnalyticsProperties.onboardingStep: atStep,
      AnalyticsProperties.onboardingTotalSteps: totalSteps,
    });
  }

  void trackOnboardingCompleted() {
    _track(AnalyticsEvents.onboardingCompleted);
  }

  void trackOnboardingSkipped({required int atStep}) {
    _track(AnalyticsEvents.onboardingSkipped, {
      AnalyticsProperties.onboardingStep: atStep,
    });
  }

  void trackWelcomeOpened() {
    _track(AnalyticsEvents.welcomeOpened);
  }

  // ── Authentication ────────────────────────────────────────────────────────

  void trackLoginStarted({String loginMethod = 'email'}) {
    _track(AnalyticsEvents.loginStarted, {
      AnalyticsProperties.loginMethod: loginMethod,
    });
    _timeEvent(AnalyticsEvents.loginSuccess);
  }

  void trackLoginSuccess({required String userId}) {
    _track(AnalyticsEvents.loginSuccess, {AnalyticsProperties.userId: userId});
    identify(userId);
    flush();
  }

  void trackLoginFailed({required String errorType}) {
    _track(AnalyticsEvents.loginFailed, {
      AnalyticsProperties.errorType: errorType,
    });
  }

  void trackRegistrationStarted() {
    _track(AnalyticsEvents.registrationStarted);
    _timeEvent(AnalyticsEvents.registrationSuccess);
  }

  void trackRegistrationSuccess({required String userId}) {
    _track(AnalyticsEvents.registrationSuccess, {
      AnalyticsProperties.userId: userId,
    });
    identify(userId);
    setUserProperty(
      AnalyticsUserProperties.firstSeen,
      DateTime.now().toIso8601String(),
    );
    flush();
  }

  void trackRegistrationFailed({required String errorType}) {
    _track(AnalyticsEvents.registrationFailed, {
      AnalyticsProperties.errorType: errorType,
    });
  }

  void trackPersonalDataConsentAccepted() {
    _track(AnalyticsEvents.personalDataConsentAccepted);
  }

  void trackProfileCreationCompleted() {
    _track(AnalyticsEvents.profileCreationCompleted);
  }

  void trackForgotPasswordStarted() {
    _track(AnalyticsEvents.forgotPasswordStarted);
  }

  void trackPasswordResetCompleted() {
    _track(AnalyticsEvents.passwordResetCompleted);
  }

  void trackVerificationCompleted({required String flow}) {
    _track(AnalyticsEvents.verificationCompleted, {'flow': flow});
  }

  // ── PIN & biometric ───────────────────────────────────────────────────────

  void trackPinCreated() {
    _track(AnalyticsEvents.pinCreated);
  }

  void trackPinVerified() {
    _track(AnalyticsEvents.pinVerified);
  }

  void trackPinFailed({required int attemptsRemaining}) {
    _track(AnalyticsEvents.pinFailed, {
      AnalyticsProperties.attemptsRemaining: attemptsRemaining,
    });
  }

  void trackPinLockoutTriggered() {
    _track(AnalyticsEvents.pinLockoutTriggered);
    flush();
  }

  void trackBiometricEnabled() {
    _track(AnalyticsEvents.biometricEnabled);
    setUserProperty(AnalyticsUserProperties.biometricEnabled, true);
  }

  void trackBiometricDisabled() {
    _track(AnalyticsEvents.biometricDisabled);
    setUserProperty(AnalyticsUserProperties.biometricEnabled, false);
  }

  void trackBiometricSetupSkipped() {
    _track(AnalyticsEvents.biometricSetupSkipped);
  }

  void trackBiometricAuthSuccess() {
    _track(AnalyticsEvents.biometricAuthSuccess);
  }

  void trackBiometricAuthFailed({String? reason}) {
    _track(AnalyticsEvents.biometricAuthFailed, {
      if (reason != null) AnalyticsProperties.failureReason: reason,
    });
  }

  // ── Logout & session ──────────────────────────────────────────────────────

  void trackLogout({bool isForced = false}) {
    _track(AnalyticsEvents.logoutTriggered, {'is_forced': isForced});
    flush();
    reset();
  }

  void trackSessionExpired() {
    _track(AnalyticsEvents.sessionExpired);
    flush();
    reset();
  }

  void trackAppLocked() {
    _track(AnalyticsEvents.appLocked);
    flush();
  }

  // ── Screen tracking ───────────────────────────────────────────────────────

  /// Called by [AnalyticsNavigationObserver] automatically. Prefer the
  /// observer over calling this directly.
  void trackScreenOpened({
    required String screenName,
    String? previousScreen,
    Map<String, dynamic>? extraProperties,
  }) {
    _track(AnalyticsEvents.screenOpened, {
      AnalyticsProperties.screenName: screenName,
      if (previousScreen != null)
        AnalyticsProperties.previousScreen: previousScreen,
      ...?extraProperties,
    });
    _timeEvent(AnalyticsEvents.screenClosed);
  }

  /// Called by [AnalyticsNavigationObserver] automatically.
  void trackScreenClosed({required String screenName, int? durationMs}) {
    _track(AnalyticsEvents.screenClosed, {
      AnalyticsProperties.screenName: screenName,
      if (durationMs != null) AnalyticsProperties.screenDurationMs: durationMs,
    });
  }

  // ── Bottom navigation ─────────────────────────────────────────────────────

  void trackBottomTabChanged({
    required int fromIndex,
    required int toIndex,
    required String toTabName,
  }) {
    _track(AnalyticsEvents.bottomTabChanged, {
      AnalyticsProperties.fromTab: fromIndex,
      AnalyticsProperties.toTab: toIndex,
      AnalyticsProperties.tabName: toTabName,
    });
  }

  // ── Home ──────────────────────────────────────────────────────────────────

  void trackHomeOpened() {
    _track(AnalyticsEvents.homeOpened);
  }

  void trackHomeRefreshed() {
    _track(AnalyticsEvents.homeRefreshTriggered);
  }

  void trackHomeBannerTapped({required String bannerName}) {
    _track(AnalyticsEvents.homeBannerTapped, {'banner_name': bannerName});
  }

  // ── Hub behavioral ────────────────────────────────────────────────────────

  void trackHubItemTapped({
    required String itemName,
    bool isComingSoon = false,
  }) {
    _track(AnalyticsEvents.hubItemTapped, {
      'item_name': itemName,
      'is_coming_soon': isComingSoon,
    });
  }

  void trackHubSearchUsed({required String query, required int resultCount}) {
    _track(AnalyticsEvents.hubSearchUsed, {
      AnalyticsProperties.query: query,
      AnalyticsProperties.resultCount: resultCount,
    });
  }

  void trackHubSearchResultTapped({required String itemName}) {
    _track(AnalyticsEvents.hubSearchResultTapped, {'item_name': itemName});
  }

  // ── Stories ───────────────────────────────────────────────────────────────

  void trackStoryCardTapped({
    required String userId,
    required String userName,
  }) {
    _track(AnalyticsEvents.storyCardTapped, {
      'user_id': userId,
      'user_name': userName,
    });
  }

  void trackStorySetViewed({
    required String authorId,
    required int storyCount,
  }) {
    _track(AnalyticsEvents.storySetViewed, {
      'author_id': authorId,
      'story_count': storyCount,
    });
  }

  void trackStorySetCompleted({required String authorId}) {
    _track(AnalyticsEvents.storySetCompleted, {'author_id': authorId});
  }

  void trackStoryUserNavigated({required String direction}) {
    _track(AnalyticsEvents.storyUserNavigated, {'direction': direction});
  }

  // ── Settings behavioral ───────────────────────────────────────────────────

  void trackSettingsItemNavigated({required String destination}) {
    _track(AnalyticsEvents.settingsItemNavigated, {'destination': destination});
  }

  void trackSettingsCityChanged({required String city}) {
    _track(AnalyticsEvents.settingsCityChanged, {'city': city});
  }

  // ── SOS behavioral ────────────────────────────────────────────────────────

  void trackSosUrgencyChanged({required String urgency}) {
    _track(AnalyticsEvents.sosUrgencyChanged, {
      AnalyticsProperties.sosUrgency: urgency,
    });
  }

  void trackSosHistoryClicked() {
    _track(AnalyticsEvents.sosHistoryClicked);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  /// Track when a push notification is received by the device.
  void trackPushReceived({
    required String category,
    String? messageId,
    String notificationState = 'foreground',
  }) {
    _track(AnalyticsEvents.pushReceived, {
      AnalyticsProperties.notificationCategory: category,
      if (messageId != null) AnalyticsProperties.notificationId: messageId,
      AnalyticsProperties.notificationState: notificationState,
    });
  }

  /// Track when the user taps a push notification.
  void trackPushOpened({
    required String category,
    String? messageId,
    required String notificationState,
  }) {
    _track(AnalyticsEvents.pushOpened, {
      AnalyticsProperties.notificationCategory: category,
      if (messageId != null) AnalyticsProperties.notificationId: messageId,
      AnalyticsProperties.notificationState: notificationState,
    });
  }

  void trackPushRedirectStarted({required String route}) {
    _track(AnalyticsEvents.pushRedirectStarted, {
      AnalyticsProperties.route: route,
    });
  }

  void trackPushRedirectCompleted({required String route}) {
    _track(AnalyticsEvents.pushRedirectCompleted, {
      AnalyticsProperties.route: route,
    });
  }

  void trackNotificationDetailOpened({
    required String notificationId,
    required String category,
  }) {
    _track(AnalyticsEvents.notificationDetailOpened, {
      AnalyticsProperties.notificationId: notificationId,
      AnalyticsProperties.notificationCategory: category,
    });
  }

  void trackNotificationActionClicked({
    required String notificationId,
    required String action,
  }) {
    _track(AnalyticsEvents.notificationActionClicked, {
      AnalyticsProperties.notificationId: notificationId,
      AnalyticsProperties.notificationAction: action,
    });
  }

  void trackNotificationsSettingsOpened() {
    _track(AnalyticsEvents.notificationsSettingsOpened);
  }

  void trackNotificationSettingChanged({
    required String settingName,
    required bool enabled,
  }) {
    _track(AnalyticsEvents.notificationSettingChanged, {
      AnalyticsProperties.settingName: settingName,
      AnalyticsProperties.settingEnabled: enabled,
    });
  }

  void trackNotificationOpenedFromList({
    required String notificationId,
    required String category,
    required bool wasUnread,
  }) {
    _track(AnalyticsEvents.notificationOpenedFromList, {
      AnalyticsProperties.notificationId: notificationId,
      AnalyticsProperties.notificationCategory: category,
      'was_unread': wasUnread,
    });
  }

  void trackNotificationDeletedFromList({
    required String notificationId,
    required String category,
  }) {
    _track(AnalyticsEvents.notificationDeletedFromList, {
      AnalyticsProperties.notificationId: notificationId,
      AnalyticsProperties.notificationCategory: category,
    });
  }

  void trackNotificationsFilterChanged({required String filter}) {
    _track(AnalyticsEvents.notificationsFilterChanged, {'filter': filter});
  }

  void trackNotificationsMarkAllReadClicked() {
    _track(AnalyticsEvents.notificationsMarkAllReadClicked);
  }

  // ── Salto access ──────────────────────────────────────────────────────────
  //
  // SALTO's own event catalog is large enough (activation funnel, unlock
  // funnel, readiness, Bluetooth, Internet, SDK, reliability) that it lives
  // in a dedicated facade, `SaltoAnalytics` (lib/features/salto/analytics/
  // salto_analytics.dart), built on top of [trackEvent] above rather than
  // as methods directly on this class. Screen-open/close for "Salto Access"
  // / "Salto Activation" / "Student Card" are already covered generically
  // by [AnalyticsNavigationObserver] (every named GoRouter route), so
  // SaltoAnalytics does not duplicate a screen-view event of its own.

  // ── Social Meal (SVC) ─────────────────────────────────────────────────────

  void trackSvcOpened() {
    _track(AnalyticsEvents.svcOpened);
  }

  void trackSvcQrOpened() {
    _track(AnalyticsEvents.svcQrOpened);
  }

  void trackSvcQrRefreshed() {
    _track(AnalyticsEvents.svcQrRefreshed);
  }

  void trackSvcBalanceViewed({int? balance}) {
    _track(AnalyticsEvents.svcBalanceViewed, {
      if (balance != null) AnalyticsProperties.mealBalance: balance,
    });
  }

  void trackSvcHistoryOpened() {
    _track(AnalyticsEvents.svcHistoryOpened);
  }

  void trackSvcLeaderboardOpened() {
    _track(AnalyticsEvents.svcLeaderboardOpened);
  }

  void trackSvcStreakOpened() {
    _track(AnalyticsEvents.svcStreakOpened);
  }

  void trackSvcCalendarOpened() {
    _track(AnalyticsEvents.svcCalendarOpened);
  }

  void trackSvcScanAttempted() {
    _track(AnalyticsEvents.svcScanAttempted);
    _timeEvent(AnalyticsEvents.svcScanSuccess);
  }

  void trackSvcScanSuccess({String? mealType}) {
    _track(AnalyticsEvents.svcScanSuccess, {
      if (mealType != null) AnalyticsProperties.mealType: mealType,
    });
  }

  void trackSvcScanFailed({required String reason}) {
    _track(AnalyticsEvents.svcScanFailed, {
      AnalyticsProperties.failureReason: reason,
    });
  }

  // ── Student Clubs ─────────────────────────────────────────────────────────

  void trackClubsOpened() {
    _track(AnalyticsEvents.clubsOpened);
  }

  void trackClubOpened({required String clubId, required String clubName}) {
    _track(AnalyticsEvents.clubOpened, {
      AnalyticsProperties.clubId: clubId,
      AnalyticsProperties.clubName: clubName,
    });
  }

  void trackClubJoinClicked({
    required String clubId,
    required String clubName,
  }) {
    _track(AnalyticsEvents.clubJoinClicked, {
      AnalyticsProperties.clubId: clubId,
      AnalyticsProperties.clubName: clubName,
    });
    _timeEvent(AnalyticsEvents.clubApplicationSubmitted);
  }

  void trackClubApplicationStarted({required String clubId}) {
    _track(AnalyticsEvents.clubApplicationStarted, {
      AnalyticsProperties.clubId: clubId,
    });
  }

  void trackClubApplicationSubmitted({required String clubId}) {
    _track(AnalyticsEvents.clubApplicationSubmitted, {
      AnalyticsProperties.clubId: clubId,
    });
  }

  void trackClubFavoriteAdded({required String clubId}) {
    _track(AnalyticsEvents.clubFavoriteAdded, {
      AnalyticsProperties.clubId: clubId,
    });
  }

  void trackClubFavoriteRemoved({required String clubId}) {
    _track(AnalyticsEvents.clubFavoriteRemoved, {
      AnalyticsProperties.clubId: clubId,
    });
  }

  // ── Classroom ─────────────────────────────────────────────────────────────

  void trackClassroomOpened() {
    _track(AnalyticsEvents.classroomOpened);
  }

  void trackCourseOpened({
    required String courseId,
    required String courseName,
  }) {
    _track(AnalyticsEvents.courseOpened, {
      AnalyticsProperties.courseId: courseId,
      AnalyticsProperties.courseName: courseName,
    });
  }

  void trackCoursePostCreated({required String courseId}) {
    _track(AnalyticsEvents.coursePostCreated, {
      AnalyticsProperties.courseId: courseId,
    });
  }

  void trackCourseMaterialUploaded({
    required String courseId,
    String? materialType,
  }) {
    _track(AnalyticsEvents.courseMaterialUploaded, {
      AnalyticsProperties.courseId: courseId,
      if (materialType != null) AnalyticsProperties.materialType: materialType,
    });
  }

  void trackCourseCreated({
    required String courseCode,
    required String courseType,
  }) {
    _track(AnalyticsEvents.courseCreated, {
      AnalyticsProperties.courseCode: courseCode,
      AnalyticsProperties.courseType: courseType,
    });
  }

  void trackCourseJoinedByCode({required String courseCode}) {
    _track(AnalyticsEvents.courseJoinedByCode, {
      AnalyticsProperties.courseCode: courseCode,
    });
  }

  void trackProfessorDashboardOpened() {
    _track(AnalyticsEvents.professorDashboardOpened);
  }

  // ── Attendance ────────────────────────────────────────────────────────────

  void trackAttendanceStudentOpened() {
    _track(AnalyticsEvents.attendanceStudentOpened);
  }

  void trackAttendanceTeacherOpened() {
    _track(AnalyticsEvents.attendanceTeacherOpened);
  }

  void trackQrScanAttempted() {
    _track(AnalyticsEvents.qrScanAttempted);
    _timeEvent(AnalyticsEvents.qrScanSuccess);
  }

  void trackQrScanSuccess({required String sessionId, int? xpEarned}) {
    _track(AnalyticsEvents.qrScanSuccess, {
      AnalyticsProperties.sessionId: sessionId,
      if (xpEarned != null) AnalyticsProperties.xpEarned: xpEarned,
    });
  }

  void trackQrScanFailed({required String reason}) {
    _track(AnalyticsEvents.qrScanFailed, {
      AnalyticsProperties.failureReason: reason,
    });
  }

  void trackAttendanceHistoryOpened() {
    _track(AnalyticsEvents.attendanceHistoryOpened);
  }

  void trackAttendanceSessionCreated({required String sessionId}) {
    _track(AnalyticsEvents.attendanceSessionCreated, {
      AnalyticsProperties.sessionId: sessionId,
    });
  }

  void trackAttendanceRewardClaimed({required String rewardId, int? xpEarned}) {
    _track(AnalyticsEvents.attendanceRewardClaimed, {
      'reward_id': rewardId,
      if (xpEarned != null) AnalyticsProperties.xpEarned: xpEarned,
    });
  }

  // ── Job Finder ────────────────────────────────────────────────────────────

  void trackJobFinderOpened() {
    _track(AnalyticsEvents.jobFinderOpened);
  }

  void trackJobCategoryOpened({
    required String categoryId,
    required String categoryName,
  }) {
    _track(AnalyticsEvents.jobCategoryOpened, {
      AnalyticsProperties.jobCategoryId: categoryId,
      AnalyticsProperties.jobCategoryName: categoryName,
    });
  }

  void trackJobDetailOpened({required String jobId, required String jobTitle}) {
    _track(AnalyticsEvents.jobDetailOpened, {
      AnalyticsProperties.jobId: jobId,
      AnalyticsProperties.jobTitle: jobTitle,
    });
  }

  void trackJobApplyClicked({required String jobId}) {
    _track(AnalyticsEvents.jobApplyClicked, {AnalyticsProperties.jobId: jobId});
  }

  // ── Orientation Week ──────────────────────────────────────────────────────

  void trackOrientationOpened() {
    _track(AnalyticsEvents.orientationOpened);
  }

  void trackOrientationChallengeOpened({required String challengeId}) {
    _track(AnalyticsEvents.orientationChallengeOpened, {'challenge_id': challengeId});
  }

  void trackOrientationChallengeCompleted({required String challengeId}) {
    _track(AnalyticsEvents.orientationChallengeCompleted, {'challenge_id': challengeId});
  }

  void trackOrientationBingoOpened() {
    _track(AnalyticsEvents.orientationBingoOpened);
  }

  void trackOrientationBingoGenerated() {
    _track(AnalyticsEvents.orientationBingoGenerated);
  }

  void trackOrientationBingoCellCompleted({
    required String cellId,
    bool completedLine = false,
    bool completedCard = false,
  }) {
    _track(AnalyticsEvents.orientationBingoCellCompleted, {
      'cell_id': cellId,
      'completed_line': completedLine,
      'completed_card': completedCard,
    });
  }

  void trackOrientationPhotoUploaded({required String questId}) {
    _track(AnalyticsEvents.orientationPhotoUploaded, {'quest_id': questId});
  }

  void trackOrientationLeaderboardOpened() {
    _track(AnalyticsEvents.orientationLeaderboardOpened);
  }

  void trackOrientationRewardRedeemed({required String rewardId}) {
    _track(AnalyticsEvents.orientationRewardRedeemed, {'reward_id': rewardId});
  }

  void trackOrientationTokensEarned({required int amount, required String source}) {
    _track(AnalyticsEvents.orientationTokensEarned, {'amount': amount, 'source': source});
  }

  void trackOrientationScannerOpened() {
    _track(AnalyticsEvents.orientationScannerOpened);
  }

  void trackOrientationScannerSuccess() {
    _track(AnalyticsEvents.orientationScannerSuccess);
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  void trackProfileOpened() {
    _track(AnalyticsEvents.profileOpened);
  }

  void trackMyProfileOpened() {
    _track(AnalyticsEvents.myProfileOpened);
  }

  void trackProfileEdited({int? fieldCount}) {
    _track(AnalyticsEvents.profileEdited, {
      if (fieldCount != null) AnalyticsProperties.fieldCount: fieldCount,
    });
  }

  void trackAvatarChanged() {
    _track(AnalyticsEvents.avatarChanged);
  }

  void trackResumeOpened() {
    _track(AnalyticsEvents.resumeOpened);
  }

  void trackResumeSectionEdited({required String section}) {
    _track(AnalyticsEvents.resumeSectionEdited, {'section': section});
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  void trackSettingsOpened() {
    _track(AnalyticsEvents.settingsOpened);
  }

  void trackThemeChanged({required String themeName}) {
    _track(AnalyticsEvents.themeChanged, {
      AnalyticsProperties.themeName: themeName,
    });
    updateThemeMode(themeName);
  }

  void trackLanguageChanged({required String languageCode}) {
    _track(AnalyticsEvents.languageChanged, {
      AnalyticsProperties.languageCode: languageCode,
    });
    updateLocale(languageCode);
  }

  void trackSecurityPageOpened() {
    _track(AnalyticsEvents.securityPageOpened);
  }

  void trackAboutAppOpened() {
    _track(AnalyticsEvents.aboutAppOpened);
  }

  void trackHelpOpened() {
    _track(AnalyticsEvents.helpOpened);
  }

  // ── Gamification ──────────────────────────────────────────────────────────

  void trackMyLevelOpened() {
    _track(AnalyticsEvents.myLevelOpened);
  }

  void trackTasksOpened() {
    _track(AnalyticsEvents.tasksOpened);
  }

  void trackTaskCompleted({required String taskId, required String taskName}) {
    _track(AnalyticsEvents.taskCompleted, {
      AnalyticsProperties.taskId: taskId,
      AnalyticsProperties.taskName: taskName,
    });
  }

  void trackPointsOpened() {
    _track(AnalyticsEvents.pointsOpened);
  }

  void trackRankingOpened() {
    _track(AnalyticsEvents.rankingOpened);
  }

  void trackAchievementsOpened() {
    _track(AnalyticsEvents.achievementsOpened);
  }

  void trackAchievementUnlocked({
    required String achievementId,
    required String achievementName,
  }) {
    _track(AnalyticsEvents.achievementUnlocked, {
      AnalyticsProperties.achievementId: achievementId,
      AnalyticsProperties.achievementName: achievementName,
    });
  }

  // ── Social / Chat ─────────────────────────────────────────────────────────

  void trackConversationsOpened() {
    _track(AnalyticsEvents.conversationsOpened);
  }

  void trackChatOpened({required String targetUserId}) {
    _track(AnalyticsEvents.chatOpened, {
      AnalyticsProperties.targetUserId: targetUserId,
    });
  }

  void trackMessageSent() {
    _track(AnalyticsEvents.messageSent);
  }

  void trackUserSearchOpened() {
    _track(AnalyticsEvents.userSearchOpened);
  }

  void trackUserSearchQuerySubmitted({
    required String query,
    int? resultCount,
  }) {
    _track(AnalyticsEvents.userSearchQuerySubmitted, {
      AnalyticsProperties.query: query,
      if (resultCount != null) AnalyticsProperties.resultCount: resultCount,
    });
  }

  void trackPublicProfileOpened({required String targetUserId}) {
    _track(AnalyticsEvents.publicProfileOpened, {
      AnalyticsProperties.targetUserId: targetUserId,
    });
  }

  void trackFollowUser({required String targetUserId}) {
    _track(AnalyticsEvents.followUser, {
      AnalyticsProperties.targetUserId: targetUserId,
    });
  }

  void trackUnfollowUser({required String targetUserId}) {
    _track(AnalyticsEvents.unfollowUser, {
      AnalyticsProperties.targetUserId: targetUserId,
    });
  }

  // ── Fintech ───────────────────────────────────────────────────────────────

  void trackFintechOpened() {
    _track(AnalyticsEvents.fintechOpened);
  }

  void trackFintechTokensOpened() {
    _track(AnalyticsEvents.fintechTokensOpened);
  }

  void trackFintechNftOpened() {
    _track(AnalyticsEvents.fintechNftOpened);
  }

  void trackFintechDiscountsOpened() {
    _track(AnalyticsEvents.fintechDiscountsOpened);
  }

  void trackFintechCardCustomizationOpened() {
    _track(AnalyticsEvents.fintechCardCustomizationOpened);
  }

  // ── Weather & Exchange ────────────────────────────────────────────────────

  void trackWeatherDetailsOpened() {
    _track(AnalyticsEvents.weatherDetailsOpened);
  }

  void trackExchangeDetailsOpened() {
    _track(AnalyticsEvents.exchangeDetailsOpened);
  }

  // ── Tutorials & Events ────────────────────────────────────────────────────

  void trackTutorialsOpened() {
    _track(AnalyticsEvents.tutorialsOpened);
  }

  void trackTutorialBannerTapped({required String tutorialId}) {
    _track(AnalyticsEvents.tutorialBannerTapped, {'tutorial_id': tutorialId});
  }

  void trackTutorialDetailOpened({required String tutorialId}) {
    _track(AnalyticsEvents.tutorialDetailOpened, {'tutorial_id': tutorialId});
  }

  void trackEventDetailOpened({
    required String eventId,
    required String eventTitle,
  }) {
    _track(AnalyticsEvents.eventDetailOpened, {
      'event_id': eventId,
      'event_title': eventTitle,
    });
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void trackSearchOpened() {
    _track(AnalyticsEvents.searchOpened);
  }

  void trackSearchQuerySubmitted({required String query, int? resultCount}) {
    _track(AnalyticsEvents.searchQuerySubmitted, {
      AnalyticsProperties.query: query,
      if (resultCount != null) AnalyticsProperties.resultCount: resultCount,
    });
  }

  void trackSearchResultOpened({
    required String resultType,
    required String resultId,
  }) {
    _track(AnalyticsEvents.searchResultOpened, {
      'result_type': resultType,
      'result_id': resultId,
    });
  }

  // ── Empty states ──────────────────────────────────────────────────────────

  void trackEmptyStateViewed({required String screen, required String reason}) {
    _track(AnalyticsEvents.emptyStateViewed, {
      AnalyticsProperties.screenName: screen,
      AnalyticsProperties.failureReason: reason,
    });
  }

  void trackRetryTriggered({required String screen}) {
    _track(AnalyticsEvents.retryTriggered, {
      AnalyticsProperties.screenName: screen,
    });
  }

  // ── Errors ────────────────────────────────────────────────────────────────

  void trackApiError({
    required String endpoint,
    required int statusCode,
    String? errorType,
  }) {
    _track(AnalyticsEvents.apiError, {
      AnalyticsProperties.endpoint: endpoint,
      AnalyticsProperties.httpStatusCode: statusCode,
      if (errorType != null) AnalyticsProperties.errorType: errorType,
    });
  }

  void trackNavigationError({required String attemptedRoute}) {
    _track(AnalyticsEvents.navigationError, {
      AnalyticsProperties.attemptedRoute: attemptedRoute,
    });
  }

  void trackAuthError({required String errorType}) {
    _track(AnalyticsEvents.authError, {
      AnalyticsProperties.errorType: errorType,
    });
  }

  void trackUnexpectedException({
    required String errorType,
    String? sourceScreen,
  }) {
    _track(AnalyticsEvents.unexpectedException, {
      AnalyticsProperties.errorType: errorType,
      if (sourceScreen != null) AnalyticsProperties.sourceScreen: sourceScreen,
    });
  }

  // ── SOS (Campus Security) ─────────────────────────────────────────────────

  void trackSosOpened() {
    _track(AnalyticsEvents.sosOpened);
  }

  void trackSosHistoryOpened() {
    _track(AnalyticsEvents.sosHistoryOpened);
  }

  void trackSosDetailOpened({
    required String reportId,
    required String status,
    required String urgency,
  }) {
    _track(AnalyticsEvents.sosDetailOpened, {
      AnalyticsProperties.sosReportId: reportId,
      AnalyticsProperties.sosReportStatus: status,
      AnalyticsProperties.sosUrgency: urgency,
    });
  }

  void trackSosCall102Clicked() {
    _track(AnalyticsEvents.sosCall102Clicked, {
      AnalyticsProperties.sosCallTarget: '102',
    });
  }

  void trackSosCall112Clicked() {
    _track(AnalyticsEvents.sosCall112Clicked, {
      AnalyticsProperties.sosCallTarget: '112',
    });
  }

  void trackSosCallCampusSecurityClicked() {
    _track(AnalyticsEvents.sosCallCampusSecurityClicked, {
      AnalyticsProperties.sosCallTarget: 'campus',
    });
  }

  void trackSosReportStarted() {
    _track(AnalyticsEvents.sosReportStarted);
    _timeEvent(AnalyticsEvents.sosReportSubmitted);
  }

  void trackSosReportImageAdded() {
    _track(AnalyticsEvents.sosReportImageAdded);
  }

  void trackSosReportSubmitted({
    required String urgency,
    required bool hasImage,
  }) {
    _track(AnalyticsEvents.sosReportSubmitted, {
      AnalyticsProperties.sosUrgency: urgency,
      AnalyticsProperties.sosHasImage: hasImage,
    });
  }

  void trackSosReportSubmitSuccess({
    required String urgency,
    required bool hasImage,
  }) {
    _track(AnalyticsEvents.sosReportSubmitSuccess, {
      AnalyticsProperties.sosUrgency: urgency,
      AnalyticsProperties.sosHasImage: hasImage,
    });
    flush();
  }

  void trackSosReportSubmitFailed({required String reason}) {
    _track(AnalyticsEvents.sosReportSubmitFailed, {
      AnalyticsProperties.failureReason: reason,
    });
  }

  void trackSosHistoryLoaded({required int reportCount}) {
    _track(AnalyticsEvents.sosHistoryLoaded, {
      AnalyticsProperties.sosReportCount: reportCount,
    });
  }

  void trackSosHistoryEmpty() {
    _track(AnalyticsEvents.sosHistoryEmpty);
  }

  void trackSosReportOpened({
    required String reportId,
    required String urgency,
    required String status,
  }) {
    _track(AnalyticsEvents.sosReportOpened, {
      AnalyticsProperties.sosReportId: reportId,
      AnalyticsProperties.sosUrgency: urgency,
      AnalyticsProperties.sosReportStatus: status,
    });
  }

  void trackSosApiError({
    required String endpoint,
    int? statusCode,
    String? errorType,
  }) {
    _track(AnalyticsEvents.sosApiError, {
      AnalyticsProperties.endpoint: endpoint,
      if (statusCode != null) AnalyticsProperties.httpStatusCode: statusCode,
      if (errorType != null) AnalyticsProperties.errorType: errorType,
    });
  }

  void trackSosImageUploadFailed({required String reason}) {
    _track(AnalyticsEvents.sosImageUploadFailed, {
      AnalyticsProperties.failureReason: reason,
    });
  }

  void trackSosDialerUnavailable({required String callTarget}) {
    _track(AnalyticsEvents.sosDialerUnavailable, {
      AnalyticsProperties.sosCallTarget: callTarget,
    });
  }

  // ── Screen active time ────────────────────────────────────────────────────

  void trackScreenActiveTime({
    required String screenName,
    required int activeTimeMs,
  }) {
    _track(AnalyticsEvents.screenActiveTime, {
      AnalyticsProperties.screenName: screenName,
      AnalyticsProperties.activeTimeMs: activeTimeMs,
    });
  }

  // ── Rage tap (UX friction) ────────────────────────────────────────────────

  void trackRageTapDetected({
    required String componentName,
    String? screenName,
    required int tapCount,
  }) {
    _track(AnalyticsEvents.uiRageTapDetected, {
      AnalyticsProperties.componentName: componentName,
      if (screenName != null) AnalyticsProperties.screenName: screenName,
      AnalyticsProperties.rageTapCount: tapCount,
    });
  }

  // ── Critical flows ────────────────────────────────────────────────────────

  void trackFlowStarted({required String flowName, String? entryPoint}) {
    _track(AnalyticsEvents.flowStarted, {
      AnalyticsProperties.flowName: flowName,
      if (entryPoint != null) AnalyticsProperties.entryPoint: entryPoint,
    });
  }

  void trackFlowCompleted({
    required String flowName,
    int? durationMs,
    Map<String, dynamic>? extra,
  }) {
    _track(AnalyticsEvents.flowCompleted, {
      AnalyticsProperties.flowName: flowName,
      if (durationMs != null) AnalyticsProperties.durationMs: durationMs,
      ...?extra,
    });
    flush();
  }

  void trackFlowAbandoned({
    required String flowName,
    String? atStep,
    int? durationMs,
  }) {
    _track(AnalyticsEvents.flowAbandoned, {
      AnalyticsProperties.flowName: flowName,
      if (atStep != null) AnalyticsProperties.flowStep: atStep,
      if (durationMs != null) AnalyticsProperties.durationMs: durationMs,
    });
  }

  void trackFlowFailed({
    required String flowName,
    String? reason,
    String? atStep,
  }) {
    _track(AnalyticsEvents.flowFailed, {
      AnalyticsProperties.flowName: flowName,
      if (reason != null) AnalyticsProperties.failureReason: reason,
      if (atStep != null) AnalyticsProperties.flowStep: atStep,
    });
  }

  // ── Scroll depth ──────────────────────────────────────────────────────────

  void trackScrollDepthReached({
    required String screenName,
    required int depthPercent,
  }) {
    _track(AnalyticsEvents.scrollDepthReached, {
      AnalyticsProperties.screenName: screenName,
      AnalyticsProperties.scrollDepth: depthPercent,
    });
  }

  // ── Feature adoption ──────────────────────────────────────────────────────

  void trackFeatureFirstUsed({required String featureName}) {
    _track(AnalyticsEvents.featureFirstUsed, {
      AnalyticsProperties.featureName: featureName,
    });
  }

  void trackFeatureRevisited({required String featureName}) {
    _track(AnalyticsEvents.featureRevisited, {
      AnalyticsProperties.featureName: featureName,
    });
  }

  // ── API performance ───────────────────────────────────────────────────────

  void trackApiRequestCompleted({
    required String endpoint,
    required String method,
    required int statusCode,
    required int durationMs,
    bool isSlow = false,
  }) {
    _track(AnalyticsEvents.apiRequestCompleted, {
      AnalyticsProperties.endpoint: endpoint,
      AnalyticsProperties.httpMethod: method,
      AnalyticsProperties.httpStatusCode: statusCode,
      AnalyticsProperties.durationMs: durationMs,
      AnalyticsProperties.isSlow: isSlow,
    });
  }

  void trackApiRequestFailed({
    required String endpoint,
    required String method,
    int? statusCode,
    String? errorType,
    int? durationMs,
  }) {
    _track(AnalyticsEvents.apiRequestFailed, {
      AnalyticsProperties.endpoint: endpoint,
      AnalyticsProperties.httpMethod: method,
      if (statusCode != null) AnalyticsProperties.httpStatusCode: statusCode,
      if (errorType != null) AnalyticsProperties.errorType: errorType,
      if (durationMs != null) AnalyticsProperties.durationMs: durationMs,
    });
  }

  // ── Share ─────────────────────────────────────────────────────────────────

  void trackShareAppOpened() {
    _track(AnalyticsEvents.shareAppOpened);
  }

  void trackShareAppClicked({required String method}) {
    _track(AnalyticsEvents.shareAppClicked, {'method': method});
  }

  void trackShareLinkCopied() {
    _track(AnalyticsEvents.shareLinkCopied);
  }

  // ── Referral ──────────────────────────────────────────────────────────────

  void trackReferralScreenOpened() {
    _track(AnalyticsEvents.referralScreenOpened);
  }

  void trackReferralCodeCopied() {
    _track(AnalyticsEvents.referralCodeCopied);
  }

  void trackReferralShareClicked() {
    _track(AnalyticsEvents.referralShareClicked);
  }

  // ── Rate App ──────────────────────────────────────────────────────────────

  void trackRateAppClicked() {
    _track(AnalyticsEvents.rateAppClicked);
  }

  void trackRateAppCompleted() {
    _track(AnalyticsEvents.rateAppCompleted);
  }

  // ── App Update ────────────────────────────────────────────────────────────

  /// Optional-update bottom sheet became visible.
  void trackUpdatePromptShown({
    required String currentVersion,
    required String latestVersion,
  }) {
    _track(AnalyticsEvents.updatePromptShown, {
      'current_version': currentVersion,
      'latest_version': latestVersion,
    });
  }

  /// "Update" tapped, from either the optional sheet or the required page.
  void trackUpdateClicked({required bool isForced}) {
    _track(AnalyticsEvents.updateClicked, {'is_forced': isForced});
  }

  /// "Later" tapped, or the optional sheet was swipe/barrier-dismissed.
  void trackUpdateDismissed() {
    _track(AnalyticsEvents.updateDismissed);
  }

  /// The blocking required-update page became visible.
  void trackForceUpdateShown({
    required String currentVersion,
    required String minimumVersion,
  }) {
    _track(AnalyticsEvents.forceUpdateShown, {
      'current_version': currentVersion,
      'minimum_version': minimumVersion,
    });
  }
}
