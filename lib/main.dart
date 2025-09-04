import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart'; // Import media_kit
import 'package:my_player/core/audio/data/audio_player_service.dart';
import 'package:my_player/core/lyrics/data/lyrics_service.dart';
import 'package:my_player/core/media_library/data/music_library_service.dart';
import 'package:provider/provider.dart';

import 'core/audio/presentation/notifiers/audio_player_notifier.dart';
import 'core/lyrics/presentation/notifiers/lyrics_notifier.dart';
import 'core/media_library/presentation/notifiers/music_library_notifier.dart';
import 'features/home/presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize media_kit. This is crucial.
  MediaKit.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
    return SafeArea(
      child: MaterialApp(
        title: 'UR Player',
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
      ),
    );
  }
}
