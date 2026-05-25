// ---------------------------------------------------------------------------
// consultation_provider.dart
//
// This is the "brain" of the app.  It holds all the data that screens need
// and notifies them whenever something changes.
//
// Think of it like a shared whiteboard that every screen can read and write.
// ---------------------------------------------------------------------------

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hair_style.dart';
import '../models/style_profile.dart';
import '../data/styles_data.dart';

class ConsultationProvider extends ChangeNotifier {
  // ── Profile filters ────────────────────────────────────────────────────────
  StyleProfile _profile = const StyleProfile(
    faceShape: 'Oval',
    occasion: 'Wedding',
    hairLength: 'Medium',
    changeType: 'Layers',
  );

  StyleProfile get profile => _profile;

  // ── Styles list derived from profile ──────────────────────────────────────
  List<HairStyle> get styles => getStylesForProfile(_profile);

  // ── Which style card is currently selected ────────────────────────────────
  HairStyle? _activeStyle;
  HairStyle? get activeStyle => _activeStyle;

  // ── Overlay opacity (0.0 = invisible, 1.0 = fully opaque) ────────────────
  // Default is 0.65 (65%) to match the mockup
  double _opacity = 0.65;
  double get opacity => _opacity;

  // Whether the opacity panel is currently expanded / visible
  bool _opacityPanelVisible = true;
  bool get opacityPanelVisible => _opacityPanelVisible;

  // ── Last captured image (shown as the RECENT thumbnail) ──────────────────
  Uint8List? _lastCapture;
  Uint8List? get lastCapture => _lastCapture;

  // ── Initialise: load saved opacity for current profile ───────────────────
  Future<void> init() async {
    await _loadOpacity();
    // Select the first style automatically so the overlay shows immediately
    if (styles.isNotEmpty) {
      _activeStyle = styles.first;
    }
    notifyListeners();
  }

  // ── Profile filter updates ────────────────────────────────────────────────

  void setFaceShape(String value) {
    _profile = _profile.copyWith(faceShape: value);
    _onProfileChanged();
  }

  void setOccasion(String value) {
    _profile = _profile.copyWith(occasion: value);
    _onProfileChanged();
  }

  void setHairLength(String value) {
    _profile = _profile.copyWith(hairLength: value);
    _onProfileChanged();
  }

  void setChangeType(String value) {
    _profile = _profile.copyWith(changeType: value);
    _onProfileChanged();
  }

  void _onProfileChanged() async {
    // When profile changes, auto-select first style and reload saved opacity
    _activeStyle = styles.isNotEmpty ? styles.first : null;
    await _loadOpacity();
    notifyListeners();
  }

  // ── Style selection ───────────────────────────────────────────────────────

  void selectStyle(HairStyle style) {
    _activeStyle = style;
    notifyListeners();
  }

  // ── Opacity control ───────────────────────────────────────────────────────

  void setOpacity(double value) {
    _opacity = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Quick-set buttons: Low = 30%, Med = 55%, High = 80%
  void setOpacityPreset(String preset) {
    switch (preset) {
      case 'Low':  _opacity = 0.30; break;
      case 'Med':  _opacity = 0.55; break;
      case 'High': _opacity = 0.80; break;
    }
    notifyListeners();
  }

  /// Save the current opacity as the default for this profile so next session
  /// it loads automatically (User Story 3).
  Future<void> saveOpacityAsDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('opacity_${_profile.storageKey}', _opacity);
  }

  Future<void> _loadOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the saved value; fall back to 0.65 if nothing is saved yet
    _opacity = prefs.getDouble('opacity_${_profile.storageKey}') ?? 0.65;
  }

  void toggleOpacityPanel() {
    _opacityPanelVisible = !_opacityPanelVisible;
    notifyListeners();
  }

  // ── Capture ───────────────────────────────────────────────────────────────

  void setLastCapture(Uint8List imageBytes) {
    _lastCapture = imageBytes;
    notifyListeners();
  }

  // ── Undo (clear active style) ────────────────────────────────────────────

  void clearActiveStyle() {
    _activeStyle = null;
    notifyListeners();
  }
}
