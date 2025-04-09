import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter/services.dart';

import '../../providers/user_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/content_models.dart';
import '../../utils/image_utils.dart';
import '../../utils/basic_video_helper.dart';
import '../../services/media_completion_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final Course? course;

  const CourseDetailScreen({
    Key? key,
    required this.courseId,
    this.course,
  }) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['LESSONS', 'OVERVIEW', 'RESOURCES'];
  bool _showDownloadButton = false;
  Course? _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // If course was passed in, use it directly
    if (widget.course != null) {
      _course = widget.course;
      _isLoading = false;
      return;
    }
    
    // Otherwise load the course from provider
    _loadCourse();
  }
  
  void _buildAnimationController() {
    // Implementation for animation controller
    // This is just a placeholder since we don't know what animations are used
  }
  
  Future<void> _loadCourse() async {
    await _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    // Add a small delay to simulate network request
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    
    try {
      // Properly await the Future returned by getCourseById
      final course = await contentProvider.getCourseById(widget.courseId);

      if (mounted) {
        setState(() {
          _course = course; // This could be null if course not found
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _course = null;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading course: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.accentColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      );
    }

    if (_course == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Course not found',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: themeProvider.accentTextColor,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: backgroundColor,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Start the course
            // Navigate to first module
            if (_course!.modules.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    lesson: _course!.modules[0],
                    courseId: widget.courseId,
                    courseTitle: _course!.title,
                  ),
                ),
              );
            }
          },
          backgroundColor: accentColor,
          foregroundColor: themeProvider.accentTextColor,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Course'),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // App Bar with course image and back button
              SliverAppBar(
                backgroundColor: surfaceColor,
                expandedHeight: 400,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Course image
                      Hero(
                        tag: 'course-image-${_course!.id}',
                        child: ImageUtils.networkImageWithFallback(
                          imageUrl: _course!.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      
                      // Gradient overlay for text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.5),
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.3, 0.65, 1.0],
                          ),
                        ),
                      ),
                      
                      // Course info at the bottom
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Course tags
                            Wrap(
                              spacing: 8,
                              children: _course!.tags.take(3).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: themeProvider.accentTextColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Course title
                            Text(
                              _course!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Creator info
                            Row(
                              children: [
                                ImageUtils.avatarWithFallback(
                                  imageUrl: _course!.creatorImageUrl,
                                  radius: 14,
                                  name: _course!.creatorName,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _course!.creatorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
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
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.bookmark_border, color: Colors.white),
                      onPressed: () {
                        // TODO: Save course to bookmarks
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Course saved!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              // Course stats row
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(Icons.access_time, '${_course!.durationMinutes ~/ 60}h ${_course!.durationMinutes % 60}m', 'Duration'),
                      _buildStatItem(Icons.menu_book, '${_course!.lessonsList.length}', 'Lessons'),
                      _buildStatItem(Icons.bolt, '${_course!.xpReward}', 'XP'),
                    ],
                  ),
                ),
              ),
              
              // Tab bar
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                    labelColor: accentColor,
                    unselectedLabelColor: secondaryTextColor,
                    indicatorColor: accentColor,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          // Use TabBarView with scrollable tabs for each tab's content
          body: TabBarView(
            children: [
              _buildScrollableTab(_buildLessonsTab()),
              _buildScrollableTab(_buildOverviewTab()),
              _buildScrollableTab(_buildResourcesTab()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableTab(Widget content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100), // Extra bottom padding for FAB
      child: content,
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    return Column(
      children: [
        Icon(icon, color: secondaryTextColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.accentColor;
    final userProvider = Provider.of<UserProvider>(context, listen: true);

    return Container(
      color: backgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.zero, // No bottom padding needed here
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // Disable scrolling since parent handles it
        itemCount: _course!.lessonsList.length,
        itemBuilder: (context, index) {
          final lesson = _course!.lessonsList[index];
          // Check if the lesson is completed using the user provider
          final bool isCompleted = userProvider.completedLessonIds.contains(lesson.id);
          
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
                      // Lesson number or completion indicator
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isCompleted 
                          ? const Icon(Icons.check, color: Colors.white) 
                          : Text(
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
                              lesson.description ?? 'No description available',
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
                      // Mark as complete or play button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            if (isCompleted) {
                              // Lesson is already completed, do nothing
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('This lesson is already completed!'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              // Mark as complete
                              bool success = await userProvider.toggleLessonCompletion(lesson.id, true, context: context);
                              // Only show success message if toggle was successful
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Lesson marked as completed!'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: isCompleted
                              ? Icon(
                                  Icons.check_box,
                                  color: Colors.green,
                                  size: 28,
                                )
                              : Icon(
                                  Icons.check_box_outline_blank,
                                  color: accentColor,
                                  size: 28,
                                ),
                          ),
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
  
  IconData _getLessonTypeIcon(LessonType type) {
    switch (type) {
      case LessonType.video:
        return Icons.videocam;
      case LessonType.audio:
        return Icons.headset;
      case LessonType.text:
        return Icons.article;
      case LessonType.quiz:
        return Icons.quiz;
      default:
        return Icons.school;
    }
  }
  
  String _getLessonTypeText(LessonType type) {
    switch (type) {
      case LessonType.video:
        return 'Video';
      case LessonType.audio:
        return 'Audio';
      case LessonType.text:
        return 'Text';
      case LessonType.quiz:
        return 'Quiz';
      default:
        return 'Lesson';
    }
  }

  Widget _buildOverviewTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.accentColor;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About this course section
          Text(
            'About this course',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _course!.description,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          
          // What you'll learn section
          Text(
            'What you\'ll learn',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Dynamically build learning points from the course data
          if (_course != null && _course!.learningPoints.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _course!.learningPoints
                  .map((point) => _buildLearningPoint(point))
                  .toList(),
            )
          else
            // Optional: Show a message if no learning points are available
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No learning points specified for this course.',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
          const SizedBox(height: 32),
          
          // Focus areas
          Text(
            'Focus Areas',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _course!.focusAreas.map((area) {
              return Chip(
                label: Text(area),
                backgroundColor: surfaceColor,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                labelStyle: TextStyle(color: secondaryTextColor),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          
          // Instructor info with card
          Text(
            'Your Instructor',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ImageUtils.avatarWithFallback(
                      imageUrl: _course!.creatorImageUrl,
                      radius: 36,
                      name: _course!.creatorName,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _course!.creatorName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.verified, size: 16, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                'Mental Performance Coach',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Expert in mental resilience and high-performance mindset. Helping individuals break barriers and achieve their full potential for over a decade.',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInstructorStat('10+', 'Years Experience'),
                    _buildInstructorStat('5', 'Courses'),
                    _buildInstructorStat('4.9', 'Rating'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPoint(String text) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final accentColor = themeProvider.accentColor;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: accentColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorStat(String value, String label) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildResourcesTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.accentColor;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Resources',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildResourceItem(
            'Course Workbook.pdf',
            'Comprehensive workbook with exercises',
            Icons.description,
            accentColor,
          ),
          _buildResourceItem(
            'Mental Focus Guide.pdf',
            'Step-by-step guide to improve focus',
            Icons.menu_book,
            Colors.green,
          ),
          _buildResourceItem(
            'Visualization Techniques.mp3',
            'Audio guide for visualization practice',
            Icons.headset,
            Colors.orange,
          ),
          _buildResourceItem(
            'Mindfulness Scripts.pdf',
            'Collection of mindfulness exercises',
            Icons.spa,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(String title, String description, IconData icon, Color iconColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.download,
              color: secondaryTextColor,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading $title'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final Lesson lesson;
  final String courseId;
  final String courseTitle;

  const VideoPlayerScreen({
    Key? key,
    required this.lesson,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  @override
  void initState() {
    super.initState();
    
    // Initialize the video when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideo();
    });
  }
  
  void _initializeVideo() {
    // Check if there's a video URL
    final videoUrl = widget.lesson.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      // If no video URL, show error message and return
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video available for this lesson'),
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    
    // Get current user ID for tracking completion
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id ?? '';

    // Play the video using BasicVideoHelper
    BasicVideoHelper.playVideo(
      context: context,
      videoUrl: videoUrl,
      title: widget.lesson.title,
      subtitle: widget.courseTitle,
      thumbnailUrl: widget.lesson.thumbnailUrl ?? '',
      mediaItem: MediaItem(
        id: widget.lesson.id,
        title: widget.lesson.title,
        description: widget.lesson.description ?? 'No description available',
        mediaType: MediaType.video,
        mediaUrl: videoUrl,
        imageUrl: widget.lesson.thumbnailUrl ?? '',
        creatorId: '',
        creatorName: '',
        durationMinutes: widget.lesson.durationMinutes,
        focusAreas: widget.lesson.type == LessonType.video ? ['Video'] : ['Audio'],
        datePublished: DateTime.now(),
        universityExclusive: false,
        category: '',
        xpReward: 10,
      ),
      openFullscreen: true,
      onMediaCompleted: (mediaId) {
        // Mark lesson media as completed in the media completion service
        final mediaCompletionService = MediaCompletionService();
        mediaCompletionService.markMediaCompleted(userId, mediaId, MediaType.video);
        
        // Show completion snackbar if desired
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lesson content completed! You can now mark it as completed.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
    
    // Do NOT pop this screen - let the video player navigate naturally
  }

  @override
  Widget build(BuildContext context) {
    // Use a minimal loading screen that won't flash
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
} 