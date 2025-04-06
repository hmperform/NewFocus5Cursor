import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart' as app_models;
import 'user_permissions_service.dart';
import 'firebase_storage_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserPermissionsService _permissionsService = UserPermissionsService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  // Get current logged in user
  User? get currentUser => _auth.currentUser;
  
  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email & password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  // Create a new user with email & password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String fullName,
    String username,
    bool isIndividual,
    String? sport,
    String? university,
    String? universityCode,
    List<String> focusAreas,
    File? profileImageFile,
    Uint8List? profileImageBytes,
    String? profileImageName,
  ) async {
    try {
      // Check if the email domain should get admin privileges
      final bool shouldBeAdmin = _permissionsService.shouldAutoAssignAdmin(email);
      
      // Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      
      // Upload profile image if provided
      String? profileImageUrl;
      
      if (kIsWeb && profileImageBytes != null) {
        // Web platform - upload bytes
        String extension = '.jpg';
        if (profileImageName != null) {
          extension = profileImageName.contains('.')
              ? '.${profileImageName.split('.').last}'
              : '.jpg';
        }
        
        profileImageUrl = await _storageService.uploadProfileImageWeb(
          userCredential.user!.uid, 
          profileImageBytes,
          extension.replaceFirst('.', '')
        );
      } else if (!kIsWeb && profileImageFile != null) {
        // Mobile platform - upload file
        profileImageUrl = await _storageService.uploadProfileImage(
          userCredential.user!.uid, 
          profileImageFile
        );
      }
      
      // Create user profile in Firestore
      final userData = {
        'id': userCredential.user!.uid,
        'email': email,
        'username': username,
        'fullName': fullName,
        'profileImageUrl': profileImageUrl,
        'sport': sport,
        'university': university,
        'universityCode': universityCode,
        'isIndividual': isIndividual,
        'isAdmin': shouldBeAdmin, // Auto-assign admin if from hmperform.com
        'focusAreas': focusAreas,
        'xp': 0,
        'focusPoints': 100, // Start with 100 Focus Points
        'badges': [],
        'completedCourses': [],
        'completedAudios': [],
        'savedCourses': [],
        'streak': 0,
        'longestStreak': 0,
        'lastLoginDate': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'preferences': {
          'notifications': {
            'dailyReminder': true,
            'newContent': true,
            'coaching': true
          },
          'theme': 'system',
          'audioQuality': 'high'
        }
      };
      
      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
      
      // If the user has a university code, add them to the university's members
      if (universityCode != null && universityCode.isNotEmpty) {
        try {
          // Check if university exists
          final universityDoc = await _firestore.collection('universities').doc(universityCode).get();
          if (universityDoc.exists) {
            // Increment user count
            await _firestore.collection('universities').doc(universityCode).update({
              'currentUserCount': FieldValue.increment(1)
            });
          }
        } catch (e) {
          // Don't fail the entire registration if this fails
          debugPrint('Error updating university member count: $e');
        }
      }
      
      if (shouldBeAdmin) {
        debugPrint('Auto-assigned admin privileges to $email (hmperform.com domain)');
      }
      
      return userCredential;
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<app_models.User?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return app_models.User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }
  
  // Update user's last active time
  Future<void> updateLastActive(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last active: $e');
    }
  }
  
  // Update user profile in Firestore
  Future<String?> updateUserProfile({
    required String uid,
    String? fullName,
    String? username,
    String? profileImageUrl,
    String? sport,
    String? university,
    String? universityCode,
    bool? isIndividual,
    List<String>? focusAreas,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      // Handle profile image upload if provided
      String? updatedImageUrl = profileImageUrl;
      
      if (imageFile != null || imageBytes != null) {
        try {
          if (kIsWeb && imageBytes != null) {
            // Web platform - upload bytes
            updatedImageUrl = await _storageService.uploadProfileImageWeb(
              uid,
              imageBytes,
              'jpg' // Default to jpg for web uploads
            );
          } else if (!kIsWeb && imageFile != null) {
            // Mobile platform - upload file
            updatedImageUrl = await _storageService.uploadProfileImage(
              uid,
              imageFile
            );
          }
        } catch (e) {
          debugPrint('Error uploading profile image: $e');
          return 'Failed to upload profile image: ${e.toString()}';
        }
      }
      
      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (username != null) updates['username'] = username;
      if (updatedImageUrl != null) updates['profileImageUrl'] = updatedImageUrl;
      if (sport != null) updates['sport'] = sport;
      if (university != null) updates['university'] = university;
      if (universityCode != null) updates['universityCode'] = universityCode;
      if (isIndividual != null) updates['isIndividual'] = isIndividual;
      if (focusAreas != null) updates['focusAreas'] = focusAreas;
      
      // Get the current university code if it exists
      String? oldUniversityCode;
      if (universityCode != null) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        oldUniversityCode = userDoc.data()?['universityCode'];
      }

      // Update the user document
      await _firestore.collection('users').doc(uid).update(updates);
      
      // Handle university membership changes if university code changed
      if (universityCode != null && universityCode != oldUniversityCode) {
        // Remove from old university if applicable
        if (oldUniversityCode != null && oldUniversityCode.isNotEmpty) {
          try {
            await _firestore.collection('universities').doc(oldUniversityCode).update({
              'currentUserCount': FieldValue.increment(-1)
            });
          } catch (e) {
            debugPrint('Error updating old university count: $e');
          }
        }
        
        // Add to new university if applicable
        if (universityCode.isNotEmpty) {
          try {
            await _firestore.collection('universities').doc(universityCode).update({
              'currentUserCount': FieldValue.increment(1)
            });
          } catch (e) {
            debugPrint('Error updating new university count: $e');
          }
        }
      }
      
      return null; // No error
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return e.toString();
    }
  }
} 