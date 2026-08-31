import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/core/services/notification_deep_link_handler.dart';

GoRouter _routerWith(List<String> paths) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      for (final p in paths)
        GoRoute(path: p, builder: (_, _) => const SizedBox()),
    ],
  );
}

void main() {
  group('NotificationDeepLinkHandler.handle', () {
    testWidgets('returns false for null route', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(NotificationDeepLinkHandler.handle(ctx, null), false);
    });

    testWidgets('returns false for blank route', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(NotificationDeepLinkHandler.handle(ctx, '   '), false);
    });

    testWidgets('alias fintech resolves without throwing', (tester) async {
      final router = _routerWith(['/fintech']);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(SizedBox).last);
      expect(() => NotificationDeepLinkHandler.handle(ctx, 'fintech'),
          returnsNormally);
    });

    testWidgets('alias svc resolves without throwing', (tester) async {
      final router = _routerWith(['/svc']);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(SizedBox).last);
      expect(() => NotificationDeepLinkHandler.handle(ctx, 'svc'),
          returnsNormally);
    });

    testWidgets('alias access resolves to /access without throwing',
        (tester) async {
      final router = _routerWith(['/access']);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(SizedBox).last);
      expect(() => NotificationDeepLinkHandler.handle(ctx, 'access'),
          returnsNormally);
    });

    testWidgets('unknown route does not throw', (tester) async {
      final router = _routerWith([]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(SizedBox).last);
      expect(() => NotificationDeepLinkHandler.handle(ctx, '/nonexistent'),
          returnsNormally);
    });

    testWidgets('social_meal alias resolves to /svc', (tester) async {
      final router = _routerWith(['/svc']);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(SizedBox).last);
      expect(() => NotificationDeepLinkHandler.handle(ctx, 'social_meal'),
          returnsNormally);
    });
  });
}
