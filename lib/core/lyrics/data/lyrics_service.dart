import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_player/core/lyrics/domain/entities/lyricLine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to fetch lyrics from LRCLIB and parse them.
class LyricsService {
  static const String _lrclibBaseUrl = 'https://lrclib.net/api';
  static const String _lyricsCacheKey = 'lyrics_cache';
  //static const String _embeddedLyricsCacheKey = 'embedded_lyrics_cache';
  static const Duration _cacheDuration = Duration(days: 30);

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
      // Clean the title and artist for better matching
      final cleanedTitle = _cleanString(title);
      final cleanedArtist = _cleanString(artist);
      final cleanedAlbum = album != null ? _cleanString(album) : null;

      print("🎵 Fetching lyrics for: '$cleanedTitle' by '$cleanedArtist'");
      // First check if we have cached lyrics
      final cachedLyrics = await _getCachedLyrics(title, artist);
      if (cachedLyrics != null && cachedLyrics.isNotEmpty) {
        print(
            "🎵 Cached lyrics found for: '$cleanedTitle' by '$cleanedArtist'");
        return cachedLyrics;
      }
      if (filePath != null) {
        final embeddedLyrics = await _extractEmbeddedLyrics(filePath);
        if (embeddedLyrics != null && embeddedLyrics.isNotEmpty) {
          print(
              "🎵 Embedded lyrics found for: '$cleanedTitle' by '$cleanedArtist'");
          await _cacheLyrics(title, artist, embeddedLyrics);
          return embeddedLyrics;
        }
      }
      // 3. Try LRCLIB with multiple strategies
      String? lyrics = await _fetchFromLrclibWithFallback(
        cleanedTitle,
        cleanedArtist,
        cleanedAlbum,
        duration,
      );

      if (lyrics != null && lyrics.isNotEmpty) {
        await _cacheLyrics(cleanedTitle, cleanedArtist, lyrics);
        return lyrics;
      }

      print("❌ No lyrics found after all attempts for '$cleanedTitle'");
      return null;
    } catch (e) {
      print("🚨 Error in fetchLyrics for '$title': $e");
      return null;
    }
  }

  /// Try multiple search strategies on LRCLIB
  Future<String?> _fetchFromLrclibWithFallback(
    String title,
    String artist,
    String? album,
    Duration duration,
  ) async {
    // Strategy 1: Exact match with all parameters
    var lyrics = await _fetchFromLrclib(title, artist, album, duration,
        strategy: "Exact match");
    if (lyrics != null) return lyrics;

    // Strategy 2: Without album
    lyrics = await _fetchFromLrclib(title, artist, null, duration,
        strategy: "Without album");
    if (lyrics != null) return lyrics;

    // Strategy 3: Without duration
    lyrics = await _fetchFromLrclib(title, artist, album, null,
        strategy: "Without duration");
    if (lyrics != null) return lyrics;

    // Strategy 4: Try search endpoint for partial matches
    lyrics = await _searchLrclib(title, artist);
    if (lyrics != null) return lyrics;

    return null;
  }

  /// Fetch from LRCLIB with specific parameters
  Future<String?> _fetchFromLrclib(
      String title, String artist, String? album, Duration? duration,
      {String strategy = "Default"}) async {
    try {
      final queryParams = <String, String>{
        'track_name': title,
        'artist_name': artist,
      };

      if (album != null && album.isNotEmpty) {
        queryParams['album_name'] = album;
      }

      if (duration != null) {
        queryParams['duration'] = duration.inSeconds.toString();
      }

      final uri = Uri.parse("$_lrclibBaseUrl/get")
          .replace(queryParameters: queryParams);
      print("🔍 [$strategy] Searching LRCLIB: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Debug the response structure
        print("📦 [$strategy] Response keys: ${data.keys.join(', ')}");

        // Try synced lyrics first
        final String? syncedLyrics = data['syncedLyrics'];
        if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
          print("✅ [$strategy] Found synced lyrics for '$title'");
          return syncedLyrics;
        }

        // Try plain lyrics
        final String? plainLyrics = data['plainLyrics'];
        if (plainLyrics != null && plainLyrics.isNotEmpty) {
          print("✅ [$strategy] Found plain lyrics for '$title'");
          return plainLyrics;
        }

        // Try alternative field names
        final String? lyrics = data['lyrics'];
        if (lyrics != null && lyrics.isNotEmpty) {
          print("✅ [$strategy] Found lyrics in alternative field for '$title'");
          return lyrics;
        }

        print("❌ [$strategy] No lyrics data in response for '$title'");
        return null;
      } else if (response.statusCode == 404) {
        print("❌ [$strategy] Not found on LRCLIB (404) for '$title'");
        return null;
      } else {
        print(
            "⚠️ [$strategy] LRCLIB error ${response.statusCode} for '$title'");
        return null;
      }
    } catch (e) {
      print("🚨 [$strategy] Error: $e");
      return null;
    }
  }

  /// Search LRCLIB for partial matches
  Future<String?> _searchLrclib(String title, String artist) async {
    try {
      final queryParams = <String, String>{
        'q': '$title $artist',
      };

      final uri = Uri.parse("$_lrclibBaseUrl/search")
          .replace(queryParameters: queryParams);
      print("🔍 [Search] Searching LRCLIB: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          print("✅ [Search] Found ${data.length} potential matches");

          // Try the first result
          final firstResult = data.first as Map<String, dynamic>;
          final String resultTitle = firstResult['trackName'] ?? '';
          final String resultArtist = firstResult['artistName'] ?? '';

          print(
              "🎯 [Search] Trying first result: '$resultTitle' by '$resultArtist'");

          // Fetch lyrics for this specific result
          return await _fetchFromLrclib(resultTitle, resultArtist, null, null,
              strategy: "From search result");
        }
      }

      print("❌ [Search] No results found for '$title $artist'");
      return null;
    } catch (e) {
      print("🚨 [Search] Error: $e");
      return null;
    }
  }

  /// Clean string for better matching
  String _cleanString(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'\([^)]*\)'), '') // Remove content in parentheses
        .replaceAll(RegExp(r'\[[^\]]*\]'), '') // Remove content in brackets
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  /// Extract embedded lyrics from audio file metadata
  Future<String?> _extractEmbeddedLyrics(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
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
          print("Found LRC lyrics file for $filePath");
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
      return null;
    }
  }

  /// Cache lyrics locally
  Future<void> _cacheLyrics(
    String title,
    String artist,
    String lyrics,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_lyricsCacheKey}_${title}_$artist';

      // Store metadata about the lyrics
      final chacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'lyrics': lyrics,
      };
      await prefs.setString('${cacheKey}_meta', json.encode(chacheData));
    } catch (e) {
      // Ignore caching errors
      print("Error caching lyrics: $e");
    }
  }

  /// Get cached lyrics
  Future<String?> _getCachedLyrics(String title, String artist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_lyricsCacheKey}_${title}_$artist';
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final Map<String, dynamic> data = json.decode(cachedData);
        final timestamp = data['timestamp'] as int;
        final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        if (DateTime.now().difference(cachedTime) < _cacheDuration) {
          return data['lyrics'] as String;
        } else {
          // Remove expired cache
          await prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      print("Error getting cached lyrics: $e");
    }
    return null;
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
      return false;
    }
  }

  /// Get cache size info
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheList = prefs.getStringList(_lyricsCacheKey) ?? [];
      final embeddedCacheList =
          prefs.getStringList(_cacheDuration.toString()) ?? [];

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
      return {
        'total_cached': 0,
        'embedded_cached': 0,
        'total_size_bytes': 0,
        'cache_keys': [],
        'embedded_keys': []
      };
    }
  }

  /// Parses a raw LRC/plain string into a list of timed lyric lines
  Future<List<LyricLine>> parseLyrics(String lyricsContent) async {
    try {
      // Check if it's LRC format (contains timestamps)
      final isLrcFormat = lyricsContent.contains(RegExp(r'\[\d+:\d+'));

      if (isLrcFormat) {
        return _parseLrcContent(lyricsContent);
      } else {
        return _parsePlainContent(lyricsContent);
      }
    } catch (e) {
      print('Error parsing lyrics: $e');
      return [];
    }
  }

  /// Parse LRC format with timestamps
  List<LyricLine> _parseLrcContent(String lrcContent) {
    final List<LyricLine> lyricsList = [];
    final lines = lrcContent.split('\n');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final timeRegex = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\]');
      final matches = timeRegex.allMatches(line);

      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        final text = line.substring(line.lastIndexOf(']') + 1).trim();

        if (text.isNotEmpty && text != '//') {
          final minutes = int.parse(lastMatch.group(1)!);
          final seconds = int.parse(lastMatch.group(2)!);
          final milliseconds = lastMatch.group(3) != null
              ? int.parse(lastMatch.group(3)!.padRight(3, '0').substring(0, 3))
              : 0;

          lyricsList.add(LyricLine(
            text: text,
            timestamp: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds,
            ),
          ));
        }
      }
    }

    lyricsList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lyricsList;
  }

  /// Parse plain text content (no timestamps)
  List<LyricLine> _parsePlainContent(String plainContent) {
    final List<LyricLine> lyricsList = [];
    final lines = plainContent.split('\n');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      lyricsList.add(LyricLine(
        text: line,
        timestamp: Duration(seconds: 0), // No timestamp for plain text
      ));
    }

    return lyricsList;
  }

  /// Clear all cached lyrics
  Future<void> clearLyricsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((key) => key.startsWith(_lyricsCacheKey));

      for (final key in keys) {
        await prefs.remove(key);
      }

      print("Lyrics cache cleared");
    } catch (e) {
      print("Error clearing lyrics cache: $e");
    }
  }
}
