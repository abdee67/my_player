// lib/core/media_library/data/windows_music_library_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:my_player/core/media_library/domain/entities/song.dart';

class MusicLibraryService {
  static final List<String> _supportedFormats = [
    '.mp3',
    '.wav',
    '.ogg',
    '.m4a',
    '.aac',
    '.flac',
    '.wma'
  ];

  /// Let user select directory and scan for music files
  Future<List<Song>> getSongs() async {
    try {
      print("🪟 Windows: No permissions needed, opening directory picker...");

      final String? selectedDirectory =
          await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Music Folder',
      );

      if (selectedDirectory == null) {
        print("❌ User cancelled directory selection");
        return [];
      }

      print("📁 Scanning directory: $selectedDirectory");
      final songs = await _scanDirectory(Directory(selectedDirectory));
      print("✅ Found ${songs.length} songs");

      return songs;
    } catch (e) {
      print('🚨 Error scanning music files: $e');
      return [];
    }
  }

  Future<List<Song>> _scanDirectory(Directory directory) async {
    final List<Song> songs = [];

    try {
      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File) {
            if (_isMusicFile(entity.path)) {
              final song = await _createSongFromFile(entity);
              if (song != null) {
                songs.add(song);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error scanning directory ${directory.path}: $e');
    }

    return songs;
  }

  bool _isMusicFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return _supportedFormats.contains(extension);
  }

  Future<Song?> _createSongFromFile(File file) async {
    try {
      final stat = await file.stat();
      final fileName = path.basenameWithoutExtension(file.path);

      // Split filename to extract title and artist (common pattern: "Artist - Title")
      String title = fileName;
      String artist = 'Unknown Artist';
      String album = 'Unknown Album';

      if (fileName.contains(' - ')) {
        final parts = fileName.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts[1].trim();
        }
      }

      // For Windows, we'll use a simple duration estimation
      // In a real app, you'd use a metadata reader
      final duration = await _estimateDuration(file);

      return Song(
        id: file.path, // Use file path as ID on Windows
        title: title,
        artist: artist,
        album: album,
        filePath: file.path,
        duration: duration,
        fileSize: stat.size,
      );
    } catch (e) {
      print('Error creating song from file ${file.path}: $e');
      return null;
    }
  }

  Future<Duration> _estimateDuration(File file) async {
    // Simple estimation: assume 1MB ≈ 1 minute for MP3
    // This is very rough - in production, use a proper metadata library
    try {
      final stat = await file.stat();
      final minutes = stat.size / (1024 * 1024); // 1MB per minute
      return Duration(minutes: minutes.toInt().clamp(1, 60));
    } catch (e) {
      return const Duration(minutes: 3); // Default fallback
    }
  }

  /// Get common music directories on Windows
  Future<List<String>> getCommonMusicDirectories() async {
    final List<String> directories = [];

    try {
      // User's Music directory
      final userMusic = Platform.environment['USERPROFILE'];
      if (userMusic != null) {
        final musicDir = path.join(userMusic, 'Music');
        if (await Directory(musicDir).exists()) {
          directories.add(musicDir);
        }
      }

      // Common locations
      final commonLocations = [
        r'C:\Users\Public\Music',
        r'C:\Music',
        r'C:\Users\Public\Documents\Music',
        r'C:\Users\Public\Documents\My Music',
        r'C:\Users\Public\Documents\My Music\Music',
      ];

      for (final location in commonLocations) {
        if (await Directory(location).exists()) {
          directories.add(location);
        }
      }
    } catch (e) {
      print('Error getting common music directories: $e');
    }

    return directories;
  }
}
