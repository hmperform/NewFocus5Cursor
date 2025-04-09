import 'package:flutter/foundation.dart';

class CourseDetailScreen extends StatefulWidget {
  // ... (existing code)
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['LESSONS', 'OVERVIEW', 'RESOURCES'];
  bool _showDownloadButton = false;
  Course? _course;
  bool _isLoading = true;

  // Add a ContentProvider instance variable
  late ContentProvider _contentProvider;

  @override
  void initState() {
    super.initState();
    
    // Get the ContentProvider instance - **don't listen here**
    _contentProvider = Provider.of<ContentProvider>(context, listen: false);

    // If course was passed in, use it directly
    if (widget.course != null) {
      _course = widget.course;
      _isLoading = false;
      debugPrint('>>> CourseDetailScreen.initState: Using passed-in course: ${_course?.id}, Lessons: ${_course?.lessonsList.length}');
    } else {
      // Otherwise load the course from provider asynchronously
      _loadCourse();
    }
  }
  
  Future<void> _loadCourse() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final course = await _contentProvider.getCourseById(widget.courseId);
      if (mounted) {
        setState(() {
          _course = course; 
          _isLoading = false;
          // DEBUG PRINT after fetching
          debugPrint('>>> CourseDetailScreen._loadCourse: Fetched course: ${_course?.id}, Lessons: ${_course?.lessonsList.length}');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _course = null;
          _isLoading = false;
          debugPrint('>>> CourseDetailScreen._loadCourse: Error fetching course: $e');
        });
      }
    }
  }

  Widget _buildLessonsTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.accentColor;

    return Container(
      color: backgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.zero, // No bottom padding needed here
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // Disable scrolling since parent handles it
        itemCount: _course!.lessonsList.length,
        itemBuilder: (context, index) {
          final lesson = _course!.lessonsList[index];
          // Enhanced lesson item
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        lesson: lesson,
                        courseId: widget.courseId,
                        courseTitle: _course!.title,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Lesson number in circle
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: themeProvider.accentTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Lesson details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lesson.description ?? '',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Lesson duration
                            Row(
                              children: [
                                Icon(
                                  _getLessonTypeIcon(lesson.type),
                                  color: secondaryTextColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getLessonTypeText(lesson.type),
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time,
                                  color: secondaryTextColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${lesson.durationMinutes} min',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Play button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of the existing build method)
  }
} 