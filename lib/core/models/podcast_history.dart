import 'word_timestamp.dart';

class PodcastHistory {
  final String id;
  final String url;
  final String title;
  final String? imageUrl;
  final String? category;
  final String audioFilePath;
  final String script;
  final List<WordTimestamp> wordTimestamps;
  final DateTime createdAt;

  PodcastHistory({
    required this.id,
    required this.url,
    required this.title,
    this.imageUrl,
    this.category,
    required this.audioFilePath,
    required this.script,
    required this.wordTimestamps,
    required this.createdAt,
  });

  factory PodcastHistory.fromJson(Map<String, dynamic> json) {
    return PodcastHistory(
      id: json['id'],
      url: json['url'],
      title: json['title'] ?? 'Untitled Podcast',
      imageUrl: json['imageUrl'],
      category: json['category'],
      audioFilePath: json['audioFilePath'],
      script: json['script'],
      wordTimestamps: (json['wordTimestamps'] as List)
          .map((e) => WordTimestamp.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'imageUrl': imageUrl,
      'category': category,
      'audioFilePath': audioFilePath,
      'script': script,
      'wordTimestamps': wordTimestamps.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
