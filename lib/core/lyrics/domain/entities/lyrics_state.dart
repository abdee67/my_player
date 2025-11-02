// lib/core/lyrics/domain/entities/lyrics_state.dart
import 'package:equatable/equatable.dart';
import 'package:my_player/core/lyrics/domain/entities/lyricLine.dart';

class LyricsState extends Equatable {
  final List<LyricLine> lyrics;
  final bool isLoading;
  final String? error;
  final bool hasTimestamps;

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

  @override
  List<Object?> get props => [lyrics, isLoading, error, hasTimestamps];
}