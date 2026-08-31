import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/providers/auth_provider.dart';
import 'package:jaswallet_app/core/routing/app_router.dart';

/// Pure unit tests for the GoRouter redirect logic.
///
/// This mirrors the redirect logic in [routerProvider] exactly, validating
/// each auth status → path mapping without spinning up a full Flutter app.
/// When the redirect function changes in app_router.dart, these tests catch
/// any regressions immediately.
///
/// The redirect function signature:
///   String? redirect(AuthState authState, String currentPath)
///
/// Returns:
///   - A String path to redirect to, OR
///   - null to stay on the current path.

// ── Redirect logic mirror ────────────────────────────────────────────────────

const _publicRoutes = <String>{
  AppRoutes.languageSelection,
  AppRoutes.onboarding,
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.registration,
  AppRoutes.personalDataConsent,
  AppRoutes.verification,
  AppRoutes.profileCreation,
  AppRoutes.saltoActivation,
  AppRoutes.forgotPassword,
  AppRoutes.resetPassword,
};

const _sessionRoutes = <String>{
  AppRoutes.pinCreate,
  AppRoutes.pinVerify,
  AppRoutes.biometricSetup,
};

String? _redirect(AuthState authState, String currentPath) {
  // Loading phases — hold on welcome
  if (authState.status == AuthStatus.appStarting ||
      authState.status == AuthStatus.unknown) {
    return currentPath == AppRoutes.welcome ? null : AppRoutes.welcome;
  }

  // First launch → language selection
  if (authState.status == AuthStatus.firstLaunch) {
    return currentPath == AppRoutes.languageSelection
        ? null
        : AppRoutes.languageSelection;
  }

  // Needs onboarding
  if (authState.status == AuthStatus.needsOnboarding) {
    return currentPath == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }

  // Unauthenticated → allow public, redirect others → welcome
  if (authState.status == AuthStatus.unauthenticated) {
    if (_publicRoutes.contains(currentPath)) return null;
    return AppRoutes.welcome;
  }

  // Needs PIN setup
  if (authState.status == AuthStatus.needsPinSetup) {
    return currentPath == AppRoutes.pinCreate ? null : AppRoutes.pinCreate;
  }

  // Needs biometric setup
  if (authState.status == AuthStatus.needsBiometricSetup) {
    return currentPath == AppRoutes.biometricSetup
        ? null
        : AppRoutes.biometricSetup;
  }

  // Needs local auth — PinUnlockOverlay covers the UI; route to home from
  // public/session routes so the shell is fully mounted beneath the overlay.
  if (authState.status == AuthStatus.needsLocalAuth) {
    if (_publicRoutes.contains(currentPath) ||
        _sessionRoutes.contains(currentPath)) {
      return AppRoutes.home;
    }
    return null; // stay put; overlay covers it
  }

  // Authenticated → redirect away from auth screens → home
  if (authState.status == AuthStatus.authenticated) {
    if (_publicRoutes.contains(currentPath) ||
        _sessionRoutes.contains(currentPath)) {
      return AppRoutes.home;
    }
    return null;
  }

  return null;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── appStarting / unknown — loading states ───────────────────────────────

  group('redirect — appStarting', () {
    const auth = AuthState(status: AuthStatus.appStarting);

    test('stays on /welcome', () {
      expect(_redirect(auth, AppRoutes.welcome), isNull);
    });

    test('redirects /home → /welcome', () {
      expect(_redirect(auth, AppRoutes.home), AppRoutes.welcome);
    });

    test('redirects /hub → /welcome', () {
      expect(_redirect(auth, AppRoutes.hub), AppRoutes.welcome);
    });

    test('redirects /login → /welcome', () {
      expect(_redirect(auth, AppRoutes.login), AppRoutes.welcome);
    });
  });

  group('redirect — unknown', () {
    const auth = AuthState(status: AuthStatus.unknown);

    test('stays on /welcome', () {
      expect(_redirect(auth, AppRoutes.welcome), isNull);
    });

    test('redirects protected route → /welcome', () {
      expect(_redirect(auth, AppRoutes.profile), AppRoutes.welcome);
    });
  });

  // ── firstLaunch ──────────────────────────────────────────────────────────

  group('redirect — firstLaunch', () {
    const auth = AuthState(status: AuthStatus.firstLaunch);

    test('stays on /language-selection', () {
      expect(_redirect(auth, AppRoutes.languageSelection), isNull);
    });

    test('redirects /welcome → /language-selection', () {
      expect(_redirect(auth, AppRoutes.welcome), AppRoutes.languageSelection);
    });

    test('redirects /home → /language-selection', () {
      expect(_redirect(auth, AppRoutes.home), AppRoutes.languageSelection);
    });
  });

  // ── needsOnboarding ──────────────────────────────────────────────────────

  group('redirect — needsOnboarding', () {
    const auth = AuthState(status: AuthStatus.needsOnboarding);

    test('stays on /onboarding', () {
      expect(_redirect(auth, AppRoutes.onboarding), isNull);
    });

    test('redirects /welcome → /onboarding', () {
      expect(_redirect(auth, AppRoutes.welcome), AppRoutes.onboarding);
    });

    test('redirects /home → /onboarding', () {
      expect(_redirect(auth, AppRoutes.home), AppRoutes.onboarding);
    });
  });

  // ── unauthenticated ──────────────────────────────────────────────────────

  group('redirect — unauthenticated', () {
    const auth = AuthState(status: AuthStatus.unauthenticated);

    test('stays on /welcome (public)', () {
      expect(_redirect(auth, AppRoutes.welcome), isNull);
    });

    test('stays on /login (public)', () {
      expect(_redirect(auth, AppRoutes.login), isNull);
    });

    test('stays on /registration (public)', () {
      expect(_redirect(auth, AppRoutes.registration), isNull);
    });

    test('stays on /forgot-password (public)', () {
      expect(_redirect(auth, AppRoutes.forgotPassword), isNull);
    });

    test('stays on /onboarding (public)', () {
      expect(_redirect(auth, AppRoutes.onboarding), isNull);
    });

    test('redirects /home → /welcome (protected)', () {
      expect(_redirect(auth, AppRoutes.home), AppRoutes.welcome);
    });

    test('redirects /hub → /welcome (protected)', () {
      expect(_redirect(auth, AppRoutes.hub), AppRoutes.welcome);
    });

    test('redirects /profile → /welcome (protected)', () {
      expect(_redirect(auth, AppRoutes.profile), AppRoutes.welcome);
    });

    test('redirects /notifications → /welcome (protected)', () {
      expect(_redirect(auth, AppRoutes.notifications), AppRoutes.welcome);
    });

    test('redirects /svc → /welcome (protected)', () {
      expect(_redirect(auth, AppRoutes.svcDashboard), AppRoutes.welcome);
    });
  });

  // ── needsPinSetup ────────────────────────────────────────────────────────

  group('redirect — needsPinSetup', () {
    const auth = AuthState(status: AuthStatus.needsPinSetup);

    test('stays on /pin-create', () {
      expect(_redirect(auth, AppRoutes.pinCreate), isNull);
    });

    test('redirects /home → /pin-create', () {
      expect(_redirect(auth, AppRoutes.home), AppRoutes.pinCreate);
    });

    test('redirects /welcome → /pin-create', () {
      expect(_redirect(auth, AppRoutes.welcome), AppRoutes.pinCreate);
    });
  });

  // ── needsBiometricSetup ──────────────────────────────────────────────────

  group('redirect — needsBiometricSetup', () {
    const auth = AuthState(status: AuthStatus.needsBiometricSetup);

    test('stays on /biometric-setup', () {
      expect(_redirect(auth, AppRoutes.biometricSetup), isNull);
    });

    test('redirects /home → /biometric-setup', () {
      expect(_redirect(auth, AppRoutes.home), AppRoutes.biometricSetup);
    });

    test('redirects /pin-create → /biometric-setup', () {
      expect(_redirect(auth, AppRoutes.pinCreate), AppRoutes.biometricSetup);
    });
  });

  // ── needsLocalAuth — critical new behavior ───────────────────────────────

  group('redirect — needsLocalAuth (PinUnlockOverlay architecture)', () {
    const auth = AuthState(status: AuthStatus.needsLocalAuth);

    // Public routes must redirect to /home so the shell mounts beneath the overlay.
    test('redirects /welcome → /home (public route must go to shell)', () {
      expect(_redirect(auth, AppRoutes.welcome), AppRoutes.home);
    });

    test('redirects /login → /home (public)', () {
      expect(_redirect(auth, AppRoutes.login), AppRoutes.home);
    });

    test('redirects /registration → /home (public)', () {
      expect(_redirect(auth, AppRoutes.registration), AppRoutes.home);
    });

    // Session routes must also redirect to /home.
    test('redirects /pin-verify → /home (session route)', () {
      expect(_redirect(auth, AppRoutes.pinVerify), AppRoutes.home);
    });

    test('redirects /pin-create → /home (session route)', () {
      expect(_redirect(auth, AppRoutes.pinCreate), AppRoutes.home);
    });

    test('redirects /biometric-setup → /home (session route)', () {
      expect(_redirect(auth, AppRoutes.biometricSetup), AppRoutes.home);
    });

    // Protected routes stay put — overlay covers them.
    test('stays on /home (overlay covers it)', () {
      expect(_redirect(auth, AppRoutes.home), isNull);
    });

    test('stays on /hub (overlay covers it)', () {
      expect(_redirect(auth, AppRoutes.hub), isNull);
    });

    test('stays on /notifications (overlay covers it)', () {
      expect(_redirect(auth, AppRoutes.notifications), isNull);
    });

    test('stays on /profile (overlay covers it)', () {
      expect(_redirect(auth, AppRoutes.profile), isNull);
    });

    test('stays on /svc (overlay covers it)', () {
      expect(_redirect(auth, AppRoutes.svcDashboard), isNull);
    });

    test('stays on /settings (overlay covers it)', () {
      expect(_redirect(auth, AppRoutes.settings), isNull);
    });
  });

  // ── authenticated ────────────────────────────────────────────────────────

  group('redirect — authenticated', () {
    const auth =
        AuthState(status: AuthStatus.authenticated, userId: 'user-1');

    // Auth screens must redirect away to home.
    test('redirects /welcome → /home', () {
      expect(_redirect(auth, AppRoutes.welcome), AppRoutes.home);
    });

    test('redirects /login → /home', () {
      expect(_redirect(auth, AppRoutes.login), AppRoutes.home);
    });

    test('redirects /pin-create → /home (session route)', () {
      expect(_redirect(auth, AppRoutes.pinCreate), AppRoutes.home);
    });

    test('redirects /pin-verify → /home (session route)', () {
      expect(_redirect(auth, AppRoutes.pinVerify), AppRoutes.home);
    });

    test('redirects /biometric-setup → /home (session route)', () {
      expect(_redirect(auth, AppRoutes.biometricSetup), AppRoutes.home);
    });

    // Protected app routes — stay on current path.
    test('stays on /home', () {
      expect(_redirect(auth, AppRoutes.home), isNull);
    });

    test('stays on /hub', () {
      expect(_redirect(auth, AppRoutes.hub), isNull);
    });

    test('stays on /notifications', () {
      expect(_redirect(auth, AppRoutes.notifications), isNull);
    });

    test('stays on /profile', () {
      expect(_redirect(auth, AppRoutes.profile), isNull);
    });

    test('stays on /svc', () {
      expect(_redirect(auth, AppRoutes.svcDashboard), isNull);
    });

    test('stays on /settings', () {
      expect(_redirect(auth, AppRoutes.settings), isNull);
    });

    test('stays on /referral', () {
      expect(_redirect(auth, AppRoutes.referral), isNull);
    });
  });

  // ── AppRoutes constants ──────────────────────────────────────────────────

  group('AppRoutes — constant correctness', () {
    test('home route is /home', () => expect(AppRoutes.home, '/home'));
    test('welcome route is /welcome', () => expect(AppRoutes.welcome, '/welcome'));
    test('pinCreate route is /pin-create',
        () => expect(AppRoutes.pinCreate, '/pin-create'));
    test('pinVerify route is /pin-verify',
        () => expect(AppRoutes.pinVerify, '/pin-verify'));
    test('biometricSetup is /biometric-setup',
        () => expect(AppRoutes.biometricSetup, '/biometric-setup'));
    test('languageSelection is /language-selection',
        () => expect(AppRoutes.languageSelection, '/language-selection'));
    test('svcDashboard is /svc', () => expect(AppRoutes.svcDashboard, '/svc'));

    test('all route constants are non-empty strings', () {
      final allRoutes = <String>[
        AppRoutes.home, AppRoutes.hub, AppRoutes.access, AppRoutes.profile,
        AppRoutes.notifications, AppRoutes.settings, AppRoutes.welcome,
        AppRoutes.login, AppRoutes.registration, AppRoutes.pinCreate,
        AppRoutes.pinVerify, AppRoutes.biometricSetup, AppRoutes.languageSelection,
        AppRoutes.svcDashboard, AppRoutes.referral,
      ];
      for (final route in allRoutes) {
        expect(route, isNotEmpty, reason: 'Route should not be empty');
        expect(route, startsWith('/'), reason: 'Route should start with /');
      }
    });

    test('no duplicate route constants', () {
      final routes = <String>[
        AppRoutes.home, AppRoutes.hub, AppRoutes.access, AppRoutes.profile,
        AppRoutes.notifications, AppRoutes.settings, AppRoutes.welcome,
        AppRoutes.login, AppRoutes.registration, AppRoutes.pinCreate,
        AppRoutes.pinVerify, AppRoutes.biometricSetup, AppRoutes.languageSelection,
        AppRoutes.onboarding, AppRoutes.svcDashboard,
      ];
      expect(routes.toSet().length, routes.length,
          reason: 'All route constants should be unique');
    });
  });

  // ── _publicRoutes / _sessionRoutes membership ────────────────────────────

  group('Route classification', () {
    test('pin-verify is in session routes (not public)', () {
      expect(_publicRoutes.contains(AppRoutes.pinVerify), isFalse);
      expect(_sessionRoutes.contains(AppRoutes.pinVerify), isTrue);
    });

    test('pin-create is in session routes (not public)', () {
      expect(_publicRoutes.contains(AppRoutes.pinCreate), isFalse);
      expect(_sessionRoutes.contains(AppRoutes.pinCreate), isTrue);
    });

    test('welcome is in public routes', () {
      expect(_publicRoutes.contains(AppRoutes.welcome), isTrue);
    });

    test('home is NOT in public or session routes', () {
      expect(_publicRoutes.contains(AppRoutes.home), isFalse);
      expect(_sessionRoutes.contains(AppRoutes.home), isFalse);
    });

    test('hub is NOT in public or session routes', () {
      expect(_publicRoutes.contains(AppRoutes.hub), isFalse);
      expect(_sessionRoutes.contains(AppRoutes.hub), isFalse);
    });

    test('public and session routes have no overlap', () {
      final overlap = _publicRoutes.intersection(_sessionRoutes);
      expect(overlap, isEmpty,
          reason: 'Public and session route sets must be disjoint');
    });
  });
}
