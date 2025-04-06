import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'user_level_service.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get all available badges
  Future<List<BadgeDefinition>> getAllBadgeDefinitions() async {
    try {
      final querySnapshot = await _firestore.collection('badges').get();
      
      return querySnapshot.docs
          .map((doc) => BadgeDefinition.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting badges: $e');
      return [];
    }
  }
  
  // Check if a user has earned any new badges
  Future<List<AppBadge>> checkForNewBadges(String userId, User currentUser) async {
    try {
      final badgeDefinitions = await getAllBadgeDefinitions();
      final earnedBadges = <AppBadge>[];
      
      // Get list of badges the user already has
      final existingBadgeIds = currentUser.badges.map((b) => b.id).toList();
      
      for (final definition in badgeDefinitions) {
        if (existingBadgeIds.contains(definition.id)) {
          // User already has this badge
          continue;
        }
        
        // Check if the user has met the requirements for this badge
        if (await _hasEarnedBadge(userId, definition, currentUser)) {
          // Create the badge for the user
          final newBadge = AppBadge(
            id: definition.id,
            name: definition.name,
            description: definition.description,
            imageUrl: definition.imageUrl,
            earnedAt: DateTime.now(),
            xpValue: definition.xpValue,
          );
          
          // Add badge to user's collection
          await _awardBadgeToUser(userId, newBadge);
          
          // Add to the list of newly earned badges
          earnedBadges.add(newBadge);
        }
      }
      
      return earnedBadges;
    } catch (e) {
      debugPrint('Error checking for badges: $e');
      return [];
    }
  }
  
  // Check if a user has earned a specific badge
  Future<bool> _hasEarnedBadge(String userId, BadgeDefinition badge, User user) async {
    try {
      // Check the badge criteria
      switch (badge.criteriaType) {
        case 'xp_milestone':
          final int requiredXp = badge.requiredCount;
          return user.xp >= requiredXp;
          
        case 'streak':
          final int requiredStreak = badge.requiredCount;
          return user.streak >= requiredStreak;
          
        case 'level':
          final int requiredLevel = badge.requiredCount;
          final userLevel = UserLevelService.getUserLevel(user.xp);
          return userLevel >= requiredLevel;
          
        case 'app_time':
          // Minutes spent in the app
          final int requiredMinutes = badge.requiredCount;
          final totalMinutes = await _getTotalAppTime(userId);
          return totalMinutes >= requiredMinutes;
          
        case 'course_completion':
          if (badge.specificIds != null && badge.specificIds!.isNotEmpty) {
            // Check if all specific courses have been completed
            return badge.specificIds!.every((courseId) => 
                user.completedCourses.contains(courseId));
          } else {
            // Check if total completed courses meets requirement
            return user.completedCourses.length >= badge.requiredCount;
          }
          
        case 'audio_completion':
          if (badge.specificIds != null && badge.specificIds!.isNotEmpty) {
            // Check if all specific audio modules have been completed
            return badge.specificIds!.every((audioId) => 
                user.completedAudios.contains(audioId));
          } else {
            // Check if total completed audio modules meets requirement
            return user.completedAudios.length >= badge.requiredCount;
          }
          
        case 'all_focus_areas':
          // User has explored all focus areas (completed at least one module per area)
          final allFocusAreas = await _getAllFocusAreas();
          // First check if user has completed at least the required count
          if (user.focusAreas.length < badge.requiredCount) {
            return false;
          }
          
          // Then check if the user has at least one module in each focus area they selected
          for (final focusArea in user.focusAreas) {
            // Query to check if user has any completed module in this focus area
            final query = await _firestore
                .collection('module_completions')
                .where('userId', isEqualTo: userId)
                .where('focusArea', isEqualTo: focusArea)
                .limit(1)
                .get();
                
            if (query.docs.isEmpty) {
              return false;
            }
          }
          
          return true;
          
        case 'login_days':
          // Number of unique days logged in (not necessarily consecutive)
          final int requiredDays = badge.requiredCount;
          final uniqueDays = await _getUniqueLoginDays(userId);
          return uniqueDays >= requiredDays;
          
        case 'journal_entries':
          // Number of journal entries created
          final int requiredEntries = badge.requiredCount;
          final entriesCount = await _getJournalEntriesCount(userId);
          return entriesCount >= requiredEntries;
          
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error checking badge criteria: $e');
      return false;
    }
  }
  
  // Award a badge to a user
  Future<void> _awardBadgeToUser(String userId, AppBadge badge) async {
    try {
      // Add the badge to the user's badge collection
      await _firestore.collection('user_badges').add({
        'userId': userId,
        'badgeId': badge.id,
        'earnedAt': FieldValue.serverTimestamp(),
      });
      
      // Add the badge to the user's badges array
      await _firestore.collection('users').doc(userId).update({
        'badges': FieldValue.arrayUnion([badge.toJson()]),
        // Also give them the XP reward
        'xp': FieldValue.increment(badge.xpValue),
      });
      
      // Log badge earned event
      await _firestore.collection('user_events').add({
        'userId': userId,
        'eventType': 'badge_earned',
        'badgeId': badge.id,
        'badgeName': badge.name,
        'xpEarned': badge.xpValue,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error awarding badge: $e');
    }
  }
  
  // Get total app time in minutes
  Future<int> _getTotalAppTime(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('app_sessions')
          .where('userId', isEqualTo: userId)
          .get();
          
      int totalMinutes = 0;
      for (var doc in snapshot.docs) {
        totalMinutes += (doc.data()['durationMinutes'] as int? ?? 0);
      }
      
      return totalMinutes;
    } catch (e) {
      debugPrint('Error getting app time: $e');
      return 0;
    }
  }
  
  // Get number of unique days logged in
  Future<int> _getUniqueLoginDays(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_logins')
          .where('userId', isEqualTo: userId)
          .get();
          
      // Create a set of unique dates (ignoring time)
      final Set<String> uniqueDates = {};
      
      for (var doc in snapshot.docs) {
        final timestamp = doc.data()['timestamp'] as Timestamp;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
        final dateString = '${date.year}-${date.month}-${date.day}';
        uniqueDates.add(dateString);
      }
      
      return uniqueDates.length;
    } catch (e) {
      debugPrint('Error getting unique login days: $e');
      return 0;
    }
  }
  
  // Get count of journal entries for user
  Future<int> _getJournalEntriesCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('journal_entries')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
          
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting journal entries count: $e');
      return 0;
    }
  }
  
  // Get all focus areas in the system
  Future<List<String>> _getAllFocusAreas() async {
    try {
      final snapshot = await _firestore.collection('focus_areas').get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting focus areas: $e');
      return [];
    }
  }
  
  // Create a new badge definition in the database
  Future<String?> createBadgeDefinition(BadgeDefinition badge) async {
    try {
      final docRef = await _firestore.collection('badges').add(badge.toJson());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating badge definition: $e');
      return null;
    }
  }
  
  // Update an existing badge definition
  Future<bool> updateBadgeDefinition(BadgeDefinition badge) async {
    try {
      await _firestore.collection('badges').doc(badge.id).update(badge.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating badge definition: $e');
      return false;
    }
  }
  
  // Delete a badge definition
  Future<bool> deleteBadgeDefinition(String badgeId) async {
    try {
      await _firestore.collection('badges').doc(badgeId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting badge definition: $e');
      return false;
    }
  }
}

// Badge definition class - represents the metadata for a badge
class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int xpValue;
  final String criteriaType; // 'xp_milestone', 'streak', 'course_completion', 'audio_completion', etc.
  final int requiredCount;
  final List<String>? specificIds; // Optional specific course/audio IDs required
  final Map<String, dynamic>? additionalCriteria; // Additional custom criteria

  BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.xpValue,
    required this.criteriaType,
    required this.requiredCount,
    this.specificIds,
    this.additionalCriteria,
  });

  factory BadgeDefinition.fromJson(Map<String, dynamic> json) {
    return BadgeDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      xpValue: json['xpValue'] as int,
      criteriaType: json['criteriaType'] as String,
      requiredCount: json['requiredCount'] as int,
      specificIds: json['specificIds'] != null
          ? List<String>.from(json['specificIds'])
          : null,
      additionalCriteria: json['additionalCriteria'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'xpValue': xpValue,
      'criteriaType': criteriaType,
      'requiredCount': requiredCount,
    };
    
    if (specificIds != null) {
      data['specificIds'] = specificIds;
    }
    
    if (additionalCriteria != null) {
      data['additionalCriteria'] = additionalCriteria;
    }
    
    return data;
  }
} 