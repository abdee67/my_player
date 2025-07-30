class LyricLine {
  final String text;
  final Duration timestamp; // Start time of the line

  LyricLine(this.text, this.timestamp);

  // Optional: Add a factory for parsing LRC lines
  factory LyricLine.fromLrcLine(String line) {
    // Basic LRC parsing (simplified for example)
    RegExp regExp = RegExp(r'^\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    var match = regExp.firstMatch(line);
    if (match != null) {
      int minutes = int.parse(match.group(1)!);
      int seconds = int.parse(match.group(2)!);
      int milliseconds = int.parse(match.group(3)!);
      return LyricLine(
        match.group(4)!.trim(),
        Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        ),
      );
    }
    return LyricLine(line.trim(), Duration.zero); // Fallback for non-timestamped lines
  }
}