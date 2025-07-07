import 'package:flutter/material.dart';
// Correct import for the package
import '../models/song.dart';
import '../services/lyrics_service.dart';

/// Notifier for managing and exposing lyrics data to the UI.
class LyricsNotifier extends ChangeNotifier {
  final LyricsService _lyricsService;

  List<Map<String, dynamic>> _currentLyrics = [];
  bool _isLoadingLyrics = false;
  String? _lyricsErrorMessage;
  String? _currentSongId; // Track current song to prevent duplicate fetching

  LyricsNotifier(this._lyricsService);

  List<Map<String, dynamic>> get currentLyrics => _currentLyrics;
  bool get isLoadingLyrics => _isLoadingLyrics;
  String? get lyricsErrorMessage => _lyricsErrorMessage;

  /// Fetches and parses lyrics for a given song.
  Future<void> fetchAndParseLyrics(Song song) async {
    // Don't start loading if already loading the same song
    if (_isLoadingLyrics && _currentSongId == song.id) {
      print("Already loading lyrics for song: ${song.title}");
      return;
    }

    // Don't fetch if we already have lyrics for this song
    if (_currentSongId == song.id && _currentLyrics.isNotEmpty) {
      print("Already have lyrics for song: ${song.title}");
      return;
    }

    _isLoadingLyrics = true;
    _lyricsErrorMessage = null;
    _currentLyrics = []; // Clear previous lyrics
    _currentSongId = song.id;

    print("Starting to fetch lyrics for: ${song.title} by ${song.artist}");

    // Use microtask to ensure notifyListeners is called after the current build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final rawLrc = await _lyricsService.fetchLyrics(
        song.title,
        song.artist,
        song.album,
        song.duration,
      );

      if (rawLrc != null) {
        _currentLyrics = await _lyricsService.parseLrc(rawLrc);
        print(
          "Successfully parsed ${_currentLyrics.length} lyric lines for ${song.title}",
        );
      } else {
        _lyricsErrorMessage = "No synchronized lyrics found for this song.";
        print("No lyrics found for: ${song.title}");
      }
    } catch (e) {
      _lyricsErrorMessage = "Error fetching or parsing lyrics: $e";
      print("Error in LyricsNotifier for ${song.title}: $e");
    } finally {
      _isLoadingLyrics = false;
      // Use microtask to ensure notifyListeners is called after the current build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Clears current lyrics (e.g., when song changes)
  void clearLyrics() {
    _currentLyrics = [];
    _lyricsErrorMessage = null;
    _isLoadingLyrics = false;
    _currentSongId = null;
    print("Cleared lyrics");
    notifyListeners();
  }
}
