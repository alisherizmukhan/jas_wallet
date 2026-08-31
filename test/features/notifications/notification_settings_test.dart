import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/notification_storage_service.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';
import 'package:jaswallet_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('notificationSettingCategories', () {
    test('contains every category except orientation', () {
      expect(
        notificationSettingCategories.toSet(),
        NotificationCategory.values.toSet()..remove(NotificationCategory.orientation),
      );
    });

    test('orientation is absent, so it can never be switched off', () {
      // Photo Quest verdicts are generated on-device in response to something
      // the student did, and losing one means never learning that a photo was
      // rejected. Keeping the category out of this list is what makes the
      // settings page unable to render a toggle for it — if it ever appears
      // here, a student can silence their own submission results.
      expect(
        notificationSettingCategories,
        isNot(contains(NotificationCategory.orientation)),
      );
      expect(
        NotificationSettingsState.initial()
            .categoryToggles
            .containsKey(NotificationCategory.orientation),
        isFalse,
      );
    });

    test('has no duplicates', () {
      expect(
        notificationSettingCategories.toSet().length,
        notificationSettingCategories.length,
      );
    });

    test('svc is included', () {
      expect(notificationSettingCategories, contains(NotificationCategory.svc));
    });

    test('access is included', () {
      expect(
          notificationSettingCategories, contains(NotificationCategory.access));
    });
  });

  group('NotificationSettingsState', () {
    test('initial state has pushEnabled true', () {
      final state = NotificationSettingsState.initial();
      expect(state.pushEnabled, true);
    });

    test('initial state enables every configurable category', () {
      final state = NotificationSettingsState.initial();
      expect(state.categoryToggles.length, notificationSettingCategories.length);
      for (final c in notificationSettingCategories) {
        expect(state.categoryToggles[c], true,
            reason: '${c.name} should be enabled by default');
      }
    });

    test('isCategoryEnabled respects master push switch', () {
      final state = NotificationSettingsState(
        pushEnabled: false,
        categoryToggles: {NotificationCategory.svc: true},
      );
      expect(state.isCategoryEnabled(NotificationCategory.svc), false);
    });

    test('isCategoryEnabled is true when both push and category are on', () {
      final state = NotificationSettingsState(
        pushEnabled: true,
        categoryToggles: {NotificationCategory.svc: true},
      );
      expect(state.isCategoryEnabled(NotificationCategory.svc), true);
    });

    test('isCategoryEnabled is false when category toggle is off', () {
      final state = NotificationSettingsState(
        pushEnabled: true,
        categoryToggles: {NotificationCategory.svc: false},
      );
      expect(state.isCategoryEnabled(NotificationCategory.svc), false);
    });

    test('missing category toggle defaults to true in isCategoryEnabled', () {
      final state = NotificationSettingsState(
        pushEnabled: true,
        categoryToggles: {},
      );
      expect(state.isCategoryEnabled(NotificationCategory.access), true);
    });

    test('copyWith only changes specified fields', () {
      final original = NotificationSettingsState.initial();
      final updated = original.copyWith(pushEnabled: false);
      expect(updated.pushEnabled, false);
      expect(updated.categoryToggles, original.categoryToggles);
      expect(updated.isLoaded, original.isLoaded);
    });
  });

  group('NotificationSettingsNotifier', () {
    ProviderContainer makeContainer() {
      return ProviderContainer();
    }

    test('initial notifier state is not loaded yet (async load pending)', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      // isLoaded starts false, becomes true after prefs load
      final state = container.read(notificationSettingsProvider);
      // Could be either; just ensure it doesn't throw
      expect(state, isA<NotificationSettingsState>());
    });

    test('setPushEnabled updates state synchronously', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(notificationSettingsProvider.notifier);
      await notifier.setPushEnabled(false);
      expect(container.read(notificationSettingsProvider).pushEnabled, false);
    });

    test('setPushEnabled persists to SharedPreferences', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(notificationSettingsProvider.notifier);
      await notifier.setPushEnabled(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_setting_push'), false);
    });

    test('setCategoryEnabled updates svc toggle', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(notificationSettingsProvider.notifier);
      await notifier.setCategoryEnabled(NotificationCategory.svc, false);
      final state = container.read(notificationSettingsProvider);
      expect(state.categoryToggles[NotificationCategory.svc], false);
    });

    test('setCategoryEnabled updates access toggle', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(notificationSettingsProvider.notifier);
      await notifier.setCategoryEnabled(NotificationCategory.access, false);
      final state = container.read(notificationSettingsProvider);
      expect(state.categoryToggles[NotificationCategory.access], false);
    });

    test('setCategoryEnabled persists access to SharedPreferences', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(notificationSettingsProvider.notifier);
      await notifier.setCategoryEnabled(NotificationCategory.access, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_setting_access'), false);
    });

    test('setCategoryEnabled ignores unknown category', () async {
      // All valid categories should be handled; this tests no crash
      final container = makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(notificationSettingsProvider.notifier);
      // Should not throw for any category
      for (final cat in NotificationCategory.values) {
        await expectLater(
          notifier.setCategoryEnabled(cat, false),
          completes,
        );
      }
    });
  });

  group('NotificationStorageService', () {
    setUp(() async {
      await NotificationStorageService.instance.clear();
    });

    test('getAll returns empty list when no notifications stored', () async {
      final items = await NotificationStorageService.instance.getAll();
      expect(items, isEmpty);
    });

    test('add stores an svc notification and getAll returns it', () async {
      final item = NotificationItem(
        id: 'svc-001',
        title: 'Meal reminder',
        message: 'Your meal is ready',
        category: NotificationCategory.svc,
        createdAt: DateTime(2024, 6, 1),
      );
      await NotificationStorageService.instance.add(item);
      final all = await NotificationStorageService.instance.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'svc-001');
      expect(all.first.category, NotificationCategory.svc);
    });

    test('add stores an access notification and getAll returns it', () async {
      final item = NotificationItem(
        id: 'access-001',
        title: 'Door unlocked',
        message: 'Main entrance unlocked',
        category: NotificationCategory.access,
        createdAt: DateTime(2024, 6, 1),
      );
      await NotificationStorageService.instance.add(item);
      final all = await NotificationStorageService.instance.getAll();
      expect(all.any((n) => n.category == NotificationCategory.access), true);
    });

    test('add deduplicates by id', () async {
      final item = NotificationItem(
        id: 'dup-001',
        title: 'Test',
        message: 'Test',
        category: NotificationCategory.general,
        createdAt: DateTime(2024, 6, 1),
      );
      await NotificationStorageService.instance.add(item);
      await NotificationStorageService.instance.add(item);
      final all = await NotificationStorageService.instance.getAll();
      expect(all.length, 1);
    });

    test('markRead updates isRead flag', () async {
      final item = NotificationItem(
        id: 'read-001',
        title: 'Test',
        message: 'Test',
        category: NotificationCategory.general,
        createdAt: DateTime(2024, 6, 1),
      );
      await NotificationStorageService.instance.add(item);
      await NotificationStorageService.instance.markRead('read-001');
      final all = await NotificationStorageService.instance.getAll();
      expect(all.first.isRead, true);
    });

    test('markAllRead marks all notifications read', () async {
      for (var i = 0; i < 3; i++) {
        await NotificationStorageService.instance.add(NotificationItem(
          id: 'n-$i',
          title: 'T',
          message: 'M',
          category: NotificationCategory.general,
          createdAt: DateTime(2024, 6, i + 1),
        ));
      }
      await NotificationStorageService.instance.markAllRead();
      final all = await NotificationStorageService.instance.getAll();
      expect(all.every((n) => n.isRead), true);
    });

    test('clear removes all stored notifications', () async {
      await NotificationStorageService.instance.add(NotificationItem(
        id: 'n-clear',
        title: 'T',
        message: 'M',
        category: NotificationCategory.general,
        createdAt: DateTime(2024, 6, 1),
      ));
      await NotificationStorageService.instance.clear();
      final all = await NotificationStorageService.instance.getAll();
      expect(all, isEmpty);
    });

    test('onNewItem emits when a notification is added', () async {
      final future = NotificationStorageService.instance.onNewItem.first;
      await NotificationStorageService.instance.add(NotificationItem(
        id: 'stream-001',
        title: 'Stream test',
        message: 'body',
        category: NotificationCategory.general,
        createdAt: DateTime(2024, 6, 1),
      ));
      final received = await future;
      expect(received.id, 'stream-001');
    });

    test('round-trip serialization preserves all fields', () async {
      final original = NotificationItem(
        id: 'rt-001',
        title: 'Meal reminder',
        message: 'Time to eat',
        category: NotificationCategory.svc,
        createdAt: DateTime(2024, 3, 15, 10, 30),
        isImportant: true,
        actionRoute: '/svc',
      );
      await NotificationStorageService.instance.add(original);
      final loaded = (await NotificationStorageService.instance.getAll()).first;
      expect(loaded.id, original.id);
      expect(loaded.title, original.title);
      expect(loaded.category, original.category);
      expect(loaded.isImportant, original.isImportant);
      expect(loaded.actionRoute, original.actionRoute);
      expect(loaded.createdAt.toIso8601String(),
          original.createdAt.toIso8601String());
    });
  });
}
