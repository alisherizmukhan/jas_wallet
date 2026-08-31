import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_channel_config.dart';
import 'pending_notification_service.dart';
import 'timezone_initializer.dart';

/// Wraps flutter_local_notifications with a clean API for the rest of the app.
///
/// Responsibilities:
///  • Initialize Android channels and iOS presentation options on startup.
///  • Show local notifications for FCM messages that arrive in the foreground.
///  • Schedule/cancel reminder notifications (meal, gym, streak).
///  • Expose a [onNotificationTap] stream so callers can react to taps.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  /// Allows tests to subclass and fake the plugin-backed methods
  /// (same pattern as [EventsService.forTesting]).
  @visibleForTesting
  LocalNotificationService.forTesting();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<String?>.broadcast();

  /// Emits the [actionRoute] payload every time the user taps a notification.
  Stream<String?> get onNotificationTap => _tapController.stream;

  // ── Initialise ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We ask via FirebaseMessaging
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Needed by [scheduleNotification]; cheap and idempotent, so done eagerly
    // here rather than lazily on first schedule.
    ensureTimeZonesInitialized();

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    await _createAndroidChannels();

    // Terminated-state tap: the app was cold-started by the user tapping a
    // scheduled LOCAL notification (e.g. an event reminder). The tap streams
    // have no subscribers yet (FCMService wires up after this), so stash the
    // payload route for BottomNavShell to consume once navigation is ready.
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) &&
          payload != null &&
          payload.isNotEmpty) {
        PendingNotificationService.instance.storeRoute(payload);
      }
    } catch (_) {}
  }

  // ── Android channels ───────────────────────────────────────────────────────

  Future<void> _createAndroidChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    for (final channel in NotificationChannels.all) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  // ── Show notifications ─────────────────────────────────────────────────────

  /// Display a local notification immediately.
  ///
  /// [channelId] must be one of the [NotificationChannels] constants.
  /// [payload] is forwarded to [onNotificationTap] when the user taps.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = NotificationChannels.general,
    String channelName = 'General',
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Convert an FCM [RemoteMessage] to a local notification and display it.
  ///
  /// Supports both notification messages (notification block present) and
  /// data-only messages (falls back to data['title'] / data['body']).
  Future<void> showFromRemoteMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ?? message.data['body'] as String?;
    if (title == null || title.isEmpty) return;

    final data = message.data;
    final channelId = _channelForDataPayload(data);
    final payload = data['action_route'] as String?;

    await showNotification(
      id: message.hashCode,
      title: title,
      body: body ?? '',
      channelId: channelId,
      channelName: _channelNameForId(channelId),
      payload: payload,
    );
  }

  // ── Schedule reminders ─────────────────────────────────────────────────────

  /// Schedule a one-shot notification for an absolute moment in time.
  ///
  /// [scheduledAt] carries its own timezone (e.g. the campus timezone for
  /// event reminders), so the notification fires at the correct instant
  /// regardless of the device timezone. The schedule survives app restarts on
  /// both platforms, and device reboots on Android via
  /// [ScheduledNotificationBootReceiver] (already declared in the manifest).
  ///
  /// Uses an exact alarm when the app is allowed to (Android 12+ user grant),
  /// otherwise falls back to an inexact alarm — acceptable drift for a
  /// day-ahead reminder and avoids a `exact_alarms_not_permitted` crash.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledAt,
    String channelId = NotificationChannels.reminders,
    String channelName = 'Reminders',
    String? payload,
  }) async {
    ensureTimeZonesInitialized();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    var scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    if (androidPlugin != null) {
      try {
        var canExact =
            await androidPlugin.canScheduleExactNotifications() ?? false;
        if (!canExact) {
          // Android 13+ revokes SCHEDULE_EXACT_ALARM by default (hard-required
          // grant from Android 14+ — see requestExactAlarmsPermission's own
          // doc comment) and we never ask for it anywhere else. Without it,
          // every reminder silently downgrades to an inexact alarm, which OEM
          // battery managers (Xiaomi/Huawei/Samsung...) can defer by minutes
          // to hours, or suppress entirely until the app is next opened —
          // reproducing as SVC meal / event reminders that only ever seem to
          // "arrive" once the user opens the app. Ask right here, the first
          // time scheduling actually needs it — the native call itself is a
          // no-op if already granted, so this stays cheap on every later
          // call; [_requestExactAlarmsOnce] caps it to a single real prompt
          // (a full-screen Settings navigation) so a user who declines isn't
          // bounced there again on every subsequent reminder.
          canExact = await _requestExactAlarmsOnce(androidPlugin) ?? false;
        }
        if (!canExact) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      } catch (_) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledAt,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static const String _kExactAlarmsAskedKey = 'exact_alarms_permission_asked';

  /// Requests SCHEDULE_EXACT_ALARM at most once ever, via SharedPreferences.
  ///
  /// The native side already no-ops instantly whenever the permission is
  /// already granted — this flag only prevents re-prompting (a full-screen
  /// system Settings navigation) a user who explicitly declined it.
  Future<bool?> _requestExactAlarmsOnce(
    AndroidFlutterLocalNotificationsPlugin androidPlugin,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kExactAlarmsAskedKey) ?? false) return false;
    await prefs.setBool(_kExactAlarmsAskedKey, true);
    return androidPlugin.requestExactAlarmsPermission();
  }

  /// Cancel a scheduled notification by [id].
  Future<void> cancelNotification(int id) => _plugin.cancel(id);

  /// Cancel ALL pending notifications.
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Returns all pending notification IDs (useful for deduplication).
  Future<List<int>> pendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((n) => n.id).toList();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _onTap(NotificationResponse response) {
    _tapController.add(response.payload);
  }

  // Top-level handler registered via [onDidReceiveBackgroundNotificationResponse].
  // Registered as a static to satisfy the isolate constraint.

  String _channelForDataPayload(Map<String, dynamic> data) {
    final category = data['category'] as String? ?? '';
    return switch (category) {
      'svc' || 'meals' => NotificationChannels.meals,
      'access' || 'salto' => NotificationChannels.access,
      'reminders' => NotificationChannels.reminders,
      'events' => NotificationChannels.events,
      _ => NotificationChannels.general,
    };
  }

  String _channelNameForId(String id) {
    return switch (id) {
      NotificationChannels.meals => 'Meals',
      NotificationChannels.access => 'Campus Access',
      NotificationChannels.reminders => 'Reminders',
      NotificationChannels.events => 'Events',
      _ => 'General',
    };
  }

  void dispose() {
    _tapController.close();
  }
}

/// Background tap handler — must be a top-level function (isolate constraint).
@pragma('vm:entry-point')
void _onBackgroundTap(NotificationResponse response) {
  // Background taps are handled when app resumes via getInitialMessage / onMessageOpenedApp.
  // No action needed here — the FCMService handles routing on app launch.
}
