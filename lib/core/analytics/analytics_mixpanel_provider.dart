import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';

/// Riverpod provider for the global [AnalyticsService].
///
/// Always resolves to the singleton [AnalyticsService.instance]. Riverpod
/// wrapping enables:
///  • Dependency injection for feature code (via [ref.read])
///  • Simple mocking in widget tests (via [ProviderScope.overrides])
///
/// Usage in UI/notifiers:
/// ```dart
/// final analytics = ref.read(analyticsServiceProvider);
/// analytics.trackLoginSuccess(userId: userId);
/// ```
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});
