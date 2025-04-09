import 'package:focus5/models/coach_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class CoachSessionsScreen extends StatefulWidget {
  final CoachModel coach;
  const CoachSessionsScreen({Key? key, required this.coach}) : super(key: key);
  // ... rest of stateful widget ...
}

class _CoachSessionsScreenState extends State<CoachSessionsScreen> {
  // ... existing state ...

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Book Session'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Coach Info Header
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: widget.coach.profileImageUrl.isNotEmpty
                          ? NetworkImage(widget.coach.profileImageUrl)
                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.coach.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor),
                      ),
                      Text(
                        widget.coach.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Calendar or booking slots (Placeholder)
            Text('TODO: Implement booking calendar/slots', style: TextStyle(color: textColor)),
            const SizedBox(height: 24),

            // Booking Button (Placeholder)
            CustomButton(
              text: 'Confirm Booking',
              onPressed: () {
                // TODO: Implement booking confirmation logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking functionality not implemented yet.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 