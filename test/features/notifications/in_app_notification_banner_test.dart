import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';
import 'package:jaswallet_app/features/notifications/presentation/widgets/in_app_notification_banner.dart';

// ── Test fixture ─────────────────────────────────────────────────────────────

NotificationItem _item({
  String id = 'test-01',
  String title = 'Test notification',
  String message = 'This is a test message.',
  NotificationCategory category = NotificationCategory.general,
  String? actionRoute = '/home',
}) {
  return NotificationItem(
    id: id,
    title: title,
    message: message,
    category: category,
    createdAt: DateTime.now(),
    actionRoute: actionRoute,
  );
}

Widget _wrap(
  Widget child, {
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  // ── Rendering ─────────────────────────────────────────────────────────────

  group('InAppNotificationBanner — rendering', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(title: 'New payment received'),
        onDismiss: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('New payment received'), findsOneWidget);
    });

    testWidgets('renders message body', (tester) async {
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(message: 'You received ₸5,000 from Arman.'),
        onDismiss: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('You received ₸5,000 from Arman.'), findsOneWidget);
    });

    testWidgets('renders close/dismiss icon', (tester) async {
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(),
        onDismiss: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.byType(AppIcon), findsWidgets);
    });

    testWidgets('category icon is shown', (tester) async {
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(category: NotificationCategory.svc),
        onDismiss: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.byType(AppIcon), findsWidgets);
    });

    testWidgets('renders correctly in dark mode without overflow', (tester) async {
      await tester.pumpWidget(_wrap(
        InAppNotificationBanner(
          item: _item(),
          onDismiss: () {},
        ),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(InAppNotificationBanner), findsOneWidget);
    });

    testWidgets('renders correctly in light mode without overflow', (tester) async {
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(),
        onDismiss: () {},
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(InAppNotificationBanner), findsOneWidget);
    });

    testWidgets('does not overflow with a long title', (tester) async {
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(title: 'A very long notification title that would normally overflow '
            'the banner and cause layout issues in production'),
        onDismiss: () {},
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow with a long message body', (tester) async {
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(message: 'A very long notification message body that contains lots of '
            'detailed information about what happened with the user account'),
        onDismiss: () {},
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ── Dismiss behaviour ─────────────────────────────────────────────────────

  group('InAppNotificationBanner — dismiss', () {
    testWidgets('tapping close icon fires onDismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(),
        onDismiss: () => dismissed = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('notification_dismiss_btn')));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('tapping the banner body fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(),
        onDismiss: () {},
        onTap: () => tapped = true,
      )));
      await tester.pumpAndSettle();

      // Tap the banner container (title text is a stable hit target)
      await tester.tap(find.text('Test notification'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('tapping banner also fires onDismiss (auto-dismiss on tap)', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(),
        onDismiss: () => dismissed = true,
        onTap: () {},
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test notification'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('banner renders without onTap (optional parameter)', (tester) async {
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(),
        onDismiss: () {},
        // onTap omitted
      )));
      await tester.pumpAndSettle();

      // Tapping with no onTap should not throw
      await tester.tap(find.text('Test notification'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ── Category icon colours ─────────────────────────────────────────────────

  group('InAppNotificationBanner — category icon colors', () {
    for (final category in NotificationCategory.values) {
      testWidgets('${category.name} renders its category icon', (tester) async {
        await tester.pumpWidget(_wrap(InAppNotificationBanner(
          item: _item(category: category),
          onDismiss: () {},
        )));
        await tester.pumpAndSettle();

        expect(find.byType(AppIcon), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // ── Animation ─────────────────────────────────────────────────────────────

  group('InAppNotificationBanner — animation', () {
    testWidgets('slide-in animation completes without errors', (tester) async {
      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        item: _item(),
        onDismiss: () {},
      )));

      // Pump through animation frames
      await tester.pump(const Duration(milliseconds: 160)); // half-way
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 160)); // complete
      expect(tester.takeException(), isNull);
    });

    testWidgets('ValueKey changes cause banner to rebuild with new item', (tester) async {
      final item1 = _item(id: 'n1', title: 'Notification 1');
      final item2 = _item(id: 'n2', title: 'Notification 2');

      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        key: ValueKey(item1.id),
        item: item1,
        onDismiss: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Notification 1'), findsOneWidget);

      await tester.pumpWidget(_wrap(InAppNotificationBanner(
        key: ValueKey(item2.id),
        item: item2,
        onDismiss: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Notification 2'), findsOneWidget);
    });
  });
}
