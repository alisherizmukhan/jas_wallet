import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/notification_storage_service.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

NotificationItem _item({
  required String id,
  NotificationCategory category = NotificationCategory.general,
  bool isRead = false,
  bool isImportant = false,
  String? actionRoute,
  String? imageUrl,
  String title = 'Test',
  String message = 'Body',
  DateTime? createdAt,
}) {
  return NotificationItem(
    id: id,
    title: title,
    message: message,
    category: category,
    createdAt: createdAt ?? DateTime(2024, 1, 1, 12, 0),
    isRead: isRead,
    isImportant: isImportant,
    actionRoute: actionRoute,
    imageUrl: imageUrl,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotificationStorageService.instance.clear();
  });

  // ── getAll ───────────────────────────────────────────────────────────────────

  group('NotificationStorageService.getAll()', () {
    test('returns empty list when nothing stored', () async {
      final items = await NotificationStorageService.instance.getAll();
      expect(items, isEmpty);
    });

    test('returns stored items after add()', () async {
      await NotificationStorageService.instance.add(_item(id: 'a'));
      await NotificationStorageService.instance.add(_item(id: 'b'));

      final items = await NotificationStorageService.instance.getAll();
      expect(items.length, 2);
    });

    test('most recently added item is first', () async {
      await NotificationStorageService.instance.add(_item(id: 'first'));
      await NotificationStorageService.instance.add(_item(id: 'second'));

      final items = await NotificationStorageService.instance.getAll();
      expect(items.first.id, 'second');
    });
  });

  // ── add / deduplication ──────────────────────────────────────────────────────

  group('NotificationStorageService.add() — deduplication', () {
    test('adding same id twice stores only once', () async {
      await NotificationStorageService.instance.add(_item(id: 'dup'));
      await NotificationStorageService.instance.add(_item(id: 'dup'));

      final items = await NotificationStorageService.instance.getAll();
      expect(items.length, 1);
    });

    test('dedup is by id — different ids both stored', () async {
      await NotificationStorageService.instance.add(_item(id: 'x'));
      await NotificationStorageService.instance.add(_item(id: 'y'));

      final items = await NotificationStorageService.instance.getAll();
      expect(items.length, 2);
    });

    test('duplicate does not fire onNewItem stream', () async {
      await NotificationStorageService.instance.add(_item(id: 'once'));

      var streamFired = false;
      final sub = NotificationStorageService.instance.onNewItem.listen((_) {
        streamFired = true;
      });
      addTearDown(sub.cancel);

      await NotificationStorageService.instance.add(_item(id: 'once'));

      expect(streamFired, isFalse);
    });

    test('new unique item fires onNewItem stream', () async {
      final received = <String>[];
      final sub = NotificationStorageService.instance.onNewItem.listen((item) {
        received.add(item.id);
      });
      addTearDown(sub.cancel);

      await NotificationStorageService.instance.add(_item(id: 'new-1'));
      await NotificationStorageService.instance.add(_item(id: 'new-2'));

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(received, ['new-1', 'new-2']);
    });
  });

  // ── 200-item cap ─────────────────────────────────────────────────────────────

  group('NotificationStorageService — 200-item cap', () {
    test('capped at 200: adding 201 items keeps only 200', () async {
      for (var i = 0; i < 201; i++) {
        await NotificationStorageService.instance.add(_item(id: 'cap-$i'));
      }

      final items = await NotificationStorageService.instance.getAll();
      expect(items.length, 200);
    });

    test('oldest item is dropped when cap exceeded', () async {
      // Add 200 items first
      for (var i = 0; i < 200; i++) {
        await NotificationStorageService.instance.add(_item(id: 'old-$i'));
      }
      // Add the 201st — should drop 'old-0' (the oldest = now at index 199)
      await NotificationStorageService.instance.add(_item(id: 'new-latest'));

      final items = await NotificationStorageService.instance.getAll();
      expect(items.length, 200);
      expect(items.first.id, 'new-latest');
      // old-0 was the first added → now last in list → gets cut
      expect(items.any((n) => n.id == 'old-0'), isFalse);
    });
  });

  // ── markRead / markAllRead ───────────────────────────────────────────────────

  group('NotificationStorageService.markRead()', () {
    test('marks targeted item as read', () async {
      await NotificationStorageService.instance.add(_item(id: 'r1'));
      await NotificationStorageService.instance.add(_item(id: 'r2'));

      await NotificationStorageService.instance.markRead('r1');

      final items = await NotificationStorageService.instance.getAll();
      expect(items.firstWhere((n) => n.id == 'r1').isRead, isTrue);
      expect(items.firstWhere((n) => n.id == 'r2').isRead, isFalse);
    });

    test('markRead on unknown id is a no-op (no crash)', () async {
      await NotificationStorageService.instance.add(_item(id: 'x'));
      await NotificationStorageService.instance.markRead('nonexistent');

      final items = await NotificationStorageService.instance.getAll();
      expect(items.first.isRead, isFalse);
    });
  });

  group('NotificationStorageService.markAllRead()', () {
    test('marks every stored item as read', () async {
      await NotificationStorageService.instance.add(_item(id: 'm1'));
      await NotificationStorageService.instance.add(_item(id: 'm2'));
      await NotificationStorageService.instance.add(_item(id: 'm3'));

      await NotificationStorageService.instance.markAllRead();

      final items = await NotificationStorageService.instance.getAll();
      for (final item in items) {
        expect(item.isRead, isTrue, reason: '${item.id} should be read');
      }
    });

    test('markAllRead on empty list is a no-op', () async {
      await NotificationStorageService.instance.markAllRead();
      final items = await NotificationStorageService.instance.getAll();
      expect(items, isEmpty);
    });
  });

  // ── clear ────────────────────────────────────────────────────────────────────

  group('NotificationStorageService.clear()', () {
    test('removes all stored items', () async {
      await NotificationStorageService.instance.add(_item(id: 'del-1'));
      await NotificationStorageService.instance.add(_item(id: 'del-2'));

      await NotificationStorageService.instance.clear();

      final items = await NotificationStorageService.instance.getAll();
      expect(items, isEmpty);
    });

    test('add() works normally after clear()', () async {
      await NotificationStorageService.instance.add(_item(id: 'before'));
      await NotificationStorageService.instance.clear();
      await NotificationStorageService.instance.add(_item(id: 'after'));

      final items = await NotificationStorageService.instance.getAll();
      expect(items.length, 1);
      expect(items.first.id, 'after');
    });
  });

  // ── Serialization roundtrip ──────────────────────────────────────────────────

  group('NotificationStorageService — serialization', () {
    test('all fields survive a persist/load roundtrip', () async {
      final ts = DateTime(2024, 6, 15, 9, 30);
      await NotificationStorageService.instance.add(
        NotificationItem(
          id: 'rt-1',
          title: 'Hello',
          message: 'World',
          category: NotificationCategory.svc,
          createdAt: ts,
          isRead: true,
          isImportant: true,
          actionRoute: '/svc',
          imageUrl: 'https://example.com/img.png',
        ),
      );

      final items = await NotificationStorageService.instance.getAll();
      final loaded = items.first;

      expect(loaded.id, 'rt-1');
      expect(loaded.title, 'Hello');
      expect(loaded.message, 'World');
      expect(loaded.category, NotificationCategory.svc);
      expect(loaded.createdAt.toIso8601String(), ts.toIso8601String());
      expect(loaded.isRead, isTrue);
      expect(loaded.isImportant, isTrue);
      expect(loaded.actionRoute, '/svc');
      expect(loaded.imageUrl, 'https://example.com/img.png');
    });

    test('null optional fields survive roundtrip as null', () async {
      await NotificationStorageService.instance.add(
        _item(id: 'rt-null', actionRoute: null, imageUrl: null),
      );

      final items = await NotificationStorageService.instance.getAll();
      expect(items.first.actionRoute, isNull);
      expect(items.first.imageUrl, isNull);
    });

    test('all 12 categories survive roundtrip', () async {
      for (final cat in NotificationCategory.values) {
        await NotificationStorageService.instance.add(
          _item(id: 'cat-${cat.name}', category: cat),
        );
      }

      final items = await NotificationStorageService.instance.getAll();
      final storedCategories = items.map((n) => n.category).toSet();
      expect(storedCategories, containsAll(NotificationCategory.values));
    });

    test('malformed JSON in storage falls back to empty list', () async {
      // Inject corrupted JSON directly into SharedPreferences
      SharedPreferences.setMockInitialValues({'notifications_v1': '{corrupt json'});

      final items = await NotificationStorageService.instance.getAll();
      expect(items, isEmpty);
    });

    test('unknown category in stored JSON falls back to general', () async {
      // Inject JSON with unknown category name
      SharedPreferences.setMockInitialValues({
        'notifications_v1':
            '[{"id":"u1","title":"T","message":"M","category":"future_category","createdAt":"2024-01-01T00:00:00.000","isRead":false,"isImportant":false}]',
      });

      final items = await NotificationStorageService.instance.getAll();
      expect(items.length, 1);
      expect(items.first.category, NotificationCategory.general);
    });

    test('missing optional JSON fields default correctly', () async {
      // Inject JSON missing optional fields
      SharedPreferences.setMockInitialValues({
        'notifications_v1':
            '[{"id":"min","title":"T","message":"M","category":"general","createdAt":"2024-01-01T00:00:00.000"}]',
      });

      final items = await NotificationStorageService.instance.getAll();
      expect(items.length, 1);
      expect(items.first.isRead, isFalse);
      expect(items.first.isImportant, isFalse);
      expect(items.first.actionRoute, isNull);
    });
  });
}
