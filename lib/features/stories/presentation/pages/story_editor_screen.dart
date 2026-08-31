import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:app_ui/app_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/story.dart';

/// Full-screen story editor, Instagram-style.
///
/// Layout (top → bottom):
///   • Phone status bar (visible — never drawn over)
///   • Content box (the media + overlays) — the editable canvas
///   • Action area (Share button) — sits *below* the content, not over it
///   • Phone navigation bar (visible)
///
/// The content box is the exact same size as the story viewer's content box,
/// so what you edit is what gets shown.
///
/// Features:
///   • Two-finger pinch / pan to scale + reposition the media inside the box
///   • Tap (photo) to add text; tap (video) to play/pause
///   • Drag a text overlay to move, pinch it to scale, long-press to delete
///   • Freehand drawing with colour selection + undo
///   • Video trim bar (max 20 s) with frame scrubbing
class StoryEditorScreen extends StatefulWidget {
  const StoryEditorScreen({
    super.key,
    required this.mediaPath,
    required this.mediaType,
  });

  final String mediaPath;
  final StoryMediaType mediaType;

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

// ── Result ────────────────────────────────────────────────────────────────────

class StoryEditorResult {
  const StoryEditorResult({
    required this.renderedMediaPath,
    required this.mediaType,
    this.trimStartMs,
    this.trimEndMs,
  });

  final String renderedMediaPath;
  final StoryMediaType mediaType;

  // ── Video-only: trim range ──
  final int? trimStartMs;
  final int? trimEndMs;
}

// ── State ─────────────────────────────────────────────────────────────────────

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final GlobalKey _captureKey = GlobalKey();

  // ── Text overlays (offsets are content-box-local) ──
  final List<_TextOverlayData> _textOverlays = [];

  // ── Drawing ──
  final List<DrawingStroke> _completedStrokes = [];
  List<DrawingPoint> _currentStroke = [];
  bool _isDrawing = false;

  // ── Colour palette (shared text + drawing) ──
  static const _colors = [
    Colors.white,
    Colors.black,
    Color(0xFFFF3B30),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF34C759),
    Color(0xFF00C7BE),
    Color(0xFF007AFF),
    Color(0xFF5E5CE6),
    Color(0xFFFF2D55),
  ];
  int _selectedColorIndex = 0;
  Color get _activeColor => _colors[_selectedColorIndex];

  // ── Inline text editing ──
  bool _isEditingText = false;
  int? _editingTextIndex;
  Offset? _newTextPosition;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  double _editFontSize = 28;

  // ── Media transform (pinch / pan / rotate) ──
  double _mediaScale = 1.0;
  Offset _mediaOffset = Offset.zero;
  double _mediaRotation = 0;
  double _scaleStart = 1.0;
  Offset _offsetStart = Offset.zero;
  double _rotationStart = 0;
  Offset _focalStart = Offset.zero;

  // Cached photo provider — created once so rebuilds during a drag don't
  // re-resolve/re-decode the image (a source of jank).
  ImageProvider? _photoProvider;

  // ── Video player ──
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  double _videoDurationSecs = 0;

  // ── Video trim ──
  static const double _kMaxTrimSecs = 20.0;
  double _trimStart = 0;
  double _trimEnd = _kMaxTrimSecs;

  // ── Video play/pause indicator ──
  bool _playPauseVisible = false;
  bool _lastWasPlay = true;

  /// Current playhead position, updated on every video tick (several times
  /// a second). A dedicated notifier — rather than routing through
  /// `setState` on the whole editor — so only the trim-bar playhead
  /// (via [ValueListenableBuilder] in [_buildTrimBarSection]) repaints on
  /// each tick instead of the entire editor tree (media transform, text
  /// overlays, drawing layer, toolbars, ...).
  final ValueNotifier<double> _playPositionNotifier = ValueNotifier(0);

  // Size of the content box (set by LayoutBuilder each frame).
  Size _boxSize = Size.zero;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == StoryMediaType.video) {
      _initVideo();
    } else {
      _photoProvider = FileImage(File(widget.mediaPath));
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _playPositionNotifier.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.file(File(widget.mediaPath));
    try {
      await ctrl.initialize();
      final durSecs = ctrl.value.duration.inMilliseconds / 1000.0;
      _videoDurationSecs = durSecs;
      _trimStart = 0;
      _trimEnd = durSecs.clamp(0, _kMaxTrimSecs);
      ctrl.addListener(_onVideoTick);
      ctrl.setLooping(false);
      await ctrl.play();
      if (mounted) {
        setState(() {
          _videoController = ctrl;
          _videoInitialized = true;
        });
      }
    } catch (_) {
      await ctrl.dispose();
    }
  }

  void _onVideoTick() {
    if (!mounted) return;
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final posSecs = ctrl.value.position.inMilliseconds / 1000.0;
    if (posSecs >= _trimEnd) {
      ctrl.seekTo(Duration(milliseconds: (_trimStart * 1000).round()));
      ctrl.play();
    }
    // Notifier-only update — no setState here. The trim bar's playhead is
    // the only thing that needs to move on every tick; see
    // [_playPositionNotifier].
    _playPositionNotifier.value = posSecs.clamp(_trimStart, _trimEnd);
  }

  void _toggleVideoPlayPause() {
    final ctrl = _videoController;
    if (ctrl == null || !_videoInitialized) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
      _lastWasPlay = false;
    } else {
      ctrl.play();
      _lastWasPlay = true;
    }
    setState(() => _playPauseVisible = true);
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) setState(() => _playPauseVisible = false);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Content fills the whole safe area (status bar → nav bar).
              // The Share button floats over the bottom of the content so the
              // content area is identical to the viewer's (which has no button).
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _boxSize = Size(constraints.maxWidth, constraints.maxHeight);
                    return ClipRect(child: _buildContentBox(l10n));
                  },
                ),
              ),

              // ── Text editor overlay (covers the whole safe area) ────────
              if (_isEditingText) Positioned.fill(child: _buildInlineTextField(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Content box ─────────────────────────────────────────────────────────

  Widget _buildContentBox(AppLocalizations l10n) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Captured layer (media + drawings + text) — flattened for photos.
        RepaintBoundary(
          key: _captureKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media (transformed)
              _buildMediaPreview(),

              // Background gesture.
              // Photo: 2-finger pinch/pan transforms the media; tap adds text.
              // Video: tap plays/pauses (no transform — it can't be persisted
              // without re-encoding, so we don't offer a no-op gesture).
              if (!_isDrawing && !_isEditingText)
                Positioned.fill(
                  child: widget.mediaType == StoryMediaType.image
                      ? GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onScaleStart: _onMediaScaleStart,
                          onScaleUpdate: _onMediaScaleUpdate,
                          onTapUp: (d) => _addTextAt(d.localPosition),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _toggleVideoPlayPause,
                        ),
                ),

              // Drawing capture layer
              if (_isDrawing) _buildDrawingLayer(),

              // Completed strokes
              IgnorePointer(
                child: CustomPaint(
                  painter: _StrokePainter(
                    _completedStrokes,
                    _isDrawing ? _currentStroke : [],
                    _activeColor,
                  ),
                  size: Size.infinite,
                ),
              ),

              // Text overlays
              if (!_isDrawing) ..._buildTextOverlays(),
            ],
          ),
        ),

        // ── Non-captured controls (NOT baked into the photo) ──────────────

        // Top gradient for toolbar legibility
        IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 96,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Colors.transparent],
                ),
              ),
            ),
          ),
        ),

        // Top toolbar
        if (!_isEditingText) _buildTopBar(l10n),

        // Video play/pause indicator
        if (widget.mediaType == StoryMediaType.video && _playPauseVisible)
          IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: _playPauseVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _lastWasPlay ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),

        // ── Bottom controls, floating over the content ───────────────────
        // Drawing mode → colour picker. Otherwise → [optional trim bar] + the
        // Share button, all overlaid so the content stays full-height.
        if (_isDrawing)
          Positioned(left: 0, right: 0, bottom: 0, child: _buildDrawingColorPicker())
        else if (!_isEditingText)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomControls(l10n),
          ),
      ],
    );
  }

  // ── Bottom controls (trim + floating Share button) ──────────────────────

  Widget _buildBottomControls(AppLocalizations l10n) {
    final showTrim = widget.mediaType == StoryMediaType.video && _videoInitialized;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xCC000000), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTrim) _buildTrimBarSection(),
          Padding(
            padding: EdgeInsets.fromLTRB(20, showTrim ? 6 : 20, 20, 16),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
          ),
                child: Center(
                  child: Text(
                    l10n.stories_share,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Media preview (original aspect, no stretch) ─────────────────────────

  Widget _buildMediaPreview() {
    Widget media;
    if (widget.mediaType == StoryMediaType.image) {
      media = Image(
        image: _photoProvider!,
        // contain → keep the original aspect ratio (no stretch, no crop).
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, e, s) =>
            const Center(child: AppIcon(AppIcons.image, size: 64, color: Colors.white54)),
      );
    } else if (!_videoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
      );
    } else {
      final ctrl = _videoController!;
      media = FittedBox(
        fit: BoxFit.contain,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: ctrl.value.size.width,
          height: ctrl.value.size.height,
          child: VideoPlayer(ctrl),
        ),
      );
    }

    // Apply the user's transform: translate, then rotate + scale about centre.
    return Positioned.fill(
      child: Transform.translate(
        offset: _mediaOffset,
        child: Transform.rotate(
          angle: _mediaRotation,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: _mediaScale,
            alignment: Alignment.center,
            child: media,
          ),
        ),
      ),
    );
  }

  // ── Media transform gestures (two-finger: scale + rotate + move) ─────────

  void _onMediaScaleStart(ScaleStartDetails d) {
    _scaleStart = _mediaScale;
    _offsetStart = _mediaOffset;
    _rotationStart = _mediaRotation;
    _focalStart = d.focalPoint;
  }

  void _onMediaScaleUpdate(ScaleUpdateDetails d) {
    // Only respond to genuine multi-finger gestures so single-finger taps
    // (add text / play-pause) are not hijacked.
    if (d.pointerCount < 2) return;
    setState(() {
      _mediaScale = (_scaleStart * d.scale).clamp(0.3, 6.0);
      _mediaRotation = _rotationStart + d.rotation;
      _mediaOffset = _offsetStart + (d.focalPoint - _focalStart);
    });
  }

  // ── Top toolbar ─────────────────────────────────────────────────────────

  Widget _buildTopBar(AppLocalizations l10n) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _circleButton(AppIcons.close, onTap: () async {
              if (_isDrawing) {
                setState(() => _isDrawing = false);
              } else {
                final confirmed = await AppPremiumDialog.show(
                  context: context,
                  icon: AppIcons.close,
                  iconColor: const Color(0xFFFF3B30),
                  title: l10n.stories_discardTitle,
                  description: l10n.stories_discardMessage,
                  confirmText: l10n.stories_discardConfirm,
                  cancelText: l10n.stories_keepEditing,
                  isDestructive: true,
                );
                if (confirmed && mounted) {
                  _videoController?.pause();
                  Navigator.pop(context);
                }
              }
            }),
            const Spacer(),
            if (_isDrawing) ...[
              _circleButton(AppIcons.back, onTap: _undoStroke),
              const SizedBox(width: 8),
              _circleButton(AppIcons.check, onTap: () => setState(() => _isDrawing = false)),
            ]
            // Text + drawing tools are photo-only: overlays on video would need
            // re-encoding to persist, which isn't supported.
            else if (widget.mediaType == StoryMediaType.image) ...[
              _circleButton(AppIcons.edit, onTap: () => setState(() => _isDrawing = true)),
              const SizedBox(width: 8),
              _circleTextButton(onTap: _addText),
            ],
          ],
        ),
      ),
    );
  }

  // ── Trim bar ──────────────────────────────────────────────────────────────

  Widget _buildTrimBarSection() {
    final selectedSecs = _trimEnd - _trimStart;
    final overLimit = selectedSecs > _kMaxTrimSecs;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xCC000000), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.content_cut_rounded, color: Colors.white54, size: 11),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${_fmtSecs(_trimStart)} – ${_fmtSecs(_trimEnd)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_fmtSecs(selectedSecs)} / ${_fmtSecs(_kMaxTrimSecs)}',
                style: TextStyle(
                  color: overLimit ? const Color(0xFFFF453A) : Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Scoped to just the playhead-driven trim bar so a video tick
          // repaints this widget alone instead of the whole editor tree —
          // see [_playPositionNotifier].
          ValueListenableBuilder<double>(
            valueListenable: _playPositionNotifier,
            builder: (context, posSeconds, _) => _VideoTrimBar(
              totalDuration: _videoDurationSecs,
              trimStart: _trimStart,
              trimEnd: _trimEnd,
              playPosition: posSeconds,
              maxTrimDuration: _kMaxTrimSecs,
              onTrimChanged: (start, end) {
                setState(() {
                  _trimStart = start;
                  _trimEnd = end;
                });
                _videoController?.seekTo(Duration(milliseconds: (start * 1000).round()));
              },
              onSeek: (seekSecs) {
                final ctrl = _videoController;
                if (ctrl == null) return;
                if (ctrl.value.isPlaying) ctrl.pause();
                ctrl.seekTo(Duration(milliseconds: (seekSecs * 1000).round()));
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmtSecs(double seconds) {
    final s = seconds.clamp(0, double.infinity).round();
    final m = s ~/ 60;
    final r = s % 60;
    return m > 0 ? '$m:${r.toString().padLeft(2, '0')}' : '${r}s';
  }

  // ── Drawing colour picker ─────────────────────────────────────────────────

  Widget _buildDrawingColorPicker() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xCC000000), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 56,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _colors.length,
          itemBuilder: (_, i) {
            final selected = i == _selectedColorIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedColorIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: selected ? 34 : 28,
                height: selected ? 34 : 28,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.white38,
                    width: selected ? 2.5 : 1.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Drawing layer ─────────────────────────────────────────────────────────

  Widget _buildDrawingLayer() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          setState(() {
            _currentStroke = [DrawingPoint(x: d.localPosition.dx, y: d.localPosition.dy)];
          });
        },
        onPanUpdate: (d) {
          setState(() {
            _currentStroke.add(DrawingPoint(x: d.localPosition.dx, y: d.localPosition.dy));
          });
        },
        onPanEnd: (_) {
          if (_currentStroke.isNotEmpty) {
            _completedStrokes.add(DrawingStroke(
              points: List.of(_currentStroke),
              color: _colorToInt(_activeColor),
              width: 3.0,
            ));
          }
          setState(() => _currentStroke = []);
        },
      ),
    );
  }

  // ── Text overlays ─────────────────────────────────────────────────────────

  List<Widget> _buildTextOverlays() {
    final w = _boxSize.width;
    final h = _boxSize.height;
    return List.generate(_textOverlays.length, (i) {
      return _StickerOverlay(
        data: _textOverlays[i],
        boxW: w,
        boxH: h,
        maxWidth: w * 0.85,
        // Update the source data without setState — the sticker owns its own
        // visuals during the gesture, so the heavy editor tree never rebuilds.
        onChanged: (d) => _textOverlays[i] = d,
        onEdit: () => _editText(i),
        onDelete: () => _deleteText(i),
      );
    });
  }

  // ── Instagram-style inline text editor ───────────────────────────────────

  Widget _buildInlineTextField(AppLocalizations l10n) {
    final mq = MediaQuery.of(context);
    final keyboardH = mq.viewInsets.bottom;
    const colorRowH = 56.0;
    const topBarH = 56.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availH = constraints.maxHeight;
        // Clamp the space reserved at the bottom (keyboard + colour row) so the
        // middle text region keeps at least ~80px — prevents a negative-height
        // Positioned (which would overflow) on short screens / tall keyboards.
        final bottomReserve =
            (keyboardH + colorRowH).clamp(0.0, (availH - topBarH - 80).clamp(0.0, availH));
        final colorRowBottom = (keyboardH + 6).clamp(0.0, (availH - colorRowH).clamp(0.0, availH));

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _commitText,
                child: Container(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),

        // Top bar: Cancel | Done
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _cancelText,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon(AppIcons.close, color: Colors.white, size: 20),
                  ),
                ),
                GestureDetector(
                  onTap: _commitText,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.common_done,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Left: vertical font-size slider
        Positioned(
          left: 0,
          top: topBarH,
          bottom: bottomReserve,
          width: 44,
          child: LayoutBuilder(
            builder: (_, constraints) => RotatedBox(
              quarterTurns: 3,
              child: SizedBox(
                width: constraints.maxHeight,
                child: SliderTheme(
                  data: SliderThemeData(
                    thumbColor: Colors.white,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white30,
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: _editFontSize,
                    min: 14,
                    max: 72,
                    onChanged: (v) => setState(() => _editFontSize = v),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Center: transparent text field
        Positioned(
          left: 44,
          right: 12,
          top: topBarH,
          bottom: bottomReserve,
          child: Center(
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              autofocus: true,
              textAlign: TextAlign.center,
              maxLines: null,
              cursorColor: _activeColor == Colors.black ? Colors.white : _activeColor,
              style: TextStyle(
                color: _activeColor,
                fontSize: _editFontSize,
                fontWeight: FontWeight.w700,
                shadows: const [
                  Shadow(blurRadius: 8, color: Colors.black87),
                  Shadow(blurRadius: 2, color: Colors.black45),
                ],
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
                hintText: l10n.stories_textHint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: _editFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onSubmitted: (_) => _commitText(),
            ),
          ),
        ),

        // Bottom: colour row
        Positioned(
          bottom: colorRowBottom,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              itemCount: _colors.length,
              itemBuilder: (_, i) {
                final selected = i == _selectedColorIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: selected ? 36 : 30,
                    height: selected ? 36 : 30,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white38,
                        width: selected ? 3 : 1.5,
                      ),
                      boxShadow: selected
                          ? [const BoxShadow(color: Colors.black38, blurRadius: 4)]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
          ],
        );
      },
    );
  }

  // ── Text actions ──────────────────────────────────────────────────────────

  void _addText() {
    _startTextEdit(
      null,
      Offset(_boxSize.width / 2 - 50, _boxSize.height / 2 - 20),
    );
  }

  void _addTextAt(Offset position) => _startTextEdit(null, position);

  void _startTextEdit(int? index, Offset position) {
    if (index != null) {
      final data = _textOverlays[index];
      _textController.text = data.text;
      _editFontSize = data.fontSize;
      final c = Color(data.color);
      final matchIdx = _colors.indexWhere((col) =>
          (col.r - c.r).abs() < 0.01 &&
          (col.g - c.g).abs() < 0.01 &&
          (col.b - c.b).abs() < 0.01);
      if (matchIdx >= 0) _selectedColorIndex = matchIdx;
    } else {
      _textController.clear();
      _editFontSize = 28;
    }
    setState(() {
      _isEditingText = true;
      _editingTextIndex = index;
      _newTextPosition = position;
    });
    _textFocusNode.requestFocus();
  }

  void _editText(int index) => _startTextEdit(index, _textOverlays[index].offset);

  void _commitText() {
    final text = _textController.text.trim();
    _textFocusNode.unfocus();
    setState(() {
      if (_editingTextIndex != null) {
        if (text.isEmpty) {
          _textOverlays.removeAt(_editingTextIndex!);
        } else {
          _textOverlays[_editingTextIndex!] = _textOverlays[_editingTextIndex!].copyWith(
            text: text,
            fontSize: _editFontSize,
            color: _colorToInt(_activeColor),
          );
        }
      } else if (text.isNotEmpty) {
        _textOverlays.add(_TextOverlayData(
          text: text,
          offset: _newTextPosition ??
              Offset(_boxSize.width / 2 - 50, _boxSize.height / 2 - 20),
          color: _colorToInt(_activeColor),
          fontSize: _editFontSize,
        ));
      }
      _isEditingText = false;
      _editingTextIndex = null;
      _newTextPosition = null;
    });
  }

  void _cancelText() {
    _textFocusNode.unfocus();
    setState(() {
      _isEditingText = false;
      _editingTextIndex = null;
      _newTextPosition = null;
    });
  }

  void _deleteText(int index) => setState(() => _textOverlays.removeAt(index));

  void _undoStroke() {
    if (_completedStrokes.isNotEmpty) {
      setState(() => _completedStrokes.removeLast());
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  bool get _hasOverlays => _textOverlays.isNotEmpty || _completedStrokes.isNotEmpty;
  bool get _hasTransform =>
      _mediaScale != 1.0 || _mediaOffset != Offset.zero || _mediaRotation != 0;

  Future<void> _save() async {
    _videoController?.pause();

    if (widget.mediaType == StoryMediaType.image) {
      await _saveImage();
    } else {
      _saveVideo();
    }
  }

  Future<void> _saveImage() async {
    // Quality first: if the user made NO edits (no text, no drawing, no
    // transform) upload the ORIGINAL file untouched — no re-encode, full
    // resolution. Only flatten when there are overlays/transform to bake in.
    if (!_hasOverlays && !_hasTransform) {
      Navigator.pop(
        context,
        StoryEditorResult(
          renderedMediaPath: widget.mediaPath,
          mediaType: StoryMediaType.image,
        ),
      );
      return;
    }

    final rendered = await _captureBoundary(_captureKey);
    if (rendered == null) {
      if (mounted) {
        AppToast.showError(context, AppLocalizations.of(context)!.stories_renderFailed);
      }
      return;
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      StoryEditorResult(
        renderedMediaPath: rendered,
        mediaType: StoryMediaType.image,
      ),
    );
  }

  void _saveVideo() {
    // Video editing is trim-only (overlays/transform would require re-encoding
    // to persist). The source file is cut natively during upload.
    Navigator.pop(
      context,
      StoryEditorResult(
        renderedMediaPath: widget.mediaPath,
        mediaType: StoryMediaType.video,
        trimStartMs: (_trimStart * 1000).round(),
        trimEndMs: (_trimEnd * 1000).round(),
      ),
    );
  }

  Future<String?> _captureBoundary(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      // Capture at full device pixel ratio (plus a little headroom) so baked-in
      // edits stay crisp.
      final pixelRatio = MediaQuery.of(context).devicePixelRatio.clamp(2.0, 3.0);
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final file = File(
        '${Directory.systemTemp.path}/story_${DateTime.now().millisecondsSinceEpoch}_${key.hashCode}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _colorToInt(Color c) =>
      ((c.a * 255).round() << 24) |
      ((c.r * 255).round() << 16) |
      ((c.g * 255).round() << 8) |
       (c.b * 255).round();

  Widget _circleButton(AppIconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 6, spreadRadius: 1),
          ],
        ),
        child: AppIcon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _circleTextButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 6, spreadRadius: 1),
          ],
        ),
        child: const Center(
          child: Text(
            'Aa',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: -0.3,
              shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Overlay capture layer (rendered off-screen for video burn-in) ─────────────
//
// Note: this widget mirrors the text + drawing overlays at the SAME box size,
// over a transparent background. It is included in the tree (behind the content
// box, fully transparent) so its RepaintBoundary can be captured on save.

// ── Draggable text sticker (self-contained, snappy) ───────────────────────────
//
// Owns its own offset + font size during gestures and rebuilds ONLY itself, so
// dragging follows the finger 1:1 without rebuilding the whole editor (image /
// video / gradients). Reports changes back to the parent for save.

class _StickerOverlay extends StatefulWidget {
  const _StickerOverlay({
    required this.data,
    required this.boxW,
    required this.boxH,
    required this.maxWidth,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final _TextOverlayData data;
  final double boxW;
  final double boxH;
  final double maxWidth;
  final ValueChanged<_TextOverlayData> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_StickerOverlay> createState() => _StickerOverlayState();
}

class _StickerOverlayState extends State<_StickerOverlay> {
  late Offset _offset;
  late double _fontSize;
  Offset _startOffset = Offset.zero;
  double _startFont = 0;
  Offset _startFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _offset = widget.data.offset;
    _fontSize = widget.data.fontSize;
  }

  @override
  void didUpdateWidget(covariant _StickerOverlay old) {
    super.didUpdateWidget(old);
    // Sync when the parent changes the data (e.g. text/colour edited via dialog).
    if (widget.data.offset != _offset) _offset = widget.data.offset;
    if (widget.data.fontSize != _fontSize) _fontSize = widget.data.fontSize;
  }

  double _clampX(double x) => x.clamp(0.0, (widget.boxW - 40).clamp(0.0, widget.boxW));
  double _clampY(double y) => y.clamp(0.0, (widget.boxH - 40).clamp(0.0, widget.boxH));

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _clampX(_offset.dx),
      top: _clampY(_offset.dy),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onScaleStart: (d) {
          _startOffset = _offset;
          _startFont = _fontSize;
          _startFocal = d.focalPoint;
        },
        onScaleUpdate: (d) {
          setState(() {
            // Absolute translation from gesture start → tracks the finger 1:1.
            _offset = Offset(
              _clampX(_startOffset.dx + (d.focalPoint.dx - _startFocal.dx)),
              _clampY(_startOffset.dy + (d.focalPoint.dy - _startFocal.dy)),
            );
            if (d.pointerCount >= 2) {
              _fontSize = (_startFont * d.scale).clamp(12.0, 80.0);
            }
          });
          widget.onChanged(widget.data.copyWith(offset: _offset, fontSize: _fontSize));
        },
        onDoubleTap: widget.onEdit,
        onLongPress: widget.onDelete,
        child: _TextOverlayWidget(
          data: widget.data.copyWith(offset: _offset, fontSize: _fontSize),
          maxWidth: widget.maxWidth,
        ),
      ),
    );
  }
}

// ── Text overlay widget ────────────────────────────────────────────────────────

class _TextOverlayWidget extends StatelessWidget {
  const _TextOverlayWidget({required this.data, required this.maxWidth});
  final _TextOverlayData data;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth > 0 ? maxWidth : 280),
      child: Text(
        data.text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(data.color),
          fontSize: data.fontSize,
          fontWeight: FontWeight.w700,
          shadows: const [
            Shadow(blurRadius: 8, color: Colors.black87),
            Shadow(blurRadius: 2, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

// ── Video trim bar ─────────────────────────────────────────────────────────────

class _VideoTrimBar extends StatefulWidget {
  const _VideoTrimBar({
    required this.totalDuration,
    required this.trimStart,
    required this.trimEnd,
    required this.playPosition,
    required this.maxTrimDuration,
    required this.onTrimChanged,
    this.onSeek,
  });

  final double totalDuration;
  final double trimStart;
  final double trimEnd;
  final double playPosition;
  final double maxTrimDuration;
  final void Function(double start, double end) onTrimChanged;
  final void Function(double positionSecs)? onSeek;

  @override
  State<_VideoTrimBar> createState() => _VideoTrimBarState();
}

enum _TrimHandle { left, right }

class _VideoTrimBarState extends State<_VideoTrimBar> {
  _TrimHandle? _activeDrag;
  bool _isScrubbing = false;
  double? _dragBaseX;
  double? _dragBaseTime;

  static const double _kBarHeight = 52.0;
  static const double _kHitSlop = 28.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: (_) => setState(() {
        _activeDrag = null;
        _isScrubbing = false;
      }),
      child: CustomPaint(
        painter: _TrimBarPainter(
          totalDuration: widget.totalDuration,
          trimStart: widget.trimStart,
          trimEnd: widget.trimEnd,
          playPosition: widget.playPosition,
          activeDrag: _activeDrag,
          isScrubbing: _isScrubbing,
        ),
        size: const Size(double.infinity, _kBarHeight),
      ),
    );
  }

  void _onTapDown(TapDownDetails d) {
    final width = context.size?.width ?? 320;
    final x = d.localPosition.dx;
    final lx = _timeToX(widget.trimStart, width);
    final rx = _timeToX(widget.trimEnd, width);
    if (x > lx + _kHitSlop && x < rx - _kHitSlop) {
      widget.onSeek?.call(_xToTime(x, width).clamp(widget.trimStart, widget.trimEnd));
    }
  }

  void _onDragStart(DragStartDetails d) {
    final width = context.size?.width ?? 320;
    final x = d.localPosition.dx;
    final lx = _timeToX(widget.trimStart, width);
    final rx = _timeToX(widget.trimEnd, width);

    if ((x - lx).abs() < _kHitSlop) {
      _activeDrag = _TrimHandle.left;
      _dragBaseX = x;
      _dragBaseTime = widget.trimStart;
      _isScrubbing = false;
    } else if ((x - rx).abs() < _kHitSlop) {
      _activeDrag = _TrimHandle.right;
      _dragBaseX = x;
      _dragBaseTime = widget.trimEnd;
      _isScrubbing = false;
    } else if (x > lx && x < rx) {
      _isScrubbing = true;
      _activeDrag = null;
      widget.onSeek?.call(_xToTime(x, width).clamp(widget.trimStart, widget.trimEnd));
    }
    setState(() {});
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final width = context.size?.width ?? 320;

    if (_isScrubbing) {
      widget.onSeek
          ?.call(_xToTime(d.localPosition.dx, width).clamp(widget.trimStart, widget.trimEnd));
      setState(() {});
      return;
    }

    if (_activeDrag == null || _dragBaseX == null || _dragBaseTime == null) return;

    final dx = d.localPosition.dx - _dragBaseX!;
    final dt = (dx / width) * widget.totalDuration;
    final newTime = _dragBaseTime! + dt;

    if (_activeDrag == _TrimHandle.left) {
      final maxStart = widget.trimEnd - 1.0;
      final clamped = newTime.clamp(0.0, maxStart);
      final newStart = (widget.trimEnd - clamped > widget.maxTrimDuration)
          ? widget.trimEnd - widget.maxTrimDuration
          : clamped;
      widget.onTrimChanged(newStart, widget.trimEnd);
    } else {
      final minEnd = widget.trimStart + 1.0;
      final maxEnd =
          (widget.trimStart + widget.maxTrimDuration).clamp(minEnd, widget.totalDuration);
      widget.onTrimChanged(widget.trimStart, newTime.clamp(minEnd, maxEnd));
    }
    setState(() {});
  }

  double _timeToX(double t, double width) {
    if (widget.totalDuration <= 0) return 0;
    return (t / widget.totalDuration) * width;
  }

  double _xToTime(double x, double width) {
    if (widget.totalDuration <= 0 || width <= 0) return 0;
    return (x / width) * widget.totalDuration;
  }
}

// ── Trim bar painter ──────────────────────────────────────────────────────────

class _TrimBarPainter extends CustomPainter {
  _TrimBarPainter({
    required this.totalDuration,
    required this.trimStart,
    required this.trimEnd,
    required this.playPosition,
    this.activeDrag,
    this.isScrubbing = false,
  });

  final double totalDuration;
  final double trimStart;
  final double trimEnd;
  final double playPosition;
  final _TrimHandle? activeDrag;
  final bool isScrubbing;

  static const double _kHandleW = 13.0;
  static const double _kBorderW = 2.0;
  static const Color _kHandleC = Color(0xFFFFD60A);
  static const Color _kBorderC = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalDuration <= 0) return;

    final w = size.width;
    final h = size.height;
    double tx(double t) => (t / totalDuration) * w;

    final lx = tx(trimStart);
    final rx = tx(trimEnd);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(5)),
      Paint()..color = const Color(0xFF2C2C2E),
    );

    final framePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3A3A3C), Color(0xFF2C2C2E), Color(0xFF3A3A3C)],
        stops: [0.0, 0.5, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(lx + _kHandleW, 0, rx - lx - _kHandleW * 2, h));
    canvas.drawRect(
      Rect.fromLTWH(lx + _kHandleW, 0, rx - lx - _kHandleW * 2, h),
      framePaint,
    );

    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    if (lx > 0) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, lx, h),
          topLeft: const Radius.circular(5),
          bottomLeft: const Radius.circular(5),
        ),
        dimPaint,
      );
    }
    if (rx < w) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(rx, 0, w - rx, h),
          topRight: const Radius.circular(5),
          bottomRight: const Radius.circular(5),
        ),
        dimPaint,
      );
    }

    final borderPaint = Paint()
      ..color = _kBorderC
      ..strokeWidth = _kBorderW;
    canvas.drawLine(
      Offset(lx + _kHandleW, _kBorderW / 2),
      Offset(rx - _kHandleW, _kBorderW / 2),
      borderPaint,
    );
    canvas.drawLine(
      Offset(lx + _kHandleW, h - _kBorderW / 2),
      Offset(rx - _kHandleW, h - _kBorderW / 2),
      borderPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(lx, 0, _kHandleW, h),
        topLeft: const Radius.circular(5),
        bottomLeft: const Radius.circular(5),
      ),
      Paint()
        ..color = activeDrag == _TrimHandle.left
            ? _kHandleC.withValues(alpha: 0.8)
            : _kHandleC,
    );
    _drawGrip(canvas, lx + _kHandleW / 2, h);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(rx - _kHandleW, 0, _kHandleW, h),
        topRight: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
      ),
      Paint()
        ..color = activeDrag == _TrimHandle.right
            ? _kHandleC.withValues(alpha: 0.8)
            : _kHandleC,
    );
    _drawGrip(canvas, rx - _kHandleW / 2, h);

    final cursorX = tx(playPosition).clamp(lx + _kHandleW, rx - _kHandleW);
    canvas.drawLine(
      Offset(cursorX, 4),
      Offset(cursorX, h - 4),
      Paint()
        ..color = isScrubbing ? const Color(0xFFFFD60A) : Colors.white
        ..strokeWidth = isScrubbing ? 3.0 : 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawGrip(Canvas canvas, double cx, double barH) {
    final p = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final midY = barH / 2;
    for (int i = -1; i <= 1; i++) {
      final y = midY + i * 5.5;
      canvas.drawLine(Offset(cx - 2.5, y), Offset(cx + 2.5, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _TrimBarPainter old) =>
      old.trimStart != trimStart ||
      old.trimEnd != trimEnd ||
      old.playPosition != playPosition ||
      old.activeDrag != activeDrag ||
      old.isScrubbing != isScrubbing;
}

// ── Text overlay data model ────────────────────────────────────────────────────

class _TextOverlayData {
  const _TextOverlayData({
    required this.text,
    required this.offset,
    this.color = 0xFFFFFFFF,
    this.fontSize = 28,
  });

  final String text;
  final Offset offset;
  final int color;
  final double fontSize;

  _TextOverlayData copyWith({
    String? text,
    Offset? offset,
    int? color,
    double? fontSize,
  }) =>
      _TextOverlayData(
        text: text ?? this.text,
        offset: offset ?? this.offset,
        color: color ?? this.color,
        fontSize: fontSize ?? this.fontSize,
      );
}

// ── Freehand stroke painter ────────────────────────────────────────────────────

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.completed, this.current, this.activeColor);

  final List<DrawingStroke> completed;
  final List<DrawingPoint> current;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in completed) {
      _drawStroke(canvas, stroke.points, Color(stroke.color), stroke.width);
    }
    if (current.isNotEmpty) {
      _drawStroke(canvas, current, activeColor, 3.0);
    }
  }

  void _drawStroke(Canvas canvas, List<DrawingPoint> pts, Color color, double width) {
    if (pts.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = ui.Path()..moveTo(pts.first.x, pts.first.y);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].x, pts[i].y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) =>
      // Always repaint: the in-progress stroke is mutated in place (same List
      // reference), so a reference comparison would miss live updates and the
      // stroke would only appear after the finger lifts.
      true;
}
