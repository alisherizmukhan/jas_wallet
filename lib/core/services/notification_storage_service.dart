import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/domain/entities/notification_item.dart';

const _kStorageKey = 'notifications_v1';
const _kMaxStored = 200;

/// Persists received notifications to [SharedPreferences] as a JSON array.
///
/// Architecture is backend-ready: swap [LocalNotificationRepository] for an
/// [ApiNotificationRepository] without touching this layer.
class NotificationStorageService {
  NotificationStorageService._();
  static final NotificationStorageService instance = NotificationStorageService._();

  final _newItemController = StreamController<NotificationItem>.broadcast();

  /// Fires whenever a new notification is stored (foreground FCM, tap from terminated).
  Stream<NotificationItem> get onNewItem => _newItemController.stream;

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<List<NotificationItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStorageKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>().map(_fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> add(NotificationItem item) async {
    final all = await getAll();
    if (all.any((n) => n.id == item.id)) return; // deduplicate
    final updated = [item, ...all];
    final capped = updated.length > _kMaxStored
        ? updated.sublist(0, _kMaxStored)
        : updated;
    await _persist(capped);
    _newItemController.add(item);
  }

  Future<void> markRead(String id) async {
    final all = await getAll();
    await _persist([
      for (final n in all) if (n.id == id) n.copyWith(isRead: true) else n,
    ]);
  }

  Future<void> markAllRead() async {
    final all = await getAll();
    await _persist([for (final n in all) n.copyWith(isRead: true)]);
  }

  Future<void> delete(String id) async {
    final all = await getAll();
    await _persist(all.where((n) => n.id != id).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStorageKey);
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  Future<void> _persist(List<NotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStorageKey, jsonEncode(items.map(_toJson).toList()));
  }

  Map<String, dynamic> _toJson(NotificationItem item) => {
        'id': item.id,
        'title': item.title,
        'message': item.message,
        'category': item.category.name,
        'createdAt': item.createdAt.toIso8601String(),
        'isRead': item.isRead,
        'isImportant': item.isImportant,
        if (item.actionRoute != null) 'actionRoute': item.actionRoute,
        if (item.imageUrl != null) 'imageUrl': item.imageUrl,
      };

  NotificationItem _fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'] as String? ?? 'general';
    final category = NotificationCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => NotificationCategory.general,
    );
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      category: category,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isImportant: json['isImportant'] as bool? ?? false,
      actionRoute: json['actionRoute'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  void dispose() => _newItemController.close();
}
