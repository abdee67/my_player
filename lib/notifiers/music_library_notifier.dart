import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_library_service.dart';

/// Notifier for managing and exposing the local music library data.
class MusicLibraryNotifier extends ChangeNotifier {
  final MusicLibraryService _musicLibraryService;

  List<Song> _songs = [];
  bool _isLoading = false;
  String? _errorMessage;

  MusicLibraryNotifier(this._musicLibraryService);

  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSongs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool permissionGranted = await _musicLibraryService.requestStoragePermissions();
      if (permissionGranted) {
        _songs = await _musicLibraryService.getSongs();
      } else {
        _errorMessage = "Permission denied to access local music.";
      }
    } catch (e) {
      _errorMessage = "Failed to load songs: $e";
      print("Error in MusicLibraryNotifier: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}