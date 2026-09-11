# StyleSync — Live Hairstyle Overlay Consultation App

A [Flutter](https://flutter.dev/) mobile/desktop app that overlays hairstyle previews on a live camera feed, letting users "try on" different hairstyles in real time before committing to a new look.

> Package name: `stylist_consult` · App description (from `pubspec.yaml`): *"StyleSync – live hairstyle overlay consultation app."*

## Features

- 📷 **Live camera preview** — uses the device camera to show a real-time video feed
- 💇 **Hairstyle overlays** — overlays hairstyle images (from `assets/overlays/`) on top of the live feed for a virtual try-on effect
- 💾 **Save results** — save captured photos to the device gallery
- ⚙️ **Permission handling** — requests camera/storage permissions gracefully
- 🌍 **Cross-platform** — built with Flutter, targeting Android, iOS, macOS, Windows, Linux, and web from a single codebase

## Tech Stack

Built with Flutter and the following key packages (see `pubspec.yaml`):

| Package | Purpose |
|---|---|
| [`camera`](https://pub.dev/packages/camera) | Access and stream the device camera |
| [`provider`](https://pub.dev/packages/provider) | State management |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Local key-value storage |
| [`gal`](https://pub.dev/packages/gal) | Save captured images to the device gallery |
| [`permission_handler`](https://pub.dev/packages/permission_handler) | Request camera/storage permissions |
| [`path_provider`](https://pub.dev/packages/path_provider) / [`path`](https://pub.dev/packages/path) | File system path handling |

## Project Structure

```
StyleCraftNewYou/
├── lib/                   # Dart application source code
├── assets/overlays/       # Hairstyle overlay images used in the live preview
├── android/ ios/ macos/   # Platform-specific native project files
├── windows/ linux/ web/
├── test/                  # Flutter/Dart tests
├── pubspec.yaml           # Project metadata and dependencies
└── analysis_options.yaml  # Dart/Flutter lint rules
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `>=3.0.0 <4.0.0`, per `pubspec.yaml`)
- A connected device, emulator/simulator, or a desktop/web target with camera access

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/jayanthi0901/StyleCraftNewYou.git
   cd StyleCraftNewYou
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on a connected device or emulator:
   ```bash
   flutter run
   ```
4. To build a release version for a specific platform:
   ```bash
   flutter build apk        # Android
   flutter build ios        # iOS
   flutter build windows    # Windows
   flutter build macos      # macOS
   flutter build linux      # Linux
   flutter build web        # Web
   ```

### Permissions

The app requests camera (and gallery/storage) permissions at runtime via `permission_handler`. Make sure to grant these when prompted, or the live overlay and photo-saving features won't work.

## Related Project

This app appears related to [StylePreview](https://github.com/jayanthi0901/StylePreview), a browser-based proof-of-concept for hairstyle preview using face-tracking — likely an earlier prototype of the same idea.

## Contributing

Issues and pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

## License

No license file is currently included in this repository. Add one (e.g. MIT) if you intend for others to reuse this code.
