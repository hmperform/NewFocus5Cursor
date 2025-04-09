import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/content_models.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/video_player_screen.dart';
import '../../services/firebase_content_service.dart';
import '../../utils/image_utils.dart';
import 'package:transparent_image/transparent_image.dart';


class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final Course? course; // Allow passing pre-fetched course

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.course, 
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['LESSONS', 'OVERVIEW', 'RESOURCES']; // Example tabs

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Use passed course if available
      if (widget.course != null) {
        _course = widget.course;
      } else {
        // Otherwise, fetch from provider or service
        final contentProvider = Provider.of<ContentProvider>(context, listen: false);
        _course = await contentProvider.getCourseById(widget.courseId);
      }

      if (_course == null) {
        _error = 'Course not found.';
      }
    } catch (e) {
      _error = 'Failed to load course: ${e.toString()}';
      debugPrint('Error loading course details: $e');
    } finally {
      if (mounted) { // Check if widget is still in the tree
         setState(() {
           _isLoading = false;
         });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context); // Listen for changes
    final textColor = Theme.of(context).colorScheme.onSurface;
    final secondaryTextColor = textColor.withOpacity(0.7);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_error!, style: TextStyle(color: Colors.red, fontSize: 16)),
          ),
        ),
      );
    }

    if (_course == null) {
      // This case should ideally be handled by the error state, but added for safety
       return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Course data is unavailable.')),
      );
    }

    // Main content scaffold
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: backgroundColor, // Match background
            elevation: 0, // Remove shadow when collapsed
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.black.withOpacity(0.3))
              )
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Course image with Hero animation
                  Hero(
                    tag: 'course-image-${_course!.id}',
                    child: ImageUtils.networkImageWithFallback(
                      imageUrl: _course!.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                    ),
                  ),
                  // Gradient overlay for text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: [0.4, 1.0], // Adjust gradient start
                      ),
                    ),
                  ),
                  // Course Title and Creator Info at the bottom
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Wrap(
                            spacing: 8,
                            children: _course!.tags.take(3).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 11)),
                              );
                            }).toList(),
                          ),
                         const SizedBox(height: 8),
                         Text(
                          _course!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
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
                                fontSize: 14,
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
          ),
          // Course Stats Section
           SliverToBoxAdapter(
            child: Container(
               padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
               color: backgroundColor, // Ensure background continuity
               child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface, 
                  borderRadius: BorderRadius.circular(16),
                ),
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
          ),
          // Tab Bar Section
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                controller: DefaultTabController.of(context),
                labelColor: themeProvider.accentColor, // Active tab color
                unselectedLabelColor: secondaryTextColor, // Inactive tab color
                indicatorColor: themeProvider.accentColor,
                onTap: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
              ),
            ),
            pinned: true,
          ),
          // Tab Content Section
          SliverFillRemaining(
             child: TabBarView(
               controller: DefaultTabController.of(context),
               children: [
                 _buildLessonsList(context, userProvider), // Lessons Tab
                 _buildOverviewTab(context, textColor, secondaryTextColor), // Overview Tab
                 _buildResourcesTab(context), // Resources Tab
               ],
            ),
          ),
        ],
      ),
      // Floating Action Button to Start Course
       floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Start the course - Navigate to the first lesson
          if (_course!.lessonsList.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  lesson: _course!.lessonsList[0],
                  courseId: widget.courseId,
                  courseTitle: _course!.title,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This course has no lessons yet.')),
            );
          }
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Course'),
        backgroundColor: themeProvider.accentColor,
        foregroundColor: Colors.white,
      ),
    );
  }

   // Helper for Stat Items
  Widget _buildStatItem(IconData icon, String value, String label) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: textColor.withOpacity(0.8), size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
      ],
    );
  }

  // Builds the Lessons List Tab
  Widget _buildLessonsList(BuildContext context, UserProvider userProvider) {
      final themeProvider = Provider.of<ThemeProvider>(context);
      final textColor = Theme.of(context).colorScheme.onSurface;

      if (_course!.lessonsList.isEmpty) {
        return const Center(child: Text('No lessons available for this course yet.'));
      }

      return ListView.builder(
        padding: EdgeInsets.zero, // Remove default padding
        itemCount: _course!.lessonsList.length,
        itemBuilder: (context, index) {
          final lesson = _course!.lessonsList[index];
          final bool isCompleted = userProvider.completedLessonIds.contains(lesson.id);

          return Container(
             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.surface,
               borderRadius: BorderRadius.circular(12),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withOpacity(0.05),
                   blurRadius: 5,
                   offset: const Offset(0, 2),
                 ),
               ],
             ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Navigate to the lesson screen (e.g., VideoPlayerScreen)
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen( // Use appropriate screen based on lesson.type
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
                       Container(
                          width: 36, height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: (isCompleted ? themeProvider.accentColor : Theme.of(context).colorScheme.primary).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}', 
                            style: TextStyle(
                              color: isCompleted ? themeProvider.accentColor : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold
                            )
                          ),
                       ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                              maxLines: 2,
                            ),
                             if (lesson.description != null && lesson.description!.isNotEmpty)
                              const SizedBox(height: 4),
                              Text(
                                lesson.description ?? '', 
                                style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.7)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                 Icon(_getLessonTypeIcon(lesson.type), size: 14, color: textColor.withOpacity(0.6)),
                                const SizedBox(width: 4),
                                Text(_getLessonTypeText(lesson.type), style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6), fontWeight: FontWeight.w500)),
                                const SizedBox(width: 12),
                                 Icon(Icons.access_time, size: 14, color: textColor.withOpacity(0.6)),
                                const SizedBox(width: 4),
                                 Text('${lesson.durationMinutes} min', style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6), fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                       Container(
                         width: 30, height: 30,
                         decoration: BoxDecoration(
                            color: isCompleted ? themeProvider.accentColor : Colors.grey.withOpacity(0.2),
                            shape: BoxShape.circle,
                         ),
                         child: Icon(
                           isCompleted ? Icons.check : Icons.play_arrow,
                           color: isCompleted ? Colors.white : textColor.withOpacity(0.6),
                           size: 18,
                         ),
                       ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

  // Builds the Overview Tab
  Widget _buildOverviewTab(BuildContext context, Color textColor, Color secondaryTextColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Text(
            _course!.description,
            style: TextStyle(color: secondaryTextColor, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),
          
          if (_course!.learningPoints.isNotEmpty)
            Text('What you'll learn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _course!.learningPoints
                  .map((point) => _buildLearningPoint(point, textColor))
                  .toList(),
            ),
             const SizedBox(height: 24),
          
           Text('Focus Areas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
             Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _course!.focusAreas.map((area) {
                return Chip(
                  label: Text(area),
                  backgroundColor: themeProvider.accentColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: themeProvider.accentColor, fontWeight: FontWeight.w500),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

          Text('About the instructor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // Add instructor title/bio if available in the Course model
                    // Text(_course!.creatorTitle ?? '', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                    // const SizedBox(height: 8),
                    // Text(_course!.creatorBio ?? '', style: TextStyle(color: secondaryTextColor, fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

   Widget _buildLearningPoint(String point, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(point, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }

  // Builds the Resources Tab (Placeholder)
  Widget _buildResourcesTab(BuildContext context) {
    return const Center(
      child: Text('Resources will be available here.'),
    );
  }

  // Helper to get icon based on lesson type
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
        return Icons.notes;
    }
  }
  
  // Helper to get text based on lesson type
  String _getLessonTypeText(LessonType type) {
     switch (type) {
      case LessonType.video:
        return 'Video';
      case LessonType.audio:
        return 'Audio';
      case LessonType.text:
        return 'Reading';
      case LessonType.quiz:
        return 'Quiz';
      default:
        return 'Lesson';
    }
  }
}

// Helper class for SliverPersistentHeader delegate
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Match background
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
} 