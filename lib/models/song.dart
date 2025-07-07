import 'dart:typed_data';

/// Represents a local music track.
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String data; // The absolute path to the audio file
  final Duration duration;
  final Uint8List? albumArt; // Raw bytes of album art

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.data,
    required this.duration,
    this.albumArt,
  });

  // Factory constructor to create a Song from on_audio_query's SongModel
  factory Song.fromAudioQuery(Map<String, dynamic> map) {
    return Song(
      id: map['id'].toString(),
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String? ?? 'Unknown Album',
      data: map['data'] as String? ?? '', // File path
      duration: Duration(milliseconds: map['duration'] as int? ?? 0),
      albumArt: map['artwork'] as Uint8List?, // Assuming 'artwork' key holds Uint8List
    );
  }

  // A simple toString for debugging
  @override
  String toString() {
    return 'Song(title: $title, artist: $artist, album: $album, duration: $duration)';
  }
}