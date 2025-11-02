import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Represents a local music track with comprehensive metadata.
class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String data; // The absolute path to the audio file
  final Duration duration;
  final Uint8List? albumArt; // Raw bytes of album art
  final int? fileSize;
  final String? genre;
  final int? trackNumber;
  final int? year;
  final String? filePath;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.data,
    required this.duration,
    this.albumArt,
    this.fileSize,
    this.genre,
    this.trackNumber,
    this.year,
    this.filePath,
  });

  String get displayTitle => title.isNotEmpty ? title : 'Unknown Title';
  String get displayArtist => artist.isNotEmpty ? artist : 'Unknown Artist';
  String get displayAlbum => album.isNotEmpty ? album : 'Unknown Album';
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Factory constructor to create a Song from on_audio_query's SongModel
  factory Song.fromAudioQuery(Map<String, dynamic> map) {
    return Song(
      id: map['id'].toString(),
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String? ?? 'Unknown Album',
      data: map['data'] as String? ?? '', // File path
      duration: Duration(milliseconds: map['duration'] as int? ?? 0),
      albumArt: map['artwork'] as Uint8List?,
      fileSize: map['fileSize'] as int? ?? 0,
      genre: map['genre'] as String? ?? 'Unknown Genre',
      trackNumber: map['trackNumber'] as int? ?? 0,
      year: map['year'] as int? ?? 0,
      filePath: map['data'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'data': data,
      'duration': duration.inMilliseconds,
      'fileSize': fileSize,
      'genre': genre,
      'trackNumber': trackNumber,
      'year': year,
      'filePath': filePath,
      //albumArt is not cached for performance/storage reasons
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      data: json['data'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      albumArt: json['albumArt'] as Uint8List?, // Not cached
      fileSize: json['fileSize'] as int?,
      genre: json['genre'] as String?,
      trackNumber: json['trackNumber'] as int?,
      year: json['year'] as int?,
    );
  }

//copyWith method for immutable objects
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? data,
    Duration? duration,
    Uint8List? albumArt,
    int? fileSize,
    String? genre,
    int? trackNumber,
    int? year,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      data: data ?? this.data,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      fileSize: fileSize ?? this.fileSize,
      genre: genre ?? this.genre,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        data,
        duration,
        albumArt,
        fileSize,
        genre,
        trackNumber,
        year
      ];

  // A simple toString for debugging
  @override
  String toString() {
    return 'Song(title: $title, artist: $artist, album: $album, duration: $formattedDuration)';
  }
}
