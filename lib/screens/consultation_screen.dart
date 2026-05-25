// ---------------------------------------------------------------------------
// consultation_screen.dart
//
// THE MAIN SCREEN – matches the mockup exactly:
//
//  ┌──────────────────────────────────────┐
//  │  [FaceShape] [Occasion] [HairLength] │  ← filter chips
//  │  [ChangeType]                        │
//  │                                      │
//  │        LIVE CAMERA PREVIEW           │  ← camera feed
//  │      + hair overlay PNG on top       │
//  │                                      │
//  │  ┌── Overlay Opacity ────────── 65%┐ │  ← opacity panel
//  │  │  ────────●──────────────────── │ │
//  │  │  [Low] [Med] [High]  □ Default │ │
//  │  └────────────────────────────────┘ │
//  │  POPULAR STYLES FOR YOU  4 Matches  │
//  │  [Card1] [Card2] [Card3] [Card4]   │  ← style cards
//  ├──────────────────────────────────────┤
//  │  [RECENT]   [● Capture]   [↺ Undo] │  ← action bar
//  │  ⓘ Disclaimer...                   │
//  └──────────────────────────────────────┘
// ---------------------------------------------------------------------------

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/consultation_provider.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/opacity_panel.dart';
import '../widgets/profile_filter_bar.dart';
import '../widgets/style_card_list.dart';
import 'setup_screen.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  String? _cameraError;

  // This key wraps the camera + overlay Stack so we can screenshot it on capture
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // ── Camera initialisation ─────────────────────────────────────────────────

  Future<void> _initCamera() async {
    // 1. Ask for camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _cameraError = 'Camera permission denied.\nPlease enable it in device settings.');
      return;
    }

    // 2. Get list of available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _cameraError = 'No camera found on this device.');
      return;
    }

    // 3. Use the FRONT camera so the client sees their own face
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    // 4. Create the controller and initialise it
    _cameraController = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false, // no audio needed
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      setState(() => _cameraError = 'Camera error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top app bar ─────────────────────────────────────────────
            _TopBar(),

            // ── Profile filter chips ────────────────────────────────────
            const ProfileFilterBar(),

            // ── Camera + overlay (fills remaining space) ────────────────
            Expanded(
              child: Stack(
                children: [
                  // Camera feed (or placeholder)
                  _buildCameraArea(),

                  // Overlay + controls on top of camera
                  _buildOverlayControls(),
                ],
              ),
            ),

            // ── Bottom action bar ───────────────────────────────────────
            BottomActionBar(
              previewKey: _previewKey,
              cameraController: _cameraController,
            ),
          ],
        ),
      ),
    );
  }

  // ── Camera area (full bleed behind everything) ────────────────────────────

  Widget _buildCameraArea() {
    if (_cameraError != null) {
      return Container(
        color: Colors.grey.shade900,
        alignment: Alignment.center,
        child: Text(
          _cameraError!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      );
    }

    if (!_cameraReady) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Color(0xFF4A90D9)),
      );
    }

    // RepaintBoundary lets us take a screenshot of exactly this widget tree
    return RepaintBoundary(
      key: _previewKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera feed
          CameraPreview(_cameraController!),

          // Hair overlay PNG (only visible when a style is selected)
          _HairOverlay(cameraController: _cameraController),
        ],
      ),
    );
  }

  // ── Opacity panel + style card list sit on top of camera ─────────────────

  Widget _buildOverlayControls() {
    return Consumer<ConsultationProvider>(
      builder: (_, provider, __) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Opacity panel (toggleable)
            if (provider.opacityPanelVisible) ...[
              const OpacityPanel(),
              const SizedBox(height: 8),
            ],

            // Style card row
            const StyleCardList(),

            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

// ── Hair overlay widget ───────────────────────────────────────────────────────
// Renders the selected style's PNG on top of the camera at the saved opacity.

class _HairOverlay extends StatelessWidget {
  final CameraController? cameraController;
  const _HairOverlay({required this.cameraController});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsultationProvider>();
    final style    = provider.activeStyle;

    if (style == null) return const SizedBox.shrink();

    return Opacity(
      opacity: provider.opacity,
      child: Image.asset(
        style.overlayAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Show a semi-transparent placeholder if the overlay PNG doesn't exist yet
        errorBuilder: (_, __, ___) => Container(
          color: Colors.brown.withOpacity(0.15),
          alignment: Alignment.center,
          child: Text(
            '[ ${style.name} overlay ]',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar with title + settings icon ───────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
      child: Row(
        children: [
          const Text(
            'StyleSync',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          // Settings icon → opens stylist setup screen
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SetupScreen()),
            ),
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: 'Stylist setup',
          ),
        ],
      ),
    );
  }
}
