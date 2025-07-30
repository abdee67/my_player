import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_player/models/lyricLine.dart';
import 'package:provider/provider.dart';
import '../notifiers/audio_player_notifier.dart';
import '../notifiers/music_library_notifier.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';
import 'settings_screen.dart'; // Import for navigation

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicLibraryNotifier = Provider.of<MusicLibraryNotifier>(context);
    final audioPlayerNotifier = Provider.of<AudioPlayerNotifier>(context);
    final AudioPlayer myPlayerInstance = AudioPlayer();
    final List<LyricLine> myParsedLYRICS = [LyricLine('', Duration.zero)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Music Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content: List of songs
          Consumer<MusicLibraryNotifier>(
            builder: (context, notifier, child) {
              if (notifier.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (notifier.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(notifier.errorMessage!),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => notifier.loadSongs(),
                        child: const Text('Retry'),
                      ),
                    ], 
                  ),
                );
              }
              if (notifier.songs.isEmpty) {
                return const Center(
                    child: Text('No music found on your device.'));
              }
              return ListView.builder(
                padding: EdgeInsets.only(
                    bottom: audioPlayerNotifier.currentSong != null
                        ? 80.0
                        : 0), // Adjust padding if mini-player is visible
                itemCount: notifier.songs.length,
                itemBuilder: (context, index) {
                  final song = notifier.songs[index];
                  return ListTile(
                    leading: song.albumArt != null
                        ? CircleAvatar(
                            backgroundImage: MemoryImage(song.albumArt!))
                        : CircleAvatar(
                            backgroundImage: const AssetImage('assets/default_album_art.png'),
                          ),
                    title: Text(song.title),
                    subtitle: Text('${song.artist} - ${song.album}'),
                    onTap: () {
                      // Set the playlist for auto-continue functionality
                      audioPlayerNotifier.setPlaylist(notifier.songs,
                          startIndex: index);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => PlayerScreen(
                                  audioPlayer: myPlayerInstance,
                                  lyrics: myParsedLYRICS,
                                )),
                      );
                    },
                  );
                },
              );
            },
          ),

          // Mini-player at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Consumer<AudioPlayerNotifier>(
              builder: (context, notifier, child) {
                if (notifier.currentSong != null) {
                  return MiniPlayer(
                    song: notifier.currentSong!,
                    isPlaying: notifier.isPlaying,
                    onPlayPause: () {
                      if (notifier.isPlaying) {
                        notifier.pauseSong();
                      } else {
                        notifier.resumeSong();
                      }
                    },
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => PlayerScreen(audioPlayer: myPlayerInstance,lyrics: myParsedLYRICS,)),
                      );
                    },
                  );
                }
                return const SizedBox
                    .shrink(); // Hide mini-player if no song is playing
              },
            ),
          ),
        ],
      ),
    );
  }
}
