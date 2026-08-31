import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';

void main() {
  group('NotificationCategory', () {
    test('enum has 6 values', () {
      expect(NotificationCategory.values.length, 6);
    });

    test('access category has correct properties', () {
      const cat = NotificationCategory.access;
      expect(cat.displayName, 'Campus Access');
      expect(cat.subtitle, isNotEmpty);
      expect(cat.color.toARGB32(), isNot(0));
    });

    test('every category has a non-empty displayName', () {
      for (final cat in NotificationCategory.values) {
        expect(cat.displayName, isNotEmpty,
            reason: '$cat.displayName must not be empty');
      }
    });

    test('every category has a non-empty subtitle', () {
      for (final cat in NotificationCategory.values) {
        expect(cat.subtitle, isNotEmpty,
            reason: '$cat.subtitle must not be empty');
      }
    });

    test('all category colors have full opacity', () {
      for (final cat in NotificationCategory.values) {
        expect((cat.color.a * 255.0).round().clamp(0, 255), 0xFF,
            reason: '$cat color must be fully opaque');
      }
    });

    test('all category colors are unique', () {
      final values = NotificationCategory.values.map((c) => c.color.toARGB32()).toList();
      expect(values.toSet().length, values.length);
    });
  });

  group('NotificationItem', () {
    test('copyWith preserves unchanged fields', () {
      final original = NotificationItem(
        id: '1',
        title: 'Test',
        message: 'Body',
        category: NotificationCategory.svc,
        createdAt: DateTime(2024, 1, 1),
        isRead: false,
        actionRoute: '/svc',
      );

      final copy = original.copyWith(isRead: true);
      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.category, original.category);
      expect(copy.actionRoute, original.actionRoute);
      expect(copy.isRead, true);
    });

    test('copyWith for access category preserves category', () {
      final item = NotificationItem(
        id: '42',
        title: 'Door unlocked',
        message: 'Main entrance unlocked',
        category: NotificationCategory.access,
        createdAt: DateTime.now(),
      );
      expect(item.copyWith().category, NotificationCategory.access);
    });
  });

  group('NotificationPreference', () {
    test('copyWith changes enabled', () {
      const pref = NotificationPreference(
        category: NotificationCategory.svc,
        enabled: true,
      );
      expect(pref.copyWith(enabled: false).enabled, false);
      expect(pref.copyWith(enabled: false).category, NotificationCategory.svc);
    });
  });
}
