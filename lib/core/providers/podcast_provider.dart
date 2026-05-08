import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/scraper_service.dart';
import '../services/ai_service.dart';
import '../models/word_timestamp.dart';
import '../models/podcast_history.dart';
import '../utils/category_detector.dart';
import 'history_provider.dart';
import 'package:uuid/uuid.dart';

final scraperServiceProvider = Provider<ScraperService>((ref) => ScraperService());
final aiServiceProvider = Provider<AIService>((ref) => AIService());

// State to manage the generation process
class PodcastGenerationState {
  final bool isLoading;
  final String statusMessage;
  final String? audioFilePath;
  final String? error;
  final List<WordTimestamp>? wordTimestamps;
  final String? script;
  final String? title;
  final String? imageUrl;
  final String? category;

  PodcastGenerationState({
    this.isLoading = false,
    this.statusMessage = '',
    this.audioFilePath,
    this.error,
    this.wordTimestamps,
    this.script,
    this.title,
    this.imageUrl,
    this.category,
  });

  PodcastGenerationState copyWith({
    bool? isLoading,
    String? statusMessage,
    String? audioFilePath,
    String? error,
    List<WordTimestamp>? wordTimestamps,
    String? script,
    String? title,
    String? imageUrl,
    String? category,
  }) {
    return PodcastGenerationState(
      isLoading: isLoading ?? this.isLoading,
      statusMessage: statusMessage ?? this.statusMessage,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      error: error,
      wordTimestamps: wordTimestamps ?? this.wordTimestamps,
      script: script ?? this.script,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
    );
  }
}

class PodcastNotifier extends Notifier<PodcastGenerationState> {
  @override
  PodcastGenerationState build() {
    return PodcastGenerationState();
  }

  Future<bool> generatePodcast(String url) async {
    final scraper = ref.read(scraperServiceProvider);
    final ai = ref.read(aiServiceProvider);

    try {
      state = state.copyWith(isLoading: true, statusMessage: 'Reading the article...', error: null);
      
      // 1. Scrape URL (now returns title, image, category too)
      final article = await scraper.scrapeArticle(url);
      
      state = state.copyWith(statusMessage: 'Writing podcast script...');
      
      // 2. Generate Script
      final script = await ai.generatePodcastScript(article.text);
      
      state = state.copyWith(statusMessage: 'Recording voice...');
      
      // 3. Generate Audio with Timestamps
      final result = await ai.generateAudio(script);
      
      state = state.copyWith(statusMessage: 'Saving to cloud...');
      
      final uuid = const Uuid().v4();
      
      // 4. Akıllı kategori tespiti
      final smartCategory = CategoryDetector.detect(
        title: article.title,
        rawCategory: article.category,
        url: url,
      );

      // 5. Upload to cloud and save metadata — returns the download URL
      final history = PodcastHistory(
        id: uuid,
        url: url,
        title: article.title,
        imageUrl: article.imageUrl,
        category: smartCategory,
        audioFilePath: '', // Will be replaced by the cloud URL
        script: script,
        wordTimestamps: result.wordTimestamps,
        createdAt: DateTime.now(),
      );
      
      final downloadUrl = await ref.read(historyProvider.notifier).addPodcast(history, result.audioBytes);

      state = state.copyWith(
        isLoading: false,
        audioFilePath: downloadUrl, // Real cloud URL — ready to play!
        statusMessage: 'Done!',
        wordTimestamps: result.wordTimestamps,
        script: script,
        title: article.title,
        imageUrl: article.imageUrl,
        category: smartCategory,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

final podcastProvider = NotifierProvider<PodcastNotifier, PodcastGenerationState>(() {
  return PodcastNotifier();
});
