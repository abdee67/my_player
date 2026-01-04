import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:my_player/core/audio/background/audio_handler.dart';
import 'package:my_player/core/media_library/domain/entities/song.dart';
import 'package:my_player/shared/exceptions/exceptions.dart';

/// Service that coordinates app state with [AudioHandler] playback.
class AudioPlayerService {
  AudioPlayerService(this._audioHandler)
      : _playerHandler = _audioHandler as PlayerAudioHandler {
    _attachHandlerStreams();
  }

  final AudioHandler _audioHandler;
  final PlayerAudioHandler _playerHandler;

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

  StreamSubscription<PlaybackState>? _playbackSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<List<MediaItem>>? _queueSub;
  StreamSubscription<Duration>? _positionTicker;

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

  void _attachHandlerStreams() {
    _playbackSub = _audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      if (!_isPlayingController.isClosed) {
        _isPlayingController.add(state.playing);
      }
      _currentPosition = state.updatePosition;
      if (!_currentPositionController.isClosed) {
        _currentPositionController.add(state.updatePosition);
      }
    });

    _mediaItemSub = _audioHandler.mediaItem.listen((item) {
      if (item == null) {
        _currentSong = null;
        if (!_currentSongController.isClosed) {
          _currentSongController.add(null);
        }
        return;
      }
      final song = _playlist.firstWhere(
        (s) => s.id == item.id,
        orElse: () => _songFromMediaItem(item),
      );
      _currentSong = song;
      if (!_currentSongController.isClosed) {
        _currentSongController.add(song);
      }
      if (item.duration != null && !_totalDurationController.isClosed) {
        _totalDuration = item.duration!;
        _totalDurationController.add(item.duration!);
      }
    });

    _queueSub = _audioHandler.queue.listen((mediaItems) {
      if (mediaItems.isEmpty) {
        _playlist = [];
        _playlistController.add([]);
        _currentIndex = -1;
        return;
      }

      final mapped = mediaItems
          .map((item) => _playlist.firstWhere(
                (song) => song.id == item.id,
                orElse: () => _songFromMediaItem(item),
              ))
          .toList(growable: false);
      _playlist = mapped;
      _playlistController.add(mapped);
    });

    _positionTicker = AudioService.position.listen((position) {
      _currentPosition = position;
      if (!_currentPositionController.isClosed) {
        _currentPositionController.add(position);
      }
    });
  }

  Future<void> setPlaylist(
    List<Song> playlist, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    if (_isDisposed) return;
    if (playlist.isEmpty) {
      await stop();
      return;
    }

    _playlist = List<Song>.from(playlist);
    _currentIndex = startIndex.clamp(0, playlist.length - 1);

    try {
      await _playerHandler.setPlaylist(
        playlist,
        startIndex: _currentIndex,
        autoPlay: autoPlay,
      );
      if (!_playlistController.isClosed) {
        _playlistController.add(_playlist);
      }
    } catch (e) {
      _handleError(PlaybackException('Failed to set playlist: $e'));
    }
  }

  List<Song> get playlist => List<Song>.from(_playlist);

  int get currentIndex => _currentIndex;

  void setAutoContinue(bool enabled) {
    _autoContinue = enabled;
  }

  bool get autoContinue => _autoContinue;

  Future<void> playNext() async {
    if (_isDisposed) return;
    if (_playlist.isEmpty) return;
    try {
      await _audioHandler.skipToNext();
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    } catch (e) {
      _handleError(PlaybackException('Failed to skip to next: $e'));
    }
  }

  Future<void> playPrevious() async {
    if (_isDisposed) return;
    if (_playlist.isEmpty) return;
    try {
      await _audioHandler.skipToPrevious();
      _currentIndex =
          _currentIndex > 0 ? _currentIndex - 1 : _playlist.length - 1;
    } catch (e) {
      _handleError(PlaybackException('Failed to skip to previous: $e'));
    }
  }

  Future<void> playAtIndex(int index) async {
    if (_isDisposed) return;
    if (_playlist.isEmpty || index < 0 || index >= _playlist.length) return;
    try {
      await _audioHandler.skipToQueueItem(index);
      _currentIndex = index;
    } catch (e) {
      _handleError(PlaybackException('Failed to play index $index: $e'));
    }
  }

  Future<void> play(Song song) async {
    if (_isDisposed) return;
    try {
      await _playerHandler.setSingleSong(song);
      _currentSong = song;
      _currentIndex = 0;
    } catch (e) {
      _handleError(PlaybackException('Failed to play song ${song.title}: $e'));
    }
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    await _audioHandler.pause();
  }

  Future<void> resume() async {
    if (_isDisposed) return;
    await _audioHandler.play();
  }

  Future<void> stop() async {
    if (_isDisposed) return;
    await _audioHandler.stop();
    _resetState();
  }

  Future<void> seek(Duration position) async {
    if (_isDisposed) return;
    await _audioHandler.seek(position);
  }

  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;
    await _playerHandler.setPlayerVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setRate(double rate) async {
    if (_isDisposed) return;
    await _playerHandler.setSpeed(rate.clamp(0.25, 2.0));
  }

  Future<void> setShuffle(bool shuffle) async {
    if (_isDisposed) return;
    final mode =
        shuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none;
    await _audioHandler.setShuffleMode(mode);
  }

  Future<void> setPlaylistMode(AudioServiceRepeatMode mode) async {
    if (_isDisposed) return;
    await _audioHandler.setRepeatMode(mode);
  }

  void _resetState() {
    _currentSong = null;
    _playlist = [];
    _currentIndex = -1;
    _isPlayingController.add(false);
    _currentSongController.add(null);
    _currentPositionController.add(Duration.zero);
    _totalDurationController.add(Duration.zero);
    _playlistController.add([]);
  }

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  Future<void> dispose() async {
    _isDisposed = true;
    await _playbackSub?.cancel();
    await _mediaItemSub?.cancel();
    await _queueSub?.cancel();
    await _positionTicker?.cancel();
    await _playerHandler.dispose();
    await _currentSongController.close();
    await _isPlayingController.close();
    await _currentPositionController.close();
    await _totalDurationController.close();
    await _playlistController.close();
    await _errorController.close();
  }

  void _handleError(PlayerException exception) {
    if (!_errorController.isClosed) {
      _errorController.add(exception);
    }
  }

  static Song _songFromMediaItem(MediaItem item) {
    final extras = item.extras ?? const {};
    final path = extras['path'] as String? ?? '';
    return Song(
      id: item.id,
      title: item.title,
      artist: item.artist ?? 'Unknown Artist',
      album: item.album ?? 'Unknown Album',
      data: path,
      duration: item.duration ?? Duration.zero,
      albumArt: null,
    );
  }
}
