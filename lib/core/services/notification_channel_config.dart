import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Defines every Android notification channel used by the app.
///
/// Channels control sound, importance, and vibration independently.
/// Users can configure each channel in Android system settings.
class NotificationChannels {
  NotificationChannels._();

  // ── Channel IDs ────────────────────────────────────────────────────────────
  static const String general = 'jaswallet_general';
  static const String meals = 'jaswallet_meals';
  static const String gym = 'jaswallet_gym';
  static const String access = 'jaswallet_access';
  static const String social = 'jaswallet_social';
  static const String education = 'jaswallet_education';
  static const String fintech = 'jaswallet_fintech';
  static const String jobs = 'jaswallet_jobs';
  static const String reminders = 'jaswallet_reminders';
  static const String events = 'jaswallet_events';
  static const String orientation = 'jaswallet_orientation';

  /// Display name for [orientation]. Kept as a constant rather than a
  /// localized string: Android stores the channel name at creation time, so a
  /// later language switch would leave a stale translation in system settings.
  static const String orientationName = 'Orientation Week';

  /// All channels to create on Android startup.
  static List<AndroidNotificationChannel> get all => [
        AndroidNotificationChannel(
          general,
          'General',
          description: 'System updates and account alerts',
          importance: Importance.defaultImportance,
        ),
        AndroidNotificationChannel(
          meals,
          'Meals',
          description: 'Meal balance and SVC menu updates',
          importance: Importance.high,
        ),
        AndroidNotificationChannel(
          gym,
          'Gym & Fitness',
          description: 'Workout reminders and gym schedules',
          importance: Importance.defaultImportance,
        ),
        AndroidNotificationChannel(
          access,
          'Campus Access',
          description: 'Door access and SALTO turnstile alerts',
          importance: Importance.high,
        ),
        AndroidNotificationChannel(
          social,
          'Social',
          description: 'Messages, follows and mentions',
          importance: Importance.high,
        ),
        AndroidNotificationChannel(
          education,
          'Education',
          description: 'Courses, assignments and grades',
          importance: Importance.defaultImportance,
        ),
        AndroidNotificationChannel(
          fintech,
          'Finance',
          description: 'Payments, transfers and transactions',
          importance: Importance.high,
        ),
        AndroidNotificationChannel(
          jobs,
          'Jobs',
          description: 'New job matches for your profile',
          importance: Importance.defaultImportance,
        ),
        AndroidNotificationChannel(
          reminders,
          'Reminders',
          description: 'Scheduled reminders and alerts',
          importance: Importance.high,
        ),
        AndroidNotificationChannel(
          events,
          'Events',
          description: 'Reminders about upcoming campus events',
          importance: Importance.high,
        ),
        AndroidNotificationChannel(
          orientation,
          orientationName,
          description: 'Photo Quest verification results and token rewards',
          importance: Importance.high,
        ),
      ];
}
