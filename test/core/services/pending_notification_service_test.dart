import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/pending_notification_service.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

NotificationItem _item({String id = 'test-01', String? actionRoute = '/svc'}) {
  return NotificationItem(
    id: id,
    title: 'Test Notification',
    message: 'Test body',
    category: NotificationCategory.svc,
    createdAt: DateTime.now(),
    actionRoute: actionRoute,
  );
}

PendingNotificationPayload _payload({
  String id = 'test-01',
  String? actionRoute = '/svc',
}) {
  return PendingNotificationPayload(
    item: _item(id: id, actionRoute: actionRoute),
    actionRoute: actionRoute,
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Reset singleton state between tests via consume().
  tearDown(() => PendingNotificationService.instance.consume());

  group('PendingNotificationService — store / consume', () {
    test('starts with no pending payload', () {
      expect(PendingNotificationService.instance.hasPending, isFalse);
      expect(PendingNotificationService.instance.consume(), isNull);
    });

    test('hasPending is true after store', () {
      PendingNotificationService.instance.store(_payload());
      expect(PendingNotificationService.instance.hasPending, isTrue);
    });

    test('consume returns stored payload', () {
      final payload = _payload();
      PendingNotificationService.instance.store(payload);
      final result = PendingNotificationService.instance.consume();
      expect(result, isNotNull);
      expect(result!.item.id, equals(payload.item.id));
    });

    test('consume clears the cache — second call returns null', () {
      PendingNotificationService.instance.store(_payload());
      PendingNotificationService.instance.consume();
      expect(PendingNotificationService.instance.consume(), isNull);
      expect(PendingNotificationService.instance.hasPending, isFalse);
    });

    test('second store overwrites the first', () {
      PendingNotificationService.instance.store(_payload(id: 'first'));
      PendingNotificationService.instance.store(_payload(id: 'second'));
      final result = PendingNotificationService.instance.consume();
      expect(result!.item.id, equals('second'));
    });

    test('consume after no store is safe (returns null, no throw)', () {
      expect(() => PendingNotificationService.instance.consume(), returnsNormally);
    });
  });

  group('PendingNotificationService — payload fields', () {
    test('payload carries item and actionRoute', () {
      final item = _item(actionRoute: '/notifications');
      final payload =
          PendingNotificationPayload(item: item, actionRoute: '/notifications');
      expect(payload.item, equals(item));
      expect(payload.actionRoute, equals('/notifications'));
    });

    test('payload actionRoute can be null', () {
      final payload = _payload(actionRoute: null);
      expect(payload.actionRoute, isNull);
    });

    test('payload item.id matches the source item', () {
      const id = 'unique-99';
      final payload = _payload(id: id);
      expect(payload.item.id, equals(id));
    });
  });

  group('PendingNotificationService — stream (onPending)', () {
    test('onPending emits when store is called', () async {
      final payload = _payload();
      final future = PendingNotificationService.instance.onPending.first;
      PendingNotificationService.instance.store(payload);
      final received = await future;
      expect(received.item.id, equals(payload.item.id));
    });

    test('onPending emits the correct actionRoute', () async {
      const route = '/gym';
      final future = PendingNotificationService.instance.onPending.first;
      PendingNotificationService.instance.store(_payload(actionRoute: route));
      final received = await future;
      expect(received.actionRoute, equals(route));
    });

    test('multiple listeners each receive the event', () async {
      final first = PendingNotificationService.instance.onPending.first;
      final second = PendingNotificationService.instance.onPending.first;
      PendingNotificationService.instance.store(_payload());
      final results = await Future.wait([first, second]);
      expect(results[0].item.id, equals(results[1].item.id));
    });

    test('listener added before store receives event', () async {
      final events = <PendingNotificationPayload>[];
      final sub =
          PendingNotificationService.instance.onPending.listen(events.add);
      PendingNotificationService.instance.store(_payload());
      await Future<void>.delayed(Duration.zero);
      sub.cancel();
      expect(events, hasLength(1));
    });

    test('listener added after store does NOT receive the past event (broadcast semantics)',
        () async {
      PendingNotificationService.instance.store(_payload());
      final events = <PendingNotificationPayload>[];
      final sub =
          PendingNotificationService.instance.onPending.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      sub.cancel();
      // Broadcast streams do not replay; no event for late subscriber.
      expect(events, isEmpty);
    });
  });

  group('PendingNotificationService — deduplication contract', () {
    test('stream listener consuming the payload prevents double-handling', () async {
      final events = <PendingNotificationPayload>[];
      final sub = PendingNotificationService.instance.onPending.listen((p) {
        // Simulate the stream listener calling consume() (as BottomNavShell does).
        PendingNotificationService.instance.consume();
        events.add(p);
      });

      PendingNotificationService.instance.store(_payload());
      await Future<void>.delayed(Duration.zero);
      sub.cancel();

      // The stream fired once.
      expect(events, hasLength(1));
      // After consume(), the cache is empty — postFrameCallback poll finds nothing.
      expect(PendingNotificationService.instance.hasPending, isFalse);
      expect(PendingNotificationService.instance.consume(), isNull);
    });
  });

  group('PendingNotificationService — singleton', () {
    test('instance is always the same object', () {
      expect(
        identical(
          PendingNotificationService.instance,
          PendingNotificationService.instance,
        ),
        isTrue,
      );
    });
  });
}
