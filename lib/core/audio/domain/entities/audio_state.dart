// lib/core/audio/domain/entities/audio_state.dart
import 'package:equatable/equatable.dart';
import 'package:my_player/core/media_library/domain/entities/song.dart';

class AudioState extends Equatable {
  final Song? currentSong;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final List<Song> playlist;
  final int currentIndex;
  final bool isLoading;
  final String? error;
  final double volume;
  final double playbackSpeed;

  const AudioState({
    this.currentSong,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.playlist = const [],
    this.currentIndex = -1,
    this.isLoading = false,
    this.error,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
  });

  // Copy with method for immutability
  AudioState copyWith({
    Song? currentSong,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    List<Song>? playlist,
    int? currentIndex,
    bool? isLoading,
    String? error,
    double? volume,
    double? playbackSpeed,
  }) {
    return AudioState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }

  // Helper methods
  bool get hasError => error != null;
  bool get hasPlaylist => playlist.isNotEmpty;
  bool get isStopped => currentSong == null;
  double get progress => totalDuration.inMilliseconds > 0 
      ? currentPosition.inMilliseconds / totalDuration.inMilliseconds 
      : 0.0;

  @override
  List<Object?> get props => [
        currentSong,
        isPlaying,
        currentPosition,
        totalDuration,
        playlist,
        currentIndex,
        isLoading,
        error,
        volume,
        playbackSpeed,
      ];

  @override
  String toString() {
    return 'AudioState('
        'currentSong: ${currentSong?.title}, '
        'isPlaying: $isPlaying, '
        'position: $currentPosition, '
        'duration: $totalDuration, '
        'playlist: ${playlist.length} songs, '
        'currentIndex: $currentIndex, '
        'volume: $volume, '
        'speed: $playbackSpeed'
        ')';
  }
}