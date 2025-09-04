import 'package:flutter/material.dart';
import 'package:my_player/core/audio/presentation/notifiers/audio_player_notifier.dart';
import 'package:my_player/features/now_playing/presentation/screens/player_screen.dart';
import 'package:provider/provider.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player =
        Provider.of<AudioPlayerNotifier>(context, listen: false).player;

    return PlayerScreen(audioPlayer: player, lyrics: []);
  }
}
