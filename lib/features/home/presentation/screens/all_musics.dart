import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_player/core/media_library/presentation/widgets/album_art_widget.dart';
import 'dart:ui';
import 'package:my_player/core/media_library/presentation/widgets/library_header.dart';
import 'package:my_player/features/home/presentation/widgets/custom_refresh_indicator.dart';
import 'package:my_player/provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _search = '';
  SortType _sortType = SortType.title;

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(musicLibraryProvider);
    final libraryNotifier = ref.read(musicLibraryProvider.notifier);
    final audioState = ref.watch(audioPlayerProvider);
    final audioNotifier = ref.read(audioPlayerProvider.notifier);

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
          onRefresh: () {
            libraryNotifier.loadSongs();
          },
          selectedSort: _sortType,
        ),
        // Main content: List of songs
        Padding(
          padding: const EdgeInsets.only(top: 80.0),
          child: Material(
            child: Builder(
              builder: (context) {
                Future<void> onRefresh() => libraryNotifier.loadSongs();

                Widget buildLoadingList() => ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 16),
                      itemCount: libraryState.songs.length + 1,
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

                if (libraryState.isLoading) {
                  return WarpIndicator(
                      onRefresh: onRefresh, child: buildLoadingList());
                }

                if (libraryState.error != null) {
                  final errorChild = ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 32),
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(libraryState.error!,
                                style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => libraryNotifier.loadSongs(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  return WarpIndicator(onRefresh: onRefresh, child: errorChild);
                }

                // Filter and sort
                List songs = libraryState.songs.where((song) {
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

                Widget buildEmptyList() => ListView(
                      physics: const BouncingScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text('No music found.',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    );

                if (songs.isEmpty) {
                  return WarpIndicator(
                      onRefresh: onRefresh, child: buildEmptyList());
                }

                final list = ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: 0,
                    bottom: audioState.currentSong != null ? 90.0 : 0,
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
                                        Text('File: ${song.filePath}',
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
                                  albumArt: song.albumArt,
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
                                  if (audioState.currentSong?.id == song.id &&
                                      audioState.isPlaying)
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 1000),
                                      transform: Matrix4.rotationZ(
                                          audioState.isPlaying ? 0.1 : 0),
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
                              onTap: () async {
                                // all_musics.dart, inside onTap:
                                final startIndex =
                                    libraryState.songs.indexOf(song);

// Set playlist without autoplay (so UI can display selection but no sound starts)
                                await audioNotifier.setPlaylist(
                                    libraryState.songs,
                                    startIndex: startIndex,
                                    autoPlay: false);

// Fetch lyrics (await API response)
                                await ref
                                    .read(lyricsProvider.notifier)
                                    .fetchAndParseLyrics(song);

// Then start playback at the selected index
                                await audioNotifier.playAtIndex(startIndex);
                              },
                            ),
                          ),
                        ));
                  },
                );

                return WarpIndicator(onRefresh: onRefresh, child: list);
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
