import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

import '../../providers/user_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/coach_provider.dart';
import '../../constants/theme.dart';
import '../../models/content_models.dart';
import '../../constants/dummy_data.dart';
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

Widget _buildFeaturedCoursesSection() {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final textColor = Theme.of(context).colorScheme.onBackground;
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

                  // Course meta info (lessons, duration)
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${course.lessonsList.length} lessons',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${course.duration} mins',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ), 