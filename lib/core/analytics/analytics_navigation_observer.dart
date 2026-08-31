import 'package:flutter/material.dart';

import 'analytics_service.dart';

/// Maps GoRouter route names to human-readable screen names for analytics.
const _kRouteNameToScreenName = <String, String>{
  // Auth flow
  'languageSelection': 'Language Selection',
  'onboarding': 'Onboarding',
  'welcome': 'Welcome',
  'login': 'Login',
  'registration': 'Registration',
  'personalDataConsent': 'Personal Data Consent',
  'verification': 'Verification',
  'biometricVerification': 'Biometric Verification',
  'profileCreation': 'Profile Creation',
  'saltoActivation': 'Salto Activation',
  'forgotPassword': 'Forgot Password',
  'resetPassword': 'Reset Password',
  // PIN & biometric
  'pinCreate': 'PIN Create',
  'pinVerify': 'PIN Verify',
  'biometricSetup': 'Biometric Setup',
  // Main tabs
  'home': 'Home',
  'access': 'Salto Access',
  'hub': 'Hub',
  'notifications': 'Notifications',
  'profile': 'Profile',
  // Nested routes
  'settings': 'Settings',
  'accessStats': 'Access Stats',
  'notificationsSettings': 'Notification Settings',
  'notificationsCategory': 'Notification Category',
  'myProfile': 'My Profile',
  'saltoStudentCard': 'Student Card',
  'editProfile': 'Edit Profile',
  'editPhone': 'Edit Phone',
  'security': 'Security',
  // Job Finder
  'jobFinder': 'Job Finder',
  'jobList': 'Job List',
  'jobDetail': 'Job Detail',
  // Student Clubs
  'studentClubs': 'Student Clubs',
  'clubDetail': 'Club Detail',
  'clubApply': 'Club Apply',
  // Fintech
  'fintech': 'Fintech',
  'fintechTokens': 'Tokens',
  'fintechNft': 'NFT',
  'fintechDiscounts': 'Discounts',
  'fintechCustomization': 'Card Customization',
  // Social
  'subscriptions': 'Subscriptions',
  'subscriptionsUser': 'User Subscriptions',
  'followers': 'Followers',
  'followersUser': 'User Followers',
  'following': 'Following',
  'followingUser': 'User Following',
  'conversations': 'Conversations',
  'chat': 'Chat',
  'userSearch': 'User Search',
  // Help & About
  'help': 'Help',
  'aboutApp': 'About App',
  // Statistics
  'statistics': 'Statistics',
  // Courses
  'courses': 'Courses',
  // Classroom
  'classroom': 'Classroom',
  'courseDetail': 'Course Detail',
  'professorDashboard': 'Professor Dashboard',
  // SVC
  'svcDashboard': 'SVC Dashboard',
  'svcQrScan': 'SVC QR Scan',
  'svcSuccess': 'SVC Success',
  'svcCalendar': 'SVC Calendar',
  'svcStreak': 'SVC Streak',
  'svcHistory': 'SVC History',
  // Attendance
  'attendanceStudent': 'Student Attendance',
  'attendanceTeacher': 'Teacher Attendance',
  'qrScan': 'QR Scan',
  'attendanceHistory': 'Attendance History',
  'createSession': 'Create Session',
  'sessionAttendees': 'Session Attendees',
  // Profile sections
  'editAboutMe': 'Edit About Me',
  'editExperience': 'Edit Experience',
  'editSkills': 'Edit Skills',
  'editAcademy': 'Edit Academy',
  'editUserActivity': 'Edit User Activity',
  // Tutorials & Events
  'tutorials': 'Tutorials',
  'tutorialDetail': 'Tutorial Detail',
  'eventDetails': 'Event Details',
  // Weather & Exchange
  'weatherDetails': 'Weather Details',
  'exchangeDetails': 'Exchange Details',
  // SOS (Campus Security)
  'sosForm': 'SOS Report',
  'sosHistory': 'SOS History',
  'sosDetail': 'SOS Report Detail',
};

/// GoRouter-compatible navigator observer that automatically tracks
/// screen open/close events and duration through [AnalyticsService].
///
/// Register with GoRouter:
/// ```dart
/// GoRouter(
///   observers: [AnalyticsNavigationObserver.instance],
///   ...
/// )
/// ```
class AnalyticsNavigationObserver extends NavigatorObserver {
  AnalyticsNavigationObserver._();

  /// Application-wide singleton.
  static final AnalyticsNavigationObserver instance =
      AnalyticsNavigationObserver._();

  final _analytics = AnalyticsService.instance;

  /// Stack of (screenName, openedAt) pairs for duration tracking.
  final _screenStack = <_ScreenEntry>[];

  // ── NavigatorObserver ────────────────────────────────────────────────────

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final screenName = _nameForRoute(route);
    if (screenName == null) return;

    final previous = _screenStack.isEmpty ? null : _screenStack.last.name;
    _screenStack.add(_ScreenEntry(name: screenName));

    _analytics.trackScreenOpened(
      screenName: screenName,
      previousScreen: previous,
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _closeTop();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _closeTop();

    if (newRoute == null) return;
    final screenName = _nameForRoute(newRoute);
    if (screenName == null) return;

    _screenStack.add(_ScreenEntry(name: screenName));
    _analytics.trackScreenOpened(screenName: screenName);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _closeTop();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _closeTop() {
    if (_screenStack.isEmpty) return;
    final top = _screenStack.removeLast();
    final durationMs = DateTime.now().difference(top.openedAt).inMilliseconds;
    _analytics.trackScreenClosed(
      screenName: top.name,
      durationMs: durationMs,
    );
  }

  /// Returns a human-readable screen name for [route], or null if the route
  /// should not be tracked (e.g. dialog overlays, unnamed routes).
  static String? _nameForRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return null;

    // GoRouter appends path parameters to the route name for dynamic routes
    // (e.g. '/chat/:userId' becomes '/chat/user123'). Extract the base name.
    final routeName = _extractRouteName(name);
    return _kRouteNameToScreenName[routeName] ?? _titleCase(routeName);
  }

  /// Strips path parameter segments from a GoRouter route name.
  static String _extractRouteName(String name) {
    // GoRouter uses the `name` parameter directly (not the path).
    // The settings.name is the route name as declared in GoRoute(name:...).
    return name;
  }

  static String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll(RegExp(r'[-_/]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

/// Internal screen stack entry for duration tracking.
class _ScreenEntry {
  _ScreenEntry({required this.name}) : openedAt = DateTime.now();

  final String name;
  final DateTime openedAt;
}
