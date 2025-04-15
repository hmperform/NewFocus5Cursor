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
    
    // Get current day of week (1-7, where 1 is Monday)
    final now = DateTime.now();
    int currentDayIndex = now.weekday - 1; // Convert to 0-based index (0 = Monday)
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        bool isActive = false;
        
        // Only proceed if there's an active streak
        if (currentStreak > 0) {
          if (currentStreak == 1) {
            // For a 1-day streak, just highlight today's day
            isActive = index == currentDayIndex;
          } else if (lastActive != null) {
            // For streaks > 1, calculate which days should be active
            
            // Get date for the weekday at this index
            final int daysFromToday = (currentDayIndex - index + 7) % 7;
            final DateTime thisWeekdayDate = DateTime.now().subtract(Duration(days: daysFromToday));
            
            // Calculate streak start date
            final DateTime lastActiveDay = DateTime(lastActive!.year, lastActive!.month, lastActive!.day);
            final DateTime streakStartDate = DateTime(
              lastActiveDay.year, 
              lastActiveDay.month, 
              lastActiveDay.day
            ).subtract(Duration(days: currentStreak - 1));
            
            // A day is active if it falls between streak start and last active date
            isActive = !thisWeekdayDate.isBefore(streakStartDate) && 
                      !thisWeekdayDate.isAfter(lastActiveDay);
          } else {
            // Fallback if no lastActive is available
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