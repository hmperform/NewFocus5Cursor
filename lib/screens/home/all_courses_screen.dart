import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:focus5/widgets/course/course_list_item.dart';
import 'package:focus5/widgets/shared/custom_app_bar.dart';
import 'package:focus5/services/firebase_content_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define _buildCourseListItem outside the build method or make it part of the state
Widget _buildCourseListItem(BuildContext context, Course course, Color textColor) {
  return CourseListItem(course: course);
}

class AllCoursesScreen extends StatelessWidget {
  // ... existing code ...
                  // Replace the inline Row with the _buildCourseListItem call or CourseListItem directly
                  // We'll use CourseListItem directly for simplicity here
                   child: CourseListItem(course: course),
  // ... existing code ...
}