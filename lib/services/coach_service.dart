import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/coach_model.dart';
import '../models/course_model.dart';
import '../models/content_models.dart';

// Helper function (ensure it's defined or imported)
Map<String, dynamic> _sanitizeDocumentData(Map<String, dynamic>? data) {
  data ??= {};
  data.removeWhere((k, v) => v == null);
  data.forEach((key, value) {
    if (value is Timestamp) {
      data![key] = value.toDate();
    } // Add other conversions if needed (lists, maps)
  });
  return data;
}

class CoachService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String coachesCollection = 'coaches';

  // Get all coaches
  Stream<List<Coach>> getCoaches() {
    return _firestore
        .collection('coaches')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Coach.fromJson(data);
      }).toList();
    });
  }

  // Get a single coach by ID
  Future<Coach?> getCoachById(String coachId) async {
    try {
      final doc = await _firestore.collection('coaches').doc(coachId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return Coach.fromJson(data);
    } catch (e) {
      debugPrint('Error getting coach: $e');
      return null;
    }
  }

  // Method to get courses associated with a coach
  Future<List<Course>> getCoachCourses(String coachId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses') // Assuming 'courses' collection exists
        .where('coachId', isEqualTo: coachId)
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      data = _sanitizeDocumentData(data); 
      data['id'] = doc.id;
      return Course.fromJson(data); // Use the factory from content_models.dart
    }).toList();
  }

  // ... rest of the file stays the same ...
} 