class LyricLine {
  final String text;
  final Duration timestamp; // Start time of the line

  LyricLine( {required this.text, required this.timestamp});

  
   factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      text: json['text'],
      timestamp: json['time'],
    );
  }
}