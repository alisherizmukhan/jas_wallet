import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_provider.dart';
import '../pages/pin_verify_page.dart';

// ── Premium easing curves ─────────────────────────────────────────────────────

/// Quintic ease-out — much snappier start, gentle landing. Approximates spring.
class _EaseOutQuintCurve extends Curve {
  const _EaseOutQuintCurve();

  @override
  double transformInternal(double t) {
    final u = t - 1.0;
    return u * u * u * u * u + 1.0;
  }
}

extension _CurvesExt on Curves {
  static const Curve easeOutQuint = _EaseOutQuintCurve();
}

// ── Two-phase slide tween ─────────────────────────────────────────────────────
//
// Phase 1 (0→0.18): Panel nudges DOWN slightly (Offset.dy: 0 → 0.018)
//   — the "dots compressing" / coiling feel before the exit spring.
// Phase 2 (0.18→1.0): Panel slides fully OFF screen (Offset.dy: 0.018 → 1.0)
//   with an easeOutQuint curve so the acceleration is sharp at the start.

class _CompressThenSlideTween extends Tween<Offset> {
  _CompressThenSlideTween()
      : super(begin: Offset.zero, end: const Offset(0, 1.0));

  static const _splitPoint = 0.18;
  static const _nudge = 0.018; // fractional downward nudge in phase 1

  static const _compressCurve = Curves.easeOut;
  static const _slideCurve = _EaseOutQuintCurve();

  @override
  Offset lerp(double t) {
    if (t <= _splitPoint) {
      // Phase 1: nudge down
      final progress = t / _splitPoint;
      final curved = _compressCurve.transform(progress);
      return Offset(0, _nudge * curved);
    } else {
      // Phase 2: spring-slide off screen
      final progress = (t - _splitPoint) / (1.0 - _splitPoint);
      final curved = _slideCurve.transformInternal(progress);
      return Offset(0, _nudge + (1.0 - _nudge) * curved);
    }
  }
}

/// Full-screen overlay that implements the layered unlock animation.
///
/// ── Startup rendering contract ─────────────────────────────────────────────
///
/// While auth is still resolving (appStarting / unknown), renders a blank
/// scaffold-colored placeholder so no intermediate route flashes through.
///
/// Once auth is known the placeholder is replaced atomically:
///   • needsLocalAuth → home shell (behind) + PIN panel (front)
///   • anything else  → router content directly (no overlay)
///
/// ── Layer architecture ─────────────────────────────────────────────────────
///
/// Stack
/// ├── child  (GoRouter shell — home/hub/etc., always mounted while locked)
/// └── PIN panel (slides downward off-screen on successful unlock)
///
/// Place inside [MaterialApp.builder] so it sits above all GoRouter pages but
/// inside MaterialApp (access to theme, locale, Navigator).
class PinUnlockOverlay extends ConsumerStatefulWidget {
  const PinUnlockOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PinUnlockOverlay> createState() => _PinUnlockOverlayState();
}

class _PinUnlockOverlayState extends ConsumerState<PinUnlockOverlay>
    with TickerProviderStateMixin {
  /// True while auth status is appStarting / unknown.
  bool _authLoading = true;

  /// Whether the PIN panel is currently in the widget tree.
  bool _showPanel = false;

  /// Whether the exit animation is in progress.
  bool _isExiting = false;

  /// True while we are waiting for the router to navigate to welcome after
  /// logout. The PIN panel is replaced with a blank screen so home never
  /// flashes through during the transition.
  bool _dismissingForLogout = false;

  // ── PIN panel: slides down off-screen ─────────────────────────────────────
  late final AnimationController _pinCtrl;
  late final Animation<Offset> _pinSlide;
  late final Animation<double> _pinFade;

  // ── Background shell: returns to full scale + opacity ─────────────────────
  late final AnimationController _bgCtrl;
  late final Animation<double> _bgScale;
  late final Animation<double> _bgOpacity;

  @override
  void initState() {
    super.initState();

    final initialAuth = ref.read(authProvider);

    // Auth always starts as appStarting; this guards against edge cases where
    // a provider is initialised with a cached resolved state.
    _authLoading = initialAuth.status == AuthStatus.appStarting ||
        initialAuth.status == AuthStatus.unknown;

    if (initialAuth.status == AuthStatus.needsLocalAuth) {
      _showPanel = true;
      _authLoading = false; // needsLocalAuth is a resolved state
    }

    // PIN panel: two-phase exit.
    //  Phase 1 (0–18%): panel compresses slightly downward — "gathering momentum"
    //  Phase 2 (18–100%): spring-slides off screen with easeOutQuint feel
    _pinCtrl = AnimationController(
      duration: const Duration(milliseconds: 760),
      vsync: this,
    );

    // Y translate: slight downward compress in phase 1, then slide away.
    // We achieve this by animating from -0.012 → 0 → 1.0 using a custom curve.
    // Simplest implementation: two separate Tween chained via Interval.
    _pinSlide = _CompressThenSlideTween().animate(
      CurvedAnimation(parent: _pinCtrl, curve: Curves.linear),
    );

    // Fade out at the tail end of the slide (panel is off screen by 72%).
    _pinFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _pinCtrl,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
      ),
    );

    // Background returns from depth-receded state — more dramatic than before.
    _bgCtrl = AnimationController(
      duration: const Duration(milliseconds: 620),
      vsync: this,
    );
    _bgScale = Tween<double>(begin: 0.968, end: 1.0).animate(
      CurvedAnimation(parent: _bgCtrl, curve: _CurvesExt.easeOutQuint),
    );
    _bgOpacity = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut),
    );

    // When the slide finishes, tear down the overlay.
    _pinCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showPanel = false;
          _isExiting = false;
        });
        _pinCtrl.reset();
        _bgCtrl.reset();
      }
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  // ── State transitions ──────────────────────────────────────────────────────

  /// Snap the PIN panel into place immediately (re-lock on background resume).
  void _lockImmediately() {
    if (_showPanel && !_isExiting) return;
    _pinCtrl.stop();
    _bgCtrl.stop();
    _pinCtrl.reset();
    _bgCtrl.reset();
    if (mounted) {
      setState(() {
        _showPanel = true;
        _isExiting = false;
      });
    }
  }

  /// Start the slide-away animation after successful PIN/biometric.
  void _startUnlockAnimation() {
    if (_isExiting || !_showPanel) return;
    setState(() => _isExiting = true);
    _pinCtrl.forward();
    _bgCtrl.forward();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      // Track when auth leaves the loading phase.
      if (_authLoading) {
        final nowResolved = next.status != AuthStatus.appStarting &&
            next.status != AuthStatus.unknown;
        if (nowResolved) {
          setState(() => _authLoading = false);
        }
      }

      if (next.status == AuthStatus.needsLocalAuth) {
        _lockImmediately();
      } else if (prev?.status == AuthStatus.needsLocalAuth &&
          next.status == AuthStatus.authenticated) {
        _startUnlockAnimation();
      } else if (prev?.status == AuthStatus.needsLocalAuth &&
          next.status != AuthStatus.authenticated &&
          next.status != AuthStatus.needsLocalAuth) {
        // Logout / force-reauth from the PIN screen.
        // Replace PIN content with a blank screen this frame so home never
        // flashes, then dismiss the overlay after the router has rendered
        // the welcome page behind it.
        _pinCtrl.stop();
        _bgCtrl.stop();
        _pinCtrl.reset();
        _bgCtrl.reset();
        if (mounted) setState(() => _dismissingForLogout = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _showPanel = false;
              _isExiting = false;
              _dismissingForLogout = false;
            });
          }
        });
      }
    });

    // ── Phase 1: Auth still resolving ─────────────────────────────────────
    // Blank placeholder — router is not rendered until auth is known.
    if (_authLoading) {
      return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
    }

    // ── Phase 2: No lock needed ────────────────────────────────────────────
    // Pass-through; overlay is not in the picture.
    if (!_showPanel) return widget.child;

    // ── Phase 3: Locked or unlocking ──────────────────────────────────────
    return Stack(
      children: [
        // Layer 1: App shell — visible behind the PIN panel.
        // Slightly scaled and dimmed while locked; reveals as the panel exits.
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (context, child) => Transform.scale(
            scale: _bgScale.value,
            child: Opacity(opacity: _bgOpacity.value, child: child),
          ),
          child: IgnorePointer(child: widget.child),
        ),

        // Layer 2: PIN panel — slides down off-screen on unlock.
        // During logout transition, replaced with a blank screen so the home
        // page behind never flashes before the router renders welcome.
        RepaintBoundary(
          child: SlideTransition(
            position: _pinSlide,
            child: FadeTransition(
              opacity: _pinFade,
              child: _dismissingForLogout
                  ? ColoredBox(color: Theme.of(context).scaffoldBackgroundColor)
                  : const PinVerifyPage(),
            ),
          ),
        ),
      ],
    );
  }
}
