// ---------------------------------------------------------------------------
// hair_style.dart
// Represents one hairstyle option shown in the "Popular Styles For You" row.
// ---------------------------------------------------------------------------

class HairStyle {
  /// Unique id, e.g. "soft_balayage"
  final String id;

  /// Display name shown under the card, e.g. "Soft Balayage"
  final String name;

  /// Path to the overlay PNG inside assets/overlays/, e.g. "assets/overlays/soft_balayage.png"
  /// This PNG is a transparent image of just the hair that sits on top of the camera feed.
  final String overlayAsset;

  /// Path to the thumbnail JPG/PNG shown in the style card, e.g. "assets/overlays/thumb_soft_balayage.jpg"
  final String thumbnailAsset;

  const HairStyle({
    required this.id,
    required this.name,
    required this.overlayAsset,
    required this.thumbnailAsset,
  });
}
