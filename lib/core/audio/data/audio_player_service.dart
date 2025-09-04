import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:my_player/core/media_library/domain/entities/song.dart';

// For native video backend setup if needed

/// Service to manage audio playback using media_kit.
class AudioPlayerService {
  late Player _player;
  Player get player => _player;
  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _autoContinue = true;

  // Streams to expose player state
  final _currentSongController = StreamController<Song?>.broadcast();
  Stream<Song?> get currentSongStream => _currentSongController.stream;

  final _isPlayingController = StreamController<bool>.broadcast();
  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  final _currentPositionController = StreamController<Duration>.broadcast();
  Stream<Duration> get currentPositionStream =>
      _currentPositionController.stream;

  final _totalDurationController = StreamController<Duration>.broadcast();
  Stream<Duration> get totalDurationStream => _totalDurationController.stream;

  final _playlistController = StreamController<List<Song>>.broadcast();
  Stream<List<Song>> get playlistStream => _playlistController.stream;

  Song? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  AudioPlayerService() {
    // For desktop platforms (Windows, macOS, Linux):
    // Install media_kit_audio to `audio/` directory.
    // Install media_kit_video to `video/` directory.
    // See: https://pub.dev/packages/media_kit_audio / https://pub.dev/packages/media_kit_video
    _player = Player();
    _initListeners();
  }

  void _initListeners() {
    _player.stream.playing.listen((isPlaying) {
      _isPlaying = isPlaying;
      _isPlayingController.add(isPlaying);
    });

    _player.stream.position.listen((position) {
      _currentPosition = position;
      _currentPositionController.add(position);
    });

    _player.stream.duration.listen((duration) {
      _totalDuration = duration;
      _totalDurationController.add(duration);
    });

    _player.stream.error.listen((error) {
      print('MediaKit Error: $error');
      // TODO: Handle playback errors (e.g., show an error message to the user)
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        print('Playback completed for $_currentSong');
        _handleSongCompletion();
      }
    });
  }

  /// Handle song completion - auto-continue to next song
  void _handleSongCompletion() {
    if (_autoContinue && _playlist.isNotEmpty && _currentIndex >= 0) {
      final nextIndex = (_currentIndex + 1) % _playlist.length;
      final nextSong = _playlist[nextIndex];
      print('Auto-continuing to next song: ${nextSong.title}');
      play(nextSong);
    }
  }

  /// Set playlist for auto-continue functionality
  void setPlaylist(List<Song> playlist, {int startIndex = 0}) {
    _playlist = playlist;
    _currentIndex = startIndex;
    _playlistController.add(_playlist);

    if (playlist.isNotEmpty && startIndex < playlist.length) {
      play(playlist[startIndex]);
    }
  }

  /// Get current playlist
  List<Song> get playlist => _playlist;

  /// Get current index in playlist
  int get currentIndex => _currentIndex;

  /// Set auto-continue mode
  void setAutoContinue(bool enabled) {
    _autoContinue = enabled;
  }

  /// Get auto-continue mode
  bool get autoContinue => _autoContinue;

  /// Play next song in playlist
  Future<void> playNext() async {
    if (_playlist.isNotEmpty && _currentIndex >= 0) {
      final nextIndex = (_currentIndex + 1) % _playlist.length;
      _currentIndex = nextIndex;
      final nextSong = _playlist[nextIndex];
      await play(nextSong);
    }
  }

  /// Play previous song in playlist
  Future<void> playPrevious() async {
    if (_playlist.isNotEmpty && _currentIndex >= 0) {
      final prevIndex =
          _currentIndex > 0 ? _currentIndex - 1 : _playlist.length - 1;
      _currentIndex = prevIndex;
      final prevSong = _playlist[prevIndex];
      await play(prevSong);
    }
  }

  /// Plays a given song from its local file path.
  Future<void> play(Song song) async {
    try {
      _currentSong = song;
      _currentSongController.add(song);
      _totalDurationController
          .add(song.duration); // Set total duration immediately

      // Update current index if song is in playlist
      if (_playlist.isNotEmpty) {
        final index = _playlist.indexWhere((s) => s.id == song.id);
        if (index >= 0) {
          _currentIndex = index;
        }
      }

      await _player.open(Media(song.data));
      await _player.play();
    } catch (e) {
      print('Error playing song: $e');
      // TODO: Notify UI about playback error
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSong = null;
    _currentSongController.add(null);
    _isPlayingController.add(false);
    _currentPositionController.add(Duration.zero);
    _totalDurationController.add(Duration.zero);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // Getters for current state (for initial state or direct access)
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  // Dispose method to release resources
  Future<void> dispose() async {
    await _player.dispose();
    await _currentSongController.close();
    await _isPlayingController.close();
    await _currentPositionController.close();
    await _totalDurationController.close();
    await _playlistController.close();
  }
}
