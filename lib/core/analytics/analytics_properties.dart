/// Type-safe analytics event property key constants.
///
/// All keys use strict snake_case. Never inline raw property key strings
/// in feature code — always reference these constants.
abstract class AnalyticsProperties {
  // ── App / Session ─────────────────────────────────────────────────────────
  static const String platform = 'platform';
  static const String appVersion = 'app_version';
  static const String buildNumber = 'build_number';
  static const String environment = 'environment';
  static const String locale = 'locale';
  static const String themeMode = 'theme_mode';
  static const String durationMs = 'duration_ms';
  static const String durationSeconds = 'duration_seconds';

  // ── Screen ────────────────────────────────────────────────────────────────
  static const String screenName = 'screen_name';
  static const String previousScreen = 'previous_screen';
  static const String screenDurationMs = 'screen_duration_ms';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String userId = 'user_id';
  static const String loginMethod = 'login_method';
  static const String errorType = 'error_type';
  static const String errorMessage = 'error_message';
  static const String attemptsRemaining = 'attempts_remaining';

  // ── Language & Onboarding ─────────────────────────────────────────────────
  static const String languageCode = 'language_code';
  static const String onboardingStep = 'step';
  static const String onboardingTotalSteps = 'total_steps';

  // ── Navigation ────────────────────────────────────────────────────────────
  static const String fromTab = 'from_tab';
  static const String toTab = 'to_tab';
  static const String tabIndex = 'tab_index';
  static const String tabName = 'tab_name';
  static const String route = 'route';

  // ── Notification ─────────────────────────────────────────────────────────
  static const String notificationId = 'notification_id';
  static const String notificationCategory = 'notification_category';
  static const String notificationTitle = 'notification_title';
  static const String notificationState = 'notification_state'; // foreground|background|terminated
  static const String notificationAction = 'notification_action';
  static const String settingName = 'setting_name';
  static const String settingEnabled = 'enabled';

  // ── Club ──────────────────────────────────────────────────────────────────
  static const String clubId = 'club_id';
  static const String clubName = 'club_name';
  static const String clubCategory = 'club_category';

  // ── Course / Classroom ────────────────────────────────────────────────────
  static const String courseId = 'course_id';
  static const String courseName = 'course_name';
  static const String courseCode = 'course_code';
  static const String courseType = 'course_type'; // lecture|lab|seminar
  static const String fieldCount = 'field_count';
  static const String materialType = 'material_type';

  // ── Attendance ────────────────────────────────────────────────────────────
  static const String sessionId = 'session_id';
  static const String sessionTitle = 'session_title';
  static const String xpEarned = 'xp_earned';
  static const String streakLength = 'streak_length';
  static const String failureReason = 'failure_reason';

  // ── Job ───────────────────────────────────────────────────────────────────
  static const String jobId = 'job_id';
  static const String jobTitle = 'job_title';
  static const String jobCategoryId = 'job_category_id';
  static const String jobCategoryName = 'job_category_name';

  // ── SVC / Social Meal ─────────────────────────────────────────────────────
  static const String mealType = 'meal_type'; // breakfast|lunch|dinner
  static const String mealBalance = 'meal_balance';

  // ── Social ────────────────────────────────────────────────────────────────
  static const String targetUserId = 'target_user_id';
  static const String resultCount = 'result_count';
  static const String query = 'query';

  // ── Gamification ─────────────────────────────────────────────────────────
  static const String achievementId = 'achievement_id';
  static const String achievementName = 'achievement_name';
  static const String taskId = 'task_id';
  static const String taskName = 'task_name';
  static const String pointsEarned = 'points_earned';

  // ── API errors / performance ──────────────────────────────────────────────
  static const String endpoint = 'endpoint';
  static const String httpStatusCode = 'http_status_code';
  static const String attemptedRoute = 'attempted_route';
  static const String sourceScreen = 'source_screen';
  /// True when a successful response took ≥ the Dio interceptor slow threshold.
  static const String isSlow = 'is_slow';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settingValue = 'setting_value';
  static const String themeName = 'theme_name'; // light|dark|system

  // ── Screen time ───────────────────────────────────────────────────────────
  static const String activeTimeMs = 'active_time_ms';

  // ── UX friction ───────────────────────────────────────────────────────────
  static const String componentName = 'component_name';
  static const String rageTapCount = 'rage_tap_count';

  // ── Flows ─────────────────────────────────────────────────────────────────
  static const String flowName = 'flow_name';
  static const String flowStep = 'flow_step';
  static const String entryPoint = 'entry_point';

  // ── Scroll ────────────────────────────────────────────────────────────────
  static const String scrollDepth = 'scroll_depth_percent';

  // ── Feature adoption ──────────────────────────────────────────────────────
  static const String featureName = 'feature_name';

  // ── API performance ───────────────────────────────────────────────────────
  static const String httpMethod = 'http_method';
  static const String retryCount = 'retry_count';

  // ── SOS ───────────────────────────────────────────────────────────────────
  static const String sosUrgency = 'urgency'; // low|medium|high
  static const String sosHasImage = 'has_image';
  static const String sosReportStatus = 'status';
  static const String sosReportId = 'report_id';
  static const String sosCallTarget = 'call_target'; // 102|112|campus
  static const String sosReportCount = 'report_count';

  // ── SALTO (BLE campus access) ─────────────────────────────────────────────
  static const String saltoFlow = 'salto_flow'; // activation|unlock
  static const String saltoBluetoothState = 'bluetooth_state';
  static const String saltoBluetoothStateFrom = 'bluetooth_state_from';
  static const String saltoInternetAvailable = 'internet_available';
  static const String saltoActivationState = 'activation_state';
  static const String saltoUnlockState = 'unlock_state';
  static const String saltoReadinessIssue = 'readiness_issue';
  static const String saltoKeyCached = 'key_cached';
  static const String saltoTriggerSource = 'trigger_source'; // manual|auto|resume|background
  static const String saltoSettingsType = 'settings_type'; // bluetooth|network
  static const String saltoNativeMethod = 'native_method';
  static const String saltoTapContext = 'tap_context';
  static const String saltoResult = 'salto_result';

  // ── SALTO V2 (correlation, timing, diagnostics) ───────────────────────────
  /// Same value on every event belonging to one activation/unlock attempt —
  /// see SALTO_ANALYTICS_INTEGRATION.md "Session ID lifecycle".
  static const String saltoSessionId = 'salto_session_id';
  /// 0 = first attempt, incremented once per retry within the same session.
  static const String saltoRetryAttempt = 'retry_attempt';
  /// timeout|rejected|stale_key|sdk_failure|manual_retry|recovery
  static const String saltoRetryReason = 'retry_reason';
  static const String saltoTotalDurationMs = 'total_duration_ms';
  static const String saltoNativeDurationMs = 'native_duration_ms';
  static const String saltoKeyFetchDurationMs = 'key_fetch_duration_ms';
  static const String saltoPermissionDurationMs = 'permission_duration_ms';
  static const String saltoReadinessDurationMs = 'readiness_duration_ms';
  /// Sourced from the single kSaltoSdkVersion constant — never hardcoded
  /// per-call-site.
  static const String saltoSdkVersion = 'sdk_version';
  /// resumed|inactive|paused|detached (Flutter AppLifecycleState.name).
  static const String appLifecycleState = 'app_lifecycle_state';
  /// timeout|stale_lock|stale_key|sdk_failure|bluetooth_restored|internet_restored
  static const String saltoRecoveryReason = 'recovery_reason';
  static const String saltoRecoveryDurationMs = 'recovery_duration_ms';
  /// permission|bluetooth|internet|key_fetch|key_validation|native_sdk|
  /// method_channel|backend|retry|unknown
  static const String saltoFailureStage = 'failure_stage';
}
