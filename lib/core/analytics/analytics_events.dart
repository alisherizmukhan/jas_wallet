/// Type-safe analytics event name constants.
///
/// All names use strict snake_case. Add new events here — never inline
/// raw strings in feature code.
abstract class AnalyticsEvents {
  // ── App lifecycle ─────────────────────────────────────────────────────────
  static const String appOpened = 'app_opened';
  static const String coldStartCompleted = 'cold_start_completed';
  static const String appForegrounded = 'app_foregrounded';
  static const String appBackgrounded = 'app_backgrounded';
  static const String sessionRestored = 'session_restored';

  // ── Onboarding & language ─────────────────────────────────────────────────
  static const String languageSelected = 'language_selected';
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingStepCompleted = 'onboarding_step_completed';
  static const String onboardingStepViewed = 'onboarding_step_viewed';
  static const String onboardingNextClicked = 'onboarding_next_clicked';
  static const String onboardingBackClicked = 'onboarding_back_clicked';
  static const String onboardingSwiped = 'onboarding_swiped';
  static const String onboardingAbandoned = 'onboarding_abandoned';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String onboardingSkipped = 'onboarding_skipped';
  static const String welcomeOpened = 'welcome_opened';

  // ── Authentication ────────────────────────────────────────────────────────
  static const String loginStarted = 'login_started';
  static const String loginSuccess = 'login_success';
  static const String loginFailed = 'login_failed';
  static const String registrationStarted = 'registration_started';
  static const String registrationSuccess = 'registration_success';
  static const String registrationFailed = 'registration_failed';
  static const String personalDataConsentAccepted = 'personal_data_consent_accepted';
  static const String profileCreationCompleted = 'profile_creation_completed';
  static const String forgotPasswordStarted = 'forgot_password_started';
  static const String passwordResetCompleted = 'password_reset_completed';
  static const String verificationCompleted = 'verification_completed';

  // ── PIN & biometric ───────────────────────────────────────────────────────
  static const String pinCreated = 'pin_created';
  static const String pinVerified = 'pin_verified';
  static const String pinFailed = 'pin_failed';
  static const String pinLockoutTriggered = 'pin_lockout_triggered';
  static const String biometricEnabled = 'biometric_enabled';
  static const String biometricDisabled = 'biometric_disabled';
  static const String biometricAuthSuccess = 'biometric_auth_success';
  static const String biometricAuthFailed = 'biometric_auth_failed';
  static const String biometricSetupSkipped = 'biometric_setup_skipped';

  // ── Logout & session ──────────────────────────────────────────────────────
  static const String logoutTriggered = 'logout_triggered';
  static const String sessionExpired = 'session_expired';
  static const String appLocked = 'app_locked';

  // ── Screen tracking ───────────────────────────────────────────────────────
  static const String screenOpened = 'screen_opened';
  static const String screenClosed = 'screen_closed';

  // ── Bottom navigation ─────────────────────────────────────────────────────
  static const String bottomTabChanged = 'bottom_tab_changed';

  // ── Home ──────────────────────────────────────────────────────────────────
  static const String homeOpened = 'home_opened';
  static const String homeRefreshTriggered = 'home_refresh_triggered';
  static const String homeBannerTapped = 'home_banner_tapped';

  // ── Hub behavioral ────────────────────────────────────────────────────────
  static const String hubItemTapped = 'hub_item_tapped';
  static const String hubSearchUsed = 'hub_search_used';
  static const String hubSearchResultTapped = 'hub_search_result_tapped';

  // ── Stories ───────────────────────────────────────────────────────────────
  static const String storyCardTapped = 'story_card_tapped';
  static const String storySetViewed = 'story_set_viewed';
  static const String storySetCompleted = 'story_set_completed';
  static const String storyUserNavigated = 'story_user_navigated';

  // ── Settings behavioral ───────────────────────────────────────────────────
  static const String settingsItemNavigated = 'settings_item_navigated';
  static const String settingsCityChanged = 'settings_city_changed';

  // ── SOS behavioral ────────────────────────────────────────────────────────
  static const String sosUrgencyChanged = 'sos_urgency_changed';
  static const String sosHistoryClicked = 'sos_history_clicked';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String pushReceived = 'push_received';
  static const String pushOpened = 'push_opened';
  static const String pushRedirectStarted = 'push_redirect_started';
  static const String pushRedirectCompleted = 'push_redirect_completed';
  static const String notificationDetailOpened = 'notification_detail_opened';
  static const String notificationActionClicked = 'notification_action_clicked';
  static const String notificationsSettingsOpened = 'notifications_settings_opened';
  static const String notificationSettingChanged = 'notification_setting_changed';
  static const String notificationMarkedRead = 'notification_marked_read';
  static const String notificationDeleted = 'notification_deleted';
  static const String notificationOpenedFromList = 'notification_opened_from_list';
  static const String notificationDeletedFromList = 'notification_deleted_from_list';
  static const String notificationsFilterChanged = 'notifications_filter_changed';
  static const String notificationsMarkAllReadClicked = 'notifications_mark_all_read_clicked';

  // ── Salto access control ──────────────────────────────────────────────────
  // SALTO's own event names live in SaltoAnalytics
  // (lib/features/salto/analytics/salto_analytics.dart), not here — see the
  // note in AnalyticsService's "Salto access" section.

  // ── Social Meal (SVC) ─────────────────────────────────────────────────────
  static const String svcOpened = 'svc_opened';
  static const String svcQrOpened = 'svc_qr_opened';
  static const String svcQrRefreshed = 'svc_qr_refreshed';
  static const String svcBalanceViewed = 'svc_balance_viewed';
  static const String svcHistoryOpened = 'svc_history_opened';
  static const String svcLeaderboardOpened = 'svc_leaderboard_opened';
  static const String svcStreakOpened = 'svc_streak_opened';
  static const String svcCalendarOpened = 'svc_calendar_opened';
  static const String svcScanAttempted = 'svc_scan_attempted';
  static const String svcScanSuccess = 'svc_scan_success';
  static const String svcScanFailed = 'svc_scan_failed';
  static const String svcCompensationRequested = 'svc_compensation_requested';

  // ── Student Clubs ─────────────────────────────────────────────────────────
  static const String clubsOpened = 'clubs_opened';
  static const String clubOpened = 'club_opened';
  static const String clubJoinClicked = 'club_join_clicked';
  static const String clubApplicationStarted = 'club_application_started';
  static const String clubApplicationSubmitted = 'club_application_submitted';
  static const String clubFavoriteAdded = 'club_favorite_added';
  static const String clubFavoriteRemoved = 'club_favorite_removed';

  // ── Classroom ─────────────────────────────────────────────────────────────
  static const String classroomOpened = 'classroom_opened';
  static const String courseOpened = 'course_opened';
  static const String coursePostCreated = 'course_post_created';
  static const String courseMaterialUploaded = 'course_material_uploaded';
  static const String courseCreated = 'course_created';
  static const String courseJoinedByCode = 'course_joined_by_code';
  static const String professorDashboardOpened = 'professor_dashboard_opened';

  // ── Attendance ────────────────────────────────────────────────────────────
  static const String attendanceStudentOpened = 'attendance_student_opened';
  static const String attendanceTeacherOpened = 'attendance_teacher_opened';
  static const String qrScanAttempted = 'qr_scan_attempted';
  static const String qrScanSuccess = 'qr_scan_success';
  static const String qrScanFailed = 'qr_scan_failed';
  static const String attendanceHistoryOpened = 'attendance_history_opened';
  static const String attendanceSessionCreated = 'attendance_session_created';
  static const String attendanceSessionStarted = 'attendance_session_started';
  static const String attendanceSessionEnded = 'attendance_session_ended';
  static const String attendanceRewardClaimed = 'attendance_reward_claimed';

  // ── Job Finder ────────────────────────────────────────────────────────────
  static const String jobFinderOpened = 'job_finder_opened';
  static const String jobCategoryOpened = 'job_category_opened';
  static const String jobDetailOpened = 'job_detail_opened';
  static const String jobApplyClicked = 'job_apply_clicked';

  // ── Orientation Week ──────────────────────────────────────────────────────
  static const String orientationOpened = 'orientation_opened';
  static const String orientationChallengeOpened = 'challenge_opened';
  static const String orientationChallengeCompleted = 'challenge_completed';
  static const String orientationBingoOpened = 'bingo_opened';
  static const String orientationBingoGenerated = 'bingo_generated';
  static const String orientationBingoCellCompleted = 'bingo_cell_completed';
  static const String orientationPhotoUploaded = 'photo_uploaded';
  static const String orientationLeaderboardOpened = 'leaderboard_opened';
  static const String orientationRewardRedeemed = 'reward_redeemed';
  static const String orientationTokensEarned = 'tokens_earned';
  static const String orientationScannerOpened = 'scanner_opened';
  static const String orientationScannerSuccess = 'scanner_success';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String profileOpened = 'profile_opened';
  static const String myProfileOpened = 'my_profile_opened';
  static const String profileEdited = 'profile_edited';
  static const String avatarChanged = 'avatar_changed';
  static const String resumeOpened = 'resume_opened';
  static const String resumeSectionEdited = 'resume_section_edited';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settingsOpened = 'settings_opened';
  static const String settingChanged = 'setting_changed';
  static const String themeChanged = 'theme_changed';
  static const String languageChanged = 'language_changed';
  static const String securityPageOpened = 'security_page_opened';
  static const String aboutAppOpened = 'about_app_opened';
  static const String helpOpened = 'help_opened';

  // ── Gamification ──────────────────────────────────────────────────────────
  static const String myLevelOpened = 'my_level_opened';
  static const String tasksOpened = 'tasks_opened';
  static const String taskCompleted = 'task_completed';
  static const String pointsOpened = 'points_opened';
  static const String rankingOpened = 'ranking_opened';
  static const String achievementsOpened = 'achievements_opened';
  static const String achievementUnlocked = 'achievement_unlocked';

  // ── Social / Chat ─────────────────────────────────────────────────────────
  static const String conversationsOpened = 'conversations_opened';
  static const String chatOpened = 'chat_opened';
  static const String messageSent = 'message_sent';
  static const String userSearchOpened = 'user_search_opened';
  static const String userSearchQuerySubmitted = 'user_search_query_submitted';
  static const String publicProfileOpened = 'public_profile_opened';
  static const String followUser = 'follow_user';
  static const String unfollowUser = 'unfollow_user';

  // ── Fintech ───────────────────────────────────────────────────────────────
  static const String fintechOpened = 'fintech_opened';
  static const String fintechTokensOpened = 'fintech_tokens_opened';
  static const String fintechNftOpened = 'fintech_nft_opened';
  static const String fintechDiscountsOpened = 'fintech_discounts_opened';
  static const String fintechCardCustomizationOpened = 'fintech_card_customization_opened';

  // ── Weather & Exchange ────────────────────────────────────────────────────
  static const String weatherDetailsOpened = 'weather_details_opened';
  static const String exchangeDetailsOpened = 'exchange_details_opened';

  // ── Tutorials & Events ────────────────────────────────────────────────────
  static const String tutorialsOpened = 'tutorials_opened';
  static const String tutorialBannerTapped = 'tutorial_banner_tapped';
  static const String tutorialDetailOpened = 'tutorial_detail_opened';
  static const String eventDetailOpened = 'event_detail_opened';

  // ── Search ────────────────────────────────────────────────────────────────
  static const String searchOpened = 'search_opened';
  static const String searchQuerySubmitted = 'search_query_submitted';
  static const String searchResultOpened = 'search_result_opened';

  // ── Empty states & errors ─────────────────────────────────────────────────
  static const String emptyStateViewed = 'empty_state_viewed';
  static const String retryTriggered = 'retry_triggered';
  static const String apiError = 'api_error';
  static const String navigationError = 'navigation_error';
  static const String authError = 'auth_error';
  static const String unexpectedException = 'unexpected_exception';

  // ── Screen active time ────────────────────────────────────────────────────
  static const String screenActiveTime = 'screen_active_time';

  // ── Rage tap (UX friction) ────────────────────────────────────────────────
  static const String uiRageTapDetected = 'ui_rage_tap_detected';

  // ── Critical flows ────────────────────────────────────────────────────────
  static const String flowStarted = 'flow_started';
  static const String flowCompleted = 'flow_completed';
  static const String flowAbandoned = 'flow_abandoned';
  static const String flowFailed = 'flow_failed';

  // ── Scroll depth ──────────────────────────────────────────────────────────
  static const String scrollDepthReached = 'scroll_depth_reached';

  // ── Feature adoption ──────────────────────────────────────────────────────
  static const String featureFirstUsed = 'feature_first_used';
  static const String featureRevisited = 'feature_revisited';

  // ── API performance ───────────────────────────────────────────────────────
  static const String apiRequestCompleted = 'api_request_completed';
  static const String apiRequestFailed = 'api_request_failed';

  // ── SOS (Campus Security) ─────────────────────────────────────────────────
  static const String sosOpened = 'sos_opened';
  static const String sosHistoryOpened = 'sos_history_opened';
  static const String sosDetailOpened = 'sos_detail_opened';
  static const String sosCall102Clicked = 'sos_call_102_clicked';
  static const String sosCall112Clicked = 'sos_call_112_clicked';
  static const String sosCallCampusSecurityClicked = 'sos_call_campus_security_clicked';
  static const String sosReportStarted = 'sos_report_started';
  static const String sosReportImageAdded = 'sos_report_image_added';
  static const String sosReportSubmitted = 'sos_report_submitted';
  static const String sosReportSubmitFailed = 'sos_report_submit_failed';
  static const String sosReportSubmitSuccess = 'sos_report_submit_success';
  static const String sosHistoryLoaded = 'sos_history_loaded';
  static const String sosHistoryEmpty = 'sos_history_empty';
  static const String sosReportOpened = 'sos_report_opened';
  static const String sosApiError = 'sos_api_error';
  static const String sosImageUploadFailed = 'sos_image_upload_failed';
  static const String sosDialerUnavailable = 'sos_dialer_unavailable';

  // ── Share ─────────────────────────────────────────────────────────────────
  static const String shareAppOpened = 'share_app_opened';
  static const String shareAppClicked = 'share_app_clicked';
  static const String shareLinkCopied = 'share_link_copied';

  // ── Referral ──────────────────────────────────────────────────────────────
  static const String referralScreenOpened = 'referral_screen_opened';
  static const String referralCodeCopied = 'referral_code_copied';
  static const String referralShareClicked = 'referral_share_clicked';

  // ── Rate App ──────────────────────────────────────────────────────────────
  static const String rateAppClicked = 'rate_app_clicked';
  static const String rateAppCompleted = 'rate_app_completed';

  // ── App Update ────────────────────────────────────────────────────────────
  static const String updatePromptShown = 'update_prompt_shown';
  static const String updateClicked = 'update_clicked';
  static const String updateDismissed = 'update_dismissed';
  static const String forceUpdateShown = 'force_update_shown';
}
