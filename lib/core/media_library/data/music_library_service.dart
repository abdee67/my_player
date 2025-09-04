import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:my_player/core/media_library/domain/entities/song.dart';

/// Service to query local music files and handle permissions.
class MusicLibraryService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Requests necessary storage permissions.
  /// Returns true if permissions are granted, false otherwise.
  Future<bool> requestStoragePermissions() async {
    try {
      // Check current permission status
      var audioStatus = await Permission.audio.status;
      var storageStatus = await Permission.storage.status;

      print("Current audio permission status: $audioStatus");
      print("Current storage permission status: $storageStatus");

      // For Android 13+ (API 33+), use audio permission
      if (audioStatus.isDenied) {
        print("Requesting audio permission...");
        audioStatus = await Permission.audio.request();
        print("Audio permission request result: $audioStatus");
      }

      // For Android < 13, also request storage permission
      if (storageStatus.isDenied) {
        print("Requesting storage permission...");
        storageStatus = await Permission.storage.request();
        print("Storage permission request result: $storageStatus");
      }

      // Check if we have the necessary permissions
      bool hasAudioPermission = audioStatus.isGranted;
      bool hasStoragePermission =
          storageStatus.isGranted || storageStatus.isLimited;

      print("Has audio permission: $hasAudioPermission");
      print("Has storage permission: $hasStoragePermission");

      // For Android 13+, we only need audio permission
      // For older versions, we need storage permission
      if (hasAudioPermission || hasStoragePermission) {
        print("Required permissions granted.");
        return true;
      } else {
        print("Required permissions denied.");
        return false;
      }
    } catch (e) {
      print("Error requesting permissions: $e");
      return false;
    }
  }

  /// Fetches all local music songs.
  Future<List<Song>> getSongs() async {
    try {
      // First check if we have permissions
      bool hasPermission = await requestStoragePermissions();

      if (!hasPermission) {
        print("Permission not granted to query audios.");
        return [];
      }

      // Use on_audio_query's built-in permission check as backup
      bool onAudioQueryPermission = await _audioQuery.checkAndRequest(
        retryRequest: true,
      );

      if (!onAudioQueryPermission) {
        print("on_audio_query permission check failed.");
        return [];
      }

      print("Querying songs from device...");
      List<SongModel> audioList = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      print("Found ${audioList.length} songs");

      List<Song> songs = [];
      for (var audio in audioList) {
        try {
          // Get album artwork (can be slow for many songs, consider lazy loading)
          Uint8List? artwork = await _audioQuery.queryArtwork(
            audio.id,
            ArtworkType.AUDIO,
            size: 200, // Adjust size as needed
            quality: 50, // Adjust quality
          );

          songs.add(
            Song.fromAudioQuery({
              'id': audio.id,
              'title': audio.title,
              'artist': audio.artist,
              'album': audio.album,
              'data': audio.data,
              'duration': audio.duration,
              'artwork': artwork,
            }),
          );
        } catch (e) {
          print("Error processing song ${audio.title}: $e");
          // Continue with other songs even if one fails
        }
      }

      print("Successfully processed ${songs.length} songs");
      return songs;
    } catch (e) {
      print("Error fetching songs: $e");
      return [];
    }
  }

  // TODO: Add methods for getAlbums(), getArtists() if needed for LibraryScreen tabs
}
