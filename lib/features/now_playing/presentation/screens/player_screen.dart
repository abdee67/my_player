// lib/features/now_playing/presentation/screens/player_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:my_player/core/audio/domain/entities/audio_state.dart';
import 'package:my_player/core/lyrics/presentation/notifiers/lyrics_notifier.dart'
    hide lyricsProvider;
import 'package:my_player/core/lyrics/presentation/widgets/lyrics_list.dart';
import 'package:my_player/features/now_playing/presentation/widgets/modern_app_bar.dart';
import 'package:my_player/features/now_playing/presentation/widgets/player_controls.dart';
import 'package:my_player/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _albumArtController;
  late AnimationController _fadeController;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  int _currentLyricIndex = 0;
  String? _currentSongId;
  bool _isManualSeeking = false;

  @override
  void initState() {
    super.initState();
    _albumArtController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _albumArtController.forward();
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndFetchLyrics();
  }

  @override
  void dispose() {
    _albumArtController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _checkAndFetchLyrics() {
    final audioState = ref.read(audioPlayerProvider);
    final lyricsNotifier = ref.read(lyricsProvider.notifier);

    final currentSong = audioState.currentSong;
    if (currentSong != null && currentSong.id != _currentSongId) {
      _currentSongId = currentSong.id;
      lyricsNotifier.fetchAndParseLyrics(currentSong);
      // Reset scroll position for new song
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(0);
      });
    }
  }

  void _updateLyricPosition(Duration position) {
    if (_isManualSeeking) return;

    final lyricsState = ref.read(lyricsProvider);
    if (!lyricsState.hasTimestamps || lyricsState.lyrics.isEmpty) return;

    final newIndex =
        ref.read(lyricsProvider.notifier).findCurrentLyricIndex(position);

    if (newIndex != _currentLyricIndex) {
      setState(() {
        _currentLyricIndex = newIndex;
      });
      _smoothScrollToLyric(newIndex);
    }
  }

  void _smoothScrollToLyric(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lyricsLen = ref.read(lyricsProvider).lyrics.length;
      if (index < 0 || index >= lyricsLen) return;
      if (!_itemScrollController.isAttached) {
        // Try again next frame once the list attaches
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _smoothScrollToLyric(index));
        return;
      }
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.4, // Slightly above center for better UX
      );
    });
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lyricsLen = ref.read(lyricsProvider).lyrics.length;
      if (index < 0 || index >= lyricsLen) return;
      if (!_itemScrollController.isAttached) {
        // Try again next frame once the list attaches
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToIndex(index));
        return;
      }
      _itemScrollController.jumpTo(index: index);
    });
  }

  void _seekToLyricTime(Duration time) {
    _isManualSeeking = true;
    ref.read(audioPlayerProvider.notifier).seek(time);

    // Update lyric position immediately
    final newIndex =
        ref.read(lyricsProvider.notifier).findCurrentLyricIndex(time);
    setState(() {
      _currentLyricIndex = newIndex;
    });
    _smoothScrollToLyric(newIndex);

    // Reset manual seeking flag after a delay
    Future.delayed(const Duration(seconds: 2), () {
      _isManualSeeking = false;
    });
  }

  void _playNextSong() {
    ref.read(audioPlayerProvider.notifier).playNext();
  }

  void _playPreviousSong() {
    ref.read(audioPlayerProvider.notifier).playPrevious();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioPlayerProvider);
    final lyricsState = ref.watch(lyricsProvider);

    // Listen to position changes for lyric sync via AudioState updates
    ref.listen<AudioState>(
      audioPlayerProvider,
      (previous, next) {
        _updateLyricPosition(next.currentPosition);
      },
    );

    // Check for song changes
    if (audioState.currentSong?.id != _currentSongId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndFetchLyrics();
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background with blurred album art or gradient
          _buildBackground(audioState),

          // Dark overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
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
                  title: audioState.currentSong?.artist ?? 'Unknown Artist',
                  subtitle: audioState.currentSong?.title ?? 'No Song Playing',
                  onBack: () => Navigator.of(context).pop(),
                ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: _buildLyricsSection(lyricsState),
                  ),
                ),

                // Player Controls
                PlayerControls(
                  key: const Key('playerControls'),
                  isPlaying: audioState.isPlaying,
                  onPlayPause: () {
                    if (audioState.isPlaying) {
                      ref.read(audioPlayerProvider.notifier).pause();
                    } else {
                      ref.read(audioPlayerProvider.notifier).resume();
                    }
                  },
                  onNext: _playNextSong,
                  onPrevious: _playPreviousSong,
                  position: audioState.currentPosition,
                  duration: audioState.totalDuration,
                  onSeek: (position) {
                    _isManualSeeking = true;
                    ref.read(audioPlayerProvider.notifier).seek(position);
                    // Update lyric position immediately
                    _updateLyricPosition(position);
                    Future.delayed(const Duration(seconds: 2), () {
                      _isManualSeeking = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(AudioState audioState) {
    if (audioState.currentSong?.albumArt != null) {
      return Positioned.fill(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Image.memory(
            audioState.currentSong!.albumArt!,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Positioned.fill(
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
      );
    }
  }

  Widget _buildLyricsSection(LyricsState lyricsState) {
    if (lyricsState.isLoading) {
      return Center(
        child: SpinKitSpinningLines(
          color: Colors.deepPurpleAccent,
          size: 50,
        ),
      );
    }

    if (lyricsState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            lyricsState.error!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (lyricsState.lyrics.isEmpty) {
      return const Center(
        child: Text(
          'No Lyrics Available',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return LyricsList(
      key: const Key('lyricsList'),
      lyrics: lyricsState.lyrics,
      currentIndex: _currentLyricIndex,
      hasTimestamps: lyricsState.hasTimestamps,
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      onTapLine: (index) {
        if (lyricsState.hasTimestamps) {
          final lyricTime = lyricsState.lyrics[index].timestamp;
          _seekToLyricTime(lyricTime);
        }
      },
    );
  }
}
