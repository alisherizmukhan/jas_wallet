import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

/// Tracks whether a user is using a feature for the first time or revisiting.
///
/// Uses [SharedPreferences] to persist first-use state across app sessions.
/// Fires [AnalyticsService.trackFeatureFirstUsed] on first call and
/// [AnalyticsService.trackFeatureRevisited] on subsequent calls.
///
/// Call [trackFeatureUsed] at the entry point of any feature you want to track.
/// This is a singleton — share the same instance across the app.
///
/// Usage:
/// ```dart
/// await FeatureAdoptionTracker.instance.trackFeatureUsed('sos_report');
/// await FeatureAdoptionTracker.instance.trackFeatureUsed('svc_dashboard');
/// ```
class FeatureAdoptionTracker {
  FeatureAdoptionTracker._();
  static final FeatureAdoptionTracker instance = FeatureAdoptionTracker._();

  static const _prefPrefix = 'feature_first_use_';

  Future<void> trackFeatureUsed(String featureName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$featureName';
      final isFirst = !prefs.containsKey(key);

      if (isFirst) {
        await prefs.setBool(key, true);
        AnalyticsService.instance.trackFeatureFirstUsed(featureName: featureName);
      } else {
        AnalyticsService.instance.trackFeatureRevisited(featureName: featureName);
      }
    } catch (_) {
      // SharedPreferences unavailable — degrade gracefully, fire revisited
      AnalyticsService.instance.trackFeatureRevisited(featureName: featureName);
    }
  }

  /// Reset first-use state for a feature (e.g. after account switch).
  Future<void> reset(String featureName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefPrefix$featureName');
    } catch (_) {}
  }

  /// Reset all tracked features (e.g. on logout).
  Future<void> resetAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
