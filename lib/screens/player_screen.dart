import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Keep this import

import '../notifiers/audio_player_notifier.dart';
import '../notifiers/lyrics_notifier.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayerNotifier _audioPlayerNotifier;
  late LyricsNotifier _lyricsNotifier;
  final ScrollController _lyricsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _audioPlayerNotifier = Provider.of<AudioPlayerNotifier>(context, listen: false);
    _lyricsNotifier = Provider.of<LyricsNotifier>(context, listen: false);

    if (_audioPlayerNotifier.currentSong != null) {
      _lyricsNotifier.fetchAndParseLyrics(_audioPlayerNotifier.currentSong!);
    }

    // Listen to audio position changes to update lyrics UI
    _audioPlayerNotifier.addListener(() {
      _scrollToCurrentLyric(_audioPlayerNotifier.currentPosition);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for changes in the current song to fetch new lyrics
    _audioPlayerNotifier.addListener(_onSongChanged);
  }

  @override
  void dispose() {
    _audioPlayerNotifier.removeListener(_onSongChanged);
    _lyricsScrollController.dispose();
    super.dispose();
  }

  void _onSongChanged() {
    if (_audioPlayerNotifier.currentSong != null) {
      _lyricsNotifier.fetchAndParseLyrics(_audioPlayerNotifier.currentSong!);
    } else {
      _lyricsNotifier.clearLyrics();
    }
  }

  void _scrollToCurrentLyric(Duration currentPosition) {
    if (_lyricsNotifier.currentLyrics.isEmpty || !_lyricsScrollController.hasClients) {
      return;
    }

    int currentLineIndex = -1;
    for (int i = 0; i < _lyricsNotifier.currentLyrics.length; i++) {
      final lyric = _lyricsNotifier.currentLyrics[i];
      if (currentPosition >= lyric.time) {
        currentLineIndex = i;
      } else {
        break; // Lyrics are usually sorted by time
      }
    }

    if (currentLineIndex != -1) {
      // Calculate scroll offset to center the current line or bring it into view
      final double itemHeight = 30.0; // Approximate height of a single lyric line
      final double targetScrollOffset = currentLineIndex * itemHeight;

      if (_lyricsScrollController.position.pixels < targetScrollOffset ||
          _lyricsScrollController.position.pixels > targetScrollOffset + _lyricsScrollController.position.viewportDimension - itemHeight) {
        _lyricsScrollController.animateTo(
          targetScrollOffset - (MediaQuery.of(context).size.height * 0.3), // Offset to put it roughly in the middle
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
    // No need to call setState here, as the ListView builder will re-evaluate highlight based on position
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AudioPlayerNotifier>(
          builder: (context, notifier, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notifier.currentSong?.title ?? 'No Song Playing',
                  style: const TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  notifier.currentSong?.artist ?? '',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer<AudioPlayerNotifier>(
        builder: (context, audioNotifier, child) {
          return Column(
            children: [
              // Album Art (same as before)
              Container(
                height: MediaQuery.of(context).size.width * 0.7,
                width: MediaQuery.of(context).size.width * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: audioNotifier.currentSong?.albumArt != null
                      ? Image.memory(
                          audioNotifier.currentSong!.albumArt!,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/default_album_art.jpeg', // Add a default image in assets folder
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 30),

              // Playback Slider (same as before)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Slider(
                      min: 0.0,
                      max: audioNotifier.totalDuration.inMilliseconds.toDouble(),
                      value: audioNotifier.currentPosition.inMilliseconds.toDouble().clamp(
                            0.0,
                            audioNotifier.totalDuration.inMilliseconds.toDouble(),
                          ),
                      onChanged: (value) {
                        audioNotifier.seek(Duration(milliseconds: value.toInt()));
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(audioNotifier.currentPosition)),
                        Text(_formatDuration(audioNotifier.totalDuration)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Playback Controls (same as before)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 48,
                    icon: Icon(audioNotifier.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    onPressed: () {
                      if (audioNotifier.isPlaying) {
                        audioNotifier.pauseSong();
                      } else {
                        audioNotifier.resumeSong();
                      }
                    },
                  ),
                  // TODO: Add Next/Previous buttons and logic
                  IconButton(
                    iconSize: 48,
                    icon: const Icon(Icons.skip_next),
                    onPressed: () {
                      // Implement skip to next song logic
                      print("Next song (not implemented)");
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Custom Lyrics Display (REPLACED AMLV)
              Expanded(
                child: Consumer<LyricsNotifier>(
                  builder: (context, lyricsNotifier, child) {
                    if (lyricsNotifier.isLoadingLyrics) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (lyricsNotifier.lyricsErrorMessage != null) {
                      return Center(child: Text(lyricsNotifier.lyricsErrorMessage!));
                    }
                    if (lyricsNotifier.currentLyrics.isEmpty) {
                      return const Center(child: Text('Your not lucky my brodda(burna\'s voice).you gotta guess for this one dawg'));
                    }

                    // Use ListView.builder to display lyrics
                    return ListView.builder(
                      controller: _lyricsScrollController,
                      itemCount: lyricsNotifier.currentLyrics.length,
                      itemBuilder: (context, index) {
                        final lyric = lyricsNotifier.currentLyrics[index];
                        final isCurrentLine = audioNotifier.currentPosition.inMilliseconds >= lyric.time.inMilliseconds &&
                                              (index + 1 < lyricsNotifier.currentLyrics.length
                                                  ? audioNotifier.currentPosition.inMilliseconds < lyricsNotifier.currentLyrics[index + 1].time.inMilliseconds
                                                  : true); // Last line logic

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                          child: Text(
                            lyric.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isCurrentLine ? 22 : 18,
                              fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                              color: isCurrentLine ? Theme.of(context).colorScheme.primary : Colors.white54,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}