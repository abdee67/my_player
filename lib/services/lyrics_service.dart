import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service to fetch lyrics from LRCLIB and parse them.
class LyricsService {
  static const String _lrclibBaseUrl = 'https://lrclib.net/api/get';
  static const String _lyricsCacheKey = 'lyrics_cache';
  static const String _embeddedLyricsCacheKey = 'embedded_lyrics_cache';

  /// Fetches LRC lyrics for a given song.
  /// Returns the raw LRC content string if found, otherwise null.
  Future<String?> fetchLyrics(
    String title,
    String artist,
    String? album,
    Duration duration,
    String? filePath,
  ) async {
    try {
      // First check if we have cached lyrics
      final cachedLyrics = await _getCachedLyrics(title, artist);
      if (cachedLyrics != null) {
        print("Using cached lyrics for $title by $artist");
        return cachedLyrics;
      }

      // Check for embedded lyrics in the audio file
      if (filePath != null) {
        final embeddedLyrics = await _extractEmbeddedLyrics(filePath);
        if (embeddedLyrics != null && embeddedLyrics.isNotEmpty) {
          print("Found embedded lyrics for $title by $artist");
          await _cacheLyrics(title, artist, embeddedLyrics, isEmbedded: true);
          return embeddedLyrics;
        }
      }

      // Check if we previously found no embedded lyrics to avoid repeated attempts
      final noEmbeddedKey = '${title}_${artist}_no_embedded';
      final prefs = await SharedPreferences.getInstance();
      final hasNoEmbedded = prefs.getBool(noEmbeddedKey) ?? false;

      if (!hasNoEmbedded && filePath != null) {
        // Try to extract embedded lyrics again
        final embeddedLyrics = await _extractEmbeddedLyrics(filePath);
        if (embeddedLyrics != null && embeddedLyrics.isNotEmpty) {
          print("Found embedded lyrics for $title by $artist");
          await _cacheLyrics(title, artist, embeddedLyrics, isEmbedded: true);
          return embeddedLyrics;
        } else {
          // Mark that this song has no embedded lyrics
          await prefs.setBool(noEmbeddedKey, true);
        }
      }

      // If no embedded lyrics, fetch from online
      final queryParameters = {
        'artist_name': artist,
        'track_name': title,
        'duration': duration.inSeconds.toString(),
      };
      // LRCLIB can also take 'album_name'
      if (album != null && album.isNotEmpty) {
        queryParameters['album_name'] = album;
      }

      final uri = Uri.parse(
        _lrclibBaseUrl,
      ).replace(queryParameters: queryParameters);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String? syncedLyrics = data['syncedLyrics'];
        if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
          print("Lyrics fetched successfully for $title by $artist");
          await _cacheLyrics(title, artist, syncedLyrics, isEmbedded: false);
          return syncedLyrics;
        } else {
          final String? plainLyrics = data['plainLyrics'];
          if (plainLyrics != null && plainLyrics.isNotEmpty) {
            print("Plain Lyrics fetched successfully for $title by $artist");
            await _cacheLyrics(title, artist, plainLyrics, isEmbedded: false);
            return plainLyrics;
          } else if (syncedLyrics == null && plainLyrics == null) {
            print("No lyrics found for $title by $artist)");
            return null;
          }
        }
      } else if (response.statusCode == 404) {
        print("Lyrics not found for $title by $artist (404)");
        return null;
      } else {
        print(
          "Failed to fetch lyrics: ${response.statusCode} ${response.body}",
        );
        return null;
      }
    } catch (e) {
      print("Error fetching lyrics: $e");
      return null;
    }
    return null;
  }

  /// Extract embedded lyrics from audio file metadata
  Future<String?> _extractEmbeddedLyrics(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print("File does not exist: $filePath");
        return null;
      }

      // For now, we'll implement a basic approach to check for common lyrics files
      // In a full implementation, you would use a library like 'taglib' or 'ffmpeg'
      // to extract lyrics from audio file metadata

      // Check if there's a corresponding .lrc file
      final lrcFile = File(filePath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc'));
      if (await lrcFile.exists()) {
        final lrcContent = await lrcFile.readAsString();
        if (lrcContent.isNotEmpty) {
          print("Found LRC file for $filePath");
          return lrcContent;
        }
      }

      // Check if there's a corresponding .txt file with lyrics
      final txtFile = File(filePath.replaceAll(RegExp(r'\.[^.]+$'), '.txt'));
      if (await txtFile.exists()) {
        final txtContent = await txtFile.readAsString();
        if (txtContent.isNotEmpty) {
          print("Found TXT lyrics file for $filePath");
          return txtContent;
        }
      }

      // TODO: Implement proper metadata extraction using appropriate libraries
      // This would require additional native libraries for audio metadata parsing

      return null;
    } catch (e) {
      print("Error extracting embedded lyrics: $e");
      return null;
    }
  }

  /// Cache lyrics locally
  Future<void> _cacheLyrics(String title, String artist, String lyrics,
      {bool isEmbedded = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${title}_$artist';
      await prefs.setString(cacheKey, lyrics);

      // Store metadata about the lyrics
      final metadata = {
        'isEmbedded': isEmbedded,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'length': lyrics.length,
      };
      await prefs.setString('${cacheKey}_meta', json.encode(metadata));

      // Also store in a general cache list
      final cacheList = prefs.getStringList(_lyricsCacheKey) ?? [];
      if (!cacheList.contains(cacheKey)) {
        cacheList.add(cacheKey);
        await prefs.setStringList(_lyricsCacheKey, cacheList);
      }

      // Store in embedded lyrics cache if it's embedded
      if (isEmbedded) {
        final embeddedCacheList =
            prefs.getStringList(_embeddedLyricsCacheKey) ?? [];
        if (!embeddedCacheList.contains(cacheKey)) {
          embeddedCacheList.add(cacheKey);
          await prefs.setStringList(_embeddedLyricsCacheKey, embeddedCacheList);
        }
      }

      print("Lyrics cached for $title by $artist (embedded: $isEmbedded)");
    } catch (e) {
      print("Error caching lyrics: $e");
    }
  }

  /// Get cached lyrics
  Future<String?> _getCachedLyrics(String title, String artist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${title}_$artist';
      return prefs.getString(cacheKey);
    } catch (e) {
      print("Error getting cached lyrics: $e");
      return null;
    }
  }

  /// Check if lyrics are embedded
  Future<bool> isLyricsEmbedded(String title, String artist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${title}_$artist';
      final metadataStr = prefs.getString('${cacheKey}_meta');

      if (metadataStr != null) {
        final metadata = json.decode(metadataStr);
        return metadata['isEmbedded'] ?? false;
      }

      return false;
    } catch (e) {
      print("Error checking if lyrics are embedded: $e");
      return false;
    }
  }

  /// Clear all cached lyrics
  Future<void> clearLyricsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheList = prefs.getStringList(_lyricsCacheKey) ?? [];

      // Clear individual lyric entries
      for (final key in cacheList) {
        await prefs.remove(key);
        await prefs.remove('${key}_meta');
      }

      // Clear the cache lists
      await prefs.remove(_lyricsCacheKey);
      await prefs.remove(_embeddedLyricsCacheKey);

      print("Lyrics cache cleared");
    } catch (e) {
      print("Error clearing lyrics cache: $e");
    }
  }

  /// Get cache size info
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheList = prefs.getStringList(_lyricsCacheKey) ?? [];
      final embeddedCacheList =
          prefs.getStringList(_embeddedLyricsCacheKey) ?? [];

      int totalSize = 0;
      for (final key in cacheList) {
        final lyrics = prefs.getString(key);
        if (lyrics != null) {
          totalSize += lyrics.length;
        }
      }

      return {
        'total_cached': cacheList.length,
        'embedded_cached': embeddedCacheList.length,
        'total_size_bytes': totalSize,
        'cache_keys': cacheList,
        'embedded_keys': embeddedCacheList,
      };
    } catch (e) {
      print("Error getting cache info: $e");
      return {
        'total_cached': 0,
        'embedded_cached': 0,
        'total_size_bytes': 0,
        'cache_keys': [],
        'embedded_keys': []
      };
    }
  }

  /// Parses a raw LRC string into a list of timed lyric lines.
  /// Returns an empty list if parsing fails.
  Future<List<Map<String, dynamic>>> parseLrc(String lrcContent) async {
    try {
      List<Map<String, dynamic>> lyricsList = [];

      // Simple LRC parser
      final lines = lrcContent.split('\n');
      print("Parsing LRC content with ${lines.length} lines");

      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        // Look for time tags like [00:00.00]
        final timeRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\]');
        final matches = timeRegex.allMatches(line);

        if (matches.isNotEmpty) {
          // Extract the text after the last time tag
          final lastMatch = matches.last;
          final textStart = line.lastIndexOf(']') + 1;
          final text = line.substring(textStart).trim();

          if (text.isNotEmpty) {
            // Parse time
            final minutes = int.parse(lastMatch.group(1)!);
            final seconds = int.parse(lastMatch.group(2)!);
            final centiseconds = int.parse(lastMatch.group(3)!);
            final time = Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: centiseconds * 10,
            );

            lyricsList.add({'time': time, 'text': text});

            // Debug: Print first few lyrics with their timing
            if (lyricsList.length <= 5) {
              print(
                "Lyric ${lyricsList.length}: [${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}.${(time.inMilliseconds % 1000 / 10).round().toString().padLeft(2, '0')}] $text",
              );
            }
          }
        }
      }

      // Sort by time
      lyricsList.sort(
        (a, b) => (a['time'] as Duration).compareTo(b['time'] as Duration),
      );

      print("Successfully parsed ${lyricsList.length} lyric lines");
      if (lyricsList.isNotEmpty) {
        print(
          "First lyric: ${lyricsList.first['time']} - ${lyricsList.first['text']}",
        );
        print(
          "Last lyric: ${lyricsList.last['time']} - ${lyricsList.last['text']}",
        );
      }

      return lyricsList;
    } catch (e) {
      print("Error parsing LRC: $e");
      return [];
    }
  }
}
