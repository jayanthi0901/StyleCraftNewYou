import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraStatus { initial, permissionDenied, initialising, ready, error }

class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  CameraStatus _status = CameraStatus.initial;
  String? _errorMessage;
  List<CameraDescription> _cameras = [];

  /// 0 = front, 1 = back (if available)
  int _activeLensIndex = 0; // default: front camera (selfie)

  // ─── Public getters ────────────────────────────────────────────────────
  CameraController? get controller => _controller;
  CameraStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == CameraStatus.ready;
  bool get isFrontCamera =>
      _cameras.isNotEmpty &&
      _cameras[_activeLensIndex].lensDirection ==
          CameraLensDirection.front;

  // ─── Init ──────────────────────────────────────────────────────────────

  /// Call once from the screen's [initState]. Requests permission then
  /// enumerates and initialises the default camera.
  Future<void> initialise() async {
    _setStatus(CameraStatus.initialising);

    // 1. Permission
    final perm = await Permission.camera.request();
    if (!perm.isGranted) {
      _setStatus(CameraStatus.permissionDenied,
          error: 'Camera permission denied. Please enable it in Settings.');
      return;
    }

    // 2. Enumerate cameras
    try {
      _cameras = await availableCameras();
    } catch (e) {
      _setStatus(CameraStatus.error, error: 'Could not list cameras: $e');
      return;
    }

    if (_cameras.isEmpty) {
      _setStatus(CameraStatus.error, error: 'No cameras found on this device.');
      return;
    }

    // Prefer FRONT camera (selfie) for initial launch
    _activeLensIndex = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
    if (_activeLensIndex < 0) _activeLensIndex = 0;

    await _initController(_cameras[_activeLensIndex]);
  }

  // ─── Lens toggle ──────────────────────────────────────────────────────

  Future<void> toggleLens() async {
    if (_cameras.length < 2) return;
    _activeLensIndex = (_activeLensIndex + 1) % _cameras.length;
    await _initController(_cameras[_activeLensIndex]);
  }

  // ─── Flash ────────────────────────────────────────────────────────────

  Future<void> cycleFlash() async {
    if (_controller == null || !isReady) return;
    final current = _controller!.value.flashMode;
    final next = current == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;
    await _controller!.setFlashMode(next);
    notifyListeners();
  }

  FlashMode get flashMode =>
      _controller?.value.flashMode ?? FlashMode.off;

  // ─── Private helpers ──────────────────────────────────────────────────

  Future<void> _initController(CameraDescription desc) async {
    // Fully dispose previous controller to prevent IntentReceiver leak
    final old = _controller;
    _controller = null;
    _setStatus(CameraStatus.initialising);
    if (old != null) {
      try {
        await old.dispose();
      } catch (_) {}
    }

    // Try progressively more compatible formats.
    // Xiaomi/MediaTek devices often reject jpeg/yuv420 format groups,
    // so we fall back to omitting imageFormatGroup entirely which lets
    // the driver choose whatever it supports.
    final attempts = [
      () => CameraController(desc, ResolutionPreset.medium,
            enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420),
      () => CameraController(desc, ResolutionPreset.low,
            enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420),
      () => CameraController(desc, ResolutionPreset.low,
            enableAudio: false), // no imageFormatGroup — driver picks
    ];

    for (final build in attempts) {
      final ctrl = build();
      try {
        await ctrl.initialize();
        if (!_isDisposed) {
          _controller = ctrl;
          _setStatus(CameraStatus.ready);
        } else {
          await ctrl.dispose();
        }
        return; // success — stop trying
      } catch (e) {
        debugPrint('[CameraProvider] attempt failed: $e');
        try { await ctrl.dispose(); } catch (_) {}
      }
    }
    // All attempts failed
    _setStatus(CameraStatus.error,
        error: 'Could not open camera. Try restarting the app.');
  }

  void _setStatus(CameraStatus status, {String? error}) {
    _status = status;
    _errorMessage = error;
    if (!_isDisposed) notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    try {
      _controller?.dispose();
    } catch (_) {}
    super.dispose();
  }
}
