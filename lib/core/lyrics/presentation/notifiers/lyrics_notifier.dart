// lib/core/lyrics/presentation/notifiers/lyrics_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_player/core/lyrics/data/lyrics_service.dart';
import 'package:my_player/core/lyrics/domain/entities/lyricLine.dart';
import 'package:my_player/core/media_library/domain/entities/song.dart';
import 'package:my_player/provider.dart';

class LyricsState {
  final List<LyricLine> lyrics;
  final bool isLoading;
  final String? error;
  final bool hasTimestamps; // Whether lyrics have proper timestamps

  const LyricsState({
    this.lyrics = const [],
    this.isLoading = false,
    this.error,
    this.hasTimestamps = false,
  });

  LyricsState copyWith({
    List<LyricLine>? lyrics,
    bool? isLoading,
    String? error,
    bool? hasTimestamps,
  }) {
    return LyricsState(
      lyrics: lyrics ?? this.lyrics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasTimestamps: hasTimestamps ?? this.hasTimestamps,
    );
  }
}

class LyricsNotifier extends StateNotifier<LyricsState> {
  final LyricsService _lyricsService;
  String? _currentSongId;

  LyricsNotifier(this._lyricsService) : super(const LyricsState());

  /// Fetches and parses lyrics for a given song
  Future<void> fetchAndParseLyrics(Song song) async {
    // Prevent duplicate fetching
    if (state.isLoading && _currentSongId == song.id) return;
    if (_currentSongId == song.id && state.lyrics.isNotEmpty) return;

    _currentSongId = song.id;
    state = const LyricsState(isLoading: true);

    try {
      final rawLyrics = await _lyricsService.fetchLyrics(
        song.title,
        song.artist,
        song.album,
        song.duration,
        song.filePath,
      );

      if (rawLyrics != null && rawLyrics.isNotEmpty) {
        final lyrics = await _lyricsService.parseLyrics(rawLyrics);
        final hasTimestamps = lyrics.isNotEmpty &&
            lyrics.any((line) => line.timestamp.inSeconds > 0);

        state = LyricsState(
          lyrics: lyrics,
          isLoading: false,
          hasTimestamps: hasTimestamps,
        );
      } else {
        state = LyricsState(
          isLoading: false,
          error: "Let's see ur guessing skill for this one..",
          lyrics: [],
          hasTimestamps: false,
        );
      }
    } catch (e) {
      state = LyricsState(
        isLoading: false,
        error: "Failed to load lyrics: ${e.toString()}",
        lyrics: [],
        hasTimestamps: false,
      );
    }
  }

  /// Find current lyric index based on playback position
  int findCurrentLyricIndex(Duration position) {
    if (state.lyrics.isEmpty || !state.hasTimestamps) return 0;

    for (int i = state.lyrics.length - 1; i >= 0; i--) {
      if (position >= state.lyrics[i].timestamp) {
        return i;
      }
    }
    return 0;
  }

  /// Clear current lyrics
  void clearLyrics() {
    _currentSongId = null;
    state = const LyricsState();
  }

  /// Get current song ID
  String? get currentSongId => _currentSongId;
}

// Riverpod Provider
final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>(
  (ref) => LyricsNotifier(ref.read(lyricsServiceProvider)),
);
