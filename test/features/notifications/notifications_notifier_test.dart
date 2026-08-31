import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/notification_storage_service.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';
import 'package:jaswallet_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:jaswallet_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeRepo implements NotificationRepository {
  final List<NotificationItem> _items;
  _FakeRepo([List<NotificationItem>? items]) : _items = items ?? [];

  @override
  Future<List<NotificationItem>> getAll() async => List.of(_items);

  @override
  Future<void> markRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i != -1) _items[i] = _items[i].copyWith(isRead: true);
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((n) => n.id == id);
  }
}

class _ErrorRepo implements NotificationRepository {
  @override
  Future<List<NotificationItem>> getAll() async => throw Exception('db error');

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> delete(String id) async {}
}

NotificationItem _item(String id, {bool isRead = false}) => NotificationItem(
      id: id,
      title: id,
      message: '',
      category: NotificationCategory.general,
      createdAt: DateTime.now(),
      isRead: isRead,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotificationStorageService.instance.clear();
  });

  // ── load() ───────────────────────────────────────────────────────────────────

  group('NotificationsNotifier.load()', () {
    test('starts in loading state', () {
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(_FakeRepo()),
      ]);
      addTearDown(container.dispose);

      // Immediately after creation — before async load completes
      expect(container.read(notificationsProvider).isLoading, isTrue);
    });

    test('loads data from repository', () async {
      final repo = _FakeRepo([_item('n1'), _item('n2')]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      container.read(notificationsProvider); // trigger lazy initialization

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(notificationsProvider);
      expect(state.hasValue, isTrue);
      expect(state.valueOrNull!.length, 2);
    });

    test('transitions to error state when repository throws', () async {
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(_ErrorRepo()),
      ]);
      addTearDown(container.dispose);
      container.read(notificationsProvider); // trigger lazy initialization

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(notificationsProvider);
      expect(state.hasError, isTrue);
    });

    test('empty repository produces empty list (not error)', () async {
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(_FakeRepo()),
      ]);
      addTearDown(container.dispose);
      container.read(notificationsProvider); // trigger lazy initialization

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(notificationsProvider);
      expect(state.valueOrNull, isEmpty);
    });
  });

  // ── markRead ─────────────────────────────────────────────────────────────────

  group('NotificationsNotifier.markRead()', () {
    test('optimistic update: state reflects read immediately', () async {
      final repo = _FakeRepo([_item('r1'), _item('r2')]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markRead('r1');

      final items = container.read(notificationsProvider).valueOrNull!;
      expect(items.firstWhere((n) => n.id == 'r1').isRead, isTrue);
      expect(items.firstWhere((n) => n.id == 'r2').isRead, isFalse);
    });

    test('markRead on nonexistent id is a no-op', () async {
      final repo = _FakeRepo([_item('only')]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markRead('ghost');

      final items = container.read(notificationsProvider).valueOrNull!;
      expect(items.first.isRead, isFalse);
    });

    test('markRead when state is loading is a no-op (no crash)', () async {
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(_FakeRepo()),
      ]);
      addTearDown(container.dispose);

      // Call markRead before load completes
      await container.read(notificationsProvider.notifier).markRead('x');
      // No exception thrown
    });
  });

  // ── markAllRead ───────────────────────────────────────────────────────────────

  group('NotificationsNotifier.markAllRead()', () {
    test('marks all items as read', () async {
      final repo = _FakeRepo([_item('a'), _item('b'), _item('c')]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markAllRead();

      final items = container.read(notificationsProvider).valueOrNull!;
      for (final item in items) {
        expect(item.isRead, isTrue, reason: '${item.id} should be read');
      }
    });

    test('markAllRead with empty list is a no-op', () async {
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(_FakeRepo()),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markAllRead();

      expect(container.read(notificationsProvider).valueOrNull, isEmpty);
    });
  });

  // ── markReadMany ──────────────────────────────────────────────────────────────

  group('NotificationsNotifier.markReadMany()', () {
    test('marks only specified ids as read', () async {
      final repo = _FakeRepo([_item('p'), _item('q'), _item('r')]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markReadMany(['p', 'r']);

      final items = container.read(notificationsProvider).valueOrNull!;
      expect(items.firstWhere((n) => n.id == 'p').isRead, isTrue);
      expect(items.firstWhere((n) => n.id == 'q').isRead, isFalse);
      expect(items.firstWhere((n) => n.id == 'r').isRead, isTrue);
    });

    test('markReadMany with empty set is a no-op (no repo calls)', () async {
      final repo = _FakeRepo([_item('z')]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markReadMany([]);

      final items = container.read(notificationsProvider).valueOrNull!;
      expect(items.first.isRead, isFalse);
    });

    test('duplicate ids in markReadMany are deduplicated', () async {
      final repo = _FakeRepo([_item('dup')]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should not throw or double-mark
      await container
          .read(notificationsProvider.notifier)
          .markReadMany(['dup', 'dup', 'dup']);

      final items = container.read(notificationsProvider).valueOrNull!;
      expect(items.first.isRead, isTrue);
    });
  });

  // ── unreadCountProvider ───────────────────────────────────────────────────────

  group('unreadCountProvider', () {
    test('returns 0 while loading', () {
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(_FakeRepo()),
      ]);
      addTearDown(container.dispose);

      expect(container.read(unreadCountProvider), 0);
    });

    test('counts only unread items', () async {
      final repo = _FakeRepo([
        _item('u1', isRead: false),
        _item('r1', isRead: true),
        _item('u2', isRead: false),
      ]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      container.read(notificationsProvider); // trigger lazy initialization
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(unreadCountProvider), 2);
    });

    test('returns 0 on error state', () async {
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(_ErrorRepo()),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(unreadCountProvider), 0);
    });

    test('updates after markRead reduces count', () async {
      final repo = _FakeRepo([_item('u1'), _item('u2')]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      container.read(notificationsProvider); // trigger lazy initialization
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(unreadCountProvider), 2);

      await container.read(notificationsProvider.notifier).markRead('u1');

      expect(container.read(unreadCountProvider), 1);
    });

    test('returns 0 after markAllRead', () async {
      final repo = _FakeRepo([_item('u1'), _item('u2'), _item('u3')]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markAllRead();

      expect(container.read(unreadCountProvider), 0);
    });
  });

  // ── pendingNotificationOpenProvider ──────────────────────────────────────────

  group('pendingNotificationOpenProvider', () {
    test('initial value is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(pendingNotificationOpenProvider), isNull);
    });

    test('setting a value makes it readable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item = _item('pending-1');
      container.read(pendingNotificationOpenProvider.notifier).state = item;

      expect(container.read(pendingNotificationOpenProvider), isNotNull);
      expect(container.read(pendingNotificationOpenProvider)!.id, 'pending-1');
    });

    test('clearing value returns null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingNotificationOpenProvider.notifier).state = _item('x');
      container.read(pendingNotificationOpenProvider.notifier).state = null;

      expect(container.read(pendingNotificationOpenProvider), isNull);
    });

    test('setting a different item replaces the old one', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingNotificationOpenProvider.notifier).state = _item('first');
      container.read(pendingNotificationOpenProvider.notifier).state = _item('second');

      expect(container.read(pendingNotificationOpenProvider)!.id, 'second');
    });
  });

  // ── NotificationStorageService stream → NotificationsNotifier reload ─────────

  group('NotificationsNotifier — stream-triggered reload', () {
    test('notifier reloads when NotificationStorageService emits onNewItem', () async {
      // Use the real storage service but with a fake repo that reads from it
      // indirectly. We test that the subscription chain is wired correctly by
      // verifying the stream fires and the notifier responds.
      var loadCallCount = 0;

      final repo = _FakeRepo();
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      // Subscribe to state changes
      container.listen<AsyncValue<List<NotificationItem>>>(
        notificationsProvider,
        (prev, next) {
          if (next.isLoading) loadCallCount++;
        },
      );

      // Initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final initialLoadCount = loadCallCount;

      // Simulate a new notification arriving via storage service
      await NotificationStorageService.instance
          .add(_item('stream-triggered'));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // At least one more reload should have been triggered
      expect(loadCallCount, greaterThan(initialLoadCount));
    });
  });
}
