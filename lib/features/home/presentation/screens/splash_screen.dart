import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:my_player/core/media_library/presentation/widgets/library_header.dart';
import 'package:my_player/features/home/presentation/widgets/bottom_nav.dart';
import 'package:provider/provider.dart';
import 'package:my_player/core/media_library/presentation/notifiers/music_library_notifier.dart';

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
    final musicLibraryNotifier =
        Provider.of<MusicLibraryNotifier>(context, listen: false);

    // Give a short delay for splash screen visibility (optional)
    await Future.delayed(const Duration(seconds: 1));

    await musicLibraryNotifier
        .loadSongs(); // This also handles permission requests

    if (mounted) {
      if (musicLibraryNotifier.errorMessage != null) {
        // Handle permission denial or loading error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(musicLibraryNotifier.errorMessage!)),
        );
        // You might want to provide an option to retry or go to settings here
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BottomNav()),
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
            CircleAvatar(
              foregroundImage: const AssetImage('assets/default_album_art.png'),
              radius: 50,
            ),
            const SizedBox(height: 20),
            Text(
              'URS Player',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 30),
            const SpinKitSpinningLines(
              color: Colors.blue,
              size: 50,
            ),
            const SizedBox(height: 10),
            Text(
              'Loading UR Cool music...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
