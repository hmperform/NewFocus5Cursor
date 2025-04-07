import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/focus_area_chip.dart';
import 'course_detail_screen.dart';
import 'coach_detail_screen.dart';
import 'article_detail_screen.dart';
import 'audio_player_screen.dart';
import '../../widgets/course/course_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

// Replace debug prints with proper logging
void _logError(String message) {
  if (kDebugMode) {
    print('Error: $message');
  }
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  Widget build(BuildContext context) {
    // Use Consumers for providers where needed in build methods
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome, ${userProvider.user?.displayName ?? 'User'}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Consumer<ContentProvider>(
              builder: (context, contentProvider, _) => 
                _buildFeaturedCoursesSection(contentProvider),
            ),
            Consumer<ContentProvider>(
              builder: (context, contentProvider, _) => 
                _buildRecentMediaSection(contentProvider),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMediaSection(ContentProvider contentProvider) {
    final List<dynamic> recentMedia = [];

    if (recentMedia.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Recently Played',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recentMedia.length,
            itemBuilder: (context, index) {
              final item = recentMedia[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(8),
                  child: Text(item?.title ?? 'Media Item'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCoursesSection(ContentProvider contentProvider) {
    final courses = contentProvider.getFeaturedCourses();

    if (courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No featured courses available yet.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Courses',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return CourseCard(
                course: course,
                onTap: () {
                  Navigator.pushNamed(context, '/course', arguments: course.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// DO NOT DEFINE CourseCard or other classes here 