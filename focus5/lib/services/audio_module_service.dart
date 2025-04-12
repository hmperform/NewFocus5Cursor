import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_models.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class AudioModuleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the audio module based on total login days provided
  Future<DailyAudio?> getCurrentAudioModule(int totalLoginDays) async {
    try {
      print('🎵 AUDIO MODULE: Service called for $totalLoginDays total login days');
      
      // Get all audio modules (remove Firestore orderBy)
      final snapshot = await _firestore
          .collection('audio_modules')
          // .orderBy('id', descending: false) // Remove Firestore ordering
          .get();
      
      if (snapshot.docs.isEmpty) {
        print('🎵 AUDIO MODULE: No audio modules found in Firestore');
        return null;
      }
      
      // Sort the documents in Dart by ID
      List<QueryDocumentSnapshot<Map<String, dynamic>>> availableModules = snapshot.docs.toList();
      availableModules.sort((a, b) => a.id.compareTo(b.id));
      
      final count = availableModules.length;
      print('🎵 AUDIO MODULE: Found and sorted $count modules by ID in Dart:');
      
      // Log modules with their indices AFTER Dart sorting
      for (var i = 0; i < count; i++) {
        final doc = availableModules[i];
        final data = doc.data();
        final title = data['title'] as String;
        print('🎵 AUDIO MODULE: Index $i = Module ${doc.id} ($title)'); 
      }
      
      // Calculate index
      final moduleIndex = totalLoginDays > 0 ? (totalLoginDays - 1) % count : 0;
      print('🎵 AUDIO MODULE: Calculated moduleIndex = ($totalLoginDays > 0 ? ($totalLoginDays - 1) % $count : 0) = $moduleIndex');
      
      // Validate index before access
      if (moduleIndex < 0 || moduleIndex >= count) {
        print('🎵 AUDIO MODULE ERROR: Calculated invalid module index: $moduleIndex for $count modules.');
        return null; 
      }
      
      // --- Explicitly log the element being accessed --- 
      final selectedDocId = availableModules[moduleIndex].id;
      print('🎵 AUDIO MODULE: Accessing availableModules[$moduleIndex] which has ID: $selectedDocId');
      
      // Get the actual document
      final doc = availableModules[moduleIndex];
      final selectedModule = doc.data();
      final selectedTitle = selectedModule['title'] as String;
      
      print('🎵 AUDIO MODULE: Final Selected module ${doc.id} ($selectedTitle) '
            'for login day $totalLoginDays (using index: $moduleIndex)');
      
      return DailyAudio.fromJson(doc.data());
    } catch (e, stackTrace) {
      print('🎵 AUDIO MODULE ERROR: $e');
      print('🎵 AUDIO MODULE STACK TRACE: $stackTrace');
      return null;
    }
  }

  // Get all available audio modules (for admin purposes)
  Future<List<DailyAudio>> getAllAudioModules() async {
    try {
      final snapshot = await _firestore
          .collection('audio_modules')
          .orderBy('datePublished')
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