import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';

import '../../providers/user_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/coach_provider.dart';
import '../../constants/theme.dart';
import '../../models/content_models.dart';
import '../../models/coach_model.dart';
import '../../widgets/article/article_card.dart';
import '../../widgets/course/course_gallery.dart';
import 'course_detail_screen.dart';
import 'coach_profile_screen.dart';
import 'articles_list_screen.dart';
import 'all_coaches_screen.dart';
import 'all_courses_screen.dart';
import 'all_modules_screen.dart';
import '../../services/paywall_service.dart';
import 'article_detail_screen.dart';
import '../explore/focus_area_courses_screen.dart';
import '../../widgets/custom_button.dart';
import 'coach_detail_screen.dart';
import '../../widgets/coach/coach_list_tile.dart';
import 'package:focus5/screens/home/coach_profile_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({Key? key}) : super(key: key);

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> with SingleTickerProviderStateMixin {
  final List<String> focusAreas = [
    'Mental Toughness',
    'Confidence',
    'Focus',
    'Resilience',
    'Motivation',
    'Anxiety Management',
    'Performance Under Pressure',
    'Team Dynamics',
    'Leadership',
    'Recovery'
  ];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final coachProvider = Provider.of<CoachProvider>(context, listen: false);
    
    await contentProvider.loadCourses();
    await coachProvider.loadCoaches();
  }

  Widget _buildFeaturedCoursesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final contentProvider = Provider.of<ContentProvider>(context);
    final courses = contentProvider.getFeaturedCourses();
    
    if (courses.isEmpty) {
      return const SizedBox.shrink(); // Hide if no courses
    }
    
    return CourseGallery(
      title: 'Featured Courses',
      courses: courses,
      onViewAllPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AllCoursesScreen(),
          ),
        );
      },
    );
  }

  Widget _buildCoachesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final coachProvider = Provider.of<CoachProvider>(context);
    final coaches = coachProvider.coaches;

    if (coaches.isEmpty) {
      return const SizedBox.shrink(); // Hide if no coaches
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coaches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: coaches.length > 3 ? 3 : coaches.length, // Limit items
          itemBuilder: (context, index) {
            final coach = coaches[index];
            return CoachListTile(
              coach: coach,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoachProfileScreen(coach: coach),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildArticlesSection() {
    final contentProvider = Provider.of<ContentProvider>(context);
    final articles = contentProvider.articles; // Get articles

    if (articles.isEmpty) {
      return const Center(child: Text('No articles available.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Articles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: articles.length > 3 ? 3 : articles.length, // Limit items
          itemBuilder: (context, index) {
            final article = articles[index];
            return ArticleCard( // Use ArticleCard widget
              article: article,
              onTap: () {
                 Navigator.pushNamed(context, '/article', arguments: article.id);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildModulesSection() {
    final contentProvider = Provider.of<ContentProvider>(context);
    // Use focusAreas instead of getModules
    final focusAreasList = contentProvider.focusAreas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explore by Focus Area',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              // Remove the "View All" button for modules/focus areas for now
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: focusAreasList
                .map((area) => ActionChip(
                      label: Text(area),
                      onPressed: () {
                        // TODO: Navigate based on focus area
                        debugPrint('Focus Area: $area');
                      },
                    ))
                .toList(),
          ),
        ),
        // Optionally show some lessons below or navigate on chip tap
      ]
    );
  }

  // Replace DummyData references with real data
  final List<String> exploreCategories = [
    'Courses',
    'Coaches',
    'Articles',
    'Videos',
    'Audio',
    'Events',
    'Community',
    'Resources'
  ];

  // Replace debug prints with proper logging
  void _logError(String message) {
    if (kDebugMode) {
      print('Error: $message');
    }
  }
} 
} 