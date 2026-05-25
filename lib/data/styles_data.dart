// ---------------------------------------------------------------------------
// styles_data.dart
// Static lookup: given a profile, return the matching list of HairStyle options.
//
// HOW TO CUSTOMISE:
//   1. Add your own PNG overlays to  assets/overlays/
//   2. Add a HairStyle entry here with the matching asset paths
//   3. Add an entry in _styleMap so the profile key maps to those styles
// ---------------------------------------------------------------------------

import '../models/hair_style.dart';
import '../models/style_profile.dart';

// ── All available styles ─────────────────────────────────────────────────────
// overlayAsset  → transparent PNG placed over the camera (just the hair)
// thumbnailAsset→ reference photo shown in the style card strip

const HairStyle kSoftBalayage = HairStyle(
  id: 'bob',
  name: 'Textured_bob',
  overlayAsset: 'assets/overlays/textured_bob.png',
  thumbnailAsset: 'assets/thumbnails/soft_balayage_thumb.jpg',
);

const HairStyle kTexturedLob = HairStyle(
  id: 'tinkerbell',
  name: 'Tinker bells',
  overlayAsset: 'assets/overlays/Tinkerbell_hair_1024.png',
  thumbnailAsset: 'assets/thumbnails/Tinkerbell_hair_1024.png',
);

const HairStyle kCurtainBangs = HairStyle(
  id: 'fringes',
  name: 'Short fringes',
  overlayAsset: 'assets/overlays/fringes_hair_1024.png',
  thumbnailAsset: 'assets/thumbnails/fringes_hair_1024.png',
);

const HairStyle kFaceFramingLayers = HairStyle(
  id: 'face_framing_layers',
  name: 'Face Framing',
  overlayAsset: 'assets/overlays/face_framing_overlay.png',
  thumbnailAsset: 'assets/overlays/face_framing_thumb.jpg',
);

const HairStyle kButtercupHighlights = HairStyle(
  id: 'buttercup_highlights',
  name: 'Buttercup Highlights',
  overlayAsset: 'assets/overlays/buttercup_highlights_overlay.png',
  thumbnailAsset: 'assets/overlays/buttercup_highlights_thumb.jpg',
);

const HairStyle kClassicLayers = HairStyle(
  id: 'classic_layers',
  name: 'Classic Layers',
  overlayAsset: 'assets/overlays/classic_layers_overlay.png',
  thumbnailAsset: 'assets/overlays/classic_layers_thumb.jpg',
);

const HairStyle kSoftFringe = HairStyle(
  id: 'soft_fringe',
  name: 'Soft Fringe',
  overlayAsset: 'assets/overlays/soft_fringe_overlay.png',
  thumbnailAsset: 'assets/overlays/soft_fringe_thumb.jpg',
);

// ── Profile → Styles map ─────────────────────────────────────────────────────
// Key format: faceShape_occasion_hairLength_changeType  (all lowercase, spaces→_)
//
// Add as many profile combinations as you need.  For any profile not listed
// the app falls back to _defaultStyles.

const List<HairStyle> _defaultStyles = [
  kSoftBalayage,
  kTexturedLob,
  kCurtainBangs,
  kFaceFramingLayers,
];

const Map<String, List<HairStyle>> _styleMap = {
  // Oval + Wedding + Medium + Layers  (the mockup default)
  'oval_wedding_medium_layers': [
    kSoftBalayage,
    kTexturedLob,
    kCurtainBangs,
    kFaceFramingLayers,
  ],

  // Oval + Wedding + Medium + Highlights
  'oval_wedding_medium_highlights': [
    kButtercupHighlights,
    kSoftBalayage,
    kFaceFramingLayers,
  ],

  // Oval + Everyday + Medium + Layers
  'oval_everyday_medium_layers': [
    kClassicLayers,
    kTexturedLob,
    kFaceFramingLayers,
  ],

  // Round + Party + Short + Fringe
  'round_party_short_fringe': [
    kCurtainBangs,
    kSoftFringe,
    kTexturedLob,
  ],
};

// ── Public API ───────────────────────────────────────────────────────────────

/// Returns the list of styles that match [profile].
/// Falls back to [_defaultStyles] when no exact match exists.
List<HairStyle> getStylesForProfile(StyleProfile profile) {
  return _styleMap[profile.storageKey] ?? _defaultStyles;
}

// ── Dropdown option lists (used by the filter bar) ───────────────────────────

const List<String> kFaceShapes = ['Oval', 'Round', 'Square', 'Heart', 'Diamond'];
const List<String> kOccasions  = ['Wedding', 'Everyday', 'Party', 'Work', 'Date Night'];
const List<String> kHairLengths = ['Short', 'Medium', 'Long'];
const List<String> kChangeTypes = ['Layers', 'Fringe', 'Highlights', 'Shorter', 'Colour'];
