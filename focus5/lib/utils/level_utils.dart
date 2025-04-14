import 'dart:math';

class LevelUtils {
  // Define XP thresholds for each level. Level 1 starts at 0 XP.
  // Index 0 = XP for level 2, Index 1 = XP for level 3, etc.
  static const List<int> xpThresholds = [
    500,    // Level 2
    1500,   // Level 3
    3000,   // Level 4
    5000,   // Level 5
    7500,   // Level 6
    10000,  // Level 7
    // Add more levels as needed
  ];

  /// Calculates the user's level based on their total XP.
  static int calculateLevel(int totalXp) {
    if (totalXp < 0) return 1; // Should not happen, but handle defensively

    // Find the highest level threshold the user has surpassed
    int level = 1;
    for (int i = 0; i < xpThresholds.length; i++) {
      if (totalXp >= xpThresholds[i]) {
        level = i + 2; // +2 because index 0 is for level 2
      } else {
        break; // Stop checking once a threshold is not met
      }
    }
    return level;
  }

  /// Calculates the XP progress towards the next level as a value between 0.0 and 1.0.
  static double calculateXpProgress(int totalXp) {
    if (totalXp < 0) return 0.0;

    int currentLevel = calculateLevel(totalXp);
    
    // Find XP required for the current level (level floor)
    int currentLevelXpFloor = (currentLevel == 1) ? 0 : xpThresholds[currentLevel - 2]; 
    
    // Find XP required for the next level (level ceiling)
    // Check if user is already at max defined level
    if (currentLevel > xpThresholds.length) {
      return 1.0; // Max level reached according to thresholds
    }
    int nextLevelXpCeiling = xpThresholds[currentLevel - 1]; 

    // Calculate progress within the current level range
    int xpInCurrentLevel = totalXp - currentLevelXpFloor;
    int xpNeededForLevelUp = nextLevelXpCeiling - currentLevelXpFloor;

    if (xpNeededForLevelUp <= 0) {
      return 1.0; // Avoid division by zero if thresholds are configured incorrectly
    }

    // Clamp progress between 0.0 and 1.0
    double progress = xpInCurrentLevel / xpNeededForLevelUp;
    return progress.clamp(0.0, 1.0);
  }

  /// Gets the total XP required to reach a specific level.
  static int getXpForLevel(int level) {
    if (level <= 1) return 0;
    if (level > xpThresholds.length + 1) {
       // Return the threshold for the max defined level if requesting higher
       return xpThresholds.last; 
    }
    return xpThresholds[level - 2]; // -2 because index 0 is for level 2
  }
} 