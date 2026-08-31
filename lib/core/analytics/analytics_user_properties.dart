/// Mixpanel People profile property key constants.
///
/// These are set on the user's People profile (not event properties).
/// NEVER store sensitive data: passwords, PINs, tokens, or private messages.
abstract class AnalyticsUserProperties {
  // ── Identity ──────────────────────────────────────────────────────────────
  /// Mixpanel built-in: display name.
  static const String name = r'$name';

  /// Mixpanel built-in: email address.
  static const String email = r'$email';

  /// Mixpanel built-in: first name (auto-parsed from $name).
  static const String firstName = r'$first_name';

  /// Mixpanel built-in: last name.
  static const String lastName = r'$last_name';

  // ── JasWallet custom properties ───────────────────────────────────────────
  /// Internal user ID from the backend.
  static const String userId = 'user_id';

  /// User's role: 'student' | 'teacher' | 'staff'.
  static const String role = 'role';

  /// User's faculty or department (if available).
  static const String faculty = 'faculty';

  /// User's preferred language code: 'en' | 'ru' | 'kk'.
  static const String language = 'language';

  /// Whether push notifications are globally enabled.
  static const String notificationsEnabled = 'notifications_enabled';

  /// Whether biometric auth is enabled.
  static const String biometricEnabled = 'biometric_enabled';

  /// App theme preference: 'light' | 'dark' | 'system'.
  static const String themePreference = 'theme_preference';

  /// Whether user is an SVC (Social Meal Program) member.
  static const String isSvcMember = 'is_svc_member';

  /// Date of first app open (ISO 8601 string).
  static const String firstSeen = r'$created';

  /// App version installed by user.
  static const String appVersion = 'app_version';

  /// Platform: 'android' | 'ios'.
  static const String platform = 'platform';
}
