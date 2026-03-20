// lib/features/scanner/presentation/image_viewer.dart
// Rotate + zoom + pan image viewer used in ScannerSection.
//
// Returns an ImageTransform when user taps "Done" so the
// scanner preview applies the same rotation/scale/offset.
//
// Usage:
//   final t = await ImageViewerSheet.show(context, imageBytes);
//   if (t != null) setState(() => _transform = t);

import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';

// ── Transform result returned to ScannerSection ───────────────────────────
class ImageTransform {
  final double rotation; // radians
  final double scale;
  final Offset offset;

  const ImageTransform({
    required this.rotation,
    required this.scale,
    required this.offset,
  });

  static const identity = ImageTransform(
    rotation: 0.0,
    scale:    1.0,
    offset:   Offset.zero,
  );
}

// ── Public API ─────────────────────────────────────────────────────────────
class ImageViewerSheet {
  /// Opens the viewer. Returns the chosen [ImageTransform] when the user
  /// taps "Done", or null if they swiped the sheet away.
  static Future<ImageTransform?> show(
    BuildContext context,
    Uint8List imageBytes, {
    ImageTransform? initial,
  }) {
    return showModalBottomSheet<ImageTransform>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageViewerWidget(
        imageBytes: imageBytes,
        initial:    initial ?? ImageTransform.identity,
      ),
    );
  }
}

// ── Widget ─────────────────────────────────────────────────────────────────
class _ImageViewerWidget extends StatefulWidget {
  final Uint8List      imageBytes;
  final ImageTransform initial;

  const _ImageViewerWidget({
    required this.imageBytes,
    required this.initial,
  });

  @override
  State<_ImageViewerWidget> createState() => _ImageViewerWidgetState();
}

class _ImageViewerWidgetState extends State<_ImageViewerWidget>
    with SingleTickerProviderStateMixin {

  late double _rotation;
  late double _scale;
  late Offset _offset;

  double _startScale    = 1.0;
  Offset _startOffset   = Offset.zero;
  Offset _startFocal    = Offset.zero;
  double _startRotation = 0.0;

  late AnimationController _resetCtrl;
  Animation<double>? _scaleAnim;
  Animation<Offset>? _offsetAnim;
  Animation<double>? _rotationAnim;

  @override
  void initState() {
    super.initState();
    // Restore whatever transform was active in the preview
    _rotation = widget.initial.rotation;
    _scale    = widget.initial.scale;
    _offset   = widget.initial.offset;

    _resetCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _resetCtrl.addListener(_onResetTick);
  }

  void _onResetTick() {
    setState(() {
      _scale    = _scaleAnim?.value    ?? _scale;
      _offset   = _offsetAnim?.value   ?? _offset;
      _rotation = _rotationAnim?.value ?? _rotation;
    });
  }

  void _resetView() {
    _scaleAnim = Tween(begin: _scale, end: 1.0).animate(
        CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOutCubic));
    _offsetAnim = Tween(begin: _offset, end: Offset.zero).animate(
        CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOutCubic));
    _rotationAnim = Tween(begin: _rotation, end: 0.0).animate(
        CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOutCubic));
    _resetCtrl.forward(from: 0);
  }

  void _rotate90()    => setState(() => _rotation += pi / 2);
  void _rotateNeg90() => setState(() => _rotation -= pi / 2);

  // ── Return current transform to caller ───────────────────────────────────
  void _done() {
    _resetCtrl.stop();
    Navigator.of(context).pop(
      ImageTransform(
        rotation: _rotation,
        scale:    _scale.clamp(0.5, 5.0),
        offset:   _offset,
      ),
    );
  }

  @override
  void dispose() {
    _resetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [

          // Drag handle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Center(
              child: Container(
                height: 5, width: 50,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Hint label
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.touch_app_rounded, color: Colors.white38, size: 14),
                SizedBox(width: 6),
                Text(
                  'Pinch to zoom · Drag to move · Twist to rotate',
                  style: TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),

          // ── Image canvas ───────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onScaleStart: (d) {
                _startScale    = _scale;
                _startOffset   = _offset;
                _startFocal    = d.focalPoint;
                _startRotation = _rotation;
                _resetCtrl.stop();
              },
              onScaleUpdate: (d) {
                setState(() {
                  _scale    = (_startScale * d.scale).clamp(0.5, 5.0);
                  _rotation = _startRotation + d.rotation;
                  _offset   = _startOffset + (d.focalPoint - _startFocal);
                });
              },
              onScaleEnd: (_) {
                if (_scale < 0.9) _resetView();
              },
              child: ClipRRect(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(_offset.dx, _offset.dy)
                    ..rotateZ(_rotation)
                    ..scale(_scale),
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),

          // ── Controls bar ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(top: BorderSide(
                  color: Colors.white.withOpacity(0.08))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _btn(Icons.rotate_left_rounded,          'Rotate L',  _rotateNeg90),
                _btn(Icons.rotate_right_rounded,         'Rotate R',  _rotate90),
                _btn(Icons.center_focus_strong_rounded,  'Reset',     _resetView, primary: true),
                _btn(Icons.zoom_in_rounded,              'Zoom in',
                    () => setState(() => _scale = (_scale + 0.5).clamp(0.5, 5.0))),
                _btn(Icons.zoom_out_rounded,             'Zoom out',
                    () => setState(() => _scale = (_scale - 0.5).clamp(0.5, 5.0))),
              ],
            ),
          ),

          // ── Done button ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _done,   // ← returns transform to caller
                child: const Text(
                  'Done — use this image',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap,
      {bool primary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary
                  ? const Color(0xFF2E7D32).withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: primary ? const Color(0xFF69F0AE) : Colors.white70,
                size: 22),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}