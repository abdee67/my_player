import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_player/models/lyricLine.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../notifiers/audio_player_notifier.dart';
import '../notifiers/lyrics_notifier.dart';
import '../notifiers/music_library_notifier.dart';

class PlayerScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final List<LyricLine> lyrics;
  const PlayerScreen(
      {super.key, required this.audioPlayer, required this.lyrics});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AudioPlayerNotifier _audioPlayerNotifier;
  late LyricsNotifier _lyricsNotifier;
  late MusicLibraryNotifier _musicLibraryNotifier;

  // Animation controllers for modern UI
  late AnimationController _albumArtController;
  late AnimationController _fadeController;
  late Animation<double> _albumArtAnimation;
  late Animation<double> _fadeAnimation;
  bool _isFetchingLyrics = false;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int _currentLyricIndex = 0; // The index of the currently active lyric line

  // Track current song to avoid duplicate lyrics fetching
  String? _currentSongId;

  @override
  void initState() {
    super.initState();
    _audioPlayerNotifier = Provider.of<AudioPlayerNotifier>(
      context,
      listen: false,
    );
    _lyricsNotifier = Provider.of<LyricsNotifier>(context, listen: false);
    _musicLibraryNotifier = Provider.of<MusicLibraryNotifier>(
      context,
      listen: false,
    );

    // Initialize animation controllers
    _albumArtController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _albumArtAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _albumArtController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animations
    _albumArtController.forward();
    _fadeController.forward();

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndFetchLyrics();
      _updateCurrentSongIndex(widget.audioPlayer.position);
    });
    widget.audioPlayer.positionStream.listen((position) {
      _updateCurrentSongIndex(position);
      // Always center the current lyric line, even if index doesn't change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _itemScrollController.scrollTo(
          index: _currentLyricIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for changes in the current song to fetch new lyrics
    _audioPlayerNotifier.addListener(_onAudioPlayerChanged);
  }

  @override
  void dispose() {
    _audioPlayerNotifier.removeListener(_onAudioPlayerChanged);
    _albumArtController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onAudioPlayerChanged() {
    // Check if song changed
    final currentSong = _audioPlayerNotifier.currentSong;
    if (currentSong?.id != _currentSongId) {
      setState(() => _currentLyricIndex = 0); // Reset index
  //    _itemScrollController.jumpTo(index: 0);
      _checkAndFetchLyrics();
      _updateCurrentSongIndex(widget.audioPlayer.position);
      _albumArtController.stop();
      _fadeController.reset();
      _albumArtController.forward();
      _fadeController.forward();
    } // Scroll to top when song change
  }

  void _checkAndFetchLyrics() async {
    if (_isFetchingLyrics) return;
    _isFetchingLyrics = true;
    final currentSong = _audioPlayerNotifier.currentSong;
    if (currentSong != null) {
      await _lyricsNotifier.fetchAndParseLyrics(currentSong);
    } else {
      _lyricsNotifier.clearLyrics();
    }
    _isFetchingLyrics = false;
  }

  void _updateCurrentSongIndex(Duration currentPosition) {
    final lyrics = _lyricsNotifier.currentLyrics;
    if (lyrics.isEmpty) return;
    int newIndex = 0;
    for (int i = 0; i < lyrics.length; i++) {
      final line = lyrics[i];
      final timestamp = line['time'] as Duration;
      if (currentPosition >= timestamp) {
        if (i + 1 < lyrics.length &&
            currentPosition < (lyrics[i + 1]['time'] as Duration)) {
          newIndex = i;
          break;
        } else if (i + 1 == lyrics.length) {
          newIndex = i;
          break;
        }
      }
    }
    if (newIndex != _currentLyricIndex) {
      setState(() => _currentLyricIndex = newIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _itemScrollController.scrollTo(
          index: newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      });
    }
  }

  void _playNextSong() {
    _audioPlayerNotifier.playNext();
  }

  void _playPreviousSong() {
    _audioPlayerNotifier.playPrevious();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  /// Seek to a specific lyric time
  void _seekToLyricTime(Duration time) {
    _audioPlayerNotifier.seek(time);
    _updateCurrentSongIndex(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AudioPlayerNotifier>(
        builder: (context, audioNotifier, child) {
          return Stack(
            children: [
              // Blurred Album Art Background
              if (audioNotifier.currentSong?.albumArt != null)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Image.memory(
                      audioNotifier.currentSong!.albumArt!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade900,
                          Colors.purple.shade900,
                          Colors.black,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

              // Dark overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Modern App Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lyrics',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  audioNotifier.currentSong?.title ??
                                      'No Song Playing',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lyrics Display Area
                    Expanded(
                      child: Consumer<LyricsNotifier>(
                        builder: (context, lyricsNotifier, child) {
                          if (lyricsNotifier.isLoadingLyrics) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: const SpinKitSpinningLines(
                                        color: Colors.white, size: 40),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading lyrics...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (lyricsNotifier.lyricsErrorMessage != null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: CircleAvatar(
                                        foregroundImage: const AssetImage(
                                          'assets/default_album_art.png',
                                        ),
                                      )),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Gotta guess for this one',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    lyricsNotifier.lyricsErrorMessage!,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          final lyrics = lyricsNotifier.currentLyrics;
                          if (lyrics.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: Icon(
                                      Icons.lyrics,
                                      size: 40,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Gotta guess for this one',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enjoy the music!',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Responsive font size and padding
                          final mediaQuery = MediaQuery.of(context);
                          final screenWidth = mediaQuery.size.width;
                          final fontSize = screenWidth < 400
                              ? 14.0
                              : (screenWidth < 600 ? 18.0 : 22.0);
                          final currentFontSize = fontSize + 4;
                          final linePadding = screenWidth < 400
                              ? 4.0
                              : (screenWidth < 600 ? 8.0 : 12.0);

                          return Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: linePadding),
                            child: ScrollablePositionedList.builder(
                              itemScrollController: _itemScrollController,
                              itemPositionsListener: _itemPositionsListener,
                              itemCount: lyrics.length,
                              itemBuilder: (context, index) {
                                final lyric = lyrics[index];
                                final isCurrent = index == _currentLyricIndex;
                                return GestureDetector(
                                  onTap: () {
                                    final lyricTime = lyric['time'] as Duration;
                                    _seekToLyricTime(lyricTime);
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      _itemScrollController.scrollTo(
                                        index: index,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        alignment: 0.5,
                                      );
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: linePadding / 2),
                                    child: Text(
                                      lyric['text'] as String,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isCurrent
                                            ? currentFontSize
                                            : fontSize,
                                        color: isCurrent
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.7),
                                        fontWeight: isCurrent
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        height: 1.3,
                                        letterSpacing: isCurrent ? -0.2 : 0.0,
                                        shadows: isCurrent
                                            ? [
                                                Shadow(
                                                  color: Colors.black
                                                      .withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ]
                                            : [],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Modern Bottom Controls
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Playback Slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.2),
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              trackHeight: 3,
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                            ),
                            child: Slider(
                              min: 0.0,
                              max: audioNotifier.totalDuration.inMilliseconds
                                  .toDouble(),
                              value: audioNotifier
                                  .currentPosition.inMilliseconds
                                  .toDouble()
                                  .clamp(
                                    0.0,
                                    audioNotifier.totalDuration.inMilliseconds
                                        .toDouble(),
                                  ),
                              onChanged: (value) {
                                audioNotifier.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                            ),
                          ),

                          // Time display
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(
                                    audioNotifier.currentPosition,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDuration(audioNotifier.totalDuration),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Playback Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  iconSize: 32,
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    color: Colors.white,
                                  ),
                                  onPressed: _playPreviousSong,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.purple.shade400,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade400.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  iconSize: 56,
                                  icon: Icon(
                                    audioNotifier.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    if (audioNotifier.isPlaying) {
                                      audioNotifier.pauseSong();
                                    } else {
                                      audioNotifier.resumeSong();
                                    }
                                  },
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  iconSize: 32,
                                  icon: const Icon(
                                    Icons.skip_next,
                                    color: Colors.white,
                                  ),
                                  onPressed: _playNextSong,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
