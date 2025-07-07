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
  }

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

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

  @override
  void dispose() {
    _audioPlayerService.dispose(); // Dispose the service when notifier is no longer needed
    super.dispose();
  }
}