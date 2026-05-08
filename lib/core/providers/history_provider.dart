import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/podcast_history.dart';

class HistoryNotifier extends Notifier<List<PodcastHistory>> {
  static const String _historyKey = 'podcast_history_v1';

  @override
  List<PodcastHistory> build() {
    _loadHistory();
    return [];
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);
    
    if (historyJson != null) {
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final List<dynamic> decodedList = jsonDecode(historyJson);
        final history = decodedList.map((e) {
          final p = PodcastHistory.fromJson(e);
          // Sadece dosya ismini al
          final fileName = p.audioFilePath.split('/').last;
          // Yeni (güncel) uygulama dizini ile birleştir
          final updatedPath = '${appDocDir.path}/$fileName';
          
          return PodcastHistory(
            id: p.id,
            url: p.url,
            title: p.title,
            imageUrl: p.imageUrl,
            category: p.category,
            audioFilePath: updatedPath,
            script: p.script,
            wordTimestamps: p.wordTimestamps,
            createdAt: p.createdAt,
          );
        }).toList();
        // Sort by newest first
        history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = history;
      } catch (e) {
        state = [];
      }
    }
  }

  Future<void> addPodcast(PodcastHistory podcast) async {
    final newState = [podcast, ...state];
    state = newState;
    await _saveToPrefs(newState);
  }

  Future<void> _saveToPrefs(List<PodcastHistory> historyList) async {
    final prefs = await SharedPreferences.getInstance();
    final String historyJson = jsonEncode(historyList.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, historyJson);
  }
  
  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> deletePodcast(String id) async {
    // MP3 dosyasını sil
    final podcast = state.firstWhere((p) => p.id == id);
    try {
      final file = File(podcast.audioFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    final newState = state.where((p) => p.id != id).toList();
    state = newState;
    await _saveToPrefs(newState);
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<PodcastHistory>>(() {
  return HistoryNotifier();
});
