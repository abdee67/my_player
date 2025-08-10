import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_player/screens/player_screen.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlayerScreen(audioPlayer: AudioPlayer(), lyrics: []);
  }
}
