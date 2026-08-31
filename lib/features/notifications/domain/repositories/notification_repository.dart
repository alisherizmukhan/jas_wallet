import '../entities/notification_item.dart';

/// Abstract interface for notification data access.
abstract class NotificationRepository {
  Future<List<NotificationItem>> getAll();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> delete(String id);
}
