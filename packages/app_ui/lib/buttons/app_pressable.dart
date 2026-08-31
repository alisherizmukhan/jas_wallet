import 'package:flutter/widgets.dart';

/// Subtle premium press feedback — a small scale-down while a pointer is
/// down, springing back on release.
///
/// The app disables Material's default ripple/highlight everywhere
/// ([ThemeData.splashFactory] = [NoSplash.splashFactory]) to match the
/// Apple-visual-language design system, but nothing replaced it, which made
/// every tappable surface feel unresponsive. [AppPressable] is that
/// replacement: wrap any tappable widget in it for a Revolut/Monzo/Apple
/// Wallet-style tactile dip.
///
/// Uses [Listener] (raw pointer events) rather than a [GestureDetector], so
/// it purely *observes* press/release and never competes with the wrapped
/// widget's own tap handling (e.g. an [ElevatedButton]'s `onPressed`) for
/// the gesture arena — safe to wrap around any existing interactive widget
/// without changing its behavior.
///
/// Example:
/// ```dart
/// AppPressable(child: MyExistingButton(onPressed: ...))
/// ```
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 100),
  });

  /// The widget to apply press feedback to.
  final Widget child;

  /// When false, no scale animation is applied (e.g. a disabled button).
  final bool enabled;

  /// Scale factor while pressed. 1.0 = no visual change.
  final double scale;

  /// How long the scale transition takes in each direction.
  final Duration duration;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed && widget.enabled ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
