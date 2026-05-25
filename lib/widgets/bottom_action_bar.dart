// ---------------------------------------------------------------------------
// bottom_action_bar.dart
//
// The row at the very bottom of the consultation screen:
//   [RECENT thumbnail]   [● Camera Capture]   [↺ Undo]
//
// Capture button triggers the camera snapshot, composites the overlay,
// and stores the result so it appears in the RECENT thumbnail.
// ---------------------------------------------------------------------------

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';

import '../providers/consultation_provider.dart';

class BottomActionBar extends StatelessWidget {
  /// Pass in the GlobalKey that wraps the camera + overlay Stack so we can
  /// take a screenshot of exactly that area.
  final GlobalKey previewKey;
  final CameraController? cameraController;

  const BottomActionBar({
    super.key,
    required this.previewKey,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsultationProvider>();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main action row ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // RECENT thumbnail
              _RecentThumbnail(
                imageBytes: provider.lastCapture,
                onTap: () => _showGallery(context, provider.lastCapture),
              ),

              // Big capture button
              _CaptureButton(
                onPressed: () => _capture(context, provider),
              ),

              // Undo / clear overlay button
              _IconCircleButton(
                icon: Icons.undo_rounded,
                onPressed: () => provider.clearActiveStyle(),
                tooltip: 'Clear overlay',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Disclaimer (User Story 1 acceptance criterion) ─────────────
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 13, color: Colors.black38),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Final look will be created by stylist. '
                  'Results may vary based on hair texture, current color, '
                  'and lighting conditions.',
                  style: TextStyle(fontSize: 10, color: Colors.black38, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Capture logic ─────────────────────────────────────────────────────────
  Future<void> _capture(
    BuildContext context,
    ConsultationProvider provider,
  ) async {
    try {
      // Grab a screenshot of the previewKey widget (camera + overlay together)
      final boundary = previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      // Save to device gallery
      //await ImageGallerySaver.saveImage(bytes, name: 'StyleSync_${DateTime.now().millisecondsSinceEpoch}');
await Gal.putImageBytes(bytes, name: 'StyleSync_${DateTime.now().millisecondsSinceEpoch}');
	

      // Store in provider so RECENT thumbnail updates
      provider.setLastCapture(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Saved to gallery'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF4A90D9),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  void _showGallery(BuildContext context, Uint8List? bytes) {
    if (bytes == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(bytes),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── RECENT thumbnail ──────────────────────────────────────────────────────────

class _RecentThumbnail extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const _RecentThumbnail({required this.imageBytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.photo, color: Colors.grey),
                    ),
            ),
          ),
          // RECENT badge
          Positioned(
            top: -6,
            left: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'RECENT',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Big camera capture button ─────────────────────────────────────────────────

class _CaptureButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CaptureButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF4A90D9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90D9).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

// ── Small icon circle button (undo / settings) ────────────────────────────────

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _IconCircleButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, size: 22, color: Colors.black54),
        ),
      ),
    );
  }
}
