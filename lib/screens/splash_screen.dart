import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/music_library_notifier.dart';
import 'library_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final musicLibraryNotifier = Provider.of<MusicLibraryNotifier>(context, listen: false);

    // Give a short delay for splash screen visibility (optional)
    await Future.delayed(const Duration(seconds: 1));

    await musicLibraryNotifier.loadSongs(); // This also handles permission requests

    if (mounted) {
      if (musicLibraryNotifier.errorMessage != null) {
        // Handle permission denial or loading error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(musicLibraryNotifier.errorMessage!)),
        );
        // You might want to provide an option to retry or go to settings here
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LibraryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for your app logo
            Icon(Icons.music_note, size: 100, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              'URS Player',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(
              'Loading UR music...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}