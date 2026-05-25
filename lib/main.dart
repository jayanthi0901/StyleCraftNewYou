// ---------------------------------------------------------------------------
// main.dart
//
// App entry point.
//
// Sets up the Provider (shared data store) and launches the consultation screen.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/consultation_provider.dart';
import 'screens/consultation_screen.dart';

void main() async {
  // Required before using any plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait so the hair overlays align correctly
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const StyleSyncApp());
}

class StyleSyncApp extends StatelessWidget {
  const StyleSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Create the provider once here; all screens below can access it
      create: (_) => ConsultationProvider()..init(),
      child: MaterialApp(
        title: 'StyleSync',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90D9)),
          useMaterial3: true,
          fontFamily: 'SF Pro Display', // falls back to system font on Android
        ),
        home: const ConsultationScreen(),
      ),
    );
  }
}
