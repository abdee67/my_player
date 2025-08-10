import 'package:flutter/material.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('playerControls'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const Key('previousButton'),
              icon: const Icon(Icons.skip_previous, size: 36, color: Colors.white),
              onPressed: onPrevious,
            ),
            IconButton(
              key: const Key('playPauseButton'),
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                size: 56,
                color: Colors.deepPurpleAccent,
              ),
              onPressed: onPlayPause,
            ),
            IconButton(
              key: const Key('nextButton'),
              icon: const Icon(Icons.skip_next, size: 36, color: Colors.white),
              onPressed: onNext,
            ),
          ],
        ),
        Slider(
          key: const Key('seekBar'),
          value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
          min: 0,
          max: duration.inMilliseconds.toDouble(),
          onChanged: (value) => onSeek(Duration(milliseconds: value.toInt())),
          activeColor: Colors.deepPurpleAccent,
          inactiveColor: Colors.white24,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }
}
