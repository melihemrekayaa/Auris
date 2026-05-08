import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/podcast_history.dart';
import '../repositories/cloud_repository.dart';
import 'auth_provider.dart';

class HistoryNotifier extends AsyncNotifier<List<PodcastHistory>> {
  @override
  Future<List<PodcastHistory>> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return []; // Return empty if not logged in
    }
    final cloudRepo = ref.read(cloudRepositoryProvider);
    return await cloudRepo.fetchPodcasts(user.uid);
  }

  /// Uploads audio to cloud, saves metadata, and returns the download URL.
  /// UI is updated ONLY after the upload completes — no more empty audioFilePath.
  Future<String> addPodcast(PodcastHistory podcast, List<int> audioBytes) async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) throw Exception('User not logged in');

    final cloudRepo = ref.read(cloudRepositoryProvider);

    // 1. Upload audio to storage FIRST — get the real download URL
    final downloadUrl = await cloudRepo.uploadAudio(user.uid, podcast.id, audioBytes);
    
    // 2. Create the final podcast object with the real cloud URL
    final cloudPodcast = PodcastHistory(
      id: podcast.id,
      url: podcast.url,
      title: podcast.title,
      imageUrl: podcast.imageUrl,
      category: podcast.category,
      audioFilePath: downloadUrl, // Real cloud URL!
      script: podcast.script,
      wordTimestamps: podcast.wordTimestamps,
      createdAt: podcast.createdAt,
    );

    // 3. Save metadata to Firestore
    await cloudRepo.savePodcastMetadata(user.uid, cloudPodcast);

    // 4. NOW update the UI with the complete data
    final previousState = state.value ?? [];
    state = AsyncValue.data([cloudPodcast, ...previousState]);

    return downloadUrl;
  }

  Future<void> clearHistory() async {
    state = const AsyncValue.data([]);
  }

  Future<void> deletePodcast(String id) async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return;

    final cloudRepo = ref.read(cloudRepositoryProvider);
    final previousState = state.value ?? [];
    
    // Optimistic delete
    state = AsyncValue.data(previousState.where((p) => p.id != id).toList());

    try {
      await cloudRepo.deleteAudio(user.uid, id);
      await cloudRepo.deletePodcastMetadata(user.uid, id);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(previousState);
    }
  }
}

final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<PodcastHistory>>(() {
  return HistoryNotifier();
});
