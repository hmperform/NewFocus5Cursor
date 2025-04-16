import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/coach_model.dart';
import '../models/content_models.dart';

// Helper function to sanitize document data
Map<String, dynamic> _sanitizeDocumentData(Map<String, dynamic>? data) {
  data ??= {};
  data.removeWhere((k, v) => v == null);
  data.forEach((key, value) {
    if (value is Timestamp) {
      data![key] = value.toDate();
    } 
  });
  return data;
}

class CoachService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String coachesCollection = 'coaches';

  // Get all coaches with optional active filter
  Future<List<Coach>> getCoaches({bool activeOnly = true}) async {
    try {
      QuerySnapshot snapshot;
      if (activeOnly) {
        snapshot = await _firestore
          .collection(coachesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      } else {
        snapshot = await _firestore
          .collection(coachesCollection)
          .orderBy('name')
          .get();
      }
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Coach.fromJson(_sanitizeDocumentData(data));
      }).toList();
    } catch (e) {
      debugPrint('Error getting coaches: $e');
      return [];
    }
  }

  // Get a single coach by ID
  Future<Coach?> getCoachById(String coachId) async {
    try {
      final doc = await _firestore.collection(coachesCollection).doc(coachId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return Coach.fromJson(_sanitizeDocumentData(data));
    } catch (e) {
      debugPrint('Error getting coach: $e');
      return null;
    }
  }

  // Method to get courses associated with a coach
  Future<List<Course>> getCoachCourses(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('creatorId.id', isEqualTo: coachId)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return Course.fromJson(_sanitizeDocumentData(data));
      }).toList();
    } catch (e) {
      debugPrint('Error getting coach courses: $e');
      return [];
    }
  }
  
  // Create a new coach
  Future<String?> createCoach(Coach coach) async {
    try {
      final docRef = await _firestore.collection(coachesCollection).add(coach.toJson());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating coach: $e');
      return null;
    }
  }
  
  // Update an existing coach
  Future<bool> updateCoach(Coach coach) async {
    try {
      await _firestore
          .collection(coachesCollection)
          .doc(coach.id)
          .update(coach.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating coach: $e');
      return false;
    }
  }
  
  // Delete a coach
  Future<bool> deleteCoach(String coachId) async {
    try {
      await _firestore.collection(coachesCollection).doc(coachId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting coach: $e');
      return false;
    }
  }
} 