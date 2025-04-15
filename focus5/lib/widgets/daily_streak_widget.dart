import 'package:flutter/material.dart';

class DailyStreakWidget extends StatelessWidget {
  final int currentStreak;
  final int? longestStreak;
  final DateTime? lastLoginDate;
  final DateTime? lastActive;
  
  const DailyStreakWidget({
    Key? key,
    required this.currentStreak,
    this.longestStreak,
    this.lastLoginDate,
    this.lastActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeekDayRow(context),
          const SizedBox(height: 16),
          _buildStatsRow(context),
        ],
      ),
    );
  }
  
  Widget _buildWeekDayRow(BuildContext context) {
    // Days of the week
    final List<String> days = ["M", "T", "W", "T", "F", "S", "S"];
    
    // Get current day of week (0 = Sunday, 1 = Monday, etc.)
    final now = DateTime.now();
    int currentDayIndex = now.weekday - 1; // Convert to 0-based index (0 = Monday)
    
    // Calculate the start day of the streak based on the streak length
    // We use lastActive as our reference point for the most recent streak day
    DateTime streakStartDate;
    
    if (lastActive != null) {
      // If we have lastActive, use that as the most recent streak day
      // Then calculate the streak start by subtracting (streak-1) days
      streakStartDate = DateTime(
        lastActive!.year, 
        lastActive!.month, 
        lastActive!.day
      ).subtract(Duration(days: currentStreak - 1));
    } else {
      // Fallback if no lastActive is available
      streakStartDate = DateTime.now().subtract(Duration(days: currentStreak - 1));
    }
    
    // Get the weekday of the streak start (0-6, with 0 being Monday)
    int streakStartDayIndex = streakStartDate.weekday - 1;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        bool isActive = false;
        
        // Only proceed if there's an active streak
        if (currentStreak > 0) {
          // We need to determine which days of the week are part of the current streak
          
          // First, get the date for this weekday
          final int daysFromToday = (currentDayIndex - index + 7) % 7;
          final DateTime thisWeekdayDate = DateTime.now().subtract(Duration(days: daysFromToday));
          
          // A day is active if it falls between the streak start date and the last active date
          if (lastActive != null) {
            final DateTime lastActiveDay = DateTime(lastActive!.year, lastActive!.month, lastActive!.day);
            final DateTime streakStartDay = DateTime(streakStartDate.year, streakStartDate.month, streakStartDate.day);
            
            // Check if this weekday's date is within the streak range
            isActive = !thisWeekdayDate.isBefore(streakStartDay) && 
                      !thisWeekdayDate.isAfter(lastActiveDay);
          } else {
            // Fallback to the simpler logic if no lastActive is available
            int daysFromCurrent = (currentDayIndex - index + 7) % 7;
            isActive = daysFromCurrent < currentStreak;
          }
        }
        
        return Column(
          children: [
            // Lightning bolt icon
            Icon(
              Icons.bolt,
              color: isActive ? const Color(0xFFB4FF00) : Colors.grey[400],
              size: 28,
            ),
            const SizedBox(height: 4),
            // Day label
            Text(
              days[index],
              style: TextStyle(
                color: isActive ? const Color(0xFFB4FF00) : Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }),
    );
  }
  
  Widget _buildStatsRow(BuildContext context) {
    final bestStreak = longestStreak ?? currentStreak;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          context, 
          label: "CURRENT", 
          value: "$currentStreak days", 
          iconColor: const Color(0xFFB4FF00)
        ),
        _buildStatItem(
          context, 
          label: "BEST", 
          value: "$bestStreak days", 
          iconColor: Colors.red
        ),
      ],
    );
  }
  
  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(
          Icons.bolt,
          color: iconColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 