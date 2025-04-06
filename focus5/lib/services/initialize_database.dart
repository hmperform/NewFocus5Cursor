import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// This class is used to initialize the Firebase database with default data
/// such as badges, focus areas, etc.
class InitializeDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Initialize all database collections with default data
  Future<void> initializeDatabase() async {
    // Only initialize if collections don't exist or are empty
    await _initializeBadges();
  }
  
  /// Initialize the badges collection with default badges
  Future<void> _initializeBadges() async {
    try {
      // Check if badges collection is empty
      final badgesQuery = await _firestore.collection('badges').limit(1).get();
      if (badgesQuery.docs.isNotEmpty) {
        // Badges already exist, no need to initialize
        return;
      }
      
      // XP milestone badges
      await _createBadge(
        id: 'xp_milestone_100',
        name: 'Beginner\'s Mind',
        description: 'Earned 100 XP on your mental skills journey',
        imageUrl: 'assets/images/badges/xp_100.png',
        xpValue: 50,
        criteriaType: 'xp_milestone',
        requiredCount: 100,
      );
      
      await _createBadge(
        id: 'xp_milestone_500',
        name: 'Rising Star',
        description: 'Earned 500 XP through dedicated practice',
        imageUrl: 'assets/images/badges/xp_500.png',
        xpValue: 100,
        criteriaType: 'xp_milestone',
        requiredCount: 500,
      );
      
      await _createBadge(
        id: 'xp_milestone_1000',
        name: 'Mental Athlete',
        description: 'Reached 1,000 XP in your mental training',
        imageUrl: 'assets/images/badges/xp_1000.png',
        xpValue: 150,
        criteriaType: 'xp_milestone',
        requiredCount: 1000,
      );
      
      await _createBadge(
        id: 'xp_milestone_5000',
        name: 'Elite Performer',
        description: 'Achieved 5,000 XP through consistent training',
        imageUrl: 'assets/images/badges/xp_5000.png',
        xpValue: 250,
        criteriaType: 'xp_milestone',
        requiredCount: 5000,
      );
      
      // Streak badges
      await _createBadge(
        id: 'streak_3',
        name: 'Momentum Builder',
        description: 'Used Focus 5 for 3 days in a row',
        imageUrl: 'assets/images/badges/streak_3.png',
        xpValue: 50,
        criteriaType: 'streak',
        requiredCount: 3,
      );
      
      await _createBadge(
        id: 'streak_7',
        name: 'Week Warrior',
        description: 'Maintained a 7-day streak',
        imageUrl: 'assets/images/badges/streak_7.png',
        xpValue: 100,
        criteriaType: 'streak',
        requiredCount: 7,
      );
      
      await _createBadge(
        id: 'streak_30',
        name: 'Consistency Champion',
        description: 'Incredible! 30 days of consistent practice',
        imageUrl: 'assets/images/badges/streak_30.png',
        xpValue: 200,
        criteriaType: 'streak',
        requiredCount: 30,
      );
      
      // Course completion badges
      await _createBadge(
        id: 'courses_complete_1',
        name: 'First Step',
        description: 'Completed your first course',
        imageUrl: 'assets/images/badges/course_1.png',
        xpValue: 75,
        criteriaType: 'course_completion',
        requiredCount: 1,
      );
      
      await _createBadge(
        id: 'courses_complete_5',
        name: 'Course Collector',
        description: 'Completed 5 different courses',
        imageUrl: 'assets/images/badges/course_5.png',
        xpValue: 150,
        criteriaType: 'course_completion',
        requiredCount: 5,
      );
      
      // Audio session badges
      await _createBadge(
        id: 'audio_complete_10',
        name: 'Audio Ace',
        description: 'Completed 10 audio sessions',
        imageUrl: 'assets/images/badges/audio_10.png',
        xpValue: 100,
        criteriaType: 'audio_completion',
        requiredCount: 10,
      );
      
      debugPrint('Database initialized with default badges');
    } catch (e) {
      debugPrint('Error initializing badges: $e');
    }
  }
  
  /// Create a badge in the database
  Future<void> _createBadge({
    required String id,
    required String name,
    required String description,
    required String imageUrl,
    required int xpValue,
    required String criteriaType,
    required int requiredCount,
    List<String>? specificIds,
  }) async {
    await _firestore.collection('badges').doc(id).set({
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'xpValue': xpValue,
      'criteriaType': criteriaType,
      'requiredCount': requiredCount,
      'specificIds': specificIds,
    });
  }
  
  /// Create necessary Firestore indexes for queries
  Future<void> createFirestoreIndexes() async {
    debugPrint('Note: Firestore indexes must be created manually in the Firebase console');
    debugPrint('Required indexes:');
    debugPrint('- Collection: journal_entries, Fields: userId ASC, createdAt DESC');
    debugPrint('- Collection: course_completions, Fields: userId ASC, completedAt DESC');
    debugPrint('- Collection: audio_completions, Fields: userId ASC, completedAt DESC');
  }
} 