import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart'; // Import media_kit
import 'package:provider/provider.dart';

import 'notifiers/audio_player_notifier.dart';
import 'notifiers/lyrics_notifier.dart';
import 'notifiers/music_library_notifier.dart';
import 'screens/splash_screen.dart';
import 'services/audio_player_service.dart';
import 'services/lyrics_service.dart';
import 'services/music_library_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize media_kit. This is crucial.
  MediaKit.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        // Services (usually provided as singletons)
        Provider<AudioPlayerService>(create: (_) => AudioPlayerService()),
        Provider<MusicLibraryService>(create: (_) => MusicLibraryService()),
        Provider<LyricsService>(create: (_) => LyricsService()),

        // Notifiers (ChangeNotifier for UI updates)
        ChangeNotifierProvider<AudioPlayerNotifier>(
          create: (context) => AudioPlayerNotifier(
            Provider.of<AudioPlayerService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<MusicLibraryNotifier>(
          create: (context) => MusicLibraryNotifier(
            Provider.of<MusicLibraryService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<LyricsNotifier>(
          create: (context) => LyricsNotifier(
            Provider.of<LyricsService>(context, listen: false),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey.shade900,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
        cardColor: Colors.grey.shade800,
      ),
      themeMode: ThemeMode.dark, // Or ThemeMode.light, or ThemeMode.system
      home: const SplashScreen(),
    );
  }
}
