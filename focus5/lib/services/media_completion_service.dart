import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/content_models.dart';

/// Service to track which videos/audios have been watched/listened to completion
class MediaCompletionService {
  static const String _completedMediaKey = 'completed_media_ids';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Marks a media item as completed
  Future<void> markMediaCompleted(String userId, String mediaId, [MediaType? mediaType]) async {
    try {
      // Store locally for immediate response
      final prefs = await SharedPreferences.getInstance();
      final completedMedia = prefs.getStringList(_completedMediaKey) ?? [];
      
      if (!completedMedia.contains(mediaId)) {
        completedMedia.add(mediaId);
        await prefs.setStringList(_completedMediaKey, completedMedia);
      }
      
      // Also store in Firestore if userId is provided
      if (userId.isNotEmpty) {
        await _firestore.collection('users').doc(userId).collection('media_completions').doc(mediaId).set({
          'mediaId': mediaId,
          'completedAt': FieldValue.serverTimestamp(),
          'mediaType': mediaType?.toString() ?? 'unknown',
        });
      }
    } catch (e) {
      debugPrint('Error marking media as completed: $e');
    }
  }
  
  /// Checks if media has been completed
  Future<bool> isMediaCompleted(String userId, String mediaId) async {
    try {
      // Check local storage first for performance
      final prefs = await SharedPreferences.getInstance();
      final completedMedia = prefs.getStringList(_completedMediaKey) ?? [];
      
      if (completedMedia.contains(mediaId)) {
        return true;
      }
      
      // If not found locally, check Firestore
      if (userId.isNotEmpty) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('media_completions')
            .doc(mediaId)
            .get();
            
        if (doc.exists) {
          // Also update local cache for future checks
          completedMedia.add(mediaId);
          await prefs.setStringList(_completedMediaKey, completedMedia);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking if media is completed: $e');
      return false;
    }
  }
  
  /// Track progress of media playback (call this periodically during playback)
  Future<void> trackMediaProgress(String userId, String mediaId, double currentPosition, double totalDuration, [MediaType? mediaType]) async {
    // Consider media completed if user has watched/listened to at least 90% of it
    final completionThreshold = totalDuration * 0.9;
    
    if (currentPosition >= completionThreshold) {
      await markMediaCompleted(userId, mediaId, mediaType);
    }
    
    // Optionally store the progress for resume functionality
    if (userId.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(userId).collection('media_progress').doc(mediaId).set({
          'mediaId': mediaId,
          'position': currentPosition,
          'duration': totalDuration,
          'percentage': totalDuration > 0 ? (currentPosition / totalDuration) * 100 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'mediaType': mediaType?.toString() ?? 'unknown',
        });
      } catch (e) {
        debugPrint('Error saving media progress: $e');
      }
    }
  }
} 