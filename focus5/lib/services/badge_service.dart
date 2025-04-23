import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'user_level_service.dart';
import '../models/content_models.dart'; // Ensure correct path to models
import 'package:flutter/material.dart';
import '../screens/badges/badge_unlock_screen.dart'; // Import the new screen

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get all available badges
  Future<List<BadgeDefinition>> getAllBadgeDefinitions() async {
    try {
      final querySnapshot = await _firestore.collection('badges').get();
      
      final List<BadgeDefinition> badges = [];
      for (var doc in querySnapshot.docs) {
        try {
          final badge = AppBadge.fromFirestore(doc);
          badges.add(BadgeDefinition(
            id: badge.id,
            name: badge.name,
            description: badge.description,
            imageUrl: badge.imageUrl ?? '',
            badgeImage: badge.badgeImage,
            xpValue: badge.xpValue,
            criteriaType: badge.criteriaType,
            requiredCount: badge.requiredCount,
            specificIds: badge.specificIds,
          ));
        } catch (e) {
          debugPrint('Error parsing badge definition for ${doc.id}: $e');
        }
      }
      
      return badges;
    } catch (e) {
      debugPrint('Error getting badges: $e');
      return [];
    }
  }
  
  // Check if a user has earned any new badges
  Future<List<AppBadge>> checkForNewBadges(String userId, User currentUser, {BuildContext? context}) async {
    try {
      final badgeDefinitions = await getAllBadgeDefinitions();
      debugPrint('[checkForNewBadges] Fetched ${badgeDefinitions.length} definitions. IDs: ${badgeDefinitions.map((d) => d.id).toList()}');
      
      final earnedBadges = <AppBadge>[];
      
      // Get list of badges the user already has using badgesgranted IDs
      final existingBadgeIds = currentUser.badgesgranted
          .map((ref) => ref['id'] as String?)
          .where((id) => id != null)
          .toSet();
      debugPrint('[checkForNewBadges] User already has badges: ${existingBadgeIds.toString()}');
      
      for (final definition in badgeDefinitions) {
        debugPrint('[checkForNewBadges] Checking definition: ${definition.id}');
        
        if (existingBadgeIds.contains(definition.id)) {
          // User already has this badge
          debugPrint('[checkForNewBadges] User already has ${definition.id}, skipping.');
          continue;
        }
        
        // Check if the user has met the requirements for this badge
        bool earned = await _hasEarnedBadge(userId, definition, currentUser);
        debugPrint('[checkForNewBadges] Result for ${definition.id}: $earned');
        
        if (earned) {
          // Create the badge for the user
          final newBadge = AppBadge(
            id: definition.id,
            name: definition.name,
            description: definition.description,
            imageUrl: definition.imageUrl,
            badgeImage: definition.badgeImage,
            earnedAt: DateTime.now(),
            xpValue: definition.xpValue,
            criteriaType: definition.criteriaType,
            requiredCount: definition.requiredCount,
            specificIds: definition.specificIds,
          );
          
          // Add badge to user's collection
          await _awardBadgeToUser(userId, newBadge);
          
          // Add to the list of newly earned badges
          earnedBadges.add(newBadge);
        }
      }
      
      // Show badge unlock popup(s) if any badges were earned and we have a context
      if (earnedBadges.isNotEmpty && context != null) {
        if (earnedBadges.length == 1) {
          // Show a single badge popup for just one badge
          showBadgeUnlockPopup(context, earnedBadges.first);
        } else {
          // Show multiple badges in sequence
          showMultipleBadgeUnlocks(context, earnedBadges);
        }
        debugPrint('Showing popup(s) for ${earnedBadges.length} newly earned badges!');
      } else if (earnedBadges.isNotEmpty) {
        // Log if we can't show popups due to missing context
        debugPrint('User earned ${earnedBadges.length} new badges, but no context to show popups.');
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
          
        case 'StreakLength':
          final int requiredStreak = badge.requiredCount;
          debugPrint('[BadgeService._hasEarnedBadge] Checking StreakLength: User Streak=${user.streak}, Required=${requiredStreak}');
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
          
        case 'JournalEntriesWritten':
          // Number of journal entries created
          final int requiredEntries = badge.requiredCount;
          // Use the lifetimeJournalEntries field from the User object
          final int currentLifetimeCount = user.lifetimeJournalEntries ?? 0;
          final bool result = currentLifetimeCount >= requiredEntries;
          debugPrint('[BadgeService._hasEarnedBadge] Checking JournalEntriesWritten: User Lifetime Count=${currentLifetimeCount}, Required=${requiredEntries}. Result: $result');
          return result;
          
        default:
          debugPrint('[BadgeService._hasEarnedBadge] Unknown criteria type: ${badge.criteriaType}');
          return false;
      }
    } catch (e) {
      debugPrint('Error checking badge criteria: $e');
      return false;
    }
  }
  
  // Award a badge to a user
  Future<void> _awardBadgeToUser(String userId, AppBadge badge) async {
    debugPrint('[BadgeService._awardBadgeToUser] Attempting to award badge: ${badge.id} to user: $userId');
    try {
      // Add the badge REFERENCE to the user's badgesgranted array
      final badgeReference = {
        'id': badge.id,
        'path': 'badges' // Assuming the collection name is 'badges'
      };
      debugPrint('[BadgeService._awardBadgeToUser] Prepared badge reference: $badgeReference');
      
      final updateData = {
        'badgesgranted': FieldValue.arrayUnion([badgeReference]), // Add the reference here
        'xp': FieldValue.increment(badge.xpValue), // Also give them the XP reward
      };
      debugPrint('[BadgeService._awardBadgeToUser] Preparing to update Firestore user $userId with data: $updateData');
      
      await _firestore.collection('users').doc(userId).update(updateData);
      
      debugPrint('[BadgeService._awardBadgeToUser] Firestore update for badgesgranted and xp successful for user $userId, badge ${badge.id}.');
      
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
  
  // Manually award a badge to a user (for admin use)
  Future<bool> manuallyAwardBadge(String userId, String badgeId) async {
    try {
      // Get the badge definition
      final badgeDoc = await _firestore.collection('badges').doc(badgeId).get();
      if (!badgeDoc.exists) {
        debugPrint('Badge not found: $badgeId');
        return false;
      }
      
      // Get user to check if they already have the badge
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('User not found: $userId');
        return false;
      }
      
      final user = User.fromFirestore(userDoc);
      
      // Check if user already has this badge using badgesgranted IDs
      if (user.badgesgranted.any((ref) => ref['id'] == badgeId)) {
        debugPrint('User already has this badge: $badgeId');
        return false;
      }
      
      // Create new badge
      final badgeData = badgeDoc.data()!;
      final newBadge = AppBadge(
        id: badgeId,
        name: badgeData['name'] ?? 'Unknown Badge',
        description: badgeData['description'] ?? '',
        imageUrl: badgeData['imageUrl'] ?? '',
        badgeImage: badgeData['badgeImage'],
        earnedAt: DateTime.now(),
        xpValue: badgeData['xpValue'] ?? 0,
        criteriaType: badgeData['criteriaType'] ?? 'Unknown',
        requiredCount: badgeData['requiredCount'] ?? 1,
        specificIds: badgeData['specificIds'] != null 
            ? List<String>.from(badgeData['specificIds']) 
            : null,
      );
      
      // Award the badge
      await _awardBadgeToUser(userId, newBadge);
      
      return true;
    } catch (e) {
      debugPrint('Error manually awarding badge: $e');
      return false;
    }
  }

  // Method to fetch all badge definitions
  Future<List<AppBadge>> fetchAllBadgeDefinitions() async {
    try {
      debugPrint('BadgeService: Fetching all badge definitions...');
      final querySnapshot = await _firestore.collection('badges').get();
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('BadgeService: No badge definitions found in Firestore');
        // Return a default badge if no badges exist in Firestore
        return [_createDefaultBadge()];
      }
      
      final List<AppBadge> badges = [];
      
      for (var doc in querySnapshot.docs) {
        try {
          final badge = AppBadge.fromFirestore(doc);
          badges.add(badge);
        } catch (e, s) { // Catch the error (e) and stack trace (s)
          // Log the specific error details for the failing badge
          debugPrint('BadgeService: Error parsing badge ${doc.id}. Error: ${e.toString()}');
          debugPrint('BadgeService: Stack trace for ${doc.id}: ${s.toString()}');
          // Continue to the next badge on error
        }
      }
      
      debugPrint('BadgeService: Successfully fetched ${badges.length} badge definitions');
      
      if (badges.isEmpty) {
        // If all badges failed to parse, return a default badge
        return [_createDefaultBadge()];
      }
      
      return badges;
    } catch (e) {
      debugPrint('BadgeService: Error fetching badge definitions: $e');
      // Return a default badge on error
      return [_createDefaultBadge()];
    }
  }
  
  // Helper to create a default badge
  AppBadge _createDefaultBadge() {
    return AppBadge(
      id: 'default_badge',
      name: 'First Steps',
      description: 'Start your mental performance journey',
      imageUrl: 'assets/images/badges/default.png',
      badgeImage: 'https://firebasestorage.googleapis.com/v0/b/focus-5-app.firebasestorage.app/o/default_badge.png?alt=media',
      xpValue: 50,
      criteriaType: 'FirstLogin',
      requiredCount: 1,
    );
  }

  // Method to fetch details for specific badge IDs (might already exist or be useful)
  Future<List<AppBadge>> fetchBadgesByIds(List<String> badgeIds) async {
    if (badgeIds.isEmpty) {
      return [];
    }
    
    List<AppBadge> badges = [];
    // Fetch badges in chunks to avoid exceeding Firestore query limits if needed
    // For simplicity, fetching one by one here, but batching is better for many IDs
    for (String id in badgeIds) {
       try {
          final docSnapshot = await _firestore.collection('badges').doc(id).get();
          if (docSnapshot.exists) {
             badges.add(AppBadge.fromFirestore(docSnapshot));
          } else {
             print('Warning: Badge document with ID $id not found.');
             // Handle missing badge doc? Create placeholder? Skip?
          }
       } catch (e) {
          print('Error fetching badge details for ID $id: $e');
          // Handle individual fetch error
       }
    }
    return badges;
  }

  // Show badge unlock popup (Now navigates to full screen)
  void showBadgeUnlockPopup(BuildContext context, AppBadge badge) {
    // Navigate to the full-screen unlock page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BadgeUnlockScreen(badge: badge),
        fullscreenDialog: true, // Make it feel like a modal presentation
      ),
    );
  }
  
  // Show multiple badges if user earned multiple at once (Show first badge full screen)
  void showMultipleBadgeUnlocks(BuildContext context, List<AppBadge> badges) {
    if (badges.isEmpty) return;
    
    // Just show the full screen for the first badge earned in this batch
    // Showing multiple full screens sequentially could be annoying
    showBadgeUnlockPopup(context, badges.first);
    
    // Original sequential dialog logic removed
  }
}

// Badge definition class - represents the metadata for a badge
class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String? badgeImage;
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
    this.badgeImage,
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
      badgeImage: json['badgeImage'] as String?,
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
      'badgeImage': badgeImage,
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