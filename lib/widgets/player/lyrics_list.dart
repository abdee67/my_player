import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../models/lyricLine.dart';

class LyricsList extends StatelessWidget {
  final List<LyricLine> lyrics;
  final int currentIndex;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Function(int) onTapLine;

  const LyricsList({
    super.key,
    required this.lyrics,
    required this.currentIndex,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.onTapLine,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      physics: const BouncingScrollPhysics(),
      key: const Key('lyricsList'),
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final lyric = lyrics[index];
        final isActive = index == currentIndex;
        return GestureDetector(
          key: Key('lyricLine_$index'),
          onTap: () => onTapLine(index),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: index == currentIndex ? Colors.deepPurpleAccent : Colors.white70,
              fontWeight: index == currentIndex ? FontWeight.bold : FontWeight.normal,
              fontSize: index == currentIndex ? 20 : 16,
              shadows: index == currentIndex
                  ? [Shadow(color: Colors.deepPurpleAccent.withOpacity(0.3), blurRadius: 8)]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
              child: Text(lyric.text, textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.deepPurpleAccent : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: isActive ? 20 : 16,
              ),
            ),
          ),
          )
        );
      },
    );
  }
}
