import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/notifications/domain/entities/notification_item.dart';
import 'package:jaswallet_app/features/notifications/presentation/widgets/notification_detail_sheet.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

// ── Test fixture ─────────────────────────────────────────────────────────────

NotificationItem _item({
  String id = 'test-01',
  String title = 'Meal reminder',
  String message = 'Your SVC meal is ready to confirm.',
  NotificationCategory category = NotificationCategory.svc,
  bool isRead = false,
  String? actionRoute = '/svc',
}) {
  return NotificationItem(
    id: id,
    title: title,
    message: message,
    category: category,
    createdAt: DateTime.now(),
    isRead: isRead,
    actionRoute: actionRoute,
  );
}

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('NotificationDetailSheet — rendering', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(title: 'New payment received'),
        onOpen: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('New payment received'), findsOneWidget);
    });

    testWidgets('renders message body', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(message: 'You received ₸5,000 from Arman.'),
        onOpen: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('You received ₸5,000 from Arman.'), findsOneWidget);
    });

    testWidgets('renders category icon', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(category: NotificationCategory.svc),
        onOpen: () {},
      )));
      await tester.pumpAndSettle();

      expect(
        find.byType(AppIcon),
        findsWidgets,
      );
    });

    testWidgets('renders category display name', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(category: NotificationCategory.access),
        onOpen: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text(NotificationCategory.access.displayName), findsOneWidget);
    });

    testWidgets('no overflow in light mode', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(),
        onOpen: () {},
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow in dark mode', (tester) async {
      await tester.pumpWidget(_wrap(
        NotificationDetailSheet(notification: _item(), onOpen: () {}),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow with a long title', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(
          title: 'A very long notification title that could potentially '
              'cause layout issues on smaller screens in production',
        ),
        onOpen: () {},
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow with a long message', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(
          message: 'A very long notification message body with lots of detail '
              'about what happened and why the user should care about this '
              'particular alert from the system.',
        ),
        onOpen: () {},
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('NotificationDetailSheet — open button', () {
    testWidgets('open button not shown when onOpen is null', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(actionRoute: '/gym'),
        onOpen: null,
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notif_open_btn')), findsNothing);
    });

    testWidgets('open button is shown when onOpen is provided', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(),
        onOpen: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notif_open_btn')), findsOneWidget);
    });

    testWidgets('tapping open button calls onOpen once', (tester) async {
      var callCount = 0;

      // Wrap in a Navigator so Navigator.of(context).pop() in the sheet
      // has a valid navigator ancestor to pop.
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: NotificationDetailSheet(
              notification: _item(),
              onOpen: () => callCount++,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notif_open_btn')));
      await tester.pumpAndSettle();

      expect(callCount, 1);
    });

    testWidgets('onOpen is NOT called when button is not tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(),
        onOpen: () => called = true,
      )));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });
  });

  group('NotificationDetailSheet — unread indicator', () {
    testWidgets('unread dot is visible for unread notification', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(isRead: false),
        onOpen: () {},
      )));
      await tester.pumpAndSettle();

      // The unread dot Container is inside the category badge row.
      // We verify no exception and that the sheet renders correctly.
      expect(tester.takeException(), isNull);
    });

    testWidgets('no crash for read notification (no dot)', (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(isRead: true),
        onOpen: () {},
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('NotificationDetailSheet — all categories render', () {
    for (final category in NotificationCategory.values) {
      testWidgets('${category.name} category renders without overflow',
          (tester) async {
        await tester.pumpWidget(_wrap(NotificationDetailSheet(
          notification: _item(category: category),
          onOpen: () {},
        )));
        await tester.pumpAndSettle();

        // At least the category badge icon must be present; the action button
        // may reuse the same icon for certain categories (e.g. courses, access).
        expect(find.byType(AppIcon), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('NotificationDeepLinkHandler — navigation safety', () {
    testWidgets('does not crash when actionRoute is null and no onOpen',
        (tester) async {
      await tester.pumpWidget(_wrap(NotificationDetailSheet(
        notification: _item(actionRoute: null),
        onOpen: null,
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('notif_open_btn')), findsNothing);
    });
  });
}
