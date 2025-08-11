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
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      itemCount: lyrics.length,
      padding: const EdgeInsets.symmetric(
          vertical: 24), // Reduced padding for better centering
      itemBuilder: (context, index) {
        final isCurrent = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(
              vertical: isCurrent ? 12 : 0, horizontal: isCurrent ? 24 : 0),
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.deepPurple.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Text(
              lyrics[index].text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isCurrent ? 22 : 18,
                color: isCurrent ? Colors.deepPurple : Colors.white70,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                shadows: isCurrent
                    ? [
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 3,
                          color: Colors.deepPurpleAccent.withOpacity(0.7),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
