import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_player/core/media_library/domain/entities/song.dart';

/// Bridges `audio_service` with `just_audio` so the OS can control playback
/// from the notification tray / lock screen.
class PlayerAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  PlayerAudioHandler() {
    _eventSub = _player.playbackEventStream.listen(_broadcastState);
    _indexSub = _player.currentIndexStream.listen(_handleIndexChange);
    _durationSub = _player.durationStream.listen(_updateDurationForCurrentItem);
  }

  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlaybackEvent>? _eventSub;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<Duration?>? _durationSub;

  /// Load an entire playlist of [songs] and optionally start at [startIndex].
  Future<void> setPlaylist(
    List<Song> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty) {
      await stop();
      return;
    }

    final safeIndex = _clampIndex(startIndex, songs.length);
    final mediaItems = songs.map(_songToMediaItem).toList(growable: false);
    queue.add(mediaItems);

    final playlistSource = ConcatenatingAudioSource(
      children: [
        for (final item in mediaItems)
          AudioSource.uri(
            _uriFromMediaItem(item),
            tag: item,
          ),
      ],
    );

    await _player.setAudioSource(
      playlistSource,
      initialIndex: safeIndex,
      initialPosition: Duration.zero,
    );

    mediaItem.add(mediaItems[safeIndex]);

    if (autoPlay) {
      await play();
    }
  }

  /// Replace the playlist with a single [song].
  Future<void> setSingleSong(Song song, {bool autoPlay = true}) async {
    await setPlaylist([song], startIndex: 0, autoPlay: autoPlay);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    final enabled = mode != AudioServiceShuffleMode.none;
    await _player.setShuffleModeEnabled(enabled);
    await super.setShuffleMode(mode);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    final loopMode = switch (mode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all => LoopMode.all,
      _ => LoopMode.off,
    };
    await _player.setLoopMode(loopMode);
    await super.setRepeatMode(mode);
  }

  Future<void> setPlayerVolume(double volume) => _player.setVolume(volume);

  Future<void> setPlayerShuffle(bool enabled) async {
    final mode =
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none;
    await setShuffleMode(mode);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (queue.value.isEmpty) {
      return;
    }
    final target = _clampIndex(index, queue.value.length);
    await _player.seek(Duration.zero, index: target);
  }

  @override
  Future<void> onTaskRemoved() => stop();

  /// Clean up internal resources. Call this from the owning service.
  Future<void> dispose() async {
    await _eventSub?.cancel();
    await _indexSub?.cancel();
    await _durationSub?.cancel();
    await _player.dispose();
  }

  void _broadcastState(PlaybackEvent event) {
    final hasMultipleItems = queue.value.length > 1;

    final controls = <MediaControl>[
      if (hasMultipleItems) MediaControl.skipToPrevious,
      _player.playing ? MediaControl.pause : MediaControl.play,
      if (hasMultipleItems) MediaControl.skipToNext,
      MediaControl.stop,
    ];

    final compactIndices = <int>[];
    for (var i = 0; i < controls.length && compactIndices.length < 3; i++) {
      if (controls[i] == MediaControl.stop) break;
      compactIndices.add(i);
    }

    final processingState =
        _processingState[event.processingState] ?? AudioProcessingState.idle;

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.stop,
        },
        androidCompactActionIndices: compactIndices,
        processingState: processingState,
        playing: _player.playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex ?? _player.currentIndex,
      ),
    );
  }

  void _handleIndexChange(int? index) {
    final currentQueue = queue.value;
    if (index == null || index < 0 || index >= currentQueue.length) {
      return;
    }
    mediaItem.add(currentQueue[index]);
  }

  void _updateDurationForCurrentItem(Duration? duration) {
    final index = _player.currentIndex;
    final currentQueue = queue.value;
    if (index == null || index < 0 || index >= currentQueue.length) {
      return;
    }
    final currentItem = currentQueue[index];
    if (currentItem.duration == duration) {
      return;
    }

    final updatedItem = currentItem.copyWith(duration: duration);
    final updatedQueue = currentQueue.toList(growable: false);
    updatedQueue[index] = updatedItem;
    queue.add(updatedQueue);
    mediaItem.add(updatedItem);
  }

  static MediaItem _songToMediaItem(Song song) {
    return MediaItem(
      id: song.id,
      album: song.album,
      title: song.displayTitle,
      artist: song.displayArtist,
      duration: song.duration,
      playable: true,
      extras: {
        'path': song.data,
      },
    );
  }

  static Uri _uriFromMediaItem(MediaItem item) {
    final path = item.extras?['path'] as String?;
    if (path == null) {
      throw StateError('Missing local file path for media item: ${item.id}');
    }
    return Uri.file(path);
  }

  static const Map<ProcessingState, AudioProcessingState> _processingState = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  static int _clampIndex(int index, int length) {
    if (length <= 0) return 0;
    if (index < 0) return 0;
    if (index >= length) return length - 1;
    return index;
  }
}

/// Convenience helper so consumers can request background playback without
/// reaching into the handler’s internals.
@pragma('vm:entry-point')
Future<AudioHandler> initPlayerAudioHandler() {
  return AudioService.init(
    builder: () => PlayerAudioHandler(),
    config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.my_player.playback',
        androidNotificationChannelName: 'Now Playing',
        androidNotificationIcon: 'mipmap/ic_launcher',
        artDownscaleHeight: 1024,
        artDownscaleWidth: 1024,
        androidNotificationOngoing: true,
        notificationColor: Colors.blue,
        androidNotificationChannelDescription:
            'Controls the playback of ur cool music'),
  );
}
