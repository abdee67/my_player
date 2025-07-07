import 'package:flutter/material.dart';
// Correct import for the package
import '../models/song.dart';
import '../services/lyrics_service.dart';

/// Notifier for managing and exposing lyrics data to the UI.
class LyricsNotifier extends ChangeNotifier {
  final LyricsService _lyricsService;

  List<dynamic> _currentLyrics = [];
  bool _isLoadingLyrics = false;
  String? _lyricsErrorMessage;

  LyricsNotifier(this._lyricsService);

  List<dynamic> get currentLyrics => _currentLyrics;
  bool get isLoadingLyrics => _isLoadingLyrics;
  String? get lyricsErrorMessage => _lyricsErrorMessage;

  /// Fetches and parses lyrics for a given song.
  Future<void> fetchAndParseLyrics(Song song) async {
    _isLoadingLyrics = true;
    _lyricsErrorMessage = null;
    _currentLyrics = []; // Clear previous lyrics
    notifyListeners();

    try {
      final rawLrc = await _lyricsService.fetchLyrics(
        song.title,
        song.artist,
        song.album,
        song.duration,
      );

      if (rawLrc != null) {
        _currentLyrics = await _lyricsService.parseLrc(rawLrc);
      } else {
        _lyricsErrorMessage = "No synchronized lyrics found for this song.";
      }
    } catch (e) {
      _lyricsErrorMessage = "Error fetching or parsing lyrics: $e";
      print("Error in LyricsNotifier: $e");
    } finally {
      _isLoadingLyrics = false;
      notifyListeners();
    }
  }

  /// Clears current lyrics (e.g., when song changes)
  void clearLyrics() {
    _currentLyrics = [];
    _lyricsErrorMessage = null;
    notifyListeners();
  }
}
