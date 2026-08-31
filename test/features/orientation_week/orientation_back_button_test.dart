import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaswallet_app/features/orientation_week/data/repositories/orientation_repository_mock_impl.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/providers/orientation_repository_provider.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/widgets/orientation_app_bar.dart';

import '../../helpers/test_app.dart';
import '../../helpers/orientation_catalog_fixture.dart';

/// The app-bar back button on the five Orientation Week tabs.
///
/// [OrientationNavShell] wraps the whole shell in `PopScope(canPop: index == 0)`
/// so the *Android system* back button walks a non-Overview tab back to
/// Overview first. `maybePop` honours that same scope, which is what used to
/// swallow the header's back arrow on Challenges/Bingo/Photo Quest/Rewards and
/// turn it into a silent tab switch — the "back button does nothing" bug.
///
/// These tests stand in for the real shell with a bare `PopScope(canPop: false)`,
/// which is the condition that broke it.
void main() {
  // The JSON catalogue, read off disk — rootBundle would hang here.
  setUp(seedOrientationCatalog);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget shellPage() => const PopScope(
        canPop: false,
        child: Scaffold(
          appBar: OrientationAppBar(
            title: 'Photo Quest',
            isShellRoot: true,
            showTokens: false,
          ),
          body: Text('orientation'),
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    // Step past the mock repository's artificial latency (the app bar loads the
    // dashboard on entry) before settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  testWidgets('leaves Orientation Week even though an enclosing PopScope blocks pops',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('hub'))),
        GoRoute(path: '/orientation', builder: (_, _) => shellPage()),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        router: router,
        overrides: [
          orientationRepositoryProvider.overrideWithValue(OrientationRepositoryMockImpl()),
        ],
      ),
    );
    await settle(tester);

    router.push('/orientation');
    await settle(tester);
    expect(find.text('orientation'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await settle(tester);

    expect(find.text('hub'), findsOneWidget,
        reason: 'the header back arrow means "leave this feature", so the '
            'PopScope that exists for the system back button must not eat it');
    expect(find.text('orientation'), findsNothing);
  });

  testWidgets('falls back to Hub when there is nothing on the stack to pop',
      (tester) async {
    // Arriving by a route that replaced the stack — a notification tap or a
    // deep link — leaves no entry to pop. Without the fallback the student is
    // trapped in Orientation Week with a dead back button.
    final router = GoRouter(
      initialLocation: '/orientation',
      routes: [
        GoRoute(path: '/hub', builder: (_, _) => const Scaffold(body: Text('hub'))),
        GoRoute(path: '/orientation', builder: (_, _) => shellPage()),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        router: router,
        overrides: [
          orientationRepositoryProvider.overrideWithValue(OrientationRepositoryMockImpl()),
        ],
      ),
    );
    await settle(tester);
    expect(find.text('orientation'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await settle(tester);

    expect(find.text('hub'), findsOneWidget);
  });
}
