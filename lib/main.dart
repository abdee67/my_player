import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/audio/background/audio_handler.dart';
import 'features/home/presentation/screens/splash_screen.dart';
import 'provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audioHandler = await initPlayerAudioHandler();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> clearAllSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
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
