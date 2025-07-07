import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lyrics_parser/lyrics_parser.dart'; // For parsing LRC

/// Service to fetch lyrics from LRCLIB and parse them.
class LyricsService {
  static const String _lrclibBaseUrl = 'https://lrclib.net/api/get';

  /// Fetches LRC lyrics for a given song.
  /// Returns the raw LRC content string if found, otherwise null.
  Future<String?> fetchLyrics(
    String title,
    String artist,
    String? album,
    Duration duration,
  ) async {
    try {
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
          return syncedLyrics;
        } else {
          final String? plainLyrics = data['plainLyrics'];
          if (plainLyrics != null && plainLyrics.isNotEmpty) {
            print("Plain Lyrics fetched successfully for $title by $artist");
            return plainLyrics;
          } else if (syncedLyrics == null && plainLyrics == null) {
            print(
              "No lyrics found for $title by $artist)",
            );
            // Optionally, you can return plain lyrics if synced are not available
            // return data['plainLyrics'] as String?;
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
        // TODO: Handle other HTTP status codes
        return null;
      }
    } catch (e) {
      print("Error fetching lyrics: $e");
      // TODO: Handle network errors (e.g., no internet connection)
      return null;
    }
    return null;
  }

  /// Parses a raw LRC string into a list of timed lyric lines.
  /// Returns an empty list if parsing fails.
  Future<List<dynamic>> parseLrc(String lrcContent) async {
    try {
      final parser = LyricsParser(lrcContent);
      final result = await parser.parse(); // Await the async parse() method
      return result as List<dynamic>; // The result is the lyrics list itself
    } catch (e) {
      print("Error parsing LRC: $e");
      return [];
    }
  }
}
