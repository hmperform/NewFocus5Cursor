import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/coach_model.dart' as coachModel;
import '../../providers/coach_provider.dart';
// import '../../widgets/coach/coach_profile_header.dart';
// import '../../widgets/course/course_card.dart';
// import '../../widgets/media/media_card.dart';
// import 'package:focus5/models/content_models.dart';

class CoachDetailScreen extends StatelessWidget {
  final String coachId;

  const CoachDetailScreen({Key? key, required this.coachId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    final accentColor = themeProvider.accentColor;
    
    final coachProvider = Provider.of<CoachProvider>(context);
    final coach = coachProvider.getCoachById(coachId);

    if (coach == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Fetch related content (courses, media) using coach.id
    // Replace dummy lists with actual data fetched based on coach.id
    final courses = []; // TODO: Fetch courses by coachId
    final mediaItems = []; // TODO: Fetch media by coachId

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: FutureBuilder<coachModel.Coach?>(
          future: Future.value(coach),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            } else if (snapshot.hasError) {
              return const Text('Error');
            } else if (snapshot.hasData && snapshot.data != null) {
              return Text(snapshot.data!.name);
            } else {
              return const Text('Coach Profile');
            }
          },
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: FutureBuilder<coachModel.Coach?>(
        future: Future.value(coach),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading coach: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data != null) {
            final coachModel.Coach coach = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // TODO: Replace with actual Coach Profile Header implementation using coach data
                  // CoachProfileHeader(
                  //   name: coach.name,
                  //   title: coach.title ?? '',
                  //   profileImageUrl: coach.profileImageUrl ?? '',
                  // ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(coach.name, style: Theme.of(context).textTheme.headlineMedium),
                         if (coach.title != null) Text(coach.title!, style: Theme.of(context).textTheme.titleLarge),
                         if (coach.bio != null) ...[
                            const SizedBox(height: 8),
                            Text(coach.bio!),
                         ],
                         const SizedBox(height: 16),
                         if (coach.specialization != null && coach.specialization!.isNotEmpty) ...[
                            Text('Specialization:', style: Theme.of(context).textTheme.titleMedium),
                            Wrap(
                                spacing: 8.0,
                                children: coach.specialization!.map((spec) => Chip(label: Text(spec))).toList(),
                            ),
                            const SizedBox(height: 16),
                         ],
                         // Placeholder for Courses Section
                         Text('Courses', style: Theme.of(context).textTheme.titleMedium),
                         const SizedBox(height: 8),
                         // TODO: Fetch and display coach's courses
                         // Replace with actual course list/cards when available
                         Container(height: 100, color: Colors.grey[200], child: Center(child: Text('Course List Placeholder'))),
                         // Placeholder for Media Section
                         const SizedBox(height: 16),
                         Text('Media', style: Theme.of(context).textTheme.titleMedium),
                         const SizedBox(height: 8),
                         // TODO: Fetch and display coach's media
                         // Replace with actual media list/cards when available
                         Container(height: 100, color: Colors.grey[200], child: Center(child: Text('Media List Placeholder'))),
                      ],
                    ),
                  ),
                  // TODO: Add Courses and Media sections here
                  // Potentially using ListView.builder with CourseCard/MediaCard if they existed
                  // For now, maybe just list titles or show placeholders
                ],
              ),
            );
          } else {
            return const Center(child: Text('Coach not found.'));
          }
        },
      ),
    );
  }
} 