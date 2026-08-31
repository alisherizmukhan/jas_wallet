import 'dart:async';

import '../../features/notifications/domain/entities/notification_item.dart';

/// A notification tap payload received while the app was backgrounded or terminated.
class PendingNotificationPayload {
  const PendingNotificationPayload({required this.item, this.actionRoute});

  final NotificationItem item;
  final String? actionRoute;
}

/// Bridges the gap between FCM message processing and the navigation tree being ready.
///
/// Two paths to handle:
///
/// **Terminated** — `FCMService._handleInitialMessage()` runs in a postFrameCallback,
/// potentially before `BottomNavShell` is mounted. The payload is cached in [_pending].
/// When the shell mounts, its `initState` postFrameCallback calls [consume] and finds it.
///
/// **Background** — the shell IS already mounted. The [onPending] broadcast stream
/// delivers the event to the shell's live subscription immediately.
///
/// Deduplication: the stream listener calls [consume] (clears [_pending]) so the shell's
/// postFrameCallback poll will not double-process the same payload.
class PendingNotificationService {
  PendingNotificationService._();
  static final PendingNotificationService instance = PendingNotificationService._();

  final _controller = StreamController<PendingNotificationPayload>.broadcast();
  final _routeController = StreamController<String>.broadcast();
  PendingNotificationPayload? _pending;
  String? _pendingRoute;

  /// Fires when a new payload is stored (background / resumed case — shell is alive).
  Stream<PendingNotificationPayload> get onPending => _controller.stream;

  /// Fires when a bare deep-link route is stored (see [storeRoute]) while the
  /// shell is already mounted.
  Stream<String> get onPendingRoute => _routeController.stream;

  /// Store a payload and emit on [onPending].
  void store(PendingNotificationPayload payload) {
    _pending = payload;
    _controller.add(payload);
  }

  /// Store a bare deep-link route — the terminated-app tap path for LOCAL
  /// notifications (e.g. event reminders), whose payload is only a route
  /// string with no feed item attached. Same two-path contract as [store]:
  /// the stream covers a mounted shell, [consumeRoute] covers cold start.
  void storeRoute(String route) {
    _pendingRoute = route;
    _routeController.add(route);
  }

  /// Return and clear the cached payload, or null if nothing is pending.
  PendingNotificationPayload? consume() {
    final p = _pending;
    _pending = null;
    return p;
  }

  /// Return and clear the cached deep-link route, or null if none is pending.
  String? consumeRoute() {
    final r = _pendingRoute;
    _pendingRoute = null;
    return r;
  }

  bool get hasPending => _pending != null;
}
