import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/hair_style.dart';

class StyleProvider extends ChangeNotifier {
  List<HairStyle> _styles = [];
  HairOverlayState? _overlayState;
  bool _isLoaded = false;
  String? _activeCategory; // null = All

  // ─── Public getters ────────────────────────────────────────────────────
  bool get isLoaded => _isLoaded;
  List<HairStyle> get allStyles => _styles;
  HairOverlayState? get overlayState => _overlayState;
  HairStyle? get selectedStyle => _overlayState?.style;
  String? get activeCategory => _activeCategory;

  List<String> get categories {
    final cats = _styles.map((s) => s.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<HairStyle> get filteredStyles {
    if (_activeCategory == null || _activeCategory == 'All') return _styles;
    return _styles.where((s) => s.category == _activeCategory).toList();
  }

  // ─── Load ──────────────────────────────────────────────────────────────

  /// Call once from [main] or a splash screen before the camera opens.
  Future<void> load() async {
    if (_isLoaded) return;
    _styles = await HairStyle.loadAll();
    if (_styles.isNotEmpty) {
      _overlayState = HairOverlayState(style: _styles.first);
    }
    _isLoaded = true;
    notifyListeners();
  }

  // ─── Selection ─────────────────────────────────────────────────────────

  void selectStyle(HairStyle style) {
    // Reset user adjustments when switching styles
    _overlayState = HairOverlayState(style: style);
    notifyListeners();
  }

  void selectCategory(String? category) {
    _activeCategory = category == 'All' ? null : category;
    notifyListeners();
  }

  // ─── Overlay drag ──────────────────────────────────────────────────────

  /// Called by [GestureDetector.onPanUpdate] on the overlay widget.
  void onOverlayDrag(Offset delta) {
    if (_overlayState == null) return;
    _overlayState = _overlayState!.copyWith(
      dragOffset: _overlayState!.dragOffset + delta,
    );
    notifyListeners();
  }

  // ─── Overlay scale ─────────────────────────────────────────────────────

  /// Called by [GestureDetector.onScaleUpdate].
  /// [scale] is the raw scale factor from the gesture (1.0 = no change).
  void onOverlayScale(double scale) {
    if (_overlayState == null) return;
    final newZoom =
        (_overlayState!.zoomMultiplier * scale).clamp(0.3, 2.5);
    _overlayState = _overlayState!.copyWith(zoomMultiplier: newZoom);
    notifyListeners();
  }

  /// Directly set the absolute zoom value (used by the new overlay widget).
  void setZoom(double zoom) {
    if (_overlayState == null) return;
    _overlayState = _overlayState!.copyWith(zoomMultiplier: zoom.clamp(0.3, 2.5));
    notifyListeners();
  }

  // ─── Reset ─────────────────────────────────────────────────────────────

  void resetOverlay() {
    if (_overlayState == null) return;
    _overlayState = _overlayState!.reset();
    notifyListeners();
  }
}
