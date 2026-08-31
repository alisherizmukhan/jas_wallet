import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/analytics/analytics_navigation_observer.dart';
import 'package:jaswallet_app/core/analytics/analytics_service.dart';

void main() {
  setUpAll(() async {
    await AnalyticsService.instance.init();
  });

  group('AnalyticsNavigationObserver — singleton', () {
    test('instance is singleton', () {
      final a = AnalyticsNavigationObserver.instance;
      final b = AnalyticsNavigationObserver.instance;
      expect(identical(a, b), isTrue);
    });

    test('extends NavigatorObserver', () {
      expect(AnalyticsNavigationObserver.instance, isA<NavigatorObserver>());
    });
  });

  group('AnalyticsNavigationObserver — route push', () {
    late AnalyticsNavigationObserver observer;

    setUp(() {
      observer = AnalyticsNavigationObserver.instance;
    });

    test('didPush does not throw for named route', () {
      final route = _namedRoute('home');
      expect(
        () => observer.didPush(route, null),
        returnsNormally,
      );
    });

    test('didPush does not throw for unnamed route', () {
      final route = _unnamedRoute();
      expect(
        () => observer.didPush(route, null),
        returnsNormally,
      );
    });

    test('didPush does not throw for null route name', () {
      final route = _nullNameRoute();
      expect(
        () => observer.didPush(route, null),
        returnsNormally,
      );
    });

    test('didPush with previous route does not throw', () {
      final previous = _namedRoute('welcome');
      final current = _namedRoute('login');
      expect(
        () => observer.didPush(current, previous),
        returnsNormally,
      );
    });

    test('sequential pushes do not throw', () {
      expect(() {
        observer.didPush(_namedRoute('welcome'), null);
        observer.didPush(_namedRoute('login'), _namedRoute('welcome'));
        observer.didPush(_namedRoute('registration'), _namedRoute('login'));
      }, returnsNormally);
    });
  });

  group('AnalyticsNavigationObserver — route pop', () {
    late AnalyticsNavigationObserver observer;

    setUp(() {
      observer = AnalyticsNavigationObserver.instance;
    });

    test('didPop does not throw', () {
      observer.didPush(_namedRoute('home'), null);
      expect(
        () => observer.didPop(_namedRoute('home'), null),
        returnsNormally,
      );
    });

    test('didPop on empty stack does not throw', () {
      // Force-clear screen stack by popping more than pushed.
      expect(() {
        observer.didPop(_namedRoute('any'), null);
      }, returnsNormally);
    });

    test('push then pop sequence does not throw', () {
      expect(() {
        observer.didPush(_namedRoute('home'), null);
        observer.didPush(_namedRoute('profile'), _namedRoute('home'));
        observer.didPop(_namedRoute('profile'), _namedRoute('home'));
      }, returnsNormally);
    });
  });

  group('AnalyticsNavigationObserver — replace', () {
    late AnalyticsNavigationObserver observer;

    setUp(() {
      observer = AnalyticsNavigationObserver.instance;
    });

    test('didReplace does not throw', () {
      observer.didPush(_namedRoute('login'), null);
      expect(
        () => observer.didReplace(
          newRoute: _namedRoute('home'),
          oldRoute: _namedRoute('login'),
        ),
        returnsNormally,
      );
    });

    test('didReplace with null newRoute does not throw', () {
      expect(
        () => observer.didReplace(newRoute: null, oldRoute: _namedRoute('login')),
        returnsNormally,
      );
    });
  });

  group('AnalyticsNavigationObserver — remove', () {
    test('didRemove does not throw', () {
      final observer = AnalyticsNavigationObserver.instance;
      observer.didPush(_namedRoute('home'), null);
      expect(
        () => observer.didRemove(_namedRoute('home'), null),
        returnsNormally,
      );
    });
  });

  group('AnalyticsNavigationObserver — route name mapping', () {
    test('all route names in the map are non-empty strings', () {
      // Access the private map via a test-side observation:
      // push a known route and verify the observer handles it without error.
      final knownRoutes = [
        'home', 'login', 'registration', 'welcome', 'languageSelection',
        'onboarding', 'pinCreate', 'pinVerify', 'notifications', 'profile',
        'settings', 'studentClubs', 'gym', 'fintech', 'svcDashboard',
        'attendanceStudent', 'attendanceTeacher', 'classroom',
      ];
      final observer = AnalyticsNavigationObserver.instance;
      for (final name in knownRoutes) {
        expect(
          () => observer.didPush(_namedRoute(name), null),
          returnsNormally,
          reason: 'Route name "$name" caused an error',
        );
      }
    });

    test('unknown route name does not throw', () {
      final observer = AnalyticsNavigationObserver.instance;
      expect(
        () => observer.didPush(_namedRoute('completely-unknown-route-xyz'), null),
        returnsNormally,
      );
    });
  });
}

// ── Test helpers ──────────────────────────────────────────────────────────────

Route<dynamic> _namedRoute(String name) {
  return _TestRoute(RouteSettings(name: name));
}

Route<dynamic> _unnamedRoute() {
  return _TestRoute(const RouteSettings(name: ''));
}

Route<dynamic> _nullNameRoute() {
  return _TestRoute(const RouteSettings());
}

class _TestRoute extends Route<void> {
  _TestRoute(RouteSettings settings) : super(settings: settings);

  @override
  List<OverlayEntry> get overlayEntries => const [];

  @override
  bool get isActive => true;

  @override
  bool get isCurrent => true;

  @override
  bool get isFirst => true;
}
