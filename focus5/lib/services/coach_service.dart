import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/coach_model.dart';

class CoachService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String coachesCollection = 'coaches';

  // Get all coaches
  Stream<List<CoachModel>> getCoaches({bool activeOnly = true}) {
    Query query = _firestore.collection(coachesCollection)
      .orderBy('name');
    
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CoachModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get a single coach by ID
  Stream<CoachModel?> getCoachById(String coachId) {
    return _firestore
        .collection(coachesCollection)
        .doc(coachId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return CoachModel.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    });
  }

  // Get courses created by a coach
  Future<List<Map<String, dynamic>>> getCoachCourses(String coachId) async {
    final coursesSnapshot = await _firestore
        .collection('courses')
        .where('coachId', isEqualTo: coachId)
        .get();

    return coursesSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
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
    required List<String> specialties,
    required List<String> credentials,
    required bool isVerified,
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
      'specialties': specialties,
      'credentials': credentials,
      'isVerified': isVerified,
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(now),
    };
    
    // If creating a new coach, add createdAt timestamp
    if (id == null) {
      coachData['createdAt'] = Timestamp.fromDate(now);
    }
    
    // Save to Firestore
    await _firestore.collection(coachesCollection).doc(coachId).set(
      coachData,
      SetOptions(merge: true),
    );
    
    return coachId;
  }

  // Delete a coach profile (admin function)
  Future<void> deleteCoach(String coachId) async {
    // Delete the coach document
    await _firestore.collection(coachesCollection).doc(coachId).delete();
    
    // Delete associated storage files
    try {
      final profileRef = _storage.ref().child('coaches/$coachId/profile.jpg');
      await profileRef.delete();
    } catch (e) {
      // File might not exist, ignore error
    }
    
    try {
      final headerRef = _storage.ref().child('coaches/$coachId/header.jpg');
      await headerRef.delete();
    } catch (e) {
      // File might not exist, ignore error
    }
  }
} 