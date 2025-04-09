import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/coach_provider.dart';
import '../../models/coach_model.dart';
import '../../widgets/coach/coach_profile_header.dart';
import '../../widgets/course/course_card.dart';
import '../../widgets/media/media_card.dart';
// Remove unused CourseCard/MediaCard imports if not used here

class CoachDetailScreen extends StatelessWidget {
  final String coachId;

  const CoachDetailScreen({super.key, required this.coachId});

  @override
  Widget build(BuildContext context) {
    final coachProvider = Provider.of<CoachProvider>(context, listen: false);
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: coachProvider.getCoachById(coachId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Coach not found or error loading: ${snapshot.error}')),
          );
        }

        final Map<String, dynamic> coach = snapshot.data!;

        // TODO: Fetch related content (courses, media) based on coach.id
        final courses = []; 
        final mediaItems = [];

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: CoachProfileHeader(
                    name: coach['name'] ?? '',
                    title: coach['title'] ?? '',
                    imageUrl: coach['profileImageUrl'] ?? '',
                    bio: coach['bio'] ?? 'Bio not available',
                    specializations: List<String>.from(coach['specializations'] ?? []),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  // Placeholder sections
                  const ListTile(
                    title: Text("Coach\'s Courses"),
                  ), 
                  // TODO: Display courses list using `courses`
                  const ListTile(
                    title: Text("Media by Coach"),
                  ), 
                  // TODO: Display media list using `mediaItems`
                  const SizedBox(height: 20), // Add some padding
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
} 