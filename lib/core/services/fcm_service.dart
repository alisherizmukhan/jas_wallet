import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/domain/entities/notification_item.dart';
import '../analytics/analytics_service.dart';
import 'auth_storage_service.dart';
import 'local_notification_service.dart';
import 'notification_storage_service.dart';
import 'pending_notification_service.dart';

// ── Background handler — must be a top-level function ─────────────────────────
// Registered in main.dart BEFORE runApp().

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Persist to the in-app feed unconditionally — previously this only
  // happened if the user went on to tap the notification (onMessageOpenedApp)
  // or the app was fully terminated (getInitialMessage). A message that
  // arrived while backgrounded and was swiped away or simply not tapped was
  // never stored, silently dropping it from the Notifications page for every
  // category (general, SVC meals, events...). This runs in the plugin's own
  // background isolate, so it reuses FCMService's private helpers directly
  // (same library file) rather than touching any UI-isolate state.
  final item = FCMService.instance._messageToItem(message);
  if (item != null) {
    final shouldStore = await FCMService.instance._shouldStoreNotification(item.category);
    if (shouldStore) {
      await NotificationStorageService.instance.add(item);
    }
  }

  // Firebase SDK auto-displays a system notification for messages that have a
  // notification block. Only show a local notification for data-only messages
  // (notification == null) to prevent duplicate banners for the same event.
  if (message.notification == null) {
    await LocalNotificationService.instance.showFromRemoteMessage(message);
  }
}

const _kPushSettingKey = 'notif_setting_push';
const _kCategorySettingPrefix = 'notif_setting_';

typedef FcmTokenSavedCallback = Future<void> Function(String token);

/// Manages Firebase Cloud Messaging lifecycle.
///
/// Responsibilities:
///  • Request notification permissions (iOS + Android 13+).
///  • Retrieve and persist the FCM device token in secure storage.
///  • Refresh the token when it rotates and notify listeners.
///  • Wire up foreground, background, and app-opened message handlers.
///  • Persist received notifications to [NotificationStorageService].
///  • Expose [onForegroundItem] stream for in-app banner display.
///  • Expose [onDeepLink] stream for navigation from notification taps.
class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final _deepLinkController = StreamController<String?>.broadcast();
  final _foregroundItemController = StreamController<NotificationItem>.broadcast();
  final _tokenUpdatedController = StreamController<String>.broadcast();

  AuthStorageService? _authStorage;
  FcmTokenSavedCallback? _onTokenSaved;
  bool _listenersRegistered = false;

  /// Emits [actionRoute] payloads when a notification is tapped and the app opens.
  Stream<String?> get onDeepLink => _deepLinkController.stream;

  /// Emits incoming foreground [NotificationItem]s so the UI can show an in-app banner.
  Stream<NotificationItem> get onForegroundItem => _foregroundItemController.stream;

  /// Emits whenever a new FCM token is obtained or refreshed.
  Stream<String> get onTokenUpdated => _tokenUpdatedController.stream;

  // ── Initialise ─────────────────────────────────────────────────────────────

  /// Call once after [Firebase.initializeApp] — safe to call multiple times.
  ///
  /// Only the first call registers the `onMessage`/`onTokenRefresh`/
  /// `onMessageOpenedApp` listeners — a second call previously added a
  /// second set of listeners on top of the first (never removed), which
  /// would have fired every foreground/background handler twice per
  /// message had a second call site ever been introduced. Permission
  /// request and token setup are safe to (and still do) repeat, but the
  /// listener registration is now genuinely idempotent, matching this
  /// method's own doc comment.
  Future<void> initialize({
    AuthStorageService? authStorage,
    FcmTokenSavedCallback? onTokenSaved,
  }) async {
    _authStorage = authStorage ?? _authStorage;
    _onTokenSaved = onTokenSaved ?? _onTokenSaved;

    await _requestPermission();
    await _setupTokenManagement();
    if (!_listenersRegistered) {
      _listenersRegistered = true;
      _setupForegroundHandler();
      _setupOpenedAppHandler();
    }
    await _handleInitialMessage();
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // iOS: suppress system banners while the app is in the foreground so we
    // can show our own in-app notification banner instead.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
  }

  // ── Token management ───────────────────────────────────────────────────────

  Future<void> _setupTokenManagement() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _saveToken(token);
    if (!_listenersRegistered) {
      FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
    }
  }

  Future<void> _saveToken(String token) async {
    final storage = _authStorage ?? AuthStorageService();
    await storage.setFcmToken(token);
    if (!_tokenUpdatedController.isClosed) {
      _tokenUpdatedController.add(token);
    }
    final callback = _onTokenSaved;
    if (callback != null) {
      await callback(token);
    }
  }

  /// Returns the locally cached FCM token, or null if unavailable.
  static Future<String?> getStoredToken() async {
    final storage = AuthStorageService();
    final secureToken = await storage.getFcmToken();
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;

    // One-time migration from legacy SharedPreferences storage.
    final prefs = await SharedPreferences.getInstance();
    const legacyKey = 'fcm_device_token';
    final legacyToken = prefs.getString(legacyKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await storage.setFcmToken(legacyToken);
      await prefs.remove(legacyKey);
      return legacyToken;
    }
    return null;
  }

  // ── Settings checks ────────────────────────────────────────────────────────

  /// Returns true if the notification should be stored (persisted to history).
  ///
  /// Toggling a category OFF = mute mode: notifications are still stored
  /// silently so the user can review them in the feed, but no banner is shown.
  /// Disabling the master push toggle fully blocks non-SVC-member notifications;
  /// SVC members retain silent storage even with push master OFF.
  Future<bool> _shouldStoreNotification(NotificationCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool(_kPushSettingKey) ?? true;

    if (!pushEnabled) {
      final isSvcMember = prefs.getBool('svc_is_member') ?? false;
      // SVC mute mode: master push OFF but still store silently
      if (isSvcMember) return true;
      // Non-SVC with master push OFF: fully blocked
      return false;
    }

    // SVC category: non-members are fully blocked regardless of toggle
    if (category == NotificationCategory.svc) {
      final isSvcMember = prefs.getBool('svc_is_member') ?? false;
      if (!isSvcMember) return false;
    }

    // Category toggle OFF → mute mode: always store (banner is suppressed separately)
    return true;
  }

  /// Returns true if the notification should be shown as a push banner.
  ///
  /// Both the master push toggle and the per-category toggle must be ON.
  /// A category that is toggled OFF enters mute mode — notifications are stored
  /// but never surfaced as banners.
  Future<bool> _shouldShowNotification(NotificationCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool(_kPushSettingKey) ?? true;
    if (!pushEnabled) return false;

    if (category == NotificationCategory.svc) {
      final isSvcMember = prefs.getBool('svc_is_member') ?? false;
      if (!isSvcMember) return false;
    }

    // Respect per-category toggle for banner visibility
    return prefs.getBool('$_kCategorySettingPrefix${category.name}') ?? true;
  }


  // ── Message handlers ───────────────────────────────────────────────────────

  /// Foreground: app is open — persist and optionally show in-app banner.
  ///
  /// SVC mute mode: notification is stored but no banner is shown.
  /// System-level notifications are suppressed in foreground (see
  /// [_requestPermission]). The in-app banner is driven via [onForegroundItem].
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((message) async {
      final item = _messageToItem(message);
      if (item == null) return;

      final shouldStore = await _shouldStoreNotification(item.category);
      if (!shouldStore) return;

      // Track push received in foreground before storage
      AnalyticsService.instance.trackPushReceived(
        category: item.category.name,
        messageId: message.messageId,
        notificationState: 'foreground',
      );

      await NotificationStorageService.instance.add(item);

      // Only show banner when push is enabled (not in mute mode)
      final shouldShow = await _shouldShowNotification(item.category);
      if (shouldShow) _foregroundItemController.add(item);
    });

    // Pipe local notification taps (from background/terminated) to deep link stream
    LocalNotificationService.instance.onNotificationTap.listen((payload) {
      if (payload != null && payload.isNotEmpty) {
        _deepLinkController.add(payload);
      }
    });
  }

  /// Background: app is backgrounded — user taps notification to reopen.
  void _setupOpenedAppHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      final item = _messageToItem(message);
      if (item == null) return;

      // Track push opened from background state
      AnalyticsService.instance.trackPushOpened(
        category: item.category.name,
        messageId: message.messageId,
        notificationState: 'background',
      );
      if (item.actionRoute != null) {
        AnalyticsService.instance.trackPushRedirectStarted(
          route: item.actionRoute!,
        );
      }

      final shouldStore = await _shouldStoreNotification(item.category);
      if (shouldStore) await NotificationStorageService.instance.add(item);
      // Store in pending service — BottomNavShell receives via onPending stream
      // or picks it up via consume() in its postFrameCallback.
      PendingNotificationService.instance
          .store(PendingNotificationPayload(item: item, actionRoute: item.actionRoute));
    });
  }

  /// Terminated: app was closed — tapping notification cold-starts the app.
  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return;
    final item = _messageToItem(message);
    if (item == null) return;

    // Track push opened from terminated state (cold-start via notification)
    AnalyticsService.instance.trackPushOpened(
      category: item.category.name,
      messageId: message.messageId,
      notificationState: 'terminated',
    );
    if (item.actionRoute != null) {
      AnalyticsService.instance.trackPushRedirectStarted(
        route: item.actionRoute!,
      );
    }

    final shouldStore = await _shouldStoreNotification(item.category);
    if (shouldStore) await NotificationStorageService.instance.add(item);
    // Cache in pending service — BottomNavShell picks it up via consume() once mounted.
    PendingNotificationService.instance
        .store(PendingNotificationPayload(item: item, actionRoute: item.actionRoute));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  NotificationItem? _messageToItem(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ?? message.data['body'] as String?;
    if (title == null || title.isEmpty) return null;

    final categoryName = message.data['category'] as String? ?? 'general';
    final category = NotificationCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => NotificationCategory.general,
    );

    return NotificationItem(
      id: message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: body ?? '',
      category: category,
      createdAt: _resolveSentTime(message),
      actionRoute: message.data['action_route'] as String?,
    );
  }

  /// On iOS the Firebase plugin populates [RemoteMessage.sentTime] from the
  /// APNs field `google.c.a.ts`, which is a Unix timestamp in **seconds**.
  /// Older plugin versions pass this value directly to
  /// [DateTime.fromMillisecondsSinceEpoch], treating seconds as milliseconds
  /// and producing a date in January 1970.
  ///
  /// We guard against this by rejecting any sentTime before year 2020.
  DateTime _resolveSentTime(RemoteMessage message) {
    final st = message.sentTime;
    if (st == null || st.year < 2020) return DateTime.now();
    return st;
  }

  void dispose() {
    _deepLinkController.close();
    _foregroundItemController.close();
    _tokenUpdatedController.close();
  }
}

// ── Riverpod provider ──────────────────────────────────────────────────────────

/// Exposes the stored FCM token for display / debugging.
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  return FCMService.getStoredToken();
});
