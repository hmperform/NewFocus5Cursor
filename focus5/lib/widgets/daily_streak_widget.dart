import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:provider/provider.dart';
import '../providers/user_provider.dart'; // Import UserProvider

class DailyStreakWidget extends StatelessWidget {
  // Remove direct streak properties, will get from provider
  // final int currentStreak;
  // final int? longestStreak;
  // final DateTime? lastLoginDate; // Use lastCompletionDate from provider
  // final DateTime? lastActive;

  const DailyStreakWidget({
    Key? key,
    // Remove required parameters
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get user data from UserProvider
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final currentStreak = user?.streak ?? 0;
    final longestStreak = user?.longestStreak ?? currentStreak;
    final lastCompletionDate = user?.lastCompletionDate;

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
          // Pass necessary data to the build methods
          _buildWeekDayRow(context, currentStreak, lastCompletionDate),
          const SizedBox(height: 16),
          _buildStatsRow(context, currentStreak, longestStreak),
        ],
      ),
    );
  }

  Widget _buildWeekDayRow(BuildContext context, int currentStreak, DateTime? lastCompletionDate) {
    final List<String> days = ["M", "T", "W", "T", "F", "S", "S"];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Determine the start of the current week (assuming Monday is the first day)
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    // Determine the date range of the current streak
    DateTime? streakStartDay;
    DateTime? streakEndDay; // This is the lastCompletionDay

    if (currentStreak > 0 && lastCompletionDate != null) {
      streakEndDay = DateTime(lastCompletionDate.year, lastCompletionDate.month, lastCompletionDate.day);
      streakStartDay = streakEndDay.subtract(Duration(days: currentStreak - 1));
      // Debug print
      print('[DailyStreakWidget] Streak Range: Start=$streakStartDay, End=$streakEndDay (Current Streak: $currentStreak)');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        // Calculate the date for the current day in the loop (Monday=0, Sunday=6)
        final dayInWeek = startOfWeek.add(Duration(days: index));
        bool isActive = false;

        // Check if this day falls within the streak range
        if (streakStartDay != null && streakEndDay != null) {
          isActive = !dayInWeek.isBefore(streakStartDay) && !dayInWeek.isAfter(streakEndDay);
        }

        // Determine color based on active status
        final activeColor = const Color(0xFFB4FF00);
        final inactiveColor = Colors.grey[400];
        final color = isActive ? activeColor : inactiveColor;
        
        // Debug print for each day
        // print('[DailyStreakWidget] Day: ${days[index]} ($dayInWeek), Is Active: $isActive');

        return Column(
          children: [
            Icon(
              Icons.bolt,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              days[index],
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatsRow(BuildContext context, int currentStreak, int longestStreak) {
    // Use the longestStreak value passed from build method
    final bestStreak = longestStreak;
    
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
          iconColor: Colors.blue
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