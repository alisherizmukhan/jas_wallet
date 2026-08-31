import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

/// Mixin for [State] subclasses that tracks accurate screen active time.
///
/// Excludes time spent in background by listening to [AppLifecycleState].
/// Fires [AnalyticsService.trackScreenActiveTime] on dispose with total ms.
///
/// Usage:
/// ```dart
/// class _MyPageState extends ConsumerState<MyPage> with ScreenTimeMixin {
///   @override
///   String get screenTimeName => 'my_page';
/// }
/// ```
mixin ScreenTimeMixin<T extends StatefulWidget> on State<T> {
  String get screenTimeName;

  late final _ScreenTimeObserver _screenTimeObserver;

  @override
  void initState() {
    super.initState();
    _screenTimeObserver = _ScreenTimeObserver(screenTimeName);
    WidgetsBinding.instance.addObserver(_screenTimeObserver);
    _screenTimeObserver.resume();
  }

  @override
  void dispose() {
    _screenTimeObserver.pause();
    _screenTimeObserver.finalize();
    WidgetsBinding.instance.removeObserver(_screenTimeObserver);
    super.dispose();
  }
}

class _ScreenTimeObserver extends WidgetsBindingObserver {
  _ScreenTimeObserver(this.screenName);

  final String screenName;
  DateTime? _enteredAt;
  int _accumulatedMs = 0;

  void resume() => _enteredAt = DateTime.now();

  void pause() {
    final entered = _enteredAt;
    if (entered == null) return;
    _accumulatedMs += DateTime.now().difference(entered).inMilliseconds;
    _enteredAt = null;
  }

  void finalize() {
    if (_accumulatedMs > 0) {
      AnalyticsService.instance.trackScreenActiveTime(
        screenName: screenName,
        activeTimeMs: _accumulatedMs,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      pause();
    } else if (state == AppLifecycleState.resumed) {
      resume();
    }
  }
}
