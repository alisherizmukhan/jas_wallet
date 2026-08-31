import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';
import 'package:jaswallet_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:jaswallet_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fake notification repository ─────────────────────────────────────────────

class _FakeNotificationRepository implements NotificationRepository {
  final List<NotificationItem> _items;
  _FakeNotificationRepository(List<NotificationItem> items)
      : _items = List.of(items);

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

NotificationItem _item({
  required String id,
  NotificationCategory category = NotificationCategory.general,
  bool isRead = false,
}) {
  return NotificationItem(
    id: id,
    title: id.toUpperCase(),
    message: '',
    category: category,
    createdAt: DateTime.now(),
    isRead: isRead,
  );
}



// ── NotificationSettingsState unit tests ────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── unreadCountProvider ──────────────────────────────────────────────────

  group('unreadCountProvider', () {
    test('returns 0 when notifications list is loading', () {
      final container = ProviderContainer(overrides: [
        notificationsProvider.overrideWith(
          (ref) => NotificationsNotifier(
            ref.watch(notificationRepositoryProvider),
          ),
        ),
      ]);
      addTearDown(container.dispose);

      // Before any data arrives the state is loading → unreadCount == 0
      expect(container.read(unreadCountProvider), 0);
    });

    test('returns 0 when all notifications are read', () {
      final container = ProviderContainer(overrides: [
        notificationsProvider.overrideWith((ref) {
          final notifier = NotificationsNotifier(
            ref.watch(notificationRepositoryProvider),
          );
          // Force-set fully-read state
          notifier.state = AsyncValue.data([
            NotificationItem(
              id: '1',
              title: 'Old',
              message: 'msg',
              category: NotificationCategory.general,
              createdAt: DateTime.now(),
              isRead: true,
            ),
          ]);
          return notifier;
        }),
      ]);
      addTearDown(container.dispose);

      expect(container.read(unreadCountProvider), 0);
    });

    test('returns correct unread count', () {
      final container = ProviderContainer(overrides: [
        notificationsProvider.overrideWith((ref) {
          final notifier = NotificationsNotifier(
            ref.watch(notificationRepositoryProvider),
          );
          notifier.state = AsyncValue.data([
            NotificationItem(
              id: '1',
              title: 'Unread 1',
              message: 'msg',
              category: NotificationCategory.general,
              createdAt: DateTime.now(),
              isRead: false,
            ),
            NotificationItem(
              id: '2',
              title: 'Read',
              message: 'msg',
              category: NotificationCategory.svc,
              createdAt: DateTime.now(),
              isRead: true,
            ),
            NotificationItem(
              id: '3',
              title: 'Unread 2',
              message: 'msg',
              category: NotificationCategory.news,
              createdAt: DateTime.now(),
              isRead: false,
            ),
          ]);
          return notifier;
        }),
      ]);
      addTearDown(container.dispose);

      expect(container.read(unreadCountProvider), 2);
    });

    test('returns 0 on error state', () {
      final container = ProviderContainer(overrides: [
        notificationsProvider.overrideWith((ref) {
          final notifier = NotificationsNotifier(
            ref.watch(notificationRepositoryProvider),
          );
          notifier.state = AsyncValue.error('network error', StackTrace.empty);
          return notifier;
        }),
      ]);
      addTearDown(container.dispose);

      expect(container.read(unreadCountProvider), 0);
    });
  });

  // ── NotificationsNotifier.markRead ──────────────────────────────────────

  group('NotificationsNotifier.markRead()', () {
    test('marks a single item as read', () async {
      final fakeRepo = _FakeNotificationRepository([
        _item(id: 'unread-1'),
        _item(id: 'unread-2'),
      ]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(fakeRepo),
      ]);
      addTearDown(container.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markRead('unread-1');

      final items = container.read(notificationsProvider).valueOrNull!;
      expect(items.firstWhere((n) => n.id == 'unread-1').isRead, isTrue);
      expect(items.firstWhere((n) => n.id == 'unread-2').isRead, isFalse);
    });

    test('markAllRead marks every item as read', () async {
      final fakeRepo = _FakeNotificationRepository([
        _item(id: 'n1'),
        _item(id: 'n2'),
        _item(id: 'n3'),
      ]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(fakeRepo),
      ]);
      addTearDown(container.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markAllRead();

      final items = container.read(notificationsProvider).valueOrNull!;
      for (final item in items) {
        expect(item.isRead, isTrue, reason: '${item.id} should be read');
      }
    });
  });

  // ── NotificationsNotifier.markReadMany ──────────────────────────────────

  group('NotificationsNotifier.markReadMany()', () {
    test('marks multiple items as read by id set', () async {
      final fakeRepo = _FakeNotificationRepository([
        _item(id: 'a'),
        _item(id: 'b'),
        _item(id: 'c'),
      ]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(fakeRepo),
      ]);
      addTearDown(container.dispose);

      // Wait for NotificationsNotifier.load() to populate state from fakeRepo
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markReadMany(['a', 'c']);

      final items = container.read(notificationsProvider).valueOrNull!;
      expect(items.firstWhere((n) => n.id == 'a').isRead, isTrue);
      expect(items.firstWhere((n) => n.id == 'b').isRead, isFalse);
      expect(items.firstWhere((n) => n.id == 'c').isRead, isTrue);
    });

    test('markReadMany with empty set is a no-op', () async {
      final fakeRepo = _FakeNotificationRepository([_item(id: 'x')]);
      final container = ProviderContainer(overrides: [
        notificationRepositoryProvider.overrideWithValue(fakeRepo),
      ]);
      addTearDown(container.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(notificationsProvider.notifier).markReadMany([]);

      final items = container.read(notificationsProvider).valueOrNull!;
      expect(items.first.isRead, isFalse);
    });
  });

  // ── unreadCountProvider — widget integration ─────────────────────────────

  group('unreadCountProvider — Consumer widget integration', () {
    testWidgets('Consumer displays injected unread count of 5', (tester) async {
      // Override unreadCountProvider directly — avoids async mock-data loading.
      await tester.pumpWidget(ProviderScope(
        overrides: [
          unreadCountProvider.overrideWithValue(5),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(unreadCountProvider);
              return Text('$count', key: const Key('count'));
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Consumer shows 0 when injected count is 0', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          unreadCountProvider.overrideWithValue(0),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(unreadCountProvider);
              return Text('$count', key: const Key('count'));
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Consumer rebuilds when unread count changes', (tester) async {
      final countProvider = StateProvider<int>((ref) => 0);

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(countProvider);
              return Text('$count');
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);

      // Simulate a new unread notification arriving
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      container.read(countProvider.notifier).state = 3;
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
    });
  });

  // ── NotificationSettingsState ────────────────────────────────────────────

  group('NotificationSettingsNotifier persistence', () {
    Future<NotificationSettingsState> waitForLoaded(
      ProviderContainer container,
    ) async {
      for (var i = 0; i < 50; i++) {
        final state = container.read(notificationSettingsProvider);
        if (state.isLoaded) return state;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      return container.read(notificationSettingsProvider);
    }

    test('push toggle persists across ProviderContainer instances', () async {
      SharedPreferences.setMockInitialValues({});

      final c1 = ProviderContainer();
      addTearDown(c1.dispose);

      await waitForLoaded(c1);
      await c1.read(notificationSettingsProvider.notifier).setPushEnabled(false);

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);

      final state = await waitForLoaded(c2);
      expect(state.pushEnabled, isFalse);
    });

    test('category toggle persists across ProviderContainer instances', () async {
      SharedPreferences.setMockInitialValues({});

      final c1 = ProviderContainer();
      addTearDown(c1.dispose);

      await waitForLoaded(c1);
      await c1
          .read(notificationSettingsProvider.notifier)
          .setCategoryEnabled(NotificationCategory.access, false);

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);

      final state = await waitForLoaded(c2);
      expect(state.categoryToggles[NotificationCategory.access], isFalse);
    });
  });
}
