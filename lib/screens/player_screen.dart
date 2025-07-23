import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

import '../notifiers/audio_player_notifier.dart';
import '../notifiers/lyrics_notifier.dart';
import '../notifiers/music_library_notifier.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

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

  // Track current song to avoid duplicate lyrics fetching
  String? _currentSongId;
  int _currentSongIndex = -1;

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
      _updateCurrentSongIndex();
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
    if (currentSong != null && currentSong.id != _currentSongId) {
      print("Song changed from $_currentSongId to ${currentSong.id}");
      _currentSongId = currentSong.id;
      _checkAndFetchLyrics();
      _updateCurrentSongIndex();
    }
  }

  void _checkAndFetchLyrics() {
    final currentSong = _audioPlayerNotifier.currentSong;
    if (currentSong != null) {
      print(
        "Fetching lyrics for: ${currentSong.title} by ${currentSong.artist}",
      );
      _lyricsNotifier.fetchAndParseLyrics(currentSong);
    } else {
      print("No current song, clearing lyrics");
      _lyricsNotifier.clearLyrics();
    }
  }

  void _updateCurrentSongIndex() {
    final currentSong = _audioPlayerNotifier.currentSong;
    if (currentSong != null) {
      final songs = _musicLibraryNotifier.songs;
      _currentSongIndex = songs.indexWhere((song) => song.id == currentSong.id);
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
  }

  /// Format time for display
  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
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
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
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
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
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
                                    child: Icon(
                                      Icons.music_note,
                                      size: 40,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No lyrics available',
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

                          if (lyricsNotifier.currentLyrics.isEmpty) {
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
                                    'No lyrics available',
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
                          

                          // Find current lyric index
                          int currentIndex = -1;
                          for (int i = 0;
                              i < lyricsNotifier.currentLyrics.length;
                              i++) {
                            final lyric = lyricsNotifier.currentLyrics[i];
                            final lyricTime = lyric['time'] as Duration;
                            if (audioNotifier.currentPosition >= lyricTime) {
                              currentIndex = i;
                            } else {
                              break;
                            }
                          }

                          return Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              children: [
                                // Current line (prominent and centered)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        currentIndex >= 0 &&
                                                currentIndex <
                                                    lyricsNotifier
                                                        .currentLyrics.length
                                            ? lyricsNotifier
                                                    .currentLyrics[currentIndex]
                                                ['text'] as String
                                            : '',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                                // Next line (if exists)
                                if (currentIndex >= 0 &&
                                    currentIndex + 1 <
                                        lyricsNotifier.currentLyrics.length)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      lyricsNotifier
                                              .currentLyrics[currentIndex + 1]
                                          ['text'] as String,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),

                                // Additional context lines (up to 2 more previous and next)
                                if (currentIndex > 1)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      lyricsNotifier
                                              .currentLyrics[currentIndex - 2]
                                          ['text'] as String,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w400,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),

                                if (currentIndex >= 0 &&
                                    currentIndex + 2 <
                                        lyricsNotifier.currentLyrics.length)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      lyricsNotifier
                                              .currentLyrics[currentIndex + 2]
                                          ['text'] as String,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.2),
                                        fontWeight: FontWeight.w400,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                              ],
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
