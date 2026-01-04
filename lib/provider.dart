// lib/provider.dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_player/core/audio/data/audio_player_service.dart';
import 'package:my_player/core/audio/domain/entities/audio_state.dart';
import 'package:my_player/core/audio/presentation/notifiers/audio_player_notifier.dart';
import 'package:my_player/core/lyrics/data/lyrics_service.dart';
import 'package:my_player/core/lyrics/presentation/notifiers/lyrics_notifier.dart';
import 'package:my_player/core/media_library/data/music_library_service.dart';
import 'package:my_player/core/media_library/domain/entities/music_library_state.dart';
import 'package:my_player/core/media_library/presentation/notifiers/music_library_notifier.dart';

// Service Providers
final audioHandlerProvider = Provider<AudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main.');
});

final audioServiceProvider = Provider<AudioPlayerService>(
  (ref) {
    final handler = ref.watch(audioHandlerProvider);
    final service = AudioPlayerService(handler);
    ref.onDispose(service.dispose);
    return service;
  },
);

final lyricsServiceProvider = Provider<LyricsService>(
  (ref) => LyricsService(),
);

final musicLibraryServiceProvider = Provider<MusicLibraryService>(
  (ref) => MusicLibraryService(),
);

// State Notifier Providers
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioState>(
  (ref) => AudioPlayerNotifier(ref.read(audioServiceProvider)),
);

final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>(
  (ref) => LyricsNotifier(ref.read(lyricsServiceProvider)),
);

final musicLibraryProvider =
    StateNotifierProvider<MusicLibraryNotifier, MusicLibraryState>(
  (ref) => MusicLibraryNotifier(ref.read(musicLibraryServiceProvider)),
);

// Stream Providers for real-time updates
final currentPositionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioServiceProvider).currentPositionStream;
});

final isPlayingProvider = StreamProvider<bool>((ref) {
  return ref.watch(audioServiceProvider).isPlayingStream;
});

// Combined Providers
final playerUIStateProvider = Provider<PlayerUIState>((ref) {
  final audioState = ref.watch(audioPlayerProvider);
  final lyricsState = ref.watch(lyricsProvider);

  return PlayerUIState(
    audioState: audioState,
    lyricsState: lyricsState,
    currentPosition: audioState.currentPosition,
    isPlaying: audioState.isPlaying,
  );
});

// Helper class for combined UI state
class PlayerUIState {
  final AudioState audioState;
  final LyricsState lyricsState;
  final Duration currentPosition;
  final bool isPlaying;

  PlayerUIState({
    required this.audioState,
    required this.lyricsState,
    required this.currentPosition,
    required this.isPlaying,
  });
}
