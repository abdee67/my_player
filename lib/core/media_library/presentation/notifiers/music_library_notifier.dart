// lib/core/media_library/presentation/notifiers/music_library_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_player/core/media_library/data/music_library_service.dart';
import 'package:my_player/core/media_library/domain/entities/music_library_state.dart';

class MusicLibraryNotifier extends StateNotifier<MusicLibraryState> {
  final MusicLibraryService _musicLibraryService;

  MusicLibraryNotifier(this._musicLibraryService)
      : super(const MusicLibraryState());

  Future<void> loadSongs() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final songs = await _musicLibraryService.getSongs();
      state = state.copyWith(
        songs: songs,
        filteredSongs: songs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load songs: ${e.toString()}',
      );
    }
  }

  void searchSongs(String query) {
    if (query.isEmpty) {
      state = state.copyWith(
        filteredSongs: state.songs,
        searchQuery: query,
      );
      return;
    }

    final filtered = state.songs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
          song.artist.toLowerCase().contains(query.toLowerCase()) ||
          song.album.toLowerCase().contains(query.toLowerCase());
    }).toList();

    state = state.copyWith(
      filteredSongs: filtered,
      searchQuery: query,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSearch() {
    state = state.copyWith(
      filteredSongs: state.songs,
      searchQuery: '',
    );
  }
}
