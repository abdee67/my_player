import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_player/core/audio/presentation/notifiers/audio_player_notifier.dart';
import 'package:my_player/core/media_library/presentation/notifiers/music_library_notifier.dart';
import 'package:my_player/core/media_library/presentation/widgets/album_art_widget.dart';
import 'package:my_player/core/media_library/presentation/widgets/library_header.dart';
import 'package:provider/provider.dart';

import 'dart:ui';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _search = '';
  SortType _sortType = SortType.title;
  final AudioPlayer myPlayerInstance = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    final musicLibraryNotifier = Provider.of<MusicLibraryNotifier>(context);
    final audioPlayerNotifier = Provider.of<AudioPlayerNotifier>(context);

    return Stack(
      children: [
        // Gradient background
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF232526),
                  Color(0xFF414345),
                  Color(0xFF000000)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        // Header: search, sort, refresh
        LibraryHeader(
          onSearch: (val) => setState(() => _search = val),
          onSort: (sortBy) => setState(() => _sortType = sortBy),
          onRefresh: () async => await musicLibraryNotifier.smartRefresh(),
          selectedSort: _sortType,
        ),
        // Main content: List of songs
        Padding(
          padding: const EdgeInsets.only(top: 80.0),
          child: Material(
            child: Consumer<MusicLibraryNotifier>(
              builder: (context, notifier, child) {
                if (notifier.isLoading) {
                  // Shimmer/skeleton loader
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 16),
                    itemCount: notifier.songs.length + 1,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade800,
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: SpinKitSpinningLines(
                                color: Colors.deepPurpleAccent,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        title: Container(
                          height: 16,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        subtitle: Container(
                          height: 12,
                          width: 9,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  );
                }
                if (notifier.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(notifier.errorMessage!,
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () =>
                              notifier.loadSongs(forceRefresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                // Filter and sort
                List songs = notifier.songs.where((song) {
                  final q = _search.toLowerCase();
                  return song.title.toLowerCase().contains(q) ||
                      song.artist.toLowerCase().contains(q) ||
                      song.album.toLowerCase().contains(q);
                }).toList();
                songs.sort((a, b) {
                  switch (_sortType) {
                    case SortType.title:
                      return a.title
                          .toLowerCase()
                          .compareTo(b.title.toLowerCase());
                    case SortType.artist:
                      return a.artist
                          .toLowerCase()
                          .compareTo(b.artist.toLowerCase());
                    case SortType.album:
                      return a.album
                          .toLowerCase()
                          .compareTo(b.album.toLowerCase());
                    case SortType.duration:
                      return a.duration.compareTo(b.duration);
                  }
                });
                if (songs.isEmpty) {
                  return const Center(
                    child: Text('No music found.',
                        style: TextStyle(color: Colors.white70)),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.only(
                    top: 0,
                    bottom: audioPlayerNotifier.currentSong != null ? 90.0 : 0,
                  ),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];

                    return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onLongPress: () {
                            showDialog(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog(
                                    backgroundColor: Colors.black87,
                                    title: Text(song.title,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Artist: ${song.artist}',
                                            style: const TextStyle(
                                                color: Colors.white70)),
                                        Text('Album: ${song.album}',
                                            style: const TextStyle(
                                                color: Colors.white70)),
                                        Text(
                                            'Duration: ${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                                color: Colors.white70)),
                                        const SizedBox(height: 12),
                                        Text('File: ${song.data}',
                                            style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 12)),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        child: const Text('Close',
                                            style: TextStyle(
                                                color:
                                                    Colors.deepPurpleAccent)),
                                      )
                                    ],
                                  );
                                });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ListTile(
                              leading: Hero(
                                tag: 'albumArt_${song.id}',
                                child: AlbumArtWidget(
                                  songId: int.tryParse(song.id) ?? 0,
                                  albumArt: notifier.songs[index].albumArt,
                                  radius: 28,
                                ),
                              ),
                              title: Text(song.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text('${song.artist} \n${song.album}',
                                  style: const TextStyle(color: Colors.white)),
                              hoverColor: (Color.alphaBlend(
                                  Colors.deepPurpleAccent.withOpacity(0.2),
                                  Colors.transparent)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (audioPlayerNotifier.currentSong?.id ==
                                          song.id &&
                                      audioPlayerNotifier.isPlaying)
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 1000),
                                      transform: Matrix4.rotationZ(
                                          audioPlayerNotifier.isPlaying
                                              ? 0.1
                                              : 0),
                                      width: 24,
                                      height: 24,
                                      child: Icon(
                                        Icons.graphic_eq,
                                        color: Colors.deepPurpleAccent,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                audioPlayerNotifier.setPlaylist(notifier.songs,
                                    startIndex: notifier.songs.indexOf(song));
                                audioPlayerNotifier.playSong(song);
                              },
                            ),
                          ),
                        ));
                  },
                );
              },
            ),
          ),
        ),

        // Mini media widget above bottom nav
        /**  Align(
          alignment: Alignment.bottomCenter,
          child: Consumer<AudioPlayerNotifier>(
            builder: (context, notifier, child) {
              if (notifier.currentSong != null) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MiniMediaWidget(
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
                            builder: (context) => PlayerScreen(
                              audioPlayer: myPlayerInstance,
                              lyrics: myParsedLYRICS,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        */
      ],
    );
  }
}
