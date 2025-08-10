import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_player/screens/library_screen.dart';
import 'package:my_player/screens/player_screen.dart';
import '../screens/music_list_screen.dart';
import '../screens/now_playing_screen.dart';
import '../screens/internal_storage_screen.dart';
import '../screens/albums_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const LibraryScreen(),
    PlayerScreen(audioPlayer: AudioPlayer(), lyrics: const []),
    const InternalStorageScreen(),
    const AlbumsScreen(),
    const SearchScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Music'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'Now Playing'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Storage'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Albums'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
