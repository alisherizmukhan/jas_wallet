import 'dart:math' show Random;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_service.dart';
import '../providers/auth_provider.dart';
import '../../features/user/presentation/providers/user_provider.dart';

/// Locks the app after inactivity when the app returns from background.
///
/// Banking-grade behaviour:
/// - Short background (< [lockThreshold]) → restore previous screen.
/// - Long background (≥ [lockThreshold]) → require PIN / biometric.
/// - App paused / hidden / detached → start the clock.
/// - App resumed → check elapsed time and decide.
class AppLifecycleService extends WidgetsBindingObserver {
  AppLifecycleService(this._ref);

  final Ref _ref;

  /// How long the app can stay in background before requiring re-auth.
  ///
  /// UX/security balance: quick app switching (e.g. music/messages) should not
  /// force PIN/biometric immediately.
  static const lockThreshold = Duration(minutes: 5);

  /// Profile data changes rarely and every refresh also re-validates the
  /// avatar cache, so a resume-triggered `/students/me` more than four times
  /// an hour is pure waste (was 1 minute).
  ///
  /// Jittered ±3 min, chosen once per app session (not per resume), so a
  /// broadcast push notification that wakes many devices at the same
  /// instant doesn't also line every device up on the exact same
  /// throttle boundary and refresh together.
  static const _userRefreshThrottleBase = Duration(minutes: 15);
  final Duration _userRefreshThrottle = _userRefreshThrottleBase +
      Duration(seconds: Random().nextInt(361) - 180);

  DateTime? _pausedAt;
  DateTime? _lastUserRefreshAt;
  final _analytics = AnalyticsService.instance;

  /// Call once to register the observer.
  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Call to unregister.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_pausedAt == null) {
          _pausedAt = DateTime.now();
          _analytics.trackAppBackgrounded();
        }
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.inactive:
        // Transitional state — ignore.
        break;
    }
  }

  void _onResumed() {
    final pausedAt = _pausedAt;
    _pausedAt = null;

    if (pausedAt == null) return;

    final elapsed = DateTime.now().difference(pausedAt);
    _analytics.trackAppForegrounded(
      backgroundDurationSeconds: elapsed.inSeconds,
    );

    // CASE 13: Background session resume — validate tokens and biometric
    if (elapsed >= lockThreshold) {
      final authState = _ref.read(authProvider);
      // Only lock if the user is currently authenticated.
      if (authState.status == AuthStatus.authenticated) {
        _analytics.trackAppLocked();
        // Will trigger PinVerifyPage for local auth re-validation
        _ref.read(authProvider.notifier).lockApp();
      }
      return;
    }

    _refreshUserInBackground();
  }

  void _refreshUserInBackground() {
    final authState = _ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) return;

    final now = DateTime.now();
    final lastRefreshAt = _lastUserRefreshAt;
    if (lastRefreshAt != null &&
        now.difference(lastRefreshAt) < _userRefreshThrottle) {
      return;
    }

    _lastUserRefreshAt = now;
    _ref.read(userProvider.notifier).refreshUserInBackground();
  }
}

/// Riverpod provider for the lifecycle service.
///
/// Eagerly watch this provider from a top-level widget (e.g., the app shell)
/// so the observer is registered for the entire lifetime of the app.
final appLifecycleServiceProvider = Provider<AppLifecycleService>((ref) {
  final service = AppLifecycleService(ref);
  service.start();
  ref.onDispose(service.dispose);
  return service;
});
