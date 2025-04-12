import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_models.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class AudioModuleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the audio module based on total login days provided
  Future<DailyAudio?> getCurrentAudioModule(int totalLoginDays) async {
    try {
      print('🎵 AUDIO MODULE: Service called for $totalLoginDays total login days');
      
      // Fetch audio modules ordered by sequence
      final snapshot = await _firestore
          .collection('audio_modules')
          .orderBy('sequence')
          .get();
      
      if (snapshot.docs.isEmpty) {
        print('🎵 AUDIO MODULE ERROR: No audio modules found in Firestore');
        return null;
      }
      
      // Sort the documents by ID as a secondary sort
      List<QueryDocumentSnapshot<Map<String, dynamic>>> availableModules = snapshot.docs
        ..sort((a, b) => a.id.compareTo(b.id));
      
      final count = availableModules.length;
      
      print('\n🎵 AUDIO MODULE: Found $count modules in sequence:');
      for (var doc in availableModules) {
        final data = doc.data();
        final title = data['title'] as String;
        final sequence = data['sequence'] as int;
        print('  - Sequence $sequence: ${doc.id} ($title)');
      }
      
      // Calculate index using modulo on the ordered list
      final moduleIndex = totalLoginDays > 0 ? (totalLoginDays - 1) % count : 0;
      print('\n🎵 AUDIO MODULE: Selection details:');
      print('  - Total login days: $totalLoginDays');
      print('  - Total modules: $count');
      print('  - Selected index: $moduleIndex');
      
      // Validate index before access
      if (moduleIndex < 0 || moduleIndex >= count) {
        print('🎵 AUDIO MODULE ERROR: Invalid module index: $moduleIndex (valid range: 0-${count-1})');
        return null;
      }
      
      // Get the selected module
      final doc = availableModules[moduleIndex];
      final selectedModule = doc.data();
      final selectedTitle = selectedModule['title'] as String;
      final selectedSequence = selectedModule['sequence'] as int;
      
      print('\n🎵 AUDIO MODULE: Final selection:');
      print('  - Selected ID: ${doc.id}');
      print('  - Selected title: $selectedTitle');
      print('  - Sequence number: $selectedSequence');
      print('  - Index position: $moduleIndex');
      print('  - Login day: $totalLoginDays');
      print('----------------------------------------\n');
      
      return DailyAudio.fromJson(doc.data());
    } catch (e, stackTrace) {
      // Check for specific Firestore index error
      if (e is FirebaseException && e.code == 'failed-precondition') {
         print('🎵 AUDIO MODULE ERROR: Missing Firestore index for orderBy("orderIndex"). Please create it.');
         print('🎵 Firestore Error Details: ${e.message}');
      } else {
        print('🎵 AUDIO MODULE ERROR: $e');
      }
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