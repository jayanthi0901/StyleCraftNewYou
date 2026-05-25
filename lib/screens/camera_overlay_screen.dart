import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/camera_provider.dart';
import '../providers/face_tracking_provider.dart';
import '../providers/style_provider.dart';
import '../services/capture_service.dart';
import '../widgets/hair_overlay_widget.dart';
import '../widgets/style_selector_sheet.dart';

class CameraOverlayScreen extends StatefulWidget {
  const CameraOverlayScreen({super.key});

  @override
  State<CameraOverlayScreen> createState() => _CameraOverlayScreenState();
}

class _CameraOverlayScreenState extends State<CameraOverlayScreen>
    with WidgetsBindingObserver {

  CameraStatus? _lastStatus; // track status changes to start/stop face tracking

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().initialise();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = context.read<CameraProvider>();
    final face = context.read<FaceTrackingProvider>();
    if (!cam.isReady || cam.controller == null) return;

    if (state == AppLifecycleState.inactive) {
      face.stop(cam.controller!);
      cam.controller?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      cam.controller?.resumePreview();
      face.start(cam.controller!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<CameraProvider>(
          builder: (_, camProvider, __) {
            // Start face tracking as soon as camera becomes ready
            if (camProvider.status == CameraStatus.ready &&
                _lastStatus != CameraStatus.ready &&
                camProvider.controller != null) {
              _lastStatus = CameraStatus.ready;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context
                      .read<FaceTrackingProvider>()
                      .start(camProvider.controller!);
                }
              });
            } else if (camProvider.status != CameraStatus.ready &&
                _lastStatus == CameraStatus.ready) {
              // Camera went away — stop face tracking
              _lastStatus = camProvider.status;
            }

            return switch (camProvider.status) {
              CameraStatus.permissionDenied => _PermissionDeniedView(),
              CameraStatus.error =>
                _ErrorView(message: camProvider.errorMessage ?? 'Unknown error'),
              CameraStatus.ready =>
                _LivePreview(controller: camProvider.controller!),
              _ => const _LoadingView(),
            };
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Live preview – camera + overlay + controls
// ──────────────────────────────────────────────────────────────────────────────
class _LivePreview extends StatefulWidget {
  final CameraController controller;
  const _LivePreview({required this.controller});

  @override
  State<_LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<_LivePreview> {
  @override
  Widget build(BuildContext context) {
    final captureService = context.watch<CaptureService>();
    final styleProvider  = context.watch<StyleProvider>();
    final selectedStyle  = styleProvider.selectedStyle;

    return SafeArea(
      child: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────────
          _TopBar(),

          // ── Camera + overlay ───────────────────────────────────────────
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CameraFeed(controller: widget.controller),
                const HairOverlayWidget(),
                if (captureService.isSaving) const _SavingOverlay(),
                // Debug HUD — shows face detection live status
                const Positioned(top: 8, left: 8, child: _FaceDebugHud()),
              ],
            ),
          ),

          // ── Tags row ───────────────────────────────────────────────────
          if (selectedStyle != null && selectedStyle.tags.isNotEmpty)
            _TagsRow(tags: selectedStyle.tags),

          // ── Disclaimer ─────────────────────────────────────────────────
          const _Disclaimer(),

          // ── Bottom controls ────────────────────────────────────────────
          _BottomControls(controller: widget.controller),
        ],
      ),
    );
  }
}

// ── Camera feed ───────────────────────────────────────────────────────────────

class _CameraFeed extends StatelessWidget {
  final CameraController controller;
  const _CameraFeed({required this.controller});

  @override
  Widget build(BuildContext context) {
    // SizedBox.expand + FittedBox fills the preview area safely without
    // ever producing invalid (non-normalised) BoxConstraints.
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final camProvider = context.watch<CameraProvider>();
    final styleProvider = context.watch<StyleProvider>();

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Selected style name
          Expanded(
            child: Text(
              styleProvider.selectedStyle?.name ?? 'No Style',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Flash toggle
          _IconBtn(
            icon: camProvider.flashMode == FlashMode.off
                ? Icons.flash_off
                : Icons.flash_on,
            onTap: camProvider.cycleFlash,
          ),
          const SizedBox(width: 8),

          // Lens switch
          _IconBtn(
            icon: Icons.flip_camera_ios_outlined,
            onTap: camProvider.toggleLens,
          ),
          const SizedBox(width: 8),

          // Reset overlay position
          _IconBtn(
            icon: Icons.center_focus_strong_outlined,
            onTap: () => styleProvider.resetOverlay(),
            tooltip: 'Reset position',
          ),
        ],
      ),
    );
  }
}

// ── Bottom controls ───────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final CameraController controller;
  const _BottomControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TextBtn(
            icon: Icons.style_outlined,
            label: 'Styles',
            onTap: () => StyleSelectorSheet.show(context),
          ),
          _ShutterButton(controller: controller),
          _SavedCountBtn(),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  final CameraController controller;
  const _ShutterButton({required this.controller});

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1, end: 0.88).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
  );

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
        if (!mounted) return;
        final captureService = context.read<CaptureService>();
        final overlayState = context.read<StyleProvider>().overlayState;
        if (overlayState == null) {
          _showSnackBar(context, false, null, 'Please select a style first');
          return;
        }
        final result = await captureService.capture(
          cameraController: widget.controller,
          overlayState: overlayState,
        );
        if (!mounted) return;
        _showSnackBar(context, result.success, result.filePath, result.error);
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            color: Colors.white.withOpacity(0.15),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, bool success, String? path,
      String? error) {
    final msg = success
        ? '✅ Saved! Tap Captures to view.'
        : '❌ ${error ?? 'Save failed'}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TextBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCountBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch<CaptureService>().savedCaptures.length;
    return GestureDetector(
      onTap: () {
        // TODO: push CaptureGalleryScreen
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.photo_library_outlined,
                    color: Colors.white, size: 26),
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Captures',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Saving spinner ─────────────────────────────────────────────────────────────

class _SavingOverlay extends StatelessWidget {
  const _SavingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Saving…',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ── State views ───────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    // Shows live status so you can see exactly what stage camera init is at
    final status = context.watch<CameraProvider>().status;
    final msg = switch (status) {
      CameraStatus.initial       => 'Preparing camera…',
      CameraStatus.initialising  => 'Opening camera…',
      _                          => 'Starting camera…',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2563EB)),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'If this takes >10 sec, tap retry below',
            style: const TextStyle(color: Colors.white24, fontSize: 11),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => context.read<CameraProvider>().initialise(),
            child: const Text('Retry', style: TextStyle(color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, color: Colors.white38, size: 56),
            const SizedBox(height: 20),
            const Text(
              'Camera access required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'StyleSnap needs camera permission to show your live hair preview.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () =>
                  context.read<CameraProvider>().initialise(),
              child: const Text('Grant Permission',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () =>
                  context.read<CameraProvider>().initialise(),
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared icon button ─────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconBtn({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ── Tags row ──────────────────────────────────────────────────────────────────

class _TagsRow extends StatelessWidget {
  final List<String> tags;
  const _TagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: tags.map((tag) => _TagChip(tag: tag)).toList(),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.5)),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          color: Color(0xFF93C5FD),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Disclaimer ────────────────────────────────────────────────────────────────

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF64748B), size: 13),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Final look will be created by stylist. Results may vary.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Face tracking debug HUD ───────────────────────────────────────────────────
// Shows live face detection status so we can diagnose issues.
// Remove this widget once face tracking is confirmed working.

class _FaceDebugHud extends StatelessWidget {
  const _FaceDebugHud();

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FaceTrackingProvider>();
    final color = f.faceDetected ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(
                f.faceDetected ? 'Face detected' : 'No face',
                style: TextStyle(color: color, fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Frames: \${f.framesReceived}  Detections: \${f.facesDetected}',
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Text(
            'Y:\${f.yaw.toStringAsFixed(1)}°  '
            'P:\${f.pitch.toStringAsFixed(1)}°  '
            'R:\${f.roll.toStringAsFixed(1)}°',
            style: const TextStyle(color: Colors.white70, fontSize: 10,
                fontFamily: 'monospace'),
          ),
          if (f.lastError.isNotEmpty)
            Text('ERR: \${f.lastError.substring(0, f.lastError.length.clamp(0, 40))}',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 9)),
        ],
      ),
    );
  }
}
