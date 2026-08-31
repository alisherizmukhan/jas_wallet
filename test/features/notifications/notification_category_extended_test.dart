import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';

void main() {
  // ── NotificationItem entity ──────────────────────────────────────────────────

  group('NotificationItem', () {
    final base = NotificationItem(
      id: 'base-01',
      title: 'Title',
      message: 'Message',
      category: NotificationCategory.general,
      createdAt: DateTime(2024, 1, 1),
    );

    test('default isRead is false', () {
      expect(base.isRead, isFalse);
    });

    test('default isImportant is false', () {
      expect(base.isImportant, isFalse);
    });

    test('default actionRoute is null', () {
      expect(base.actionRoute, isNull);
    });

    test('default imageUrl is null', () {
      expect(base.imageUrl, isNull);
    });

    test('copyWith preserves all unspecified fields', () {
      final copy = base.copyWith(isRead: true);
      expect(copy.id, base.id);
      expect(copy.title, base.title);
      expect(copy.message, base.message);
      expect(copy.category, base.category);
      expect(copy.createdAt, base.createdAt);
      expect(copy.isRead, isTrue);
      expect(copy.isImportant, base.isImportant);
    });

    test('copyWith(id:) replaces id only', () {
      final copy = base.copyWith(id: 'new-id');
      expect(copy.id, 'new-id');
      expect(copy.title, base.title);
    });

    test('copyWith(actionRoute:) sets action route', () {
      final copy = base.copyWith(actionRoute: '/gym');
      expect(copy.actionRoute, '/gym');
    });

    test('copyWith(imageUrl:) sets image url', () {
      final copy = base.copyWith(imageUrl: 'https://img.example.com/x.png');
      expect(copy.imageUrl, 'https://img.example.com/x.png');
    });

    test('copyWith produces a distinct object from original', () {
      final copy = base.copyWith(isRead: true);
      expect(identical(base, copy), isFalse);
    });
  });

  // ── NotificationCategoryX.displayName ───────────────────────────────────────

  group('NotificationCategoryX.displayName', () {
    test('all categories have non-empty displayName', () {
      for (final cat in NotificationCategory.values) {
        expect(cat.displayName, isNotEmpty,
            reason: '${cat.name} has empty displayName');
      }
    });

    test('displayName values are unique across categories', () {
      final names = NotificationCategory.values.map((c) => c.displayName).toList();
      expect(names.toSet().length, names.length, reason: 'duplicate displayName found');
    });

    test('specific displayName mappings are correct', () {
      expect(NotificationCategory.general.displayName, 'General');
      expect(NotificationCategory.svc.displayName, 'Meal Pass');
      expect(NotificationCategory.news.displayName, 'News & Promotions');
      expect(NotificationCategory.access.displayName, 'Campus Access');
      expect(NotificationCategory.events.displayName, 'Events');
    });
  });

  // ── NotificationCategoryX.subtitle ──────────────────────────────────────────

  group('NotificationCategoryX.subtitle', () {
    test('all categories have non-empty subtitle', () {
      for (final cat in NotificationCategory.values) {
        expect(cat.subtitle, isNotEmpty,
            reason: '${cat.name} has empty subtitle');
      }
    });
  });

  // ── NotificationCategoryX.icon ───────────────────────────────────────────────

  group('NotificationCategoryX.icon', () {
    test('all categories have an icon', () {
      for (final cat in NotificationCategory.values) {
        expect(cat.icon, isA<AppIconData>(),
            reason: '${cat.name} has no icon');
      }
    });

    test('specific icon mappings are correct', () {
      expect(NotificationCategory.svc.icon, AppIcons.utensils);
      expect(NotificationCategory.news.icon, AppIcons.megaphone);
      expect(NotificationCategory.access.icon, AppIcons.doorOpen);
      expect(NotificationCategory.general.icon, AppIcons.notification);
      expect(NotificationCategory.events.icon, AppIcons.calendar);
    });
  });

  // ── NotificationCategoryX.actionButtonIcon ───────────────────────────────────

  group('NotificationCategoryX.actionButtonIcon', () {
    test('all categories have an actionButtonIcon', () {
      for (final cat in NotificationCategory.values) {
        expect(cat.actionButtonIcon, isA<AppIconData>(),
            reason: '${cat.name} has no actionButtonIcon');
      }
    });

    test('svc action icon is QR code', () {
      expect(NotificationCategory.svc.actionButtonIcon, AppIcons.qrCode);
    });

    test('access action icon is door sliding', () {
      expect(NotificationCategory.access.actionButtonIcon, AppIcons.doorOpen);
    });

    test('news action icon is document', () {
      expect(NotificationCategory.news.actionButtonIcon, AppIcons.document);
    });

    test('general action icon is open_in_new', () {
      expect(NotificationCategory.general.actionButtonIcon, AppIcons.openInNew);
    });
  });

  // ── NotificationCategoryX.color ─────────────────────────────────────────────

  group('NotificationCategoryX.color', () {
    test('all categories have a non-transparent color', () {
      for (final cat in NotificationCategory.values) {
        final color = cat.color;
        expect(color.a, isNot(0),
            reason: '${cat.name} has fully transparent color');
      }
    });

    test('color values are valid Color objects', () {
      for (final cat in NotificationCategory.values) {
        expect(cat.color, isA<Color>());
      }
    });
  });

  // ── NotificationPreference ───────────────────────────────────────────────────

  group('NotificationPreference', () {
    test('copyWith(enabled: false) flips enabled', () {
      const pref = NotificationPreference(
        category: NotificationCategory.svc,
        enabled: true,
      );

      final updated = pref.copyWith(enabled: false);
      expect(updated.enabled, isFalse);
      expect(updated.category, NotificationCategory.svc);
    });

    test('copyWith without args preserves all fields', () {
      const pref = NotificationPreference(
        category: NotificationCategory.access,
        enabled: true,
      );

      final copy = pref.copyWith();
      expect(copy.category, pref.category);
      expect(copy.enabled, pref.enabled);
    });
  });

  // ── NotificationCategory enum contract ──────────────────────────────────────

  group('NotificationCategory enum', () {
    test('has exactly 6 values', () {
      expect(NotificationCategory.values.length, 6);
    });

    test('includes all expected categories', () {
      const expected = {
        NotificationCategory.general,
        NotificationCategory.svc,
        NotificationCategory.news,
        NotificationCategory.access,
        NotificationCategory.events,
        NotificationCategory.orientation,
      };
      expect(NotificationCategory.values.toSet(), expected);
    });
  });
}
