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
  final bool isFavorite;
  final bool isDownloaded;
  final String? localFilePath; // Cihaza indirildiğinde yerel dosya yolu

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
    this.isFavorite = false,
    this.isDownloaded = false,
    this.localFilePath,
  });

  PodcastHistory copyWith({
    String? id,
    String? url,
    String? title,
    String? imageUrl,
    String? category,
    String? audioFilePath,
    String? script,
    List<WordTimestamp>? wordTimestamps,
    DateTime? createdAt,
    bool? isFavorite,
    bool? isDownloaded,
    String? localFilePath,
  }) {
    return PodcastHistory(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      script: script ?? this.script,
      wordTimestamps: wordTimestamps ?? this.wordTimestamps,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

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
      isFavorite: json['isFavorite'] ?? false,
      isDownloaded: json['isDownloaded'] ?? false,
      localFilePath: json['localFilePath'],
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
      'isFavorite': isFavorite,
      'isDownloaded': isDownloaded,
      'localFilePath': localFilePath,
    };
  }
}
