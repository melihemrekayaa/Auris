import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/podcast_history.dart';
import '../repositories/cloud_repository.dart';
import 'auth_provider.dart';

class HistoryNotifier extends AsyncNotifier<List<PodcastHistory>> {
  @override
  Future<List<PodcastHistory>> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return [];
    }
    final cloudRepo = ref.read(cloudRepositoryProvider);
    final podcasts = await cloudRepo.fetchPodcasts(user.uid);
    
    // Yerel dosya durumlarını kontrol et
    final appDocDir = await getApplicationDocumentsDirectory();
    return podcasts.map((p) {
      final localPath = '${appDocDir.path}/podcast_${p.id}.mp3';
      final exists = File(localPath).existsSync();
      return p.copyWith(
        isDownloaded: exists,
        localFilePath: exists ? localPath : null,
      );
    }).toList();
  }

  /// Uploads audio to cloud, saves metadata, and returns the download URL.
  Future<String> addPodcast(PodcastHistory podcast, List<int> audioBytes) async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) throw Exception('User not logged in');

    final cloudRepo = ref.read(cloudRepositoryProvider);

    final downloadUrl = await cloudRepo.uploadAudio(user.uid, podcast.id, audioBytes);
    
    final cloudPodcast = podcast.copyWith(audioFilePath: downloadUrl);

    await cloudRepo.savePodcastMetadata(user.uid, cloudPodcast);

    final previousState = state.value ?? [];
    state = AsyncValue.data([cloudPodcast, ...previousState]);

    return downloadUrl;
  }

  /// Favorilere ekle/çıkar
  Future<void> toggleFavorite(String podcastId) async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return;

    final cloudRepo = ref.read(cloudRepositoryProvider);
    final currentList = state.value ?? [];
    
    final index = currentList.indexWhere((p) => p.id == podcastId);
    if (index == -1) return;

    final podcast = currentList[index];
    final updated = podcast.copyWith(isFavorite: !podcast.isFavorite);

    // Optimistic UI update
    final newList = [...currentList];
    newList[index] = updated;
    state = AsyncValue.data(newList);

    // Firestore'a kaydet
    await cloudRepo.savePodcastMetadata(user.uid, updated);
  }

  /// Cloud'dan cihaza indir
  Future<void> downloadPodcast(String podcastId) async {
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((p) => p.id == podcastId);
    if (index == -1) return;

    final podcast = currentList[index];
    if (podcast.isDownloaded) return; // Zaten indirilmiş

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDocDir.path}/podcast_${podcast.id}.mp3';

      // Firebase Storage URL'den indir
      final response = await http.get(Uri.parse(podcast.audioFilePath));
      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);

        final updated = podcast.copyWith(
          isDownloaded: true,
          localFilePath: localPath,
        );

        final newList = [...currentList];
        newList[index] = updated;
        state = AsyncValue.data(newList);
      }
    } catch (e) {
      // Sessizce hata yut — indirme başarısız oldu
    }
  }

  /// İndirilen dosyayı sil (cloud'dan silmez, sadece yerelden)
  Future<void> removeDownload(String podcastId) async {
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((p) => p.id == podcastId);
    if (index == -1) return;

    final podcast = currentList[index];
    if (podcast.localFilePath != null) {
      try {
        final file = File(podcast.localFilePath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    final updated = podcast.copyWith(isDownloaded: false, localFilePath: null);
    final newList = [...currentList];
    newList[index] = updated;
    state = AsyncValue.data(newList);
  }

  Future<void> deletePodcast(String id) async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return;

    final cloudRepo = ref.read(cloudRepositoryProvider);
    final previousState = state.value ?? [];
    
    // Yerel dosyayı da sil
    final podcast = previousState.firstWhere((p) => p.id == id);
    if (podcast.localFilePath != null) {
      try {
        final file = File(podcast.localFilePath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    
    state = AsyncValue.data(previousState.where((p) => p.id != id).toList());

    try {
      await cloudRepo.deleteAudio(user.uid, id);
      await cloudRepo.deletePodcastMetadata(user.uid, id);
    } catch (e) {
      state = AsyncValue.data(previousState);
    }
  }
}

final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<PodcastHistory>>(() {
  return HistoryNotifier();
});
