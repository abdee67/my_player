// lib/core/media_library/domain/entities/music_library_state.dart
import 'package:equatable/equatable.dart';
import 'package:my_player/core/media_library/domain/entities/song.dart';

class MusicLibraryState extends Equatable {
  final List<Song> songs;
  final bool isLoading;
  final String? error;
  final List<Song> filteredSongs;
  final String searchQuery;

  const MusicLibraryState({
    this.songs = const [],
    this.isLoading = false,
    this.error,
    this.filteredSongs = const [],
    this.searchQuery = '',
  });

  MusicLibraryState copyWith({
    List<Song>? songs,
    bool? isLoading,
    String? error,
    List<Song>? filteredSongs,
    String? searchQuery,
  }) {
    return MusicLibraryState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        songs,
        isLoading,
        error,
        filteredSongs,
        searchQuery,
      ];
}