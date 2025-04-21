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
  
  final bool showStreak;

  const DailyStreakWidget({
    Key? key,
    this.showStreak = true,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with flame icon
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.deepOrange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                "Weekly Activity",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Pass necessary data to the build methods
          _buildWeekDayRow(context, currentStreak, lastCompletionDate),
          if (showStreak) const SizedBox(height: 20),
          if (showStreak) _buildCurrentStreakDisplay(context, currentStreak),
          if (showStreak) const SizedBox(height: 12),
          if (showStreak) _buildBestStreakDisplay(context, longestStreak),
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
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        // Calculate the date for the current day in the loop (Monday=0, Sunday=6)
        final dayInWeek = startOfWeek.add(Duration(days: index));
        bool isActive = false;
        bool isToday = dayInWeek.day == today.day && 
                        dayInWeek.month == today.month && 
                        dayInWeek.year == today.year;

        // Check if this day falls within the streak range
        if (streakStartDay != null && streakEndDay != null) {
          isActive = !dayInWeek.isBefore(streakStartDay) && !dayInWeek.isAfter(streakEndDay);
        }

        // Create gradient colors for active days
        Color primaryColor = isActive ? const Color(0xFFB4FF00) : Colors.grey[600]!;
        Color secondaryColor = isActive ? Colors.amber : Colors.grey[800]!;
        
        return Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isActive ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, secondaryColor]
                ) : null,
                color: isActive ? null : Colors.grey[800],
                shape: BoxShape.circle,
                boxShadow: isActive ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ] : null,
                border: isToday ? Border.all(
                  color: Colors.white,
                  width: 2,
                ) : null,
              ),
              child: Center(
                child: Icon(
                  isActive ? Icons.local_fire_department : Icons.circle_outlined,
                  color: isActive ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              days[index],
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCurrentStreakDisplay(BuildContext context, int currentStreak) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF64B5F6).withOpacity(0.2),
            const Color(0xFF1E88E5).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF64B5F6).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF42A5F5),
                          const Color(0xFF1E88E5),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CURRENT STREAK",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "$currentStreak",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "DAYS",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          // Streak icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt,
              color: const Color(0xFF42A5F5),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestStreakDisplay(BuildContext context, int longestStreak) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFB4FF00).withOpacity(0.2),
            Colors.amber.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB4FF00).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.amber,
                          const Color(0xFFB4FF00),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BEST STREAK",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "$longestStreak",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "DAYS",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          // Trophy icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department,
              color: Colors.amber,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
} 