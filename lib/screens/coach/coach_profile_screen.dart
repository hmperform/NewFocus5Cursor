import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:focus5/providers/theme_provider.dart';
import 'package:provider/provider.dart';
// Import other necessary widgets/services, e.g., CustomButton, url_launcher
import '../../widgets/custom_button.dart';
// <<< ADDED: Import necessary providers and models >>>
import '../../providers/content_provider.dart';
import '../../models/content_models.dart';
import '../home/course_detail_screen.dart'; 

class CoachProfileScreen extends StatefulWidget {
  final Map<String, dynamic> coach;

  const CoachProfileScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  _CoachProfileScreenState createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  // <<< ADDED: State variables for courses >>>
  List<Course> _coachCourses = [];
  bool _coursesLoading = true;

  @override
  void initState() {
    super.initState();
    // <<< ADDED: Print incoming coach data >>>
    print("Coach Profile InitState - Received Coach Data: ${widget.coach}"); 
    _loadCoachCourses(); 
  }

  // <<< ADDED: Function to load courses >>>
  Future<void> _loadCoachCourses() async {
    // <<< ADDED: Print course IDs >>>
    final coachCourseIds = widget.coach['courses'];
    print("Coach Profile LoadCourses - Course IDs from widget: $coachCourseIds"); 

    if (coachCourseIds is List && coachCourseIds.isNotEmpty) {
      final List<String> courseIds = coachCourseIds.map((id) => id.toString()).toList(); 
      print("Coach Profile LoadCourses - Parsed Course IDs: $courseIds");
      
      if (mounted) {
        final contentProvider = Provider.of<ContentProvider>(context, listen: false);
        try {
          print("Coach Profile LoadCourses - Calling contentProvider.getCoursesByIds...");
          final courses = await contentProvider.getCoursesByIds(courseIds); 
          print("Coach Profile LoadCourses - Fetched Courses: ${courses.map((c) => c.id).toList()}");
          if (mounted) {
            setState(() {
              _coachCourses = courses;
              _coursesLoading = false;
            });
          }
        } catch (e) {
          print("Error loading coach's courses: $e");
          if (mounted) {
             setState(() { _coursesLoading = false; });
          }
        }
      } 
    } else {
      print("Coach Profile LoadCourses - No valid course IDs found.");
       if (mounted) {
          setState(() { _coursesLoading = false; });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coach = widget.coach;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // <<< ADDED: Print coach data in build >>>
    print("Coach Profile Build - Coach Data: $coach");
    print("Coach Profile Build - Booking Link: ${coach['bookingLink']}");
    print("Coach Profile Build - Courses Loading: $_coursesLoading, Course Count: ${_coachCourses.length}");

    return Scaffold(
      appBar: AppBar(
        title: Text(coach['name'] ?? 'Coach Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach header with Hero animation
            Hero(
              tag: coach['id'] ?? coach['name'],
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(coach['imageUrl'] ?? ''),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      print('Error loading coach image: $exception');
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach['name'] ?? 'Unknown Coach',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (coach['bio'] != null && coach['bio'].isNotEmpty)
                    Text(
                      coach['bio'],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 16),
                  // Booking Link Button (Keep Existing Logic)
                  if (coach['bookingLink'] != null && coach['bookingLink'].isNotEmpty)
                    CustomButton(
                      text: 'Book a Session', 
                      onPressed: () async {
                        final url = Uri.parse(coach['bookingLink']);
                        try {
                          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                            print('Could not launch ${coach['bookingLink']}');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not open booking link')),
                              );
                            }
                          }
                        } catch (e) {
                          print('Error launching URL: $e');
                           if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error opening link: $e')),
                              );
                           }
                        }
                      },
                    )
                  else // <<< ADDED: Show 'Booking Unavailable' if no link >>>
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       decoration: BoxDecoration(
                         color: Colors.grey[800], // Dark grey background
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Text(
                         'Booking Unavailable',
                         textAlign: TextAlign.center,
                         style: TextStyle(
                           color: Colors.grey[400], // Lighter grey text
                           fontSize: 16,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ),
                  // <<< ADDED: Courses Section >>>
                  const SizedBox(height: 24),
                  Divider(),
                  const SizedBox(height: 16),
                  Text(
                     'Courses by ${coach['name'] ?? "Coach"}',
                     style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildCoursesSection(), // Call helper to build the section
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // <<< ADDED: Helper to build the courses section >>>
  Widget _buildCoursesSection() {
    if (_coursesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_coachCourses.isEmpty) {
      return const Center(child: Text('No courses found for this coach yet.'));
    }

    // Display courses in a Column of ListTiles for simplicity
    return Column(
      children: _coachCourses.map((course) {
        return ListTile(
          leading: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
            ? Image.network(course.thumbnailUrl!, width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.school), // Placeholder
          title: Text(course.title),
          subtitle: Text('${course.lessonsList.length} Lessons'), 
          onTap: () {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailScreen(
                  courseId: course.id,
                  course: course, 
                  // Note: No Hero animation here as we removed it
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
} 