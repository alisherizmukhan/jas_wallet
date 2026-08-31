import 'package:flutter/material.dart';

import 'feature_style.dart';

/// Staggered entrance — fades and slides a section up by 12px on first
/// build. Give each section on the page an increasing [delay] to produce
/// the "cards appear with staggered fade" effect from the brief.
class FeatureFadeIn extends StatefulWidget {
  const FeatureFadeIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<FeatureFadeIn> createState() => _FeatureFadeInState();
}

class _FeatureFadeInState extends State<FeatureFadeIn> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: FeatureStyle.animationDuration);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: FeatureStyle.animationCurve);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - curved.value) * 12), child: child),
      ),
      child: widget.child,
    );
  }
}
