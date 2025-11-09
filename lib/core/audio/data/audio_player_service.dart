import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:my_player/core/media_library/domain/entities/song.dart';
import 'package:my_player/shared/exceptions/exceptions.dart';

/// Service to manage audio playback using media_kit with proper error handling
class AudioPlayerService {
  late final Player player;
  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _autoContinue = true;
  bool _isDisposed = false;

  // Streams controllers with error handling
  final _currentSongController = StreamController<Song?>.broadcast();
  final _isPlayingController = StreamController<bool>.broadcast();
  final _currentPositionController = StreamController<Duration>.broadcast();
  final _totalDurationController = StreamController<Duration>.broadcast();
  final _playlistController = StreamController<List<Song>>.broadcast();
  final _errorController = StreamController<PlayerException>.broadcast();

  Song? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  Stream<Song?> get currentSongStream => _currentSongController.stream;
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get currentPositionStream =>
      _currentPositionController.stream;
  Stream<Duration> get totalDurationStream => _totalDurationController.stream;
  Stream<List<Song>> get playlistStream => _playlistController.stream;
  Stream<PlayerException> get errorStream => _errorController.stream;

  AudioPlayerService() {
    _initPlayer();
  }

  void _initPlayer() {
    try {
      MediaKit.ensureInitialized();
      player = Player();
      _initListeners();
    } catch (e) {
      _handleError(PlayerInitializationException(
        'Failed to initialize player: ${e.toString()}',
      ));
    }
  }

  void _initListeners() {
    player.stream.playing.listen((isPlaying) {
      _isPlaying = isPlaying;
      if (!_isPlayingController.isClosed) {
        _isPlayingController.add(isPlaying);
      }
    }, onError: (error) {
      _handleError(
          PlaybackStateException('Playing state error: ${error.toString()}'));
    });

    player.stream.position.listen((position) {
      _currentPosition = position;
      if (!_currentPositionController.isClosed) {
        _currentPositionController.add(position);
      }
    }, onError: (error) {
      _handleError(PositionTrackingException(
          'Position state error: ${error.toString()}'));
    });

    player.stream.duration.listen((duration) {
      _totalDuration = duration;
      if (!_totalDurationController.isClosed) {
        _totalDurationController.add(duration);
      }
    }, onError: (error) {
      _handleError(DurationTrackingException(
          'Duration state error: ${error.toString()}'));
    });

    player.stream.error.listen((error) {
      _handleError(PlaybackException('MediaKit Error: $error'));
    });

    player.stream.completed.listen((completed) {
      if (completed) {
        print('Playback completed for $_currentSong');
        _handleSongCompletion();
      }
    }, onError: (error) {
      _handleError(PlaybackCompletionException(
          'Completion tracking error: ${error.toString()}'));
    });
  }

  void _handleError(PlayerException exception) {
    if (!_errorController.isClosed) {
      _errorController.add(exception);
    }
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
    if (playlist.isEmpty) return;
    _playlist = List<Song>.from(playlist);
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    _playlistController.add(_playlist);
    play(_playlist[_currentIndex]);
  }

  /// Get current playlist
  List<Song> get playlist => List<Song>.from(_playlist);

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
    if (_playlist.isEmpty || _currentIndex < 0) return;
    final nextIndex = (_currentIndex + 1) % _playlist.length;
    _currentIndex = nextIndex;
    final nextSong = _playlist[nextIndex];
    await play(nextSong);
  }

  /// Play previous song in playlist
  Future<void> playPrevious() async {
    if (_playlist.isEmpty || _currentIndex < 0) return;
    final prevIndex =
        _currentIndex > 0 ? _currentIndex - 1 : _playlist.length - 1;
    _currentIndex = prevIndex;
    final prevSong = _playlist[prevIndex];
    await play(prevSong);
  }

  Future<void> playAtIndex(int index) async {
    if (_playlist.isEmpty || index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    final song = _playlist[index];
    await play(song);
  }

  /// Plays a given song from its local file path.
  Future<void> play(Song song) async {
    if (_isDisposed) return;
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
      final fileUri = _getFileUri(song.filePath);
      await player.open(Media(fileUri));
      await player.play();
    } catch (e) {
      _handleError(PlaybackException('Failed to play song ${song.title}: $e'));
    }
  }

  String _getFileUri(String filePath) {
    // On Windows, we need to handle different path formats
    if (filePath.startsWith('file://')) {
      return filePath;
    } else {
      // Convert Windows path to file URI
      final path = filePath.replaceAll(r'\', '/');
      return 'file://$path';
    }
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    await player.pause();
  }

  Future<void> resume() async {
    if (_isDisposed) return;
    await player.play();
  }

  Future<void> stop() async {
    if (_isDisposed) return;
    await player.stop();
    _resetState();
  }

  Future<void> seek(Duration position) async {
    if (_isDisposed) return;
    await player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;
    await player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setRate(double rate) async {
    if (_isDisposed) return;
    await player.setRate(rate.clamp(0.25, 2.0));
  }

  Future<void> setShuffle(bool shuffle) async {
    if (_isDisposed) return;
    await player.setShuffle(shuffle);
  }

  Future<void> setPlaylistMode(PlaylistMode mode) async {
    if (_isDisposed) return;
    await player.setPlaylistMode(mode);
  }

  Future<void> setPitch(double pitch) async {
    if (_isDisposed) return;
    await player.setPitch(pitch.clamp(0.25, 2.0));
  }

  Future<void> setAudioDevice(AudioDevice device) async {
    if (_isDisposed) return;
    await player.setAudioDevice(device);
  }

  void _resetState() {
    _currentSong = null;
    _currentSongController.add(null);
    _isPlayingController.add(false);
    _currentPositionController.add(Duration.zero);
    _totalDurationController.add(Duration.zero);
    _playlistController.add([]);
  }

  // Getters for current state (for initial state or direct access)
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  // Dispose method to release resources
  Future<void> dispose() async {
    _isDisposed = true;
    await player.dispose();
    // Close all stream controllers
    await _currentSongController.close();
    await _isPlayingController.close();
    await _currentPositionController.close();
    await _totalDurationController.close();
    await _playlistController.close();
    await _errorController.close();
  }
}
