import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/hair_style.dart';

class CaptureResult {
  final bool success;
  final String? filePath;
  final String? error;
  const CaptureResult._({required this.success, this.filePath, this.error});
  factory CaptureResult.ok(String path) => CaptureResult._(success: true, filePath: path);
  factory CaptureResult.fail(String err) => CaptureResult._(success: false, error: err);
}

/// Captures camera frame + composites the hairstyle overlay on top.
///
/// Strategy:
///   1. controller.takePicture()  → real camera frame (JPEG)
///   2. Load overlay PNG from assets
///   3. Scale and position overlay to match what was visible on screen
///   4. Composite using dart:ui Canvas + PictureRecorder
///   5. Save PNG to documents/captures/
class CaptureService extends ChangeNotifier {
  bool _isSaving = false;
  List<File> _savedCaptures = [];

  bool get isSaving => _isSaving;
  List<File> get savedCaptures => List.unmodifiable(_savedCaptures);

  Future<CaptureResult> capture({
    required CameraController cameraController,
    required HairOverlayState overlayState,
  }) async {
    if (_isSaving) return CaptureResult.fail('Capture already in progress');

    _isSaving = true;
    notifyListeners();

    try {
      // ── Step 1: Capture camera frame ─────────────────────────────────
      final XFile photoFile = await cameraController.takePicture();
      final Uint8List photoBytes = await photoFile.readAsBytes();

      // ── Step 2: Decode camera photo ───────────────────────────────────
      final ui.Codec photoCodec = await ui.instantiateImageCodec(photoBytes);
      final ui.FrameInfo photoFrame = await photoCodec.getNextFrame();
      final ui.Image photoImage = photoFrame.image;

      final int photoW = photoImage.width;
      final int photoH = photoImage.height;

      // ── Step 3: Load overlay PNG from assets ──────────────────────────
      final ByteData overlayData =
          await rootBundle.load(overlayState.style.assetPath);
      final Uint8List overlayBytes = overlayData.buffer.asUint8List();

      final ui.Codec overlayCodec =
          await ui.instantiateImageCodec(overlayBytes);
      final ui.FrameInfo overlayFrame = await overlayCodec.getNextFrame();
      final ui.Image overlayImage = overlayFrame.image;

      // ── Step 4: Calculate overlay rect in photo coordinates ───────────
      // The preview widget is overlayState.previewWidth × previewHeight.
      // The photo can be a different resolution — we scale proportionally.
      final double scaleX = photoW / overlayState.previewWidth;
      final double scaleY = photoH / overlayState.previewHeight;

      final ui.Rect overlayRect = ui.Rect.fromLTWH(
        overlayState.left  * scaleX,
        overlayState.top   * scaleY,
        overlayState.overlayW * scaleX,
        overlayState.overlayH * scaleY,
      );

      // ── Step 5: Composite on canvas ───────────────────────────────────
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder,
          ui.Rect.fromLTWH(0, 0, photoW.toDouble(), photoH.toDouble()));

      // Draw camera photo
      canvas.drawImage(photoImage, ui.Offset.zero, ui.Paint());

      // Draw overlay PNG scaled to the computed rect
      canvas.drawImageRect(
        overlayImage,
        ui.Rect.fromLTWH(0, 0,
            overlayImage.width.toDouble(), overlayImage.height.toDouble()),
        overlayRect,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );

      final ui.Picture picture = recorder.endRecording();
      final ui.Image composited =
          await picture.toImage(photoW, photoH);

      // ── Step 6: Encode to PNG bytes ───────────────────────────────────
      final ByteData? pngData =
          await composited.toByteData(format: ui.ImageByteFormat.png);

      photoImage.dispose();
      overlayImage.dispose();
      composited.dispose();

      if (pngData == null) {
        return CaptureResult.fail('Failed to encode composited image');
      }

      // ── Step 7: Save to disk ──────────────────────────────────────────
      final dir = await _capturesDirectory();
      final fileName = 'stylesnap_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pngData.buffer.asUint8List(), flush: true);

      _savedCaptures = [file, ..._savedCaptures];
      debugPrint('[CaptureService] Saved → ${file.path}');
      return CaptureResult.ok(file.path);
    } catch (e, st) {
      debugPrint('[CaptureService] Error: $e\n$st');
      return CaptureResult.fail('Capture failed: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedCaptures() async {
    final dir = await _capturesDirectory();
    final entities = dir.listSync()
      ..sort((a, b) => b.path.compareTo(a.path));
    _savedCaptures = entities
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();
    notifyListeners();
  }

  Future<void> deleteCapture(File file) async {
    if (await file.exists()) await file.delete();
    _savedCaptures.removeWhere((f) => f.path == file.path);
    notifyListeners();
  }

  Future<Directory> _capturesDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/captures');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
