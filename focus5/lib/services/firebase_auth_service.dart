import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart' as app_models;

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  ) async {
    try {
      // Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      
      // Create user profile in Firestore
      final userData = {
        'id': userCredential.user!.uid,
        'email': email,
        'username': username,
        'fullName': fullName,
        'profileImageUrl': null,
        'sport': sport,
        'university': university,
        'universityCode': universityCode,
        'isIndividual': isIndividual,
        'focusAreas': focusAreas,
        'xp': 0,
        'badges': [],
        'completedCourses': [],
        'completedAudios': [],
        'savedCourses': [],
        'streak': 0,
        'lastActive': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
      
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
        return app_models.User.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile in Firestore
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? username,
    String? profileImageUrl,
    String? sport,
    List<String>? focusAreas,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (username != null) updates['username'] = username;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (sport != null) updates['sport'] = sport;
      if (focusAreas != null) updates['focusAreas'] = focusAreas;
      
      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
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
        'lastActive': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating last active: $e');
    }
  }
} 