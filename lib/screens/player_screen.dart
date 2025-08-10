import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:media_kit/media_kit.dart';
import 'package:my_player/models/lyricLine.dart';
// Removed unused import: album_art.dart
import '../widgets/player/modern_app_bar.dart';
import '../widgets/player/lyrics_list.dart';
import '../widgets/player/player_controls.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../notifiers/audio_player_notifier.dart';
import '../notifiers/lyrics_notifier.dart';
// Removed unused import: music_library_notifier.dart

class PlayerScreen extends StatefulWidget {
  final Player audioPlayer;
  final List<LyricLine> lyrics;
  const PlayerScreen({super.key, required this.audioPlayer, required this.lyrics});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AudioPlayerNotifier _audioPlayerNotifier;
  late LyricsNotifier _lyricsNotifier;
  // Removed unused _musicLibraryNotifier

  // Animation controllers for modern UI
  late AnimationController _albumArtController;
  late AnimationController _fadeController;
  // Removed unused _albumArtAnimation
  // Removed unused _fadeAnimation
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
  // Removed _musicLibraryNotifier initialization

    // Initialize animation controllers
    _albumArtController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

  // Removed _albumArtAnimation initialization

    // Start animations
    _albumArtController.forward();
    _fadeController.forward();

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndFetchLyrics();
    });
    // Listen to position updates from media_kit.Player
    widget.audioPlayer.stream.position.listen((position) {
      if (!_isManualSeeking){
      _updateCurrentSongIndex(position);
      }
    });
    
  }
  bool _isManualSeeking = false; // Track if user is manually seeking

  void _seekToLyricTime(Duration time) {
  _isManualSeeking = true;
  widget.audioPlayer.seek(time);
  _updateCurrentSongIndex(time);
  Future.delayed(Duration(milliseconds: 500), () => _isManualSeeking = false);
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
  // Removed: _updateCurrentSongIndex(widget.audioPlayer.position); (no direct position getter in media_kit.Player)
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

  int newIndex = _findLyricIndex(currentPosition, lyrics);
  
  if (newIndex != _currentLyricIndex) {
    setState(() => _currentLyricIndex = newIndex);
    _smoothScrollToLyric(newIndex);
  }
}

int _findLyricIndex(Duration position, List<LyricLine> lyrics) {
  for (int i = 0; i < lyrics.length; i++) {
    final currentLine = lyrics[i];
    final nextLine = i + 1 < lyrics.length ? lyrics[i + 1] : null;
    
    if (position >= currentLine.timestamp && 
        (nextLine == null || position < nextLine.timestamp)) {
      return i;
    }
  }
  return 0;
}

void _smoothScrollToLyric(int index) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.5, // Center the active line
    );
  });
}

  void _playNextSong() {
    _audioPlayerNotifier.playNext();
  }

  void _playPreviousSong() {
    _audioPlayerNotifier.playPrevious();
  }

  // Removed unused _formatDuration


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer2<AudioPlayerNotifier,LyricsNotifier>(
        builder: (context, audioNotifier, lyricsNotifier, _) {
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
                    ModernAppBar(
                      key: const Key('modernAppBar'),
                      title: audioNotifier.currentSong?.artist ?? 'No Artist',
                      subtitle: audioNotifier.currentSong?.title ?? 'No Song Playing',
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    // Album Art
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                     
                    ),
                    // Lyrics List
                    Expanded(
                      child: _buildLyricsSection(lyricsNotifier),
                    ),
                    // Player Controls
                    PlayerControls(
                      key: const Key('playerControls'),
                      isPlaying: audioNotifier.isPlaying,
                      onPlayPause: () {
                        if (audioNotifier.isPlaying) {
                          audioNotifier.pauseSong();
                        } else {
                          audioNotifier.resumeSong();
                        }
                      },
                      onNext: _playNextSong,
                      onPrevious: _playPreviousSong,
                      position: audioNotifier.currentPosition,
                      duration: audioNotifier.totalDuration,
                      onSeek: (d) => audioNotifier.seek(d),
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
  Widget _buildLyricsSection(LyricsNotifier lyricsNotifier) {
    if (lyricsNotifier.isLoadingLyrics || _isFetchingLyrics) {
      return Center(
        child: SpinKitFadingCircle(color: Colors.deepPurpleAccent, size: 50),
      );
    }

    final lyrics = lyricsNotifier.currentLyrics;
    if (lyrics.isEmpty) {
      return const Center(
        child: Text(
          'No Lyrics Available',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return LyricsList(
      key: const Key('lyricsList'),
      lyrics: lyrics,
      currentIndex: _currentLyricIndex,
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      onTapLine: (index) {
        final lyricTime = lyrics[index].timestamp;
        _seekToLyricTime(lyricTime);
      },
    );
  }
}
