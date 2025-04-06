import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/content_models.dart';
import '../home/course_detail_screen.dart';
import '../../services/paywall_service.dart';

class FocusAreaCoursesScreen extends StatefulWidget {
  final String focusArea;
  
  const FocusAreaCoursesScreen({
    Key? key,
    required this.focusArea,
  }) : super(key: key);

  @override
  State<FocusAreaCoursesScreen> createState() => _FocusAreaCoursesScreenState();
}

class _FocusAreaCoursesScreenState extends State<FocusAreaCoursesScreen> {
  List<Course> _courses = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCourses();
  }
  
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });
    
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final focusAreaCourses = contentProvider.getCoursesForFocusArea(widget.focusArea);
    
    setState(() {
      _courses = focusAreaCourses;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          widget.focusArea,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: themeProvider.accentColor,
              ),
            )
          : _courses.isEmpty
              ? _buildEmptyState()
              : _buildCoursesList(),
    );
  }
  
  Widget _buildEmptyState() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any courses for "${widget.focusArea}". Try exploring other focus areas.',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Explore Other Areas'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCoursesList() {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        
        return GestureDetector(
          onTap: () async {
            final paywallService = PaywallService();
            final canAccess = await paywallService.checkAccess();
            
            if (!canAccess && course.premium) {
              Navigator.pushNamed(context, '/paywall');
              return;
            }
            
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course image
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          course.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.image, size: 64, color: Colors.grey.shade400),
                          ),
                        ),
                        if (course.premium)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade800,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Course info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: textColor.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.durationMinutes} mins',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.book,
                              size: 16,
                              color: textColor.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.modules.length} modules',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withOpacity(0.6),
                              ),
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
        );
      },
    );
  }
} 