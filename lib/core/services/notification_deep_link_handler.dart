import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Routes notification action payloads to the correct GoRouter path.
///
/// The [actionRoute] field on [NotificationItem] and FCM data payloads
/// should use the values defined in [AppRoutes] or the shorthand aliases below.
class NotificationDeepLinkHandler {
  NotificationDeepLinkHandler._();

  /// Known shorthand aliases → GoRouter full paths.
  /// Add entries here when new hub sections are added.
  static const _aliases = <String, String>{
    // Fintech
    'fintech': '/fintech',
    // SVC / Social Meal
    'svc': '/svc',
    'social_meal': '/svc',
    'svc_streak': '/svc/streak',
    'svc_history': '/svc/history',
    'svc_calendar': '/svc/calendar',
    // Social / Profile
    'social': '/profile',
    'profile': '/profile',
    'conversations': '/conversations',
    // Job Finder
    'jobs': '/job-finder',
    'job_finder': '/job-finder',
    // Student Clubs
    'clubs': '/student-clubs',
    'student_clubs': '/student-clubs',
    // Campus Access (SALTO tab)
    'access': '/access',
    // Education
    'classroom': '/classroom',
    'courses': '/courses',
    'attendance': '/attendance/student',
    // Referral
    'referral': '/referral',
    // General
    'notifications': '/notifications',
    'settings': '/settings',
  };

  /// Resolve [actionRoute] alias to a full GoRouter path without navigating.
  ///
  /// Returns `null` if the route is null or empty.
  static String? resolve(String? actionRoute) {
    if (actionRoute == null || actionRoute.trim().isEmpty) return null;
    return _aliases[actionRoute.toLowerCase()] ?? actionRoute;
  }

  /// Navigate to the destination encoded in [actionRoute].
  ///
  /// Returns `true` if navigation was attempted, `false` if route was empty.
  static bool handle(BuildContext context, String? actionRoute) {
    if (actionRoute == null || actionRoute.trim().isEmpty) return false;

    final route = _aliases[actionRoute.toLowerCase()] ?? actionRoute;

    try {
      context.push(route);
      return true;
    } catch (_) {
      // Route not found — silently ignore rather than crash
      return false;
    }
  }
}
