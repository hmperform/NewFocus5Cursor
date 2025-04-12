import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/services/user_service.dart';

class AudioModuleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // Get the audio module based on user's total login days
  Future<DailyAudio?> getCurrentAudioModule(String userId) async {
    try {
      // Get user's total login days
      final userData = await _userService.getUserData(userId);
      final totalLoginDays = userData?.totalLoginDays ?? 0;
      
      // Get all audio modules sorted by creation date (oldest first)
      final snapshot = await _firestore
          .collection('audio_modules')
          .orderBy('createdAt', descending: false)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      // Get the module that corresponds to the user's login days
      // If they've logged in more days than we have modules, we cycle through them
      final moduleIndex = totalLoginDays > 0 ? (totalLoginDays - 1) % snapshot.docs.length : 0;
      final doc = snapshot.docs[moduleIndex];
      
      return DailyAudio.fromJson(doc.data());
    } catch (e) {
      print('Error getting audio module: $e');
      return null;
    }
  }

  // Get all available audio modules (for admin purposes)
  Future<List<DailyAudio>> getAllAudioModules() async {
    try {
      final snapshot = await _firestore
          .collection('audio_modules')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => DailyAudio.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all audio modules: $e');
      return [];
    }
  }

  // Add a new audio module (admin only)
  Future<bool> addAudioModule(DailyAudio audio) async {
    try {
      await _firestore.collection('audio_modules').add(audio.toJson());
      return true;
    } catch (e) {
      print('Error adding audio module: $e');
      return false;
    }
  }

  // Update an existing audio module (admin only)
  Future<bool> updateAudioModule(String audioId, DailyAudio audio) async {
    try {
      await _firestore
          .collection('audio_modules')
          .doc(audioId)
          .update(audio.toJson());
      return true;
    } catch (e) {
      print('Error updating audio module: $e');
      return false;
    }
  }

  // Delete an audio module (admin only)
  Future<bool> deleteAudioModule(String audioId) async {
    try {
      await _firestore.collection('audio_modules').doc(audioId).delete();
      return true;
    } catch (e) {
      print('Error deleting audio module: $e');
      return false;
    }
  }
} 