import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/providers/theme_provider.dart';
// import 'package:focus5/widgets/course/course_list_item.dart'; // Removed - Using custom card now
import 'package:focus5/widgets/shared/custom_app_bar.dart';
import 'package:focus5/services/firebase_content_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus5/screens/home/course_detail_screen.dart';
import '../../providers/content_provider.dart';
import '../../utils/app_icons.dart'; // Import the app icons utility
import 'package:transparent_image/transparent_image.dart'; // Added for image loading

// Removed unused _buildCourseListItem function

class AllCoursesScreen extends StatelessWidget {
  const AllCoursesScreen({super.key});

  // <<< Refactored Course Item Builder >>>
  Widget _buildCourseCard(BuildContext context, Course course) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final String heroTag = 'course_image_${course.id}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 4.0,
        clipBehavior: Clip.antiAlias, // Ensures content respects card shape
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailScreen(
                  courseId: course.id,
                  course: course, 
                  heroTag: heroTag, // Pass hero tag
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with Hero Animation
              Hero(
                tag: heroTag,
                child: Container(
                  height: screenWidth * 0.4, // Adjust height as needed
                  width: double.infinity,
                  child: course.imageUrl.isNotEmpty
                      ? FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: course.imageUrl,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) => 
                            Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.school, color: Colors.grey, size: 50),
                            ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.school, color: Colors.grey, size: 50),
                        ), // Placeholder
                ),
              ),
              // Title and Details Section
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Lesson Count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${course.lessonsList.length} Lessons',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Focus Points Cost (if applicable)
                    if (course.focusPointsCost > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeProvider.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcons.getFocusPointIcon(
                              width: 14,
                              height: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${course.focusPointsCost}',
                              style: TextStyle(
                                color: themeProvider.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);

    return Scaffold(
      // Use CustomAppBar for consistency if desired, or standard AppBar
      appBar: CustomAppBar(title: 'All Courses'),
      // appBar: AppBar(
      //   title: const Text('All Courses'),
      //   elevation: 0,
      //   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      //   foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      // ),
      body: FutureBuilder<List<Course>>(
        future: contentProvider.getAllCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Consider a more user-friendly error message
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Could not load courses. Please check your connection and try again.\nError: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No courses available yet.'));
          } else {
            final courses = snapshot.data!;
            // Use the new card builder
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8.0, bottom: 80), // Add padding, esp. bottom for mini-player overlap
              itemCount: courses.length,
              itemBuilder: (context, index) {
                // Use the new card builder
                return _buildCourseCard(context, courses[index]);
              },
            );
          }
        },
      ),
    );
  }
}