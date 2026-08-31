import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

/// Minimal widget test wrapper that provides:
/// - ProviderScope with optional provider overrides
/// - MaterialApp.router with English localization
/// - A GoRouter without auth-redirect logic (for isolated page tests)
Widget buildTestApp({
  required GoRouter router,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    ),
  );
}

/// Minimal router that shows [child] at '/' with no redirect logic.
/// Additional named routes can be provided for navigation assertions.
GoRouter testRouter({
  required Widget child,
  Map<String, Widget> extraRoutes = const {},
  List<NavigatorObserver> observers = const [],
}) {
  return GoRouter(
    initialLocation: '/',
    observers: observers,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
      for (final entry in extraRoutes.entries)
        GoRoute(
          path: entry.key,
          builder: (context, state) => entry.value,
        ),
    ],
  );
}

/// Scaffold key used to find the ScaffoldMessenger in tests.
final testScaffoldKey = GlobalKey<ScaffoldState>();
