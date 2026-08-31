import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

/// Wraps a widget and detects rage-tapping (frustrated repeated taps).
///
/// Fires [AnalyticsService.trackRageTapDetected] once per rage session when
/// [threshold] taps occur within [windowMs] milliseconds.
///
/// The event resets after firing so subsequent rage sessions are tracked
/// independently.
///
/// Usage:
/// ```dart
/// RageTapDetector(
///   componentName: 'login_button',
///   screenName: 'login',
///   child: AppPrimaryButton(...),
/// )
/// ```
class RageTapDetector extends StatefulWidget {
  const RageTapDetector({
    super.key,
    required this.child,
    required this.componentName,
    this.screenName,
    this.threshold = 3,
    this.windowMs = 1500,
  });

  final Widget child;
  final String componentName;
  final String? screenName;
  final int threshold;
  final int windowMs;

  @override
  State<RageTapDetector> createState() => _RageTapDetectorState();
}

class _RageTapDetectorState extends State<RageTapDetector> {
  final List<DateTime> _tapTimestamps = [];

  void _onTap() {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(milliseconds: widget.windowMs));
    _tapTimestamps.removeWhere((t) => t.isBefore(cutoff));
    _tapTimestamps.add(now);

    if (_tapTimestamps.length >= widget.threshold) {
      AnalyticsService.instance.trackRageTapDetected(
        componentName: widget.componentName,
        screenName: widget.screenName,
        tapCount: _tapTimestamps.length,
      );
      _tapTimestamps.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onTap,
      child: widget.child,
    );
  }
}
