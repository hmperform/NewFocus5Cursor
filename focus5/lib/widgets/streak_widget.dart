import 'package:flutter/material.dart';

class StreakWidget extends StatelessWidget {
  final List<bool> weekData; // Data for the last 7 days (true = day complete)
  final int currentStreak; // Current consecutive streak
  final int bestStreak; // Best streak ever achieved
  
  const StreakWidget({
    Key? key,
    required this.weekData,
    required this.currentStreak,
    required this.bestStreak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day streak circles
            _buildWeekStreak(),
            
            const SizedBox(height: 24),
            
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("CURRENT", currentStreak, const Color(0xFFB4FF00)),
                _buildStatItem("BEST", bestStreak, Colors.red),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStreak() {
    // Day labels
    final List<String> dayLabels = ["M", "T", "W", "T", "F", "S", "S"];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        // Calculate day active status
        final bool isActive = index < weekData.length ? weekData[index] : false;
        
        // Choose color based on active status
        final Color iconColor = isActive ? const Color(0xFFB4FF00) : Colors.grey;
        
        return Column(
          children: [
            // Brain icon 
            Icon(
              Icons.psychology,
              color: iconColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            // Day label
            Text(
              dayLabels[index],
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              "$count days",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 