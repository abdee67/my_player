// lib/core/lyrics/presentation/widgets/lyrics_list.dart
import 'package:flutter/material.dart';
import 'package:my_player/core/lyrics/domain/entities/lyricLine.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class LyricsList extends StatelessWidget {
  final List<LyricLine> lyrics;
  final int currentIndex;
  final bool hasTimestamps;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Function(int) onTapLine;

  const LyricsList({
    super.key,
    required this.lyrics,
    required this.currentIndex,
    required this.hasTimestamps,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.onTapLine,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemCount: lyrics.length,
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      itemBuilder: (context, index) {
        final lyric = lyrics[index];
        final isActive = index == currentIndex && hasTimestamps;
        
        return GestureDetector(
          onTap: () => onTapLine(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              lyric.text,
              style: TextStyle(
                fontSize: isActive ? 22 : 18,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}