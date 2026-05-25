import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/face_tracking_provider.dart';
import '../providers/style_provider.dart';

class HairOverlayWidget extends StatefulWidget {
  const HairOverlayWidget({super.key});
  @override
  State<HairOverlayWidget> createState() => _HairOverlayWidgetState();
}

class _HairOverlayWidgetState extends State<HairOverlayWidget> {
  double _baseZoom = 1.0;
  Offset _lastFocalPoint = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final sp           = context.watch<StyleProvider>();
    final face         = context.watch<FaceTrackingProvider>();
    final overlayState = sp.overlayState;

    if (overlayState == null) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final previewW = constraints.maxWidth;
      final previewH = constraints.maxHeight;

      overlayState.previewWidth  = previewW;
      overlayState.previewHeight = previewH;

      // ── Position: JSON anchor + user drag ──────────────────────────
      // No bounding-box auto-positioning — coordinate systems differ.
      // User drags once to sit the hairstyle on their head; rotation
      // then tracks naturally via the yaw/pitch transform below.
      final overlayW = previewW
          * overlayState.style.scaleRatio
          * overlayState.zoomMultiplier;
      final overlayH = overlayW;

      final left = previewW * overlayState.style.anchorX
          - overlayW / 2
          + overlayState.dragOffset.dx;
      final top  = previewH * overlayState.style.anchorY
          + overlayState.dragOffset.dy;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,

        onScaleStart: (details) {
          _baseZoom = overlayState.zoomMultiplier;
          _lastFocalPoint = details.localFocalPoint;
        },

        onScaleUpdate: (details) {
          final provider = context.read<StyleProvider>();
          if (details.pointerCount >= 2) {
            final newZoom =
                (_baseZoom * details.scale).clamp(0.3, 2.5);
            provider.setZoom(newZoom);
          } else {
            final delta =
                details.localFocalPoint - _lastFocalPoint;
            _lastFocalPoint = details.localFocalPoint;
            provider.onOverlayDrag(delta);
          }
        },

        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: left,
              top: top,
              width: overlayW,
              height: overlayH,
              child: _PerspectiveHair(
                assetPath: overlayState.style.assetPath,
                yawDegrees: face.yaw,
                pitchDegrees: face.pitch,
              ),
            ),

            if (top > 36)
              Positioned(
                left: left + overlayW / 2 - 70,
                top: top - 28,
                child: const _DragHint(),
              ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Perspective transform — rotation only, no position change
// ─────────────────────────────────────────────────────────────────────────────
class _PerspectiveHair extends StatelessWidget {
  final String assetPath;
  final double yawDegrees;
  final double pitchDegrees;

  const _PerspectiveHair({
    required this.assetPath,
    required this.yawDegrees,
    required this.pitchDegrees,
  });

  @override
  Widget build(BuildContext context) {
    final yawRad   = -yawDegrees   * (math.pi / 180) * 0.85;
    final pitchRad =  pitchDegrees * (math.pi / 180) * 0.40;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateY(yawRad.clamp(-1.2, 1.2))
      ..rotateX(pitchRad.clamp(-0.6, 0.6));

    return Transform(
      transform: matrix,
      alignment: Alignment.topCenter,
      child: _OverlayImage(assetPath: assetPath),
    );
  }
}

class _OverlayImage extends StatelessWidget {
  final String assetPath;
  const _OverlayImage({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _PlaceholderOverlay(),
    );
  }
}

class _PlaceholderOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: const Color(0xFF2563EB).withOpacity(0.7), width: 2),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF2563EB).withOpacity(0.08),
      ),
      child: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.content_cut, color: Color(0xFF2563EB), size: 32),
          SizedBox(height: 6),
          Text('Add PNG to\nassets/overlays/',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _DragHint extends StatelessWidget {
  const _DragHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_with, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text('Drag to place · Pinch to resize',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
