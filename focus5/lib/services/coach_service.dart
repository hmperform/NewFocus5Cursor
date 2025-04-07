import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/coach_model.dart';
import 'package:flutter/foundation.dart';

class CoachService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CollectionReference _coachesCollection = 
      FirebaseFirestore.instance.collection('coaches');

  // Get all coaches
  Stream<List<Coach>> getCoaches() {
    return _coachesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Coach.fromJson(data);
      }).toList();
    });
  }

  // Get a single coach by ID
  Future<Coach?> getCoach(String id) async {
    final doc = await _coachesCollection.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Coach.fromJson(data);
  }

  // Get courses created by a coach
  Future<List<Map<String, dynamic>>> getCoachCourses(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('coachId', isEqualTo: coachId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting coach courses: $e');
      return [];
    }
  }

  // Get audio modules created by a coach
  Future<List<Map<String, dynamic>>> getCoachAudioModules(String coachId) async {
    final audioSnapshot = await _firestore
        .collection('audio_modules')
        .where('coachId', isEqualTo: coachId)
        .get();

    return audioSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // Get articles written by a coach
  Future<List<Map<String, dynamic>>> getCoachArticles(String coachId) async {
    final articlesSnapshot = await _firestore
        .collection('articles')
        .where('coachId', isEqualTo: coachId)
        .get();

    return articlesSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // Create or update a coach profile (admin function)
  Future<String> createOrUpdateCoach({
    String? id,
    required String name,
    required String title,
    required String bio,
    File? profileImage,
    File? headerImage,
    String? existingProfileUrl,
    String? existingHeaderUrl,
    required String bookingUrl,
    String? email,
    String? phoneNumber,
    String? instagramUrl,
    String? twitterUrl,
    String? linkedinUrl,
    String? websiteUrl,
    required String specialization,
    required List<String> credentials,
    required bool isActive,
  }) async {
    // Generate a new ID if not provided
    final coachId = id ?? const Uuid().v4();
    
    // Upload profile image if provided
    String profileImageUrl = existingProfileUrl ?? '';
    if (profileImage != null) {
      final profileRef = _storage.ref().child('coaches/$coachId/profile.jpg');
      await profileRef.putFile(profileImage);
      profileImageUrl = await profileRef.getDownloadURL();
    }
    
    // Upload header image if provided
    String headerImageUrl = existingHeaderUrl ?? '';
    if (headerImage != null) {
      final headerRef = _storage.ref().child('coaches/$coachId/header.jpg');
      await headerRef.putFile(headerImage);
      headerImageUrl = await headerRef.getDownloadURL();
    }
    
    // Create coach data
    final now = DateTime.now();
    final coachData = {
      'id': coachId,
      'name': name,
      'title': title,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'headerImageUrl': headerImageUrl,
      'bookingUrl': bookingUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      'instagramUrl': instagramUrl,
      'twitterUrl': twitterUrl,
      'linkedinUrl': linkedinUrl,
      'websiteUrl': websiteUrl,
      'specialization': specialization,
      'credentials': credentials,
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(now),
    };
    
    // If creating a new coach, add createdAt timestamp
    if (id == null) {
      coachData['createdAt'] = Timestamp.fromDate(now);
    }
    
    // Save to Firestore
    await _coachesCollection.doc(coachId).set(
      coachData,
      SetOptions(merge: true),
    );
    
    return coachId;
  }

  // Delete a coach profile (admin function)
  Future<void> deleteCoach(String id) async {
    await _coachesCollection.doc(id).delete();
    
    // Delete associated storage files
    try {
      final profileRef = _storage.ref().child('coaches/$id/profile.jpg');
      await profileRef.delete();
    } catch (e) {
      // File might not exist, ignore error
    }
    
    try {
      final headerRef = _storage.ref().child('coaches/$id/header.jpg');
      await headerRef.delete();
    } catch (e) {
      // File might not exist, ignore error
    }
  }

  // Update coach status (admin function)
  Future<void> updateCoachStatus(String id, bool isActive) async {
    await _coachesCollection.doc(id).update({
      'isActive': isActive,
      'updatedAt': Timestamp.now(),
    });
  }
} 