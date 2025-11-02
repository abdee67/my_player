// lib/shared/exceptions/exceptions.dart
/// Base class for player exceptions
abstract class PlayerException implements Exception {
  final String message;
  final DateTime timestamp;

  PlayerException(this.message) : timestamp = DateTime.now();

  @override
  String toString() => '$runtimeType: $message (at $timestamp)';
}

// Specific exception types
class PlayerInitializationException extends PlayerException {
  PlayerInitializationException(super.message);
}

class PlaybackException extends PlayerException {
  PlaybackException(super.message);
}

class PlaybackStateException extends PlayerException {
  PlaybackStateException(super.message);
}

class PositionTrackingException extends PlayerException {
  PositionTrackingException(super.message);
}

class DurationTrackingException extends PlayerException {
  DurationTrackingException(super.message);
}

class PlaybackCompletionException extends PlayerException {
  PlaybackCompletionException(super.message);
}