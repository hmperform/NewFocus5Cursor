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
import '../../utils/app_icons.dart';
import '../../services/media_completion_service.dart';
import '../../services/firebase_content_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final Course? course;

  const CourseDetailScreen({
    Key? key,
    required this.courseId,
    this.course,
  }) : super(key: key);

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['LESSONS', 'OVERVIEW', 'RESOURCES'];
  bool _showDownloadButton = false;
  late Course _course;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Refresh user data to ensure we have latest from Firestore
    Provider.of<UserProvider>(context, listen: false).refreshUser();
    _loadCourse();
  }
  
  void _buildAnimationController() {
    // Implementation for animation controller
    // This is just a placeholder since we don't know what animations are used
  }
  
  Future<void> _loadCourse() async {
    if (widget.course != null) {
      setState(() {
        _course = widget.course!;
        _isLoading = false;
      });
      return;
    }

    try {
      final course = await FirebaseContentService().getCourseById(widget.courseId);
      if (course != null) {
        setState(() {
          _course = course;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Course not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load course: $e';
        _isLoading = false;
      });
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

    if (_error != null) {
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
                _error!,
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
        floatingActionButton: _buildActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // App Bar with course image and back button
              SliverAppBar(
                backgroundColor: surfaceColor,
                expandedHeight: 400,
                pinned: true,
                stretch: true,
                actions: [
                  // Debug button for forcing course purchase
                  if (_course.id == 'course-001')
                    IconButton(
                      icon: Icon(
                        Icons.build,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        final userProvider = Provider.of<UserProvider>(context, listen: false);
                        final result = await userProvider.forceAddConfidence101Course();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result 
                              ? 'Force added Confidence 101 course!' 
                              : 'Failed to force add course'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Force Add Course (Debug)',
                    ),
                  // Bookmark button
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
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Course image
                      Hero(
                        tag: 'course-image-${_course.id}',
                        child: ImageUtils.networkImageWithFallback(
                          imageUrl: _course.thumbnailUrl,
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
                              children: _course.tags.take(3).map((tag) {
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
                              _course.title,
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
                                  imageUrl: _course.creatorImageUrl,
                                  radius: 14,
                                  name: _course.creatorName,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _course.creatorName,
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
              ),
              
              // Course stats row
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(Icons.access_time, '${_course.durationMinutes ~/ 60}h ${_course.durationMinutes % 60}m', 'Duration'),
                      _buildStatItem(Icons.menu_book, '${_course.lessonsList.length}', 'Lessons'),
                      _buildStatItem(Icons.bolt, '${_course.xpReward}', 'XP'),
                      _buildStatItem(Icons.diamond, '${_course.focusPointsCost}', 'Focus Points'),
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
    final accentColor = themeProvider.accentColor;
    
    // Special case for Focus Points - use custom widget with better visibility
    if (icon == Icons.diamond) {
      return Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Circle background with number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.15),
                ),
                child: Center(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              // Focus Points Icon on top right
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.8),
                  ),
                  child: Image.asset(
                    'assets/icons/focuspointicon-removebg-preview.png',
                    width: 12,
                    height: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    
    // Original implementation for other icons
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
        itemCount: _course.lessonsList.length,
        itemBuilder: (context, index) {
          final lesson = _course.lessonsList[index];
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
                        courseTitle: _course.title,
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
            _course.description,
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
          if (_course.learningPoints.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _course.learningPoints
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
            children: _course.focusAreas.map((area) {
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
                      imageUrl: _course.creatorImageUrl,
                      radius: 36,
                      name: _course.creatorName,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _course.creatorName,
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

  Widget _buildActionButton() {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final userFocusPoints = userProvider.focusPoints;
    final hasEnoughPoints = userFocusPoints >= _course.focusPointsCost;
    final isPremium = _course.premium;
    final hasLessons = _course.modules.isNotEmpty;
    final alreadyPurchased = userProvider.isCoursePurchased(_course.id);
    
    // Debug information
    debugPrint('CourseDetailScreen [_buildActionButton]: Current course ID: "${_course.id}"');
    debugPrint('CourseDetailScreen [_buildActionButton]: Course title: "${_course.title}"');
    debugPrint('CourseDetailScreen [_buildActionButton]: Already purchased: $alreadyPurchased');
    debugPrint('CourseDetailScreen [_buildActionButton]: Is premium: $isPremium');
    debugPrint('CourseDetailScreen [_buildActionButton]: Has enough points: $hasEnoughPoints ($userFocusPoints >= ${_course.focusPointsCost})');
    
    // If course is already purchased or premium, show Start Course button
    if (alreadyPurchased || isPremium) {
      debugPrint('CourseDetailScreen [_buildActionButton]: Showing START COURSE button');
      return FloatingActionButton.extended(
        onPressed: () {
          if (hasLessons) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  lesson: _course.modules[0],
                  courseId: widget.courseId,
                  courseTitle: _course.title,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This course has no lessons yet.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        backgroundColor: accentColor,
        foregroundColor: themeProvider.accentTextColor,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Course'),
      );
    }
    
    // If user has enough focus points, show Redeem button
    if (hasEnoughPoints) {
      debugPrint('CourseDetailScreen [_buildActionButton]: Showing REDEEM button');
      return FloatingActionButton.extended(
        onPressed: () {
          _showRedeemConfirmationDialog();
        },
        backgroundColor: accentColor,
        foregroundColor: themeProvider.accentTextColor,
        icon: AppIcons.getFocusPointIcon(
          width: 24,
          height: 24,
          // Don't provide color to preserve the original image colors
        ),
        label: Text('Redeem for ${_course.focusPointsCost} Points'),
      );
    }
    
    // If user doesn't have enough points, show "Get More Points" button
    debugPrint('CourseDetailScreen [_buildActionButton]: Showing GET MORE POINTS button');
    return FloatingActionButton.extended(
      onPressed: () {
        _showFocusPointsPaywall();
      },
      backgroundColor: Colors.amber,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.shopping_cart),
      label: Text('Get More Points (Need ${_course.focusPointsCost - userFocusPoints} more)'),
    );
  }

  void _showRedeemConfirmationDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to redeem this course for ${_course.focusPointsCost} Focus Points?'),
            const SizedBox(height: 16),
            Text('Your balance: ${userProvider.focusPoints} Points'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.accentColor,
              foregroundColor: themeProvider.accentTextColor,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Attempt to spend focus points
              final success = await userProvider.spendFocusPoints(
                userProvider.user!.id,
                _course.focusPointsCost,
                'Course redemption: ${_course.title}',
                courseId: _course.id
              );
              
              if (success) {
                _showSuccessDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to redeem course. Please try again.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Redeem Course'),
          ),
        ],
      ),
    );
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              'You Got It!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'You have successfully redeemed "${_course.title}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(_course.thumbnailUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Start the course
                if (_course.modules.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        lesson: _course.modules[0],
                        courseId: widget.courseId,
                        courseTitle: _course.title,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Start Course'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  void _showFocusPointsPaywall() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Get Focus Points',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use Focus Points to unlock premium courses',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            
            // Focus Points packages
            _buildFocusPointPackage(
              points: 5,
              price: '\$30',
              isPopular: false,
              onTap: () => _handleFocusPointPurchase(5),
            ),
            const SizedBox(height: 12),
            _buildFocusPointPackage(
              points: 10,
              price: '\$50',
              isPopular: true,
              onTap: () => _handleFocusPointPurchase(10),
            ),
            const SizedBox(height: 12),
            _buildFocusPointPackage(
              points: 20,
              price: '\$75',
              isPopular: false,
              onTap: () => _handleFocusPointPurchase(20),
            ),
            
            const SizedBox(height: 32),
            Text(
              'Current Balance: ${userProvider.focusPoints} Points',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFocusPointPackage({
    required int points,
    required String price,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accentColor = themeProvider.accentColor;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular 
            ? accentColor 
            : Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Focus Points Icon and count
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isPopular 
                      ? accentColor.withOpacity(0.15)
                      : Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Points count
                      Text(
                        '$points',
                        style: TextStyle(
                          color: isPopular ? accentColor : Colors.blue,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Focus points icon (top right)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPopular 
                              ? Colors.black.withOpacity(0.7)
                              : Colors.grey[800],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Image.asset(
                            'assets/icons/focuspointicon-removebg-preview.png',
                            width: 18,
                            height: 18,
                          ),
                        ),
                      ),
                      
                      if (isPopular)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'BEST',
                              style: TextStyle(
                                color: themeProvider.accentTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Points and Price Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 16,
                          color: isPopular ? accentColor : Theme.of(context).colorScheme.onBackground,
                          fontWeight: isPopular ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Purchase Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPopular ? accentColor : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Purchase',
                    style: TextStyle(
                      color: isPopular ? themeProvider.accentTextColor : Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _handleFocusPointPurchase(int points) {
    // Here you would implement the in-app purchase flow
    // For now, just show a placeholder message
    Navigator.of(context).pop(); // Close the bottom sheet
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing purchase of $points Focus Points...'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: Implement actual in-app purchase flow
    // This would connect to RevenueCat or the appropriate payment processor
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