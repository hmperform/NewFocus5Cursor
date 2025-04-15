import 'package:flutter/material.dart';

class DailyStreakWidget extends StatelessWidget {
  final int currentStreak;
  final int? longestStreak;
  
  const DailyStreakWidget({
    Key? key,
    required this.currentStreak,
    this.longestStreak,
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
    final List<String> days = ["T", "W", "T", "F", "S", "S", "M"];
    
    // Get current day of week (0 = Sunday, 1 = Monday, etc.)
    final now = DateTime.now();
    int currentDayIndex = now.weekday - 1; // Convert to 0-based index (0 = Monday)
    if (currentDayIndex < 0) currentDayIndex = 6; // Handle Sunday
    
    // Remap current day to our array index (which starts with Tuesday)
    int mappedCurrentDayIndex = (currentDayIndex + 6) % 7;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        // Determine if this day is active (part of the streak)
        // In this implementation, active days should be today and days before today
        // up to the streak count
        
        bool isActive = false;
        
        // Calculate position relative to current day
        // If index <= mappedCurrentDayIndex, it's today or past
        // If index > mappedCurrentDayIndex, it's future
        
        if (index <= mappedCurrentDayIndex) {
          // For past days (and today), mark as active if within streak range
          int daysAgo = mappedCurrentDayIndex - index;
          isActive = daysAgo < currentStreak;
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