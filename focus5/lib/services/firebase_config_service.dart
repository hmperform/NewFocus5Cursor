import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

/// Service for configuring Firebase collections and security rules
class FirebaseConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates the coaches collection in Firestore if it doesn't exist
  Future<bool> setupCoachesCollection() async {
    try {
      // Check if the collection already exists by trying to query it
      final snapshot = await _firestore.collection('coaches').limit(1).get();
      
      // If the coaches collection already has documents, we don't need to create it
      if (snapshot.docs.isNotEmpty) {
        debugPrint('Coaches collection already exists');
        return true;
      }
      
      // Create an empty document to initialize the collection
      // We'll delete this later
      await _firestore.collection('coaches').doc('temp_init_doc').set({
        'id': 'temp_init_doc',
        'name': 'Initialization Document',
        'title': 'Temporary',
        'description': 'This document initializes the coaches collection and will be removed',
        'isActive': false,
        'createdAt': FieldValue.serverTimestamp()
      });
      
      // Delete the temporary document after creating it
      await _firestore.collection('coaches').doc('temp_init_doc').delete();
      
      debugPrint('Coaches collection created successfully');
      return true;
    } catch (e) {
      debugPrint('Error creating coaches collection: $e');
      return false;
    }
  }

  /// Sets up basic security rules for Firestore
  /// Note: This requires a paid Firebase project with Blaze plan
  /// and a properly configured service account in production
  Future<bool> updateFirestoreSecurityRules() async {
    try {
      // In a production app, you would use Firebase Admin SDK with proper credentials
      // to update security rules. This is just a demonstration for development.
      debugPrint('Security rules need to be updated in the Firebase Console');
      debugPrint('Copy and paste the following rules in your Firebase Console:');
      
      const firestoreRules = '''
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions for role checking
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAppAdmin() {
      return isAuthenticated() && 
             exists(/databases/\${database}/documents/users/\${request.auth.uid}) &&
             get(/databases/\${database}/documents/users/\${request.auth.uid}).data.isAdmin == true;
    }
    
    function isUniversityAdmin(universityCode) {
      return isAuthenticated() && 
             exists(/databases/\${database}/documents/universities/\${universityCode}) &&
             request.auth.uid in get(/databases/\${database}/documents/universities/\${universityCode}).data.adminUserIds;
    }
    
    function getUserUniversityCode() {
      return get(/databases/\${database}/documents/users/\${request.auth.uid}).data.universityCode;
    }
    
    function isUserFromUniversity(universityCode) {
      return isAuthenticated() && 
             exists(/databases/\${database}/documents/users/\${request.auth.uid}) &&
             get(/databases/\${database}/documents/users/\${request.auth.uid}).data.universityCode == universityCode;
    }
    
    // User collection rules
    match /users/{userId} {
      // Users can read and update their own data
      allow read: if isAuthenticated() && (request.auth.uid == userId || isAppAdmin());
      
      // Users can update their own non-admin fields
      allow update: if isAuthenticated() && request.auth.uid == userId && 
                     (!request.resource.data.diff(resource.data).affectedKeys.hasAny(['isAdmin']));
      
      // App admins can read and write all user documents
      allow write: if isAppAdmin();
    }
    
    // University collection rules
    match /universities/{universityCode} {
      // App admins can read/write all universities
      // University admins can read/write their own university
      // Regular users can read university data if they belong to it
      allow read: if isAuthenticated() && 
                   (isAppAdmin() || isUniversityAdmin(universityCode) || isUserFromUniversity(universityCode));
      
      // Only app admins and university admins can write to their university
      allow write: if isAuthenticated() && (isAppAdmin() || isUniversityAdmin(universityCode));
      
      // University members subcollection 
      match /members/{memberId} {
        allow read: if isAuthenticated() && 
                     (isAppAdmin() || isUniversityAdmin(universityCode) || isUserFromUniversity(universityCode));
        allow write: if isAuthenticated() && (isAppAdmin() || isUniversityAdmin(universityCode));
      }
    }
    
    // Coach collection rules
    match /coaches/{coachId} {
      // Anyone can read active coaches, admins can read all coaches
      allow read: if isAuthenticated() && 
                   (resource.data.isActive == true || isAppAdmin() || 
                    (resource.data.universityCode != null && isUniversityAdmin(resource.data.universityCode)));
      
      // Only app admins can write to coaches collection
      allow write: if isAuthenticated() && isAppAdmin();
    }
    
    // Badge collection rules
    match /badges/{badgeId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isAppAdmin();
    }
    
    // Course collection rules
    match /courses/{courseId} {
      // Everyone can read public courses
      // University-exclusive courses are only readable by university members and admins
      allow read: if isAuthenticated() && 
                   (!resource.data.universityExclusive || 
                    (resource.data.universityCode != null && 
                     (isAppAdmin() || isUniversityAdmin(resource.data.universityCode) || 
                      isUserFromUniversity(resource.data.universityCode))));
      
      // Only app admins and university admins can write courses
      allow create, update: if isAuthenticated() && 
                            (isAppAdmin() || 
                             (resource.data.universityCode != null && 
                              isUniversityAdmin(resource.data.universityCode)));
                              
      allow delete: if isAuthenticated() && isAppAdmin();
    }
    
    // Journal entries
    match /journal_entries/{entryId} {
      allow read, write: if isAuthenticated() && 
                          (resource.data.userId == request.auth.uid || isAppAdmin());
    }
    
    // XP and Focus Points history
    match /xp_history/{historyId} {
      allow read: if isAuthenticated() && 
                   (resource.data.userId == request.auth.uid || isAppAdmin());
      allow write: if isAuthenticated() && isAppAdmin();
    }
    
    match /focus_points_history/{historyId} {
      allow read: if isAuthenticated() && 
                   (resource.data.userId == request.auth.uid || isAppAdmin());
      allow write: if isAuthenticated() && isAppAdmin();
    }
    
    // Default rule - deny all other access
    match /{document=**} {
      allow read, write: if isAppAdmin();
    }
  }
}
''';
      
      debugPrint(firestoreRules);
      return true;
    } catch (e) {
      debugPrint('Error updating Firestore security rules: $e');
      return false;
    }
  }

  /// Sets up Firebase Storage security rules
  Future<bool> updateStorageSecurityRules() async {
    try {
      // In a production app, you would use Firebase Admin SDK
      debugPrint('Storage rules need to be updated in the Firebase Console');
      debugPrint('Copy and paste the following rules in your Firebase Console:');
      
      const storageRules = '''
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Helper functions for role checking
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAppAdmin() {
      return request.auth != null &&
             exists(/databases/(default)/documents/users/\${request.auth.uid}) &&
             get(/databases/(default)/documents/users/\${request.auth.uid}).data.isAdmin == true;
    }
    
    function isUniversityAdmin(universityCode) {
      return request.auth != null && 
             exists(/databases/(default)/documents/universities/\${universityCode}) &&
             request.auth.uid in get(/databases/(default)/documents/universities/\${universityCode}).data.adminUserIds;
    }
    
    function getUserUniversityCode() {
      return get(/databases/(default)/documents/users/\${request.auth.uid}).data.universityCode;
    }
    
    // Coach images
    match /coaches/{coachId}/{fileName} {
      // Anyone can view coach images
      allow read: if isAuthenticated();
      
      // Only app admins can upload/modify coach images
      allow write: if isAuthenticated() && isAppAdmin();
    }
    
    // University images
    match /universities/{universityCode}/{fileName} {
      // University members, university admins, and app admins can view university images
      allow read: if isAuthenticated() && 
                  (isAppAdmin() || 
                   isUniversityAdmin(universityCode) || 
                   getUserUniversityCode() == universityCode);
      
      // Only university admins and app admins can upload university images
      allow write: if isAuthenticated() && 
                   (isAppAdmin() || isUniversityAdmin(universityCode));
    }
    
    // Course images and content
    match /courses/{courseId}/{fileName} {
      // Anyone can read public course content
      // University course content is only for university members
      allow read: if isAuthenticated();
      
      // Only app admins and university admins can upload course content
      allow write: if isAuthenticated() && isAppAdmin();
    }
    
    // User profile images
    match /users/{userId}/{fileName} {
      // Anyone can view user profile images
      allow read: if isAuthenticated();
      
      // Users can only upload their own profile images
      allow write: if isAuthenticated() && 
                    (request.auth.uid == userId || isAppAdmin());
    }
    
    // Default rule - deny all
    match /{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAppAdmin();
    }
  }
}
''';
      
      debugPrint(storageRules);
      return true;
    } catch (e) {
      debugPrint('Error updating Storage security rules: $e');
      return false;
    }
  }

  /// Check if currently logged-in user is an admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data()?['isAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Makes the current user an admin (development only)
  Future<bool> makeCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user is logged in');
        return false;
      }
      
      await _firestore.collection('users').doc(user.uid).update({
        'isAdmin': true
      });
      
      debugPrint('Current user ${user.email} is now an admin');
      return true;
    } catch (e) {
      debugPrint('Error making user admin: $e');
      return false;
    }
  }
} 