import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import '../tokens/app_colors.dart';

/// A reusable full-screen QR scanner.
///
/// One camera + viewfinder implementation shared by every feature that needs
/// QR scanning (Social Meal redemption, Orientation Week supervisor
/// confirmation, and anything added later). It owns the camera, the frosted
/// close button, pinch-to-zoom with a side slider, the viewfinder mask /
/// corner brackets / scan line, and the camera-permission error view.
///
/// It is deliberately unopinionated about what a scan *means*: it calls
/// [onDetect] with the decoded string and lets the caller decide. Callers
/// drive the flow with [active] (camera on / detection enabled) and layer
/// their own result UI via [overlay]:
///
/// - A one-shot caller (e.g. "scan to confirm") just pops on the first
///   detection.
/// - A stateful caller (e.g. redeem-then-show-result) sets `active: false`
///   while it processes and passes a processing / success / error [overlay].
///
/// All user-facing copy is injected as plain strings so this widget carries
/// no localization dependency.
class AppQrScanner extends StatefulWidget {
  const AppQrScanner({
    super.key,
    required this.onDetect,
    required this.onClose,
    this.active = true,
    this.showViewfinder = true,
    this.title,
    this.instruction,
    this.cameraErrorText,
    this.openSettingsText,
    this.overlay,
  });

  /// Called with the decoded value on the first detection of each active
  /// session. Detection is suppressed until [active] cycles back to true.
  final ValueChanged<String> onDetect;

  /// Invoked when the student taps the close button.
  final VoidCallback onClose;

  /// When true the camera runs and detections fire. Set false while the
  /// caller processes a result; set true again to resume scanning.
  final bool active;

  /// Whether to draw the viewfinder chrome (mask, brackets, close button,
  /// zoom slider, title/instruction). Hide it when a full-screen result
  /// [overlay] takes over (e.g. a success screen).
  final bool showViewfinder;

  /// Optional heading above the viewfinder.
  final String? title;

  /// Optional hint under the viewfinder.
  final String? instruction;

  /// Copy shown when the camera can't start (usually permission denied).
  final String? cameraErrorText;

  /// Label for the "open settings" button on the camera-error view.
  final String? openSettingsText;

  /// A layer drawn above the scanner — the caller's processing / success /
  /// error UI.
  final Widget? overlay;

  @override
  State<AppQrScanner> createState() => _AppQrScannerState();
}

class _AppQrScannerState extends State<AppQrScanner>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MobileScannerController _scanner = MobileScannerController(
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  late final AnimationController _closeCtrl;
  late final Animation<double> _closeFade;

  /// Guards against delivering the same code twice within one active session.
  bool _delivered = false;

  double _zoom = 0.0;
  double _zoomAtPinchStart = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _closeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _closeFade = CurvedAnimation(parent: _closeCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _closeCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(AppQrScanner old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      // Resuming: clear the one-shot guard and restart the camera.
      _delivered = false;
      _scanner.start();
    } else if (!widget.active && old.active) {
      _scanner.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _scanner.stop();
      case AppLifecycleState.resumed:
        if (widget.active) _scanner.start();
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closeCtrl.dispose();
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_delivered || !widget.active) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    _delivered = true;
    HapticFeedback.selectionClick();
    widget.onDetect(value);
  }

  void _setZoom(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if ((clamped - _zoom).abs() < 0.001) return;
    if ((clamped <= 0.001 || clamped >= 0.999) && clamped != _zoom) {
      HapticFeedback.lightImpact();
    }
    setState(() => _zoom = clamped);
    _scanner.setZoomScale(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onScaleStart: (_) => _zoomAtPinchStart = _zoom,
              onScaleUpdate: (details) {
                if (details.pointerCount < 2) return;
                _setZoom(_zoomAtPinchStart + (details.scale - 1.0) * 0.5);
              },
              child: RepaintBoundary(
                child: MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _CameraErrorView(
                    onClose: widget.onClose,
                    message: widget.cameraErrorText,
                    openSettingsLabel: widget.openSettingsText,
                  ),
                ),
              ),
            ),
            if (widget.showViewfinder) ...[
              _ViewfinderOverlay(
                title: widget.title,
                instruction: widget.instruction,
                paused: !widget.active,
              ),
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  bottom: false,
                  right: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: FadeTransition(
                      opacity: _closeFade,
                      child: GlassIconButton(icon: AppIcons.close, onPressed: widget.onClose),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(child: _ZoomSlider(value: _zoom, onChanged: _setZoom)),
              ),
            ],
            if (widget.overlay != null) widget.overlay!,
          ],
        ),
      ),
    );
  }
}

// ─── Viewfinder overlay ───────────────────────────────────────────────────────

class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay({this.title, this.instruction, required this.paused});

  final String? title;
  final String? instruction;
  final bool paused;

  static const double _cutoutSize = 256.0;
  static const double _cutoutRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: const _ViewfinderMaskPainter(cutoutSize: _cutoutSize, cutoutRadius: _cutoutRadius)),
        Center(
          child: SizedBox(
            width: _cutoutSize,
            height: _cutoutSize,
            child: Stack(
              children: [
                CustomPaint(size: const Size(_cutoutSize, _cutoutSize), painter: const _CornerBracketPainter()),
                if (!paused) const _ScanLine(),
              ],
            ),
          ),
        ),
        if (title != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 64, left: 24, right: 24),
                child: Text(
                  title!,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        if (instruction != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Text(
                  instruction!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 14, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ViewfinderMaskPainter extends CustomPainter {
  const _ViewfinderMaskPainter({required this.cutoutSize, required this.cutoutRadius});

  final double cutoutSize;
  final double cutoutRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.62);
    final center = Offset(size.width / 2, size.height / 2);
    final cutout = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: cutoutSize, height: cutoutSize),
      Radius.circular(cutoutRadius),
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(cutout),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ViewfinderMaskPainter old) =>
      old.cutoutSize != cutoutSize || old.cutoutRadius != cutoutRadius;
}

class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter();

  static const double _armLength = 24.0;
  static const double _cornerRadius = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    const a = _armLength;
    const r = _cornerRadius;

    canvas.drawPath(Path()..moveTo(0, a)..lineTo(0, r)..quadraticBezierTo(0, 0, r, 0)..lineTo(a, 0), paint);
    canvas.drawPath(Path()..moveTo(w - a, 0)..lineTo(w - r, 0)..quadraticBezierTo(w, 0, w, r)..lineTo(w, a), paint);
    canvas.drawPath(Path()..moveTo(0, h - a)..lineTo(0, h - r)..quadraticBezierTo(0, h, r, h)..lineTo(a, h), paint);
    canvas.drawPath(Path()..moveTo(w - a, h)..lineTo(w - r, h)..quadraticBezierTo(w, h, w, h - r)..lineTo(w, h - a), paint);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) => false;
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => CustomPaint(painter: _ScanLinePainter(position: _anim.value)),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  const _ScanLinePainter({required this.position});

  final double position;

  @override
  void paint(Canvas canvas, Size size) {
    final y = 4 + (size.height - 8) * position;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, AppColors.primary.withValues(alpha: 0.85), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2));
    canvas.drawRect(Rect.fromLTWH(0, y - 1, size.width, 2), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.position != position;
}

// ─── Camera error view ─────────────────────────────────────────────────────────

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.onClose, this.message, this.openSettingsLabel});

  final VoidCallback onClose;
  final String? message;
  final String? openSettingsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(children: [GlassIconButton(icon: AppIcons.close, onPressed: onClose)]),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(AppIcons.camera, size: 56, color: Colors.white.withValues(alpha: 0.35)),
                      const SizedBox(height: 20),
                      if (message != null)
                        Text(
                          message!,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 15, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      if (openSettingsLabel != null) ...[
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              await SystemChannels.platform.invokeMethod('SystemNavigator.routeUpdated');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(openSettingsLabel!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared chrome ─────────────────────────────────────────────────────────────

/// A frosted-glass circular icon button — reusable over any camera preview.
class GlassIconButton extends StatefulWidget {
  const GlassIconButton({super.key, required this.icon, required this.onPressed});

  final AppIconData icon;
  final VoidCallback onPressed;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        await _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedBuilder(
            animation: _scale,
            builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                  ),
                  child: AppIcon(widget.icon, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  const _ZoomSlider({required this.value, required this.onChanged});

  final double value;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: 40,
          height: 176,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.28),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.12),
              ),
              child: Slider(value: value, onChanged: onChanged),
            ),
          ),
        ),
      ),
    );
  }
}
