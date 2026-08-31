import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/profile_completion_provider.dart';
import '../../providers/section_highlight_provider.dart';

/// Wraps a widget with an animated accent border when [section] is highlighted.
///
/// The border fades in smoothly, remains visible while the highlight is active,
/// then fades out when cleared. It is painted as a foreground decoration so it
/// appears on top of the child's own border rather than behind it.
///
/// Sizing contract: the child must NOT carry external margin; spacing between
/// cards is the parent's responsibility. This keeps the border aligned exactly
/// with the card's visual edges.
class SectionHighlightBorder extends ConsumerStatefulWidget {
  const SectionHighlightBorder({
    super.key,
    required this.section,
    required this.child,
    this.borderRadius = 16.0,
  });

  final ProfileSection section;
  final Widget child;
  final double borderRadius;

  @override
  ConsumerState<SectionHighlightBorder> createState() =>
      _SectionHighlightBorderState();
}

class _SectionHighlightBorderState
    extends ConsumerState<SectionHighlightBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Sync to initial state in case the widget mounts while already highlighted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final highlighted = ref.read(
        sectionHighlightProvider.select((s) => s.contains(widget.section)),
      );
      if (highlighted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Drive animation from state changes; runs after build, never during.
    ref.listen<bool>(
      sectionHighlightProvider.select((s) => s.contains(widget.section)),
      (_, isHighlighted) {
        if (isHighlighted) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      },
    );

    final accentColor = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF007AFF)
        : const Color(0xFF0A84FF);

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        final opacity = _opacity.value;
        if (opacity == 0) return widget.child;
        return DecoratedBox(
          // Foreground: paints on top of the child's own border.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: accentColor.withValues(alpha: opacity * 0.65),
              width: 1.5,
            ),
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
