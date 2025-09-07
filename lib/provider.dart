import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_player/core/audio/data/audio_player_service.dart';
import 'package:my_player/core/lyrics/data/lyrics_service.dart';
import 'package:my_player/core/media_library/data/music_library_service.dart';

final audioServiceProvider =
    Provider<AudioPlayerService>((ref) => AudioPlayerService());

final lyricsServieProvider = Provider<LyricsService>((ref) => LyricsService());

final musicLibraryProvider =
    Provider<MusicLibraryService>((ref) => MusicLibraryService());
