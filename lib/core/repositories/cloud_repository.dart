import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/podcast_history.dart';

class CloudRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads audio bytes to Firebase Storage and returns the download URL
  Future<String> uploadAudio(String uid, String podcastId, List<int> audioBytes) async {
    final ref = _storage.ref().child('users/$uid/podcasts/$podcastId.mp3');
    final metadata = SettableMetadata(contentType: 'audio/mpeg');
    
    // Uint8List is required by putData
    final data = Uint8List.fromList(audioBytes);
    final uploadTask = await ref.putData(data, metadata);
    
    return await uploadTask.ref.getDownloadURL();
  }

  /// Deletes an audio file from Firebase Storage
  Future<void> deleteAudio(String uid, String podcastId) async {
    final ref = _storage.ref().child('users/$uid/podcasts/$podcastId.mp3');
    try {
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
    }
  }

  /// Saves podcast metadata to Firestore
  Future<void> savePodcastMetadata(String uid, PodcastHistory podcast) async {
    final docRef = _firestore.collection('users').doc(uid).collection('podcasts').doc(podcast.id);
    await docRef.set(podcast.toJson());
  }

  /// Fetches all podcasts for a user, sorted by creation date (newest first)
  Future<List<PodcastHistory>> fetchPodcasts(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('podcasts')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => PodcastHistory.fromJson(doc.data())).toList();
  }

  /// Deletes podcast metadata from Firestore
  Future<void> deletePodcastMetadata(String uid, String podcastId) async {
    final docRef = _firestore.collection('users').doc(uid).collection('podcasts').doc(podcastId);
    await docRef.delete();
  }
}

final cloudRepositoryProvider = Provider<CloudRepository>((ref) {
  return CloudRepository();
});
