import 'package:flutter/material.dart';

class DailyStreakWidget extends StatelessWidget {
  final int currentStreak;
  
  const DailyStreakWidget({
    Key? key,
    required this.currentStreak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Text(
            'Daily Streak',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 70,
          child: _buildDayCircles(),
        ),
      ],
    );
  }
  
  Widget _buildDayCircles() {
    // Days of the week
    final List<String> days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: days.length,
      itemBuilder: (context, index) {
        // Check if this day is part of the current streak
        // The active day will be the current day (index 0) if streak > 0
        // or no days if streak = 0
        bool isActive = currentStreak > 0 && index == 0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              // Day circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? const Color(0xFFB4FF00) : Colors.grey[850],
                ),
                child: Center(
                  child: Text(
                    days[index],
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              // Checkmark icon if active
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Icon(
                    Icons.check_circle,
                    color: const Color(0xFFB4FF00),
                    size: 14,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
} 