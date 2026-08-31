import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';
import 'package:jaswallet_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

NotificationItem _item({String id = 'notif-01', String? actionRoute = '/svc'}) {
  return NotificationItem(
    id: id,
    title: 'Meal reminder',
    message: 'Your meal is ready to confirm.',
    category: NotificationCategory.svc,
    createdAt: DateTime.now(),
    actionRoute: actionRoute,
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('pendingNotificationOpenProvider', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(pendingNotificationOpenProvider), isNull);
    });

    test('can be set to a NotificationItem', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item = _item();
      container.read(pendingNotificationOpenProvider.notifier).state = item;

      expect(container.read(pendingNotificationOpenProvider), equals(item));
    });

    test('can be cleared back to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingNotificationOpenProvider.notifier).state = _item();
      container.read(pendingNotificationOpenProvider.notifier).state = null;

      expect(container.read(pendingNotificationOpenProvider), isNull);
    });

    test('item id is preserved through the provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const id = 'preserved-id-42';
      container.read(pendingNotificationOpenProvider.notifier).state =
          _item(id: id);

      expect(container.read(pendingNotificationOpenProvider)!.id, equals(id));
    });

    test('item actionRoute is preserved through the provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const route = '/gym/session/123';
      container.read(pendingNotificationOpenProvider.notifier).state =
          _item(actionRoute: route);

      expect(
        container.read(pendingNotificationOpenProvider)!.actionRoute,
        equals(route),
      );
    });

    test('actionRoute can be null on the item', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingNotificationOpenProvider.notifier).state =
          _item(actionRoute: null);

      expect(
        container.read(pendingNotificationOpenProvider)!.actionRoute,
        isNull,
      );
    });

    test('setting null does not throw', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(pendingNotificationOpenProvider.notifier).state = null,
        returnsNormally,
      );
    });

    test('multiple containers are independent', () {
      final c1 = ProviderContainer();
      final c2 = ProviderContainer();
      addTearDown(c1.dispose);
      addTearDown(c2.dispose);

      c1.read(pendingNotificationOpenProvider.notifier).state =
          _item(id: 'c1-item');

      expect(c1.read(pendingNotificationOpenProvider)?.id, equals('c1-item'));
      expect(c2.read(pendingNotificationOpenProvider), isNull);
    });

    test('listener fires when item changes from null to item', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final changes = <NotificationItem?>[];
      container.listen<NotificationItem?>(
        pendingNotificationOpenProvider,
        (_, next) => changes.add(next),
        fireImmediately: false,
      );

      container.read(pendingNotificationOpenProvider.notifier).state = _item();
      expect(changes, hasLength(1));
      expect(changes.first, isNotNull);
    });

    test('listener fires when item changes from item to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingNotificationOpenProvider.notifier).state = _item();

      final changes = <NotificationItem?>[];
      container.listen<NotificationItem?>(
        pendingNotificationOpenProvider,
        (_, next) => changes.add(next),
        fireImmediately: false,
      );

      container.read(pendingNotificationOpenProvider.notifier).state = null;
      expect(changes, hasLength(1));
      expect(changes.first, isNull);
    });

    test('listener does not fire when set to same value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final item = _item();
      container.read(pendingNotificationOpenProvider.notifier).state = item;

      final changes = <NotificationItem?>[];
      container.listen<NotificationItem?>(
        pendingNotificationOpenProvider,
        (_, next) => changes.add(next),
        fireImmediately: false,
      );

      // StateProvider uses identical() — setting same object does not notify.
      container.read(pendingNotificationOpenProvider.notifier).state = item;
      expect(changes, isEmpty);
    });
  });
}
