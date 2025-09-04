import 'package:flutter/material.dart';
import 'package:my_player/core/audio/presentation/notifiers/audio_player_notifier.dart';
import 'package:my_player/features/albums/presentation/screens/albums_screen.dart';
import 'package:my_player/features/home/presentation/screens/all_musics.dart';
import 'package:my_player/features/internal_storage/presentation/screens/internal_storage_screen.dart';
import 'package:my_player/features/now_playing/presentation/screens/player_screen.dart';
import 'package:my_player/features/search/presentation/screens/search_screen.dart';
import 'package:my_player/features/settings/presentation/screens/settings_screen.dart';
// Removed unused import: just_audio
import 'package:provider/provider.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Get the shared AudioPlayer instance from the AudioPlayerNotifier
    final player =
        Provider.of<AudioPlayerNotifier>(context, listen: false).player;
    final List<Widget> screens = [
      const LibraryScreen(),
      PlayerScreen(audioPlayer: player, lyrics: const []),
      const InternalStorageScreen(),
      const AlbumsScreen(),
      const SearchScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.library_music), label: 'Music'),
          BottomNavigationBarItem(
              icon: Icon(Icons.play_circle), label: 'Now Playing'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Storage'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Albums'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
