import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

/// Wraps a [ScrollController] and fires [AnalyticsService.trackScrollDepthReached]
/// at 25 %, 50 %, 75 %, and 100 % milestones.
///
/// Each milestone fires at most once per page view. Attach [controller] to
/// any [ScrollView] and dispose together with the parent widget.
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage> {
///   late final _scrollController = ScrollController();
///   late final _scrollTracker = ScrollDepthTracker(
///     controller: _scrollController,
///     screenName: 'my_page',
///   );
///
///   @override
///   void dispose() {
///     _scrollTracker.dispose();
///     _scrollController.dispose();
///     super.dispose();
///   }
/// }
/// ```
class ScrollDepthTracker {
  ScrollDepthTracker({
    required ScrollController controller,
    required this.screenName,
    this.milestones = const [25, 50, 75, 100],
  }) : _controller = controller {
    _controller.addListener(_onScroll);
  }

  final ScrollController _controller;
  final String screenName;
  final List<int> milestones;

  final Set<int> _reached = {};

  void _onScroll() {
    final pos = _controller.position;
    if (pos.maxScrollExtent <= 0) return;
    final pct = (pos.pixels / pos.maxScrollExtent * 100).round();

    for (final milestone in milestones) {
      if (pct >= milestone && !_reached.contains(milestone)) {
        _reached.add(milestone);
        AnalyticsService.instance.trackScrollDepthReached(
          screenName: screenName,
          depthPercent: milestone,
        );
      }
    }
  }

  void dispose() {
    _controller.removeListener(_onScroll);
  }
}
