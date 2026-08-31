import 'dart:math' as math;

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import '../theme/orientation_brand.dart';

/// Lightweight, dependency-free confetti burst. No confetti/lottie package
/// exists in this repo yet — this hand-rolls ~36 particles with a
/// `CustomPainter` instead of adding one for a single celebratory moment.
///
/// Fired via the overlay (`OrientationConfetti.play`), same "insert an
/// `OverlayEntry`, auto-remove after the animation ends" shape as
/// `RewardToastManager` in `app_ui` — so both celebratory effects in this
/// app behave consistently.
class OrientationConfetti {
  OrientationConfetti._();

  static void play(BuildContext context) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiOverlay(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay> with SingleTickerProviderStateMixin {
  static const _particleCount = 36;
  static List<Color> get _colors => [
    OrientationBrand.accent,
    AppColors.gold,
    AppColors.success,
    AppColors.blue,
    AppColors.purple,
    AppColors.orange,
  ];

  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();

    final random = math.Random();
    _particles = List.generate(_particleCount, (i) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 180 + random.nextDouble() * 260;
      return _Particle(
        color: _colors[random.nextInt(_colors.length)],
        angle: angle,
        speed: speed,
        size: 5 + random.nextDouble() * 5,
        spin: (random.nextDouble() - 0.5) * 10,
        isSquare: random.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final origin = Offset(size.width / 2, size.height * 0.35);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: size,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
              origin: origin,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.color,
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.isSquare,
  });

  final Color color;
  final double angle;
  final double speed;
  final double size;
  final double spin;
  final bool isSquare;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress, required this.origin});

  final List<_Particle> particles;
  final double progress;
  final Offset origin;

  static const _gravity = 420.0;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final opacity = (1 - t).clamp(0.0, 1.0);
    if (opacity <= 0) return;

    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * t;
      final dy = math.sin(p.angle) * p.speed * t + 0.5 * _gravity * t * t;
      final position = origin + Offset(dx, dy);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(p.spin * t * math.pi);
      final rect = Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.6);
      if (p.isSquare) {
        canvas.drawRect(rect, paint);
      } else {
        canvas.drawOval(rect, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
