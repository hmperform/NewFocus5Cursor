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
import '../../providers/coach_provider.dart';
import '../../models/coach_model.dart';

class CoachProfileScreen extends StatefulWidget {
  final String coachId;

  const CoachProfileScreen({
    Key? key,
    required this.coachId,
  }) : super(key: key);

  @override
  _CoachProfileScreenState createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  // <<< ADDED: State variables for courses >>>
  List<Course> _coachCourses = [];
  bool _coursesLoading = true;
  Map<String, dynamic>? _coach;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoachData();
  }

  Future<void> _loadCoachData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final coachProvider = Provider.of<CoachProvider>(context, listen: false);
      
      // Load coach from provider using the ID
      final coach = await coachProvider.getCoachById(widget.coachId);
      
      if (coach == null) {
        throw Exception('Coach not found');
      }
      
      if (mounted) {
        setState(() {
          _coach = coach.toJson();
          _isLoading = false;
        });
      }
      
      _loadCoachCourses();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // <<< ADDED: Function to load courses >>>
  Future<void> _loadCoachCourses() async {
    if (_coach == null) return;
    
    // <<< ADDED: Print course IDs >>>
    final coachCourseIds = _coach!['courses'];
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: _loadCoachData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_coach == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Coach not found'),
        ),
      );
    }

    final coach = _coach!;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(coach['name'] ?? 'Coach Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach header with image
            Container(
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coach name and title
                  Text(
                    coach['name'] ?? 'Unknown Coach',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coach['title'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Rating and review count
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${coach['rating']?.toString() ?? '0.0'} (${coach['reviewCount']?.toString() ?? '0'} reviews)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Specialization and experience
                  Row(
                    children: [
                      const Icon(Icons.psychology, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Specialization: ${coach['specialization'] ?? 'Not specified'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.work_history, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Experience: ${coach['experience'] ?? 'Not specified'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Bio
                  if (coach['bio'] != null && coach['bio'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bio',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          coach['bio'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  
                  // Booking Link Button
                  if (coach['bookingLink'] != null && coach['bookingLink'].isNotEmpty)
                    CustomButton(
                      text: 'Book a Session', 
                      onPressed: () async {
                        final url = Uri.parse(coach['bookingLink']);
                        try {
                          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not open booking link')),
                              );
                            }
                          }
                        } catch (e) {
                           if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error opening link: $e')),
                              );
                           }
                        }
                      },
                    )
                  else
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       decoration: BoxDecoration(
                         color: Colors.grey[800],
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Text(
                         'Booking Unavailable',
                         textAlign: TextAlign.center,
                         style: TextStyle(
                           color: Colors.grey[400],
                           fontSize: 16,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ),
                     
                  // Courses Section
                  const SizedBox(height: 24),
                  Divider(),
                  const SizedBox(height: 16),
                  Text(
                     'Courses by ${coach['name'] ?? "Coach"}',
                     style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildCoursesSection(),
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No courses found',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      children: _coachCourses.map((course) => 
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailScreen(
                    courseId: course.id,
                    course: course,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Course image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      course.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Course details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${course.duration} mins',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ).toList(),
    );
  }
} 