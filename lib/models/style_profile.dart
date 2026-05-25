// ---------------------------------------------------------------------------
// style_profile.dart
// The four filter dimensions the stylist sets before showing styles.
// Together they form a "profile key" used to look up saved opacity settings.
// ---------------------------------------------------------------------------

class StyleProfile {
  final String faceShape;   // e.g. "Oval", "Round", "Square", "Heart"
  final String occasion;    // e.g. "Wedding", "Everyday", "Party"
  final String hairLength;  // e.g. "Short", "Medium", "Long"
  final String changeType;  // e.g. "Layers", "Fringe", "Highlights", "Shorter"

  const StyleProfile({
    required this.faceShape,
    required this.occasion,
    required this.hairLength,
    required this.changeType,
  });

  /// Used as the key in SharedPreferences to save opacity per profile.
  String get storageKey =>
      '${faceShape}_${occasion}_${hairLength}_${changeType}'
          .toLowerCase()
          .replaceAll(' ', '_');

  StyleProfile copyWith({
    String? faceShape,
    String? occasion,
    String? hairLength,
    String? changeType,
  }) {
    return StyleProfile(
      faceShape: faceShape ?? this.faceShape,
      occasion: occasion ?? this.occasion,
      hairLength: hairLength ?? this.hairLength,
      changeType: changeType ?? this.changeType,
    );
  }
}
