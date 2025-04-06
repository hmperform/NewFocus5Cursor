import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/coach_model.dart';
import '../../providers/coaches_provider.dart';
import '../coach/coach_profile_screen.dart';

class CoachesSection extends StatelessWidget {
  const CoachesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Coaches',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all coaches page
                  Navigator.of(context).pushNamed('/coaches');
                },
                child: Row(
                  children: const [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: Color(0xFFB4FF00),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Color(0xFFB4FF00),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<Coach>>(
            future: Provider.of<CoachesProvider>(context, listen: false).getCoaches(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB4FF00)),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading coaches: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No coaches available',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              
              final coaches = snapshot.data!;
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: coaches.length,
                itemBuilder: (context, index) {
                  final coach = coaches[index];
                  return _buildCoachCard(context, coach);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildCoachCard(BuildContext context, Coach coach) {
    // Handle null values by providing defaults
    final name = coach.name ?? 'Coach';
    final specialty = coach.specialty != null && coach.specialty!.isNotEmpty 
        ? coach.specialty! 
        : 'Mental Performance Coach';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoachProfileScreen(coach: coach),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Coach image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                image: coach.profileImageUrl != null && coach.profileImageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(coach.profileImageUrl!),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // On error, don't display an image
                        },
                      )
                    : null,
              ),
              // Fallback if image fails to load
              child: coach.profileImageUrl == null || coach.profileImageUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white70,
                    )
                  : null,
            ),
            
            // Coach name and specialty
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 