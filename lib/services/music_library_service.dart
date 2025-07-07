import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';

/// Service to query local music files and handle permissions.
class MusicLibraryService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Requests necessary storage permissions.
  /// Returns true if permissions are granted, false otherwise.
  Future<bool> requestStoragePermissions() async {
    // For Android 13+ use Permission.audio
    // For older Android, use Permission.storage
    // For iOS, relevant permissions might be in Info.plist already,
    // or mediaLibrary for explicit access.
    var status = await Permission.audio.status;
    if (status.isDenied) {
      status = await Permission.audio.request();
    }

    if (status.isGranted) {
      print("Audio permission granted.");
      // On Android < 13, you might still need storage permission
      if (await Permission.storage.status.isDenied) {
        var storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          print("Storage permission granted.");
          return true;
        } else {
          print("Storage permission denied.");
          return false;
        }
      }
      return true;
    } else {
      print("Audio permission denied.");
      return false;
    }
  }

  /// Fetches all local music songs.
  Future<List<Song>> getSongs() async {
    try {
      bool hasPermission = await _audioQuery.checkAndRequest(
        retryRequest: true,
      );
      if (hasPermission) {
        List<SongModel> audioList = await _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );

        List<Song> songs = [];
        for (var audio in audioList) {
          // Get album artwork (can be slow for many songs, consider lazy loading)
          Uint8List? artwork = await _audioQuery.queryArtwork(
            audio.id,
            ArtworkType.AUDIO,
            size: 200, // Adjust size as needed
            quality: 50, // Adjust quality
          );

          songs.add(Song.fromAudioQuery({
            'id': audio.id,
            'title': audio.title,
            'artist': audio.artist,
            'album': audio.album,
            'data': audio.data,
            'duration': audio.duration,
            'artwork': artwork,
          }));
        }
        return songs;
      } else {
        print("Permission not granted to query audios.");
        return [];
      }
    } catch (e) {
      print("Error fetching songs: $e");
      return [];
    }
  }

  // TODO: Add methods for getAlbums(), getArtists() if needed for LibraryScreen tabs
}