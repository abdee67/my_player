import 'package:flutter/material.dart';
import 'package:my_player/core/media_library/data/music_library_service.dart';
import 'package:my_player/core/media_library/domain/entities/song.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier for managing and exposing the local music library data.
class MusicLibraryNotifier extends ChangeNotifier {
  /// Smart refresh: only add new songs, keep existing cached ones
  Future<void> smartRefresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Load cached songs
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      List<Song> cachedSongs = [];
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        cachedSongs = decoded.map((e) => Song.fromJson(e)).toList();
      }

      // Get latest songs from device
      bool permissionGranted =
          await _musicLibraryService.requestStoragePermissions();
      if (!permissionGranted) {
        _errorMessage = "Permission denied to access local music.";
        _isLoading = false;
        notifyListeners();
        return;
      }
      final deviceSongs = await _musicLibraryService.getSongs();

      // Merge: keep all cached, add only new ones
      final cachedIds = cachedSongs.map((s) => s.id).toSet();
      final newSongs =
          deviceSongs.where((s) => !cachedIds.contains(s.id)).toList();
      final merged = [...cachedSongs, ...newSongs];

      _songs = merged;
      // Update cache
      final toCache = jsonEncode(_songs.map((s) => s.toJson()).toList());
      await prefs.setString(_cacheKey, toCache);
    } catch (e) {
      _errorMessage = "Failed to smart refresh: $e";
      print("Error in smartRefresh: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static const String _cacheKey = 'music_list_cache_v1';
  final MusicLibraryService _musicLibraryService;

  List<Song> _songs = [];
  bool _isLoading = false;
  String? _errorMessage;

  MusicLibraryNotifier(this._musicLibraryService);

  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSongs({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!forceRefresh) {
        // Try to load from cache first
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          final List<dynamic> decoded = jsonDecode(cached);
          _songs = decoded.map((e) => Song.fromJson(e)).toList();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // If no cache or forceRefresh, load from device
      bool permissionGranted =
          await _musicLibraryService.requestStoragePermissions();
      if (permissionGranted) {
        _songs = await _musicLibraryService.getSongs();
        // Save to cache (without albumArt for performance)
        final prefs = await SharedPreferences.getInstance();
        final toCache = jsonEncode(_songs.map((s) => s.toJson()).toList());
        await prefs.setString(_cacheKey, toCache);
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

  /// Call this to clear the cache (e.g. for a manual refresh)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
