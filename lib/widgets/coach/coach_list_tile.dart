import 'package:flutter/material.dart';
import '../../models/coach_model.dart'; // Assuming coach_model.dart is two levels up

class CoachListTile extends StatelessWidget {
  final Coach coach;
  final VoidCallback? onTap;

  const CoachListTile({
    Key? key,
    required this.coach,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using a standard ListTile as a base
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(coach.profileImageUrl),
        // Provide a fallback in case of error or empty URL
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading coach image: $exception');
        },
        child: coach.profileImageUrl.isEmpty 
            ? const Icon(Icons.person) // Fallback icon
            : null, 
      ),
      title: Text(coach.name),
      subtitle: Text(coach.title),
      onTap: onTap, // Assign the onTap callback
      // Add trailing arrow if desired, like in AllCoachesScreen
      // trailing: Icon(
      //   Icons.arrow_forward_ios,
      //   size: 16,
      //   color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      // ),
    );
  }
} 