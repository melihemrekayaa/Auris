class WordTimestamp {
  final String word;
  final double startTime; // in seconds
  final double endTime; // in seconds

  WordTimestamp({
    required this.word,
    required this.startTime,
    required this.endTime,
  });

  factory WordTimestamp.fromJson(Map<String, dynamic> json) {
    return WordTimestamp(
      word: json['word'],
      startTime: json['startTime'].toDouble(),
      endTime: json['endTime'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class AudioGenerationResult {
  final List<int> audioBytes;
  final List<WordTimestamp> wordTimestamps;

  AudioGenerationResult({
    required this.audioBytes,
    required this.wordTimestamps,
  });
}
