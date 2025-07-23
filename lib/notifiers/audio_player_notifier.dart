import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';

/// Notifier for managing and exposing audio player state to the UI.
class AudioPlayerNotifier extends ChangeNotifier {
  final AudioPlayerService _audioPlayerService;

  Song? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _autoContinue = true;

  AudioPlayerNotifier(this._audioPlayerService) {
    _audioPlayerService.currentSongStream.listen((song) {
      _currentSong = song;
      notifyListeners();
    });
    _audioPlayerService.isPlayingStream.listen((isPlaying) {
      _isPlaying = isPlaying;
      notifyListeners();
    });
    _audioPlayerService.currentPositionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    _audioPlayerService.totalDurationStream.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });
    _audioPlayerService.playlistStream.listen((playlist) {
      _playlist = playlist;
      notifyListeners();
    });
  }

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get autoContinue => _autoContinue;

  Future<void> playSong(Song song) async {
    await _audioPlayerService.play(song);
  }

  Future<void> pauseSong() async {
    await _audioPlayerService.pause();
  }

  Future<void> resumeSong() async {
    await _audioPlayerService.resume();
  }

  Future<void> stopSong() async {
    await _audioPlayerService.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayerService.seek(position);
  }

  /// Set playlist for auto-continue functionality
  void setPlaylist(List<Song> playlist, {int startIndex = 0}) {
    _playlist = playlist;
    _currentIndex = startIndex;
    _audioPlayerService.setPlaylist(playlist, startIndex: startIndex);
    notifyListeners();
  }

  /// Play next song in playlist
  Future<void> playNext() async {
    await _audioPlayerService.playNext();
  }

  /// Play previous song in playlist
  Future<void> playPrevious() async {
    await _audioPlayerService.playPrevious();
  }

  /// Set auto-continue mode
  void setAutoContinue(bool enabled) {
    _autoContinue = enabled;
    _audioPlayerService.setAutoContinue(enabled);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayerService
        .dispose(); // Dispose the service when notifier is no longer needed
    super.dispose();
  }
}
