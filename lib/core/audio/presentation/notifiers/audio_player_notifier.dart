// lib/core/audio/presentation/notifiers/audio_player_notifier.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_player/core/audio/data/audio_player_service.dart';
import 'package:my_player/core/audio/domain/entities/audio_state.dart';
import 'package:my_player/core/media_library/domain/entities/song.dart';

class AudioPlayerNotifier extends StateNotifier<AudioState> {
  final AudioPlayerService _audioService;
  StreamSubscription<Song?>? _currentSongSubscription;
  StreamSubscription<bool>? _isPlayingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  AudioPlayerNotifier(this._audioService) : super(const AudioState()) {
    _initializeListeners();
  }

  void _initializeListeners() {
    _currentSongSubscription = _audioService.currentSongStream.listen((song) {
      state = state.copyWith(currentSong: song);
    });

    _isPlayingSubscription = _audioService.isPlayingStream.listen((isPlaying) {
      state = state.copyWith(isPlaying: isPlaying);
    });

    _positionSubscription =
        _audioService.currentPositionStream.listen((position) {
      state = state.copyWith(currentPosition: position);
    });

    _durationSubscription =
        _audioService.totalDurationStream.listen((duration) {
      state = state.copyWith(totalDuration: duration);
    });
  }

  // Play a single song
  Future<void> play(Song song) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _audioService.play(song);
      state = state.copyWith(
        isLoading: false,
        currentSong: song,
        playlist: [song],
        currentIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to play song: ${e.toString()}',
      );
    }
  }

  // Set and play a playlist
  Future<void> setPlaylist(List<Song> playlist,
      {int startIndex = 0, bool autoPlay = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      _audioService.setPlaylist(playlist,
          startIndex: startIndex, autoPlay: autoPlay);
      state = state.copyWith(
        isLoading: false,
        playlist: playlist,
        currentIndex: startIndex,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set playlist: ${e.toString()}',
      );
    }
  }

  // Play next song in playlist
  Future<void> playNext() async {
    if (state.playlist.isEmpty || state.currentIndex < 0) return;

    try {
      await _audioService.playNext();
      final nextIndex = (state.currentIndex + 1) % state.playlist.length;
      state = state.copyWith(currentIndex: nextIndex);
    } catch (e) {
      state = state.copyWith(error: 'Failed to play next: ${e.toString()}');
    }
  }

  // Play previous song in playlist
  Future<void> playPrevious() async {
    if (state.playlist.isEmpty || state.currentIndex < 0) return;

    try {
      await _audioService.playPrevious();
      final prevIndex = state.currentIndex > 0
          ? state.currentIndex - 1
          : state.playlist.length - 1;
      state = state.copyWith(currentIndex: prevIndex);
    } catch (e) {
      state = state.copyWith(error: 'Failed to play previous: ${e.toString()}');
    }
  }

  // Play song at specific index
  Future<void> playAtIndex(int index) async {
    if (state.playlist.isEmpty || index < 0 || index >= state.playlist.length)
      return;

    try {
      await _audioService.playAtIndex(index);
      state = state.copyWith(currentIndex: index);
    } catch (e) {
      state = state.copyWith(error: 'Failed to play at index: ${e.toString()}');
    }
  }

  // Pause playback
  Future<void> pause() async {
    try {
      await _audioService.pause();
    } catch (e) {
      state = state.copyWith(error: 'Failed to pause: ${e.toString()}');
    }
  }

  // Resume playback
  Future<void> resume() async {
    try {
      await _audioService.resume();
    } catch (e) {
      state = state.copyWith(error: 'Failed to resume: ${e.toString()}');
    }
  }

  // Stop playback
  Future<void> stop() async {
    try {
      await _audioService.stop();
      state = const AudioState();
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop: ${e.toString()}');
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioService.seek(position);
    } catch (e) {
      state = state.copyWith(error: 'Failed to seek: ${e.toString()}');
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioService.setVolume(volume);
      state = state.copyWith(volume: volume);
    } catch (e) {
      state = state.copyWith(error: 'Failed to set volume: ${e.toString()}');
    }
  }

  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _audioService.setRate(speed);
      state = state.copyWith(playbackSpeed: speed);
    } catch (e) {
      state = state.copyWith(error: 'Failed to set speed: ${e.toString()}');
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _currentSongSubscription?.cancel();
    _isPlayingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
