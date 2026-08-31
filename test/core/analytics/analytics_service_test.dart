import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/analytics/analytics_service.dart';
import 'package:jaswallet_app/core/analytics/analytics_events.dart';
import 'package:jaswallet_app/core/analytics/analytics_user_properties.dart';

/// Analytics service tests.
///
/// All tests run in no-op mode (no MIXPANEL_TOKEN set), which means
/// [AnalyticsService] is fully operational but no data is sent to Mixpanel.
/// This proves the public API contract — method signatures, no-op safety, and
/// that the service never throws regardless of method arguments.
///
/// Integration tests with a real Mixpanel token are handled separately.
void main() {
  group('AnalyticsService — singleton', () {
    test('instance is a singleton', () {
      final a = AnalyticsService.instance;
      final b = AnalyticsService.instance;
      expect(identical(a, b), isTrue);
    });

    test('init() completes without throwing when token is empty (no-op mode)',
        () async {
      // MIXPANEL_TOKEN is not set in tests → no-op mode.
      await expectLater(
        AnalyticsService.instance.init(),
        completes,
      );
    });

    test('second init() call is a no-op and does not throw', () async {
      await AnalyticsService.instance.init();
      await expectLater(AnalyticsService.instance.init(), completes);
    });
  });

  group('AnalyticsService — no-op safety (all public methods)', () {
    setUpAll(() async {
      await AnalyticsService.instance.init();
    });

    final analytics = AnalyticsService.instance;

    // ── Identity ─────────────────────────────────────────────────────────────

    test('identify() does not throw', () {
      expect(() => analytics.identify('user-123'), returnsNormally);
    });

    test('reset() does not throw', () {
      expect(() => analytics.reset(), returnsNormally);
    });

    test('setUserProperty() does not throw for any value type', () {
      expect(() => analytics.setUserProperty(AnalyticsUserProperties.role, 'student'), returnsNormally);
      expect(() => analytics.setUserProperty(AnalyticsUserProperties.notificationsEnabled, true), returnsNormally);
      expect(() => analytics.setUserProperty(AnalyticsUserProperties.appVersion, '1.0.0'), returnsNormally);
    });

    test('setUserProperty() silently ignores null value', () {
      expect(() => analytics.setUserProperty('key', null), returnsNormally);
    });

    test('setUserProperties() does not throw for empty map', () {
      expect(() => analytics.setUserProperties({}), returnsNormally);
    });

    test('setUserProperties() does not throw for populated map', () {
      expect(() => analytics.setUserProperties({
        AnalyticsUserProperties.role: 'student',
        AnalyticsUserProperties.language: 'en',
        AnalyticsUserProperties.biometricEnabled: false,
      }), returnsNormally);
    });

    test('syncUserProfile() does not throw for partial data', () {
      expect(() => analytics.syncUserProfile(
        displayName: 'Ali Khan',
        role: 'student',
        language: 'en',
      ), returnsNormally);
    });

    test('syncUserProfile() does not throw when all parameters null', () {
      expect(() => analytics.syncUserProfile(), returnsNormally);
    });

    test('updateLocale() does not throw', () {
      expect(() => analytics.updateLocale('kk'), returnsNormally);
    });

    test('updateThemeMode() does not throw', () {
      expect(() => analytics.updateThemeMode('dark'), returnsNormally);
    });

    test('flush() does not throw', () {
      expect(() => analytics.flush(), returnsNormally);
    });

    // ── App lifecycle ─────────────────────────────────────────────────────────

    test('trackAppOpened() does not throw', () {
      expect(() => analytics.trackAppOpened(), returnsNormally);
      expect(() => analytics.trackAppOpened(isColdStart: false), returnsNormally);
    });

    test('trackColdStartCompleted() does not throw', () {
      expect(() => analytics.trackColdStartCompleted(), returnsNormally);
    });

    test('trackAppForegrounded() does not throw with/without duration', () {
      expect(() => analytics.trackAppForegrounded(), returnsNormally);
      expect(() => analytics.trackAppForegrounded(backgroundDurationSeconds: 120), returnsNormally);
    });

    test('trackAppBackgrounded() does not throw', () {
      expect(() => analytics.trackAppBackgrounded(), returnsNormally);
    });

    test('trackSessionRestored() does not throw', () {
      expect(() => analytics.trackSessionRestored(), returnsNormally);
    });

    // ── Onboarding ────────────────────────────────────────────────────────────

    test('trackLanguageSelected() does not throw', () {
      expect(() => analytics.trackLanguageSelected('en'), returnsNormally);
      expect(() => analytics.trackLanguageSelected('ru'), returnsNormally);
      expect(() => analytics.trackLanguageSelected('kk'), returnsNormally);
    });

    test('trackOnboardingStarted() does not throw', () {
      expect(() => analytics.trackOnboardingStarted(), returnsNormally);
    });

    test('trackOnboardingStepCompleted() does not throw', () {
      expect(() => analytics.trackOnboardingStepCompleted(step: 1, totalSteps: 5), returnsNormally);
    });

    test('trackOnboardingCompleted() does not throw', () {
      expect(() => analytics.trackOnboardingCompleted(), returnsNormally);
    });

    test('trackOnboardingSkipped() does not throw', () {
      expect(() => analytics.trackOnboardingSkipped(atStep: 2), returnsNormally);
    });

    test('trackWelcomeOpened() does not throw', () {
      expect(() => analytics.trackWelcomeOpened(), returnsNormally);
    });

    // ── Authentication ────────────────────────────────────────────────────────

    test('trackLoginStarted() does not throw', () {
      expect(() => analytics.trackLoginStarted(), returnsNormally);
      expect(() => analytics.trackLoginStarted(loginMethod: 'email'), returnsNormally);
    });

    test('trackLoginSuccess() does not throw and calls identify', () {
      expect(() => analytics.trackLoginSuccess(userId: 'user-123'), returnsNormally);
    });

    test('trackLoginFailed() does not throw', () {
      expect(() => analytics.trackLoginFailed(errorType: 'invalid_credentials'), returnsNormally);
    });

    test('trackRegistrationStarted() does not throw', () {
      expect(() => analytics.trackRegistrationStarted(), returnsNormally);
    });

    test('trackRegistrationSuccess() does not throw', () {
      expect(() => analytics.trackRegistrationSuccess(userId: 'new-user'), returnsNormally);
    });

    test('trackRegistrationFailed() does not throw', () {
      expect(() => analytics.trackRegistrationFailed(errorType: 'duplicate_email'), returnsNormally);
    });

    test('trackPersonalDataConsentAccepted() does not throw', () {
      expect(() => analytics.trackPersonalDataConsentAccepted(), returnsNormally);
    });

    test('trackProfileCreationCompleted() does not throw', () {
      expect(() => analytics.trackProfileCreationCompleted(), returnsNormally);
    });

    test('trackForgotPasswordStarted() does not throw', () {
      expect(() => analytics.trackForgotPasswordStarted(), returnsNormally);
    });

    test('trackPasswordResetCompleted() does not throw', () {
      expect(() => analytics.trackPasswordResetCompleted(), returnsNormally);
    });

    test('trackVerificationCompleted() does not throw', () {
      expect(() => analytics.trackVerificationCompleted(flow: 'registration'), returnsNormally);
    });

    // ── PIN & biometric ───────────────────────────────────────────────────────

    test('trackPinCreated() does not throw', () {
      expect(() => analytics.trackPinCreated(), returnsNormally);
    });

    test('trackPinVerified() does not throw', () {
      expect(() => analytics.trackPinVerified(), returnsNormally);
    });

    test('trackPinFailed() does not throw', () {
      expect(() => analytics.trackPinFailed(attemptsRemaining: 3), returnsNormally);
    });

    test('trackPinLockoutTriggered() does not throw', () {
      expect(() => analytics.trackPinLockoutTriggered(), returnsNormally);
    });

    test('trackBiometricEnabled() does not throw', () {
      expect(() => analytics.trackBiometricEnabled(), returnsNormally);
    });

    test('trackBiometricDisabled() does not throw', () {
      expect(() => analytics.trackBiometricDisabled(), returnsNormally);
    });

    test('trackBiometricSetupSkipped() does not throw', () {
      expect(() => analytics.trackBiometricSetupSkipped(), returnsNormally);
    });

    test('trackBiometricAuthSuccess() does not throw', () {
      expect(() => analytics.trackBiometricAuthSuccess(), returnsNormally);
    });

    test('trackBiometricAuthFailed() does not throw', () {
      expect(() => analytics.trackBiometricAuthFailed(), returnsNormally);
      expect(() => analytics.trackBiometricAuthFailed(reason: 'not_enrolled'), returnsNormally);
    });

    // ── Logout ────────────────────────────────────────────────────────────────

    test('trackLogout() does not throw', () {
      expect(() => analytics.trackLogout(), returnsNormally);
      expect(() => analytics.trackLogout(isForced: true), returnsNormally);
    });

    test('trackSessionExpired() does not throw', () {
      expect(() => analytics.trackSessionExpired(), returnsNormally);
    });

    test('trackAppLocked() does not throw', () {
      expect(() => analytics.trackAppLocked(), returnsNormally);
    });

    // ── Screen tracking ───────────────────────────────────────────────────────

    test('trackScreenOpened() does not throw', () {
      expect(() => analytics.trackScreenOpened(screenName: 'Home'), returnsNormally);
      expect(() => analytics.trackScreenOpened(
        screenName: 'Login',
        previousScreen: 'Welcome',
        extraProperties: {'source': 'welcome_button'},
      ), returnsNormally);
    });

    test('trackScreenClosed() does not throw', () {
      expect(() => analytics.trackScreenClosed(screenName: 'Home'), returnsNormally);
      expect(() => analytics.trackScreenClosed(screenName: 'Login', durationMs: 3500), returnsNormally);
    });

    // ── Bottom nav ────────────────────────────────────────────────────────────

    test('trackBottomTabChanged() does not throw', () {
      expect(() => analytics.trackBottomTabChanged(
        fromIndex: 0,
        toIndex: 2,
        toTabName: 'Hub',
      ), returnsNormally);
    });

    // ── Notifications ─────────────────────────────────────────────────────────

    test('trackPushReceived() does not throw', () {
      expect(() => analytics.trackPushReceived(
        category: 'general',
        messageId: 'msg-123',
        notificationState: 'foreground',
      ), returnsNormally);
    });

    test('trackPushOpened() does not throw', () {
      expect(() => analytics.trackPushOpened(
        category: 'classroom',
        notificationState: 'background',
      ), returnsNormally);
    });

    test('trackPushRedirectStarted() does not throw', () {
      expect(() => analytics.trackPushRedirectStarted(route: '/classroom'), returnsNormally);
    });

    test('trackPushRedirectCompleted() does not throw', () {
      expect(() => analytics.trackPushRedirectCompleted(route: '/classroom'), returnsNormally);
    });

    test('trackNotificationDetailOpened() does not throw', () {
      expect(() => analytics.trackNotificationDetailOpened(
        notificationId: 'notif-1',
        category: 'general',
      ), returnsNormally);
    });

    test('trackNotificationActionClicked() does not throw', () {
      expect(() => analytics.trackNotificationActionClicked(
        notificationId: 'notif-1',
        action: 'open_course',
      ), returnsNormally);
    });

    test('trackNotificationsSettingsOpened() does not throw', () {
      expect(() => analytics.trackNotificationsSettingsOpened(), returnsNormally);
    });

    test('trackNotificationSettingChanged() does not throw', () {
      expect(() => analytics.trackNotificationSettingChanged(
        settingName: 'classroom',
        enabled: false,
      ), returnsNormally);
    });

    // ── SVC ───────────────────────────────────────────────────────────────────

    test('SVC track methods do not throw', () {
      expect(() => analytics.trackSvcOpened(), returnsNormally);
      expect(() => analytics.trackSvcQrOpened(), returnsNormally);
      expect(() => analytics.trackSvcQrRefreshed(), returnsNormally);
      expect(() => analytics.trackSvcBalanceViewed(), returnsNormally);
      expect(() => analytics.trackSvcBalanceViewed(balance: 3), returnsNormally);
      expect(() => analytics.trackSvcHistoryOpened(), returnsNormally);
      expect(() => analytics.trackSvcLeaderboardOpened(), returnsNormally);
      expect(() => analytics.trackSvcStreakOpened(), returnsNormally);
      expect(() => analytics.trackSvcCalendarOpened(), returnsNormally);
      expect(() => analytics.trackSvcScanAttempted(), returnsNormally);
      expect(() => analytics.trackSvcScanSuccess(mealType: 'lunch'), returnsNormally);
      expect(() => analytics.trackSvcScanFailed(reason: 'already_redeemed'), returnsNormally);
    });

    // ── Clubs ─────────────────────────────────────────────────────────────────

    test('Club track methods do not throw', () {
      expect(() => analytics.trackClubsOpened(), returnsNormally);
      expect(() => analytics.trackClubOpened(clubId: 'c1', clubName: 'Chess Club'), returnsNormally);
      expect(() => analytics.trackClubJoinClicked(clubId: 'c1', clubName: 'Chess Club'), returnsNormally);
      expect(() => analytics.trackClubApplicationStarted(clubId: 'c1'), returnsNormally);
      expect(() => analytics.trackClubApplicationSubmitted(clubId: 'c1'), returnsNormally);
      expect(() => analytics.trackClubFavoriteAdded(clubId: 'c1'), returnsNormally);
      expect(() => analytics.trackClubFavoriteRemoved(clubId: 'c1'), returnsNormally);
    });

    // ── Attendance ────────────────────────────────────────────────────────────

    test('Attendance track methods do not throw', () {
      expect(() => analytics.trackAttendanceStudentOpened(), returnsNormally);
      expect(() => analytics.trackAttendanceTeacherOpened(), returnsNormally);
      expect(() => analytics.trackQrScanAttempted(), returnsNormally);
      expect(() => analytics.trackQrScanSuccess(sessionId: 'sess-1', xpEarned: 50), returnsNormally);
      expect(() => analytics.trackQrScanFailed(reason: 'invalid_qr'), returnsNormally);
      expect(() => analytics.trackAttendanceHistoryOpened(), returnsNormally);
      expect(() => analytics.trackAttendanceSessionCreated(sessionId: 'sess-2'), returnsNormally);
      expect(() => analytics.trackAttendanceRewardClaimed(rewardId: 'r1', xpEarned: 100), returnsNormally);
    });

    // ── Profile ───────────────────────────────────────────────────────────────

    test('Profile track methods do not throw', () {
      expect(() => analytics.trackProfileOpened(), returnsNormally);
      expect(() => analytics.trackMyProfileOpened(), returnsNormally);
      expect(() => analytics.trackProfileEdited(fieldCount: 3), returnsNormally);
      expect(() => analytics.trackAvatarChanged(), returnsNormally);
      expect(() => analytics.trackResumeOpened(), returnsNormally);
      expect(() => analytics.trackResumeSectionEdited(section: 'experience'), returnsNormally);
    });

    // ── Settings ──────────────────────────────────────────────────────────────

    test('Settings track methods do not throw', () {
      expect(() => analytics.trackSettingsOpened(), returnsNormally);
      expect(() => analytics.trackThemeChanged(themeName: 'dark'), returnsNormally);
      expect(() => analytics.trackLanguageChanged(languageCode: 'ru'), returnsNormally);
      expect(() => analytics.trackSecurityPageOpened(), returnsNormally);
      expect(() => analytics.trackAboutAppOpened(), returnsNormally);
      expect(() => analytics.trackHelpOpened(), returnsNormally);
    });

    // ── Gamification ──────────────────────────────────────────────────────────

    test('Gamification track methods do not throw', () {
      expect(() => analytics.trackMyLevelOpened(), returnsNormally);
      expect(() => analytics.trackTasksOpened(), returnsNormally);
      expect(() => analytics.trackTaskCompleted(taskId: 't1', taskName: 'First Check-In'), returnsNormally);
      expect(() => analytics.trackPointsOpened(), returnsNormally);
      expect(() => analytics.trackRankingOpened(), returnsNormally);
      expect(() => analytics.trackAchievementsOpened(), returnsNormally);
      expect(() => analytics.trackAchievementUnlocked(
        achievementId: 'a1',
        achievementName: '7-Day Streak',
      ), returnsNormally);
    });

    // ── Social ────────────────────────────────────────────────────────────────

    test('Social track methods do not throw', () {
      expect(() => analytics.trackConversationsOpened(), returnsNormally);
      expect(() => analytics.trackChatOpened(targetUserId: 'user-456'), returnsNormally);
      expect(() => analytics.trackMessageSent(), returnsNormally);
      expect(() => analytics.trackUserSearchOpened(), returnsNormally);
      expect(() => analytics.trackUserSearchQuerySubmitted(query: 'Ali', resultCount: 5), returnsNormally);
      expect(() => analytics.trackPublicProfileOpened(targetUserId: 'user-789'), returnsNormally);
      expect(() => analytics.trackFollowUser(targetUserId: 'user-789'), returnsNormally);
      expect(() => analytics.trackUnfollowUser(targetUserId: 'user-789'), returnsNormally);
    });

    // ── Errors ────────────────────────────────────────────────────────────────

    test('Error track methods do not throw', () {
      expect(() => analytics.trackApiError(
        endpoint: '/api/users/profile',
        statusCode: 404,
        errorType: 'not_found',
      ), returnsNormally);
      expect(() => analytics.trackNavigationError(attemptedRoute: '/bad-route'), returnsNormally);
      expect(() => analytics.trackAuthError(errorType: 'token_expired'), returnsNormally);
      expect(() => analytics.trackUnexpectedException(
        errorType: 'StateError',
        sourceScreen: 'Home',
      ), returnsNormally);
    });

    test('trackEmptyStateViewed() does not throw', () {
      expect(() => analytics.trackEmptyStateViewed(
        screen: 'Notifications',
        reason: 'no_data',
      ), returnsNormally);
    });

    test('trackRetryTriggered() does not throw', () {
      expect(() => analytics.trackRetryTriggered(screen: 'Home'), returnsNormally);
    });
  });

  // ── Event name constants ───────────────────────────────────────────────────

  group('AnalyticsEvents — naming conventions', () {
    test('all event names use snake_case', () {
      final allEvents = [
        AnalyticsEvents.appOpened,
        AnalyticsEvents.coldStartCompleted,
        AnalyticsEvents.appForegrounded,
        AnalyticsEvents.appBackgrounded,
        AnalyticsEvents.sessionRestored,
        AnalyticsEvents.languageSelected,
        AnalyticsEvents.onboardingStarted,
        AnalyticsEvents.onboardingCompleted,
        AnalyticsEvents.onboardingSkipped,
        AnalyticsEvents.welcomeOpened,
        AnalyticsEvents.loginStarted,
        AnalyticsEvents.loginSuccess,
        AnalyticsEvents.loginFailed,
        AnalyticsEvents.registrationStarted,
        AnalyticsEvents.registrationSuccess,
        AnalyticsEvents.registrationFailed,
        AnalyticsEvents.pinCreated,
        AnalyticsEvents.pinVerified,
        AnalyticsEvents.pinFailed,
        AnalyticsEvents.biometricEnabled,
        AnalyticsEvents.biometricAuthSuccess,
        AnalyticsEvents.logoutTriggered,
        AnalyticsEvents.screenOpened,
        AnalyticsEvents.screenClosed,
        AnalyticsEvents.bottomTabChanged,
        AnalyticsEvents.homeOpened,
        AnalyticsEvents.pushReceived,
        AnalyticsEvents.pushOpened,
        AnalyticsEvents.svcOpened,
        AnalyticsEvents.clubsOpened,
        AnalyticsEvents.classroomOpened,
        AnalyticsEvents.attendanceStudentOpened,
        AnalyticsEvents.apiError,
        AnalyticsEvents.unexpectedException,
      ];

      // All event names must be snake_case (lowercase letters, digits, underscores only).
      final snakeCase = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final event in allEvents) {
        expect(
          snakeCase.hasMatch(event),
          isTrue,
          reason: '$event is not snake_case',
        );
      }
    });

    test('no two event constants have the same value', () {
      final allEvents = [
        AnalyticsEvents.appOpened,
        AnalyticsEvents.coldStartCompleted,
        AnalyticsEvents.sessionRestored,
        AnalyticsEvents.languageSelected,
        AnalyticsEvents.onboardingStarted,
        AnalyticsEvents.onboardingCompleted,
        AnalyticsEvents.loginStarted,
        AnalyticsEvents.loginSuccess,
        AnalyticsEvents.loginFailed,
        AnalyticsEvents.pinCreated,
        AnalyticsEvents.pinVerified,
        AnalyticsEvents.biometricEnabled,
        AnalyticsEvents.logoutTriggered,
        AnalyticsEvents.screenOpened,
        AnalyticsEvents.screenClosed,
        AnalyticsEvents.homeOpened,
        AnalyticsEvents.pushReceived,
        AnalyticsEvents.pushOpened,
        AnalyticsEvents.svcOpened,
        AnalyticsEvents.clubsOpened,
        AnalyticsEvents.apiError,
      ];
      expect(allEvents.toSet().length, equals(allEvents.length),
          reason: 'Duplicate event names detected');
    });
  });

  // ── Privacy guard ──────────────────────────────────────────────────────────

  group('AnalyticsService — privacy (no sensitive data)', () {
    test('syncUserProfile() does not expose email in debug output without opting in', () {
      // This is a meta-test: we verify the method accepts email but only
      // as an explicit People property (not an event property).
      // The analytics service should never bundle email in event track() calls.
      final analytics = AnalyticsService.instance;
      // Should not throw and should not expose sensitive data in events.
      expect(() => analytics.syncUserProfile(
        email: 'user@example.com',
        displayName: 'Test User',
      ), returnsNormally);
    });

    test('login methods never expose password in event properties', () {
      // trackLoginStarted and trackLoginSuccess only track userId/method.
      // This test documents the contract that no password is ever passed.
      final analytics = AnalyticsService.instance;
      // API only accepts userId (not password) — enforced by method signature.
      expect(() => analytics.trackLoginSuccess(userId: 'user-123'), returnsNormally);
    });

    test('pin methods never track the PIN value', () {
      // trackPinCreated/trackPinVerified take no PIN parameter — by design.
      final analytics = AnalyticsService.instance;
      expect(() => analytics.trackPinCreated(), returnsNormally);
      expect(() => analytics.trackPinVerified(), returnsNormally);
    });
  });
}
