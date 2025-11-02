class AppConstants {
  static const String appName = 'URS Player';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'URS Player';
  static const String appIcon = 'assets/default_album_art.png';
  static const String appSupportEmail = 'alaziizz67@gmail.com'; // Corrected the typo
  static const String appSupportPhone = '0977764845';

  // Storage and File Paths
  static const String audioCachePath = 'audio_cache'; // Corrected spelling from Cahce to Cache
  static const String lyricsCachePath = 'lyrics_cache';
  static const String albumArtCachePath = 'album_art_cache';

  // Player and Playback
  static const double miniPlaybackSpeed = 0.5;
  static const double maxPlaybackSpeed = 2.0;
  static const double defaultPlaybackSpeed = 1.0;
  static const int seekMilliseconds = 10000; // 10 seconds for a quick seek action

  // UI and Animation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration seekAnimationDuration = Duration(milliseconds: 200);
  static const Duration splashScreenDuration = Duration(seconds: 3);

  // Layouts and Dimensions
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 8.0;
  static const double buttonRadius = 24.0;
}