import 'analytics_service.dart';

/// Singleton that tracks multi-step user flows (funnels).
///
/// Use [start] when the user enters a flow, [complete] on success,
/// [abandon] on back/dismiss, [fail] on error. Each method is idempotent
/// and safe to call even if a flow was never started.
///
/// Usage:
/// ```dart
/// // Entry point:
/// AnalyticsFlowTracker.instance.start(FlowName.sosReport);
///
/// // Success:
/// AnalyticsFlowTracker.instance.complete(FlowName.sosReport);
///
/// // In dispose if not completed:
/// AnalyticsFlowTracker.instance.abandon(FlowName.sosReport, atStep: 'photo');
/// ```
class AnalyticsFlowTracker {
  AnalyticsFlowTracker._();
  static final AnalyticsFlowTracker instance = AnalyticsFlowTracker._();

  final Map<String, DateTime> _startTimes = {};
  final Set<String> _completedFlows = {};

  void start(FlowName flow, {String? entryPoint}) {
    final name = flow.value;
    _startTimes[name] = DateTime.now();
    _completedFlows.remove(name);
    AnalyticsService.instance.trackFlowStarted(
      flowName: name,
      entryPoint: entryPoint,
    );
  }

  void complete(FlowName flow, {Map<String, dynamic>? extra}) {
    final name = flow.value;
    final started = _startTimes.remove(name);
    if (_completedFlows.contains(name)) return;
    _completedFlows.add(name);
    final durationMs = started != null
        ? DateTime.now().difference(started).inMilliseconds
        : null;
    AnalyticsService.instance.trackFlowCompleted(
      flowName: name,
      durationMs: durationMs,
      extra: extra,
    );
  }

  void abandon(FlowName flow, {String? atStep}) {
    final name = flow.value;
    if (_completedFlows.contains(name)) return;
    final started = _startTimes.remove(name);
    final durationMs = started != null
        ? DateTime.now().difference(started).inMilliseconds
        : null;
    AnalyticsService.instance.trackFlowAbandoned(
      flowName: name,
      atStep: atStep,
      durationMs: durationMs,
    );
  }

  void fail(FlowName flow, {String? reason, String? atStep}) {
    final name = flow.value;
    _startTimes.remove(name);
    AnalyticsService.instance.trackFlowFailed(
      flowName: name,
      reason: reason,
      atStep: atStep,
    );
  }

  bool isActive(FlowName flow) => _startTimes.containsKey(flow.value);
}

/// Enumeration of all tracked user flows in the app.
enum FlowName {
  login('login'),
  registration('registration'),
  pinSetup('pin_setup'),
  biometricSetup('biometric_setup'),
  onboarding('onboarding'),
  sosReport('sos_report'),
  clubApplication('club_application'),
  profileEdit('profile_edit'),
  notificationSettings('notification_settings');

  const FlowName(this.value);
  final String value;
}
