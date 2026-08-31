import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/notification_storage_service.dart';
import '../../data/repositories/local_notification_repository.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';

// ─── Re-export FCM token provider so pages can import from one place ──────────
export '../../../../core/services/fcm_service.dart' show fcmTokenProvider;

// ─── Repository provider ───────────────────────────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => const LocalNotificationRepository(),
);

// ─── All categories shown in settings (one toggle per category) ───────────────

const notificationSettingCategories = <NotificationCategory>[
  NotificationCategory.general,
  NotificationCategory.news,
  NotificationCategory.svc,
  NotificationCategory.access,
  NotificationCategory.events,
];

// ─── Notifications list ────────────────────────────────────────────────────────

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationItem>>>(
  (ref) {
    final repo = ref.watch(notificationRepositoryProvider);
    return NotificationsNotifier(repo);
  },
);

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  NotificationsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
    // Reload feed whenever a new notification arrives via FCM/local trigger
    _sub = NotificationStorageService.instance.onNewItem.listen((_) => load());
  }

  final NotificationRepository _repo;
  StreamSubscription<NotificationItem>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repo.getAll();
      if (mounted) state = AsyncValue.data(items);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    _updateLocal((items) => [
          for (final n in items)
            if (n.id == id) n.copyWith(isRead: true) else n,
        ]);
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    _updateLocal((items) => [for (final n in items) n.copyWith(isRead: true)]);
  }

  Future<void> markReadMany(Iterable<String> ids) async {
    final idSet = ids.toSet();
    if (idSet.isEmpty) return;
    for (final id in idSet) {
      await _repo.markRead(id);
    }
    _updateLocal((items) => [
          for (final n in items)
            if (idSet.contains(n.id)) n.copyWith(isRead: true) else n,
        ]);
  }

  Future<void> deleteNotification(String id) async {
    // Optimistic UI: remove from local state immediately
    _updateLocal((items) => items.where((n) => n.id != id).toList());
    // Then persist
    await _repo.delete(id);
  }

  void _updateLocal(
    List<NotificationItem> Function(List<NotificationItem>) updater,
  ) {
    state.whenData((items) {
      if (mounted) state = AsyncValue.data(updater(items));
    });
  }
}

// ─── Unread count — drives the badge on the Notifications tab ─────────────────

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (items) => items.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});

// ─── Pending notification open — signals NotificationsPage to auto-open a detail sheet ──

/// Set by BottomNavShell when a tapped notification (background/terminated) should
/// open its detail sheet. NotificationsPage listens and clears this after handling.
final pendingNotificationOpenProvider = StateProvider<NotificationItem?>((ref) => null);

// ─── Notification settings (per-category toggles + master push) ───────────────

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
  (ref) => NotificationSettingsNotifier(),
);

class NotificationSettingsState {
  const NotificationSettingsState({
    required this.pushEnabled,
    required this.categoryToggles,
    this.isLoaded = false,
  });

  factory NotificationSettingsState.initial() {
    return NotificationSettingsState(
      pushEnabled: true,
      categoryToggles: {
        for (final c in notificationSettingCategories) c: true,
      },
    );
  }

  final bool pushEnabled;
  final Map<NotificationCategory, bool> categoryToggles;
  final bool isLoaded;

  bool isCategoryEnabled(NotificationCategory c) =>
      pushEnabled && (categoryToggles[c] ?? true);

  NotificationSettingsState copyWith({
    bool? pushEnabled,
    Map<NotificationCategory, bool>? categoryToggles,
    bool? isLoaded,
  }) {
    return NotificationSettingsState(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      categoryToggles: categoryToggles ?? this.categoryToggles,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier() : super(NotificationSettingsState.initial()) {
    _loadFromPrefs();
  }

  static const _keyPrefix = 'notif_setting_';
  static const _keyPush = '${_keyPrefix}push';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final push = prefs.getBool(_keyPush) ?? true;
    final toggles = <NotificationCategory, bool>{};
    for (final c in notificationSettingCategories) {
      toggles[c] = prefs.getBool('$_keyPrefix${c.name}') ?? true;
    }
    if (mounted) {
      state = state.copyWith(
        pushEnabled: push,
        categoryToggles: toggles,
        isLoaded: true,
      );
    }
    await syncTopicSubscriptions();
  }

  /// Whether the FCM topic for [c] should be subscribed.
  ///
  /// Category toggles are mute-mode only: a toggled-off category stays
  /// subscribed so FCM still delivers the message, which is then stored
  /// silently in the feed without a banner (see FCMService). Only the master
  /// push toggle unsubscribes — and even then SVC members keep silent
  /// delivery. The SVC topic itself is member-only: non-members are never
  /// subscribed, so meal notifications are only ever sent to SVC people.
  static bool _shouldBeSubscribed({
    required NotificationCategory c,
    required bool pushEnabled,
    required bool isSvcMember,
  }) {
    final base = pushEnabled || isSvcMember;
    if (c == NotificationCategory.svc) return base && isSvcMember;
    return base;
  }

  static const _keyTopicSyncSignature = '${_keyPrefix}topic_sync_signature';

  /// Align FCM topic subscriptions with persisted settings.
  ///
  /// Called on settings load and after login — but "after login" in practice
  /// means every transition to an authenticated state, including routine PIN
  /// unlocks, not just a fresh sign-in. The only inputs that change the
  /// outcome are [pushEnabled]/[isSvcMember] (see [_shouldBeSubscribed]), so
  /// this no-ops the whole subscribe/unsubscribe loop — up to 5 Firebase SDK
  /// calls — whenever neither has changed since the last successful sync,
  /// [forceResync] set only where the caller genuinely needs the loop to run
  /// unconditionally (e.g. the settings page itself, right after the user
  /// flips a toggle).
  Future<void> syncTopicSubscriptions({bool forceResync = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool(_keyPush) ?? true;
    final isSvcMember = prefs.getBool('svc_is_member') ?? false;

    final signature = 'push:$pushEnabled|svc:$isSvcMember';
    if (!forceResync && prefs.getString(_keyTopicSyncSignature) == signature) {
      return;
    }

    for (final c in notificationSettingCategories) {
      final topic = 'jaswallet_${c.name}';
      final shouldSubscribe = _shouldBeSubscribed(
        c: c,
        pushEnabled: pushEnabled,
        isSvcMember: isSvcMember,
      );

      try {
        if (shouldSubscribe) {
          await FirebaseMessaging.instance.subscribeToTopic(topic);
        } else {
          await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        }
      } catch (_) {
        // Firebase not initialized (e.g. placeholder values) — ignore silently
      }
    }

    await prefs.setString(_keyTopicSyncSignature, signature);
  }

  Future<void> setPushEnabled(bool value) async {
    state = state.copyWith(pushEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPush, value);

    // SVC members: disabling push = mute mode (stay subscribed, suppress banners client-side)
    // Non-SVC members: disabling push = fully disable (unsubscribe from all topics)
    final isSvcMember = prefs.getBool('svc_is_member') ?? false;
    if (!value && isSvcMember) return; // mute mode — keep subscriptions active

    // Sync FCM topic subscriptions for all categories
    for (final c in notificationSettingCategories) {
      final shouldSubscribe = _shouldBeSubscribed(
        c: c,
        pushEnabled: value,
        isSvcMember: isSvcMember,
      );
      final topic = 'jaswallet_${c.name}';
      try {
        if (shouldSubscribe) {
          await FirebaseMessaging.instance.subscribeToTopic(topic);
        } else {
          await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        }
      } catch (_) {
        // Firebase not initialized (e.g. placeholder values) — ignore silently
      }
    }
  }

  Future<void> setCategoryEnabled(NotificationCategory c, bool value) async {
    if (!notificationSettingCategories.contains(c)) return;
    final updated = Map<NotificationCategory, bool>.from(state.categoryToggles);
    updated[c] = value;
    state = state.copyWith(categoryToggles: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${c.name}', value);

    // Toggling a category OFF = mute mode: stay subscribed so FCM still delivers
    // the message, which is then stored silently (no banner). Never unsubscribe
    // on toggle-off — only the master push toggle unsubscribes.
    if (!value) return;

    // Category turned ON: subscribe (only if master push is also ON, and
    // never subscribe non-members to the member-only SVC topic)
    if (!state.pushEnabled) return;
    if (c == NotificationCategory.svc &&
        !(prefs.getBool('svc_is_member') ?? false)) {
      return;
    }
    final topic = 'jaswallet_${c.name}';
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {
      // Firebase not initialized (e.g. placeholder values) — ignore silently
    }
  }
}
