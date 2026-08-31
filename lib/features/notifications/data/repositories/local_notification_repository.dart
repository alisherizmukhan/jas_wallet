import '../../../../core/services/notification_storage_service.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';

/// Production repository — persists notifications locally via [NotificationStorageService].
///
/// Drop-in replacement for [MockNotificationRepository].
/// When a backend is ready, create [ApiNotificationRepository] and swap the
/// provider in [notification_provider.dart].
class LocalNotificationRepository implements NotificationRepository {
  const LocalNotificationRepository();

  @override
  Future<List<NotificationItem>> getAll() =>
      NotificationStorageService.instance.getAll();

  @override
  Future<void> markRead(String id) =>
      NotificationStorageService.instance.markRead(id);

  @override
  Future<void> markAllRead() =>
      NotificationStorageService.instance.markAllRead();

  @override
  Future<void> delete(String id) =>
      NotificationStorageService.instance.delete(id);
}
