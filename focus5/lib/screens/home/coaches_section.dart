import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../models/content_models.dart';
import 'coach_profile_screen.dart';

class CoachesSection extends StatelessWidget {
  const CoachesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Sample coaches data (in a real app, this would come from a provider)
    final coaches = [
      {
        'id': 'coach-001',
        'name': 'Dr. Sarah Johnson',
        'title': 'Performance Psychologist',
        'imageUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
        'specialization': 'Mental Toughness',
        'experience': '15+ years',
        'rating': 4.9,
        'reviews': 127,
      },
      {
        'id': 'coach-002',
        'name': 'Michael Davis',
        'title': 'Mental Performance Coach',
        'imageUrl': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=200',
        'specialization': 'Visualization',
        'experience': '10+ years',
        'rating': 4.8,
        'reviews': 98,
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Text(
            'Top Coaches',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: coaches.length,
            padding: const EdgeInsets.only(left: 16),
            itemBuilder: (context, index) {
              final coach = coaches[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoachProfileScreen(
                        coachId: coach['id']?.toString() ?? '',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: themeProvider.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: (coach['imageUrl'] is String && (coach['imageUrl'] as String).isNotEmpty)
                            ? Image.network(
                                coach['imageUrl'] as String,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 120,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 60, color: Colors.grey),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coach['name']?.toString() ?? 'Unknown Coach',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              coach['specialization']?.toString() ?? 'No Specialization',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                          ],
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
    );
  }
} 