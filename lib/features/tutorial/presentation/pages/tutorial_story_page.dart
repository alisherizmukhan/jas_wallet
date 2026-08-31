import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/tutorial_slide.dart';

/// Full-screen tutorial story viewer — image-backed, Instagram-style.
///
/// - Auto-advances per slide duration (default 15 s)
/// - Tap left third  → previous slide / restart
/// - Tap right two-thirds → next slide / dismiss on last
/// - Long-press → pause / release → resume
/// - X button → dismiss immediately
/// - Bottom button → explicit Next / Done
class TutorialStoryPage extends StatefulWidget {
  const TutorialStoryPage({
    super.key,
    required this.tutorialId,
    required this.slides,
    this.onDismiss,
  });

  final String tutorialId;
  final List<TutorialSlide> slides;

  /// Called when the tutorial finishes or is closed.
  ///
  /// When null (default), the tutorial pops itself as a route — used by the
  /// hub where it is pushed via [Navigator.push]. When provided, it is shown
  /// as an in-page overlay (first-launch auto-show) and the host removes it.
  final VoidCallback? onDismiss;

  @override
  State<TutorialStoryPage> createState() => _TutorialStoryPageState();
}

class _TutorialStoryPageState extends State<TutorialStoryPage>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _progress;
  bool _isPaused = false;

  TutorialSlide get _slide => widget.slides[_index];

  @override
  void initState() {
    super.initState();
    // Pre-cache slides using the same ResizeImage key that Image.asset uses
    // (cacheWidth must match or Flutter decodes again on first render, causing jank).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mq = MediaQuery.of(context);
      final cacheW = (mq.size.width * mq.devicePixelRatio).round();
      for (final s in widget.slides) {
        precacheImage(
          ResizeImage(AssetImage(s.imagePath), width: cacheW),
          context,
        );
      }
    });
    _progress = AnimationController(vsync: this, duration: _slide.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _advance();
      })
      ..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (!mounted) return;
    setState(() => _index = index);
    _progress
      ..duration = _slide.duration
      ..forward(from: 0);
  }

  void _advance() {
    if (_index < widget.slides.length - 1) {
      _goTo(_index + 1);
    } else {
      _dismiss();
    }
  }

  void _dismiss() {
    if (!mounted) return;
    final onDismiss = widget.onDismiss;
    if (onDismiss != null) {
      onDismiss();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleTap(double x, double screenWidth) {
    if (x < screenWidth / 3) {
      if (_index > 0) {
        _goTo(_index - 1);
      } else {
        _progress.forward(from: 0);
      }
    } else {
      _advance();
    }
  }

  void _pause() {
    if (!mounted || _isPaused) return;
    _progress.stop();
    setState(() => _isPaused = true);
  }

  void _resume() {
    if (!mounted || !_isPaused) return;
    setState(() => _isPaused = false);
    _progress.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    // Decode at native display resolution — avoids blurry scaling AND
    // prevents decoding 4K assets into memory at full resolution.
    final cacheW = (size.width * dpr).round();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _handleTap(d.localPosition.dx, size.width),
          onLongPressStart: (_) => _pause(),
          onLongPressEnd: (_) => _resume(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background image — crossfade per slide ────────────────────
              // Positioned.fill gives tight screen-size constraints so the
              // image layer can never overflow. SizedBox.expand is the keyed
              // AnimatedSwitcher child so it detects slide changes.
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox.expand(
                      key: ValueKey(_index),
                      child: Image.asset(
                        _slide.imagePath,
                        fit: BoxFit.contain,
                        cacheWidth: cacheW,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Top scrim — darkens area behind progress bars + controls ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 260,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom scrim — darkens area behind text + button ──────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 400,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.90),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── UI overlay ────────────────────────────────────────────────
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress bars — RepaintBoundary isolates per-frame repaints
                    // from the rest of the overlay (text, dots, button).
                    RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.df,
                          AppSpacing.md,
                          AppSpacing.df,
                          0,
                        ),
                        child: _ProgressBars(
                          count: widget.slides.length,
                          current: _index,
                          controller: _progress,
                        ),
                      ),
                    ),
                    // Step chip + close button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.df,
                        AppSpacing.sm,
                        AppSpacing.md,
                        0,
                      ),
                      child: Row(
                        children: [
                          _StepChip(
                            current: _index + 1,
                            total: widget.slides.length,
                          ),
                          const Spacer(),
                          _CircleButton(
                            icon: Icons.close_rounded,
                            onTap: _dismiss,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Title + body — fade-switches per slide
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: _SlideText(
                        key: ValueKey(_index),
                        slide: _slide,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Dots
                    _SlideDots(
                      count: widget.slides.length,
                      current: _index,
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step chip ────────────────────────────────────────────────────────────────

class _StepChip extends StatelessWidget {
  const _StepChip({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: AppSpacing.borderRadiusRound,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: pad(current),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: ' / ${pad(total)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Close button ─────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Progress bars ────────────────────────────────────────────────────────────

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.count,
    required this.current,
    required this.controller,
  });

  final int count;
  final int current;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final isCompleted = i < current;
        final isCurrent = i == current;

        Widget segment;
        if (isCurrent) {
          segment = AnimatedBuilder(
            animation: controller,
            builder: (context, _) => _ProgressSegment(value: controller.value),
          );
        } else {
          segment = _ProgressSegment(value: isCompleted ? 1.0 : 0.0);
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < count - 1 ? 4 : 0),
            child: segment,
          ),
        );
      }),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.white.withValues(alpha: 0.35),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

// ─── Slide text ───────────────────────────────────────────────────────────────

class _SlideText extends StatelessWidget {
  const _SlideText({
    super.key,
    required this.slide,
  });

  final TutorialSlide slide;

  static const _shadows = <Shadow>[
    Shadow(offset: Offset(0, 1), blurRadius: 6, color: Colors.black54),
    Shadow(offset: Offset(0, 3), blurRadius: 14, color: Colors.black38),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            slide.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
              shadows: _shadows,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slide.body,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w400,
              shadows: _shadows,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide dots ───────────────────────────────────────────────────────────────

class _SlideDots extends StatelessWidget {
  const _SlideDots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

