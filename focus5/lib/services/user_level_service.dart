import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserLevelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Map of level thresholds - key is level number, value is XP required
  static final Map<int, int> levelThresholds = {
    1: 0,      // Level 1: 0-499 XP
    2: 500,    // Level 2: 500-999 XP
    3: 1000,   // Level 3: 1000-1499 XP
    4: 1500,   // Level 4: 1500-1999 XP
    5: 2000,   // Level 5: 2000-2499 XP
    6: 2500,   // Level 6: 2500-2999 XP
    7: 3000,   // Level 7: 3000-3499 XP
    8: 3500,   // Level 8: 3500-3999 XP
    9: 4000,   // Level 9: 4000-4499 XP
    10: 4500,  // Level 10: 4500+ XP
  };
  
  // Focus points rewarded for each level up (1 point per level)
  static final Map<int, int> levelFocusPointsRewards = {
    2: 1,  // Reward for reaching level 2
    3: 1,  // Reward for reaching level 3
    4: 1,  // Reward for reaching level 4
    5: 1,  // Reward for reaching level 5
    6: 1,  // Reward for reaching level 6
    7: 1,  // Reward for reaching level 7
    8: 1,  // Reward for reaching level 8
    9: 1,  // Reward for reaching level 9
    10: 1, // Reward for reaching level 10
  };
  
  // Get user's current level based on XP
  static int getUserLevel(int xp) {
    int level = 1;
    
    for (int i = 10; i >= 1; i--) {
      if (xp >= levelThresholds[i]!) {
        level = i;
        break;
      }
    }
    
    return level;
  }
  
  // Get XP required for next level
  static int getXpForNextLevel(int currentXp) {
    int currentLevel = getUserLevel(currentXp);
    
    // If at max level, return current XP (no next level)
    if (currentLevel >= 10) {
      return currentXp;
    }
    
    return levelThresholds[currentLevel + 1]!;
  }
  
  // Get progress to next level (0.0 to 1.0)
  static double getLevelProgress(int currentXp) {
    int currentLevel = getUserLevel(currentXp);
    
    // If at max level, return 100% progress
    if (currentLevel >= 10) {
      return 1.0;
    }
    
    int currentLevelXp = levelThresholds[currentLevel]!;
    int nextLevelXp = levelThresholds[currentLevel + 1]!;
    
    return (currentXp - currentLevelXp) / (nextLevelXp - currentLevelXp);
  }
  
  // Calculate time spent stats
  static Map<String, int> calculateTimeStats(List<Map<String, dynamic>> sessions) {
    int totalMinutes = 0;
    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastDate;
    
    // Sort sessions by date (descending)
    sessions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    // Calculate streaks and total time
    for (var session in sessions) {
      // Add to total time
      totalMinutes += session['durationMinutes'] as int;
      
      // Calculate streaks
      DateTime sessionDate = session['date'] as DateTime;
      sessionDate = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
      
      if (lastDate == null) {
        // First session
        currentStreak = 1;
        longestStreak = 1;
        lastDate = sessionDate;
      } else {
        // Check if consecutive days
        final difference = lastDate.difference(sessionDate).inDays;
        
        if (difference == 1) {
          // Consecutive day
          currentStreak++;
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
        } else if (difference > 1) {
          // Streak broken
          currentStreak = 1;
        }
        
        lastDate = sessionDate;
      }
    }
    
    return {
      'totalMinutes': totalMinutes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }
  
  // Check if user leveled up and award focus points if needed
  static Future<bool> checkAndProcessLevelUp(String userId, int oldXp, int newXp) async {
    int oldLevel = getUserLevel(oldXp);
    int newLevel = getUserLevel(newXp);
    
    // If no level change, return false
    if (oldLevel == newLevel) {
      return false;
    }
    
    // User leveled up! Award focus points
    int focusPointsToAward = 0;
    
    // Calculate total focus points to award (could be multiple levels at once)
    for (int level = oldLevel + 1; level <= newLevel; level++) {
      if (levelFocusPointsRewards.containsKey(level)) {
        focusPointsToAward += levelFocusPointsRewards[level]!;
      }
    }
    
    if (focusPointsToAward > 0) {
      try {
        final firestore = FirebaseFirestore.instance;
        // Update user's focus points in Firestore
        await firestore.collection('users').doc(userId).update({
          'focusPoints': FieldValue.increment(focusPointsToAward),
        });
        
        // Record the transaction
        await firestore.collection('focus_points_history').add({
          'userId': userId,
          'amount': focusPointsToAward,
          'source': 'level_up',
          'sourceDetails': 'Reached level $newLevel',
          'isAddition': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Record level up event
        await firestore.collection('user_events').add({
          'userId': userId,
          'eventType': 'level_up',
          'oldLevel': oldLevel,
          'newLevel': newLevel,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        return true;
      } catch (e) {
        debugPrint('Error processing level up rewards: $e');
        return false;
      }
    }
    
    return true;
  }
  
  // Track time spent in the app
  Future<void> trackAppSession(String userId, int durationMinutes) async {
    try {
      // Record the session
      await _firestore.collection('app_sessions').add({
        'userId': userId,
        'durationMinutes': durationMinutes,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Award XP for time spent (10 XP per minute)
      int xpToAward = durationMinutes * 10;
      
      if (xpToAward > 0) {
        // Get current XP to check for level up
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final currentXp = userDoc.data()?['xp'] as int? ?? 0;
        
        // Update XP
        await _firestore.collection('users').doc(userId).update({
          'xp': FieldValue.increment(xpToAward),
        });
        
        // Record XP transaction
        await _firestore.collection('xp_history').add({
          'userId': userId,
          'amount': xpToAward,
          'reason': 'App usage time',
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Check for level up and award focus points if needed
        await checkAndProcessLevelUp(userId, currentXp, currentXp + xpToAward);
      }
    } catch (e) {
      debugPrint('Error tracking app session: $e');
    }
  }
} 