import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Tracks head pose angles in real time for the 3D hair overlay effect.
///
/// [yaw]   – left/right rotation in degrees (negative = turned right)
/// [pitch] – up/down tilt in degrees
class FaceTrackingProvider extends ChangeNotifier {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: false,
      enableContours: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  // ── Head pose ─────────────────────────────────────────────────────────
  double _yaw   = 0.0;
  double _pitch = 0.0;

  double get yaw   => _yaw;
  double get pitch => _pitch;

  bool _faceDetected = false;
  bool get faceDetected => _faceDetected;

  // ── Debug ─────────────────────────────────────────────────────────────
  int    _framesReceived = 0;
  int    _facesDetected  = 0;
  String _lastError      = '';

  int    get framesReceived => _framesReceived;
  int    get facesDetected  => _facesDetected;
  String get lastError      => _lastError;

  // ── Internal ──────────────────────────────────────────────────────────
  bool _isRunning    = false;
  bool _isProcessing = false;
  bool _isDisposed   = false;
  int  _frameSkip    = 0;

  // Process every 2nd frame — fast enough for smooth tracking
  static const int _kFrameInterval = 2;

  // Smoothing factor: higher = faster/snappier tracking, lower = smoother
  // 0.55 gives a good balance between responsiveness and stability
  static const double _kSmooth = 0.55;

  Future<void> start(CameraController controller) async {
    if (_isRunning) return;
    _isRunning = true;
    _lastError = '';
    try {
      await controller.startImageStream(_onCameraImage);
      debugPrint('[FaceTracking] Stream started');
    } catch (e) {
      _lastError = e.toString();
      _isRunning = false;
    }
  }

  Future<void> stop(CameraController controller) async {
    if (!_isRunning) return;
    _isRunning = false;
    try { await controller.stopImageStream(); } catch (_) {}
  }

  void _onCameraImage(CameraImage image) {
    _framesReceived++;
    _frameSkip++;
    if (_frameSkip % _kFrameInterval != 0) return;
    if (_isProcessing || _isDisposed) return;
    _isProcessing = true;

    _detectAsync(image).then((_) {
      _isProcessing = false;
    }).catchError((e) {
      _isProcessing = false;
      _lastError = e.toString();
    });
  }

  Future<void> _detectAsync(CameraImage image) async {
    final inputImage = _toInputImage(image);
    if (inputImage == null) return;

    final faces = await _detector.processImage(inputImage);
    if (_isDisposed) return;

    if (faces.isEmpty) {
      _faceDetected = false;
      _yaw   = _lerp(_yaw,   0, 0.08);
      _pitch = _lerp(_pitch, 0, 0.08);
    } else {
      _faceDetected = true;
      _facesDetected++;
      final face = faces.first;
      _yaw   = _lerp(_yaw,   face.headEulerAngleY ?? 0, _kSmooth);
      _pitch = _lerp(_pitch, face.headEulerAngleX ?? 0, _kSmooth);
      debugPrint('[FaceTracking] ✅ Y=${_yaw.toStringAsFixed(1)}° P=${_pitch.toStringAsFixed(1)}°');
    }

    if (!_isDisposed) notifyListeners();
  }

  // ── YUV_420_888 → NV21 ──────────────────────────────────────────────
  InputImage? _toInputImage(CameraImage image) {
    try {
      if (image.planes.length < 3) return null;

      final yPlane  = image.planes[0].bytes;
      final uPlane  = image.planes[1].bytes;
      final vPlane  = image.planes[2].bytes;
      final yRS  = image.planes[0].bytesPerRow;
      final uvRS = image.planes[1].bytesPerRow;
      final uvPS = image.planes[1].bytesPerPixel ?? 1;

      final w = image.width;
      final h = image.height;
      final nv21 = Uint8List(w * h + w * h ~/ 2);

      // Copy Y plane
      for (int row = 0; row < h; row++) {
        nv21.setRange(row * w, row * w + w, yPlane, row * yRS);
      }

      // Interleave VU
      int uvIdx = w * h;
      for (int row = 0; row < h ~/ 2; row++) {
        for (int col = 0; col < w ~/ 2; col++) {
          final off = row * uvRS + col * uvPS;
          if (off < vPlane.length && off < uPlane.length) {
            nv21[uvIdx++] = vPlane[off];
            nv21[uvIdx++] = uPlane[off];
          }
        }
      }

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      return InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(w.toDouble(), h.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: w,
        ),
      );
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void dispose() {
    _isDisposed = true;
    _detector.close();
    super.dispose();
  }
}
