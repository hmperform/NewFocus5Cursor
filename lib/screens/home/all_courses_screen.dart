import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:focus5/widgets/course/course_list_item.dart';
import 'package:focus5/widgets/shared/custom_app_bar.dart';
import 'package:focus5/services/firebase_content_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus5/screens/home/course_detail_screen.dart';
import '../../providers/content_provider.dart';

// Define _buildCourseListItem outside the build method or make it part of the state
Widget _buildCourseListItem(BuildContext context, Course course, Color textColor) {
  return CourseListItem(course: course);
}

class AllCoursesScreen extends StatelessWidget {
  const AllCoursesScreen({super.key});

  Widget _buildCourseItem(BuildContext context, Course course) {
    // Replace CourseListItem with ListTile
    return ListTile(
      leading: course.imageUrl.isNotEmpty 
          ? Image.network(course.imageUrl, width: 50, height: 50, fit: BoxFit.cover) 
          : const Icon(Icons.school), // Placeholder icon
      title: Text(course.title),
      subtitle: Text('${course.lessonsList.length} Lessons'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              courseId: course.id,
              course: course, // Pass the full course object
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);
    
    // Use future builder to handle loading state
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Courses'),
      ),
      body: FutureBuilder<List<Course>>(
        future: contentProvider.getAllCourses(), // Assuming getAllCourses returns Future<List<Course>>
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading courses: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No courses found.'));
          } else {
            final courses = snapshot.data!;
            return ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                return _buildCourseItem(context, courses[index]);
              },
            );
          }
        },
      ),
    );
  }
}