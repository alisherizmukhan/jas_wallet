import 'package:flutter/material.dart';

/// Wraps a child (the student card) with a scanning glare sweep and an
/// optional result flash (green for granted, red for rejected).
class SaltoCardScanEffect extends StatefulWidget {
  const SaltoCardScanEffect({
    super.key,
    required this.child,
    this.isScanning = false,
    this.showResult = false,
    this.resultColor,
  });

  final Widget child;

  /// True while an unlock attempt is in progress (scanning / connecting).
  final bool isScanning;

  /// True briefly after the unlock outcome is known.
  final bool showResult;

  /// The colour of the result flash (green = granted, red = rejected).
  final Color? resultColor;

  @override
  State<SaltoCardScanEffect> createState() => _SaltoCardScanEffectState();
}

class _SaltoCardScanEffectState extends State<SaltoCardScanEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SaltoCardScanEffect old) {
    super.didUpdateWidget(old);
    if (widget.isScanning && !old.isScanning) {
      _controller.repeat();
    } else if (!widget.isScanning && old.isScanning) {
      // Let the current sweep finish, then stop.
      _controller.forward().then((_) {
        if (!widget.isScanning && mounted) _controller.reset();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          widget.child,

          // Glare sweep
          if (widget.isScanning)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, _) => CustomPaint(
                  painter: _GlarePainter(_controller.value),
                ),
              ),
            ),

          // Result flash
          if (widget.showResult && widget.resultColor != null)
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.28, end: 0.0),
                duration: const Duration(milliseconds: 800),
                builder: (_, opacity, _) => Container(
                  color: widget.resultColor!.withValues(alpha: opacity),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlarePainter extends CustomPainter {
  _GlarePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const bandWidthFraction = 0.25;
    final bandWidth = size.width * bandWidthFraction;
    final totalTravel = size.width + bandWidth;
    final left = -bandWidth + totalTravel * progress;

    final rect = Rect.fromLTWH(left, 0, bandWidth, size.height);
    final gradient = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.18),
        Colors.white.withValues(alpha: 0.32),
        Colors.white.withValues(alpha: 0.18),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_GlarePainter old) => old.progress != progress;
}
