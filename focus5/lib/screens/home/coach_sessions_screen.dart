import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../../models/coach_model.dart';

class CoachSessionsScreen extends StatefulWidget {
  final CoachModel coach;
  
  const CoachSessionsScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  State<CoachSessionsScreen> createState() => _CoachSessionsScreenState();
}

class _CoachSessionsScreenState extends State<CoachSessionsScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedTimeSlot = -1;
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    final accentColor = themeProvider.accentColor;
    final surfaceColor = themeProvider.surfaceColor;
    
    // Sample time slots (in a real app, these would come from a provider)
    final timeSlots = [
      {'time': '9:00 AM', 'available': true},
      {'time': '10:00 AM', 'available': true},
      {'time': '11:00 AM', 'available': false},
      {'time': '1:00 PM', 'available': true},
      {'time': '2:00 PM', 'available': true},
      {'time': '3:00 PM', 'available': false},
      {'time': '4:00 PM', 'available': true},
    ];
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'Book a Session',
          style: TextStyle(color: textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Coach info section
          Container(
            padding: const EdgeInsets.all(16),
            color: surfaceColor,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                    widget.coach.profileImageUrl.isNotEmpty 
                      ? widget.coach.profileImageUrl 
                      : 'https://via.placeholder.com/48',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.coach.name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.coach.title,
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Date selection
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Date',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14, // Show 2 weeks
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected = _selectedDate.year == date.year && 
                          _selectedDate.month == date.month && 
                          _selectedDate.day == date.day;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? accentColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('EEE').format(date),
                                style: TextStyle(
                                  color: isSelected ? Colors.black : textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('d').format(date),
                                style: TextStyle(
                                  color: isSelected ? Colors.black : textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM').format(date),
                                style: TextStyle(
                                  color: isSelected ? Colors.black : textColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Time slot selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Time',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: timeSlots.length,
                  itemBuilder: (context, index) {
                    final slot = timeSlots[index];
                    final isAvailable = slot['available'] as bool;
                    final isSelected = _selectedTimeSlot == index && isAvailable;
                    
                    return GestureDetector(
                      onTap: isAvailable ? () {
                        setState(() {
                          _selectedTimeSlot = index;
                        });
                      } : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? accentColor 
                              : isAvailable ? surfaceColor : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? accentColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            slot['time'] as String,
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.black 
                                  : isAvailable ? textColor : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Booking button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _selectedTimeSlot >= 0 ? () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: surfaceColor,
                    title: Text(
                      'Confirm Booking',
                      style: TextStyle(color: textColor),
                    ),
                    content: Text(
                      'Book a session with ${widget.coach.name} on ${DateFormat('EEEE, MMMM d').format(_selectedDate)} at ${timeSlots[_selectedTimeSlot]['time']}?',
                      style: TextStyle(color: textColor),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Session booked successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Navigate back
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: const Text(
                'Book Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 