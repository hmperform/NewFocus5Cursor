import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';
import '../../models/content_models.dart';
import 'course_detail_screen.dart';
import 'audio_player_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      if (contentProvider.courses.isEmpty) {
        contentProvider.initContent(null);
      }
      
      // Reset scroll position to top
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = userProvider.user;
    
    // Get theme-aware colors
    final accentColor = themeProvider.accentColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    if (user == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            )
          : RefreshIndicator(
              color: accentColor,
              backgroundColor: surfaceColor,
              onRefresh: () async {
                setState(() {
                  _isLoading = true;
                });
                
                // Refresh content
                await contentProvider.refreshTodayAudio();
                
                setState(() {
                  _isLoading = false;
                });
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8), // Add space at the top
                      _buildDayStreak(),
                      _buildFocusAreas(),
                      _buildFeaturedCourses(context),
                      _buildStartYourDay(context),
                      const SizedBox(height: 24), // Add space at the bottom for better UX
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDayStreak() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Daily Streak',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(7, (index) {
                final bool isActive = index == 0;
                final String day = index == 0 ? 'MO' : 
                                index == 1 ? 'TU' : 
                                index == 2 ? 'WE' : 
                                index == 3 ? 'TH' : 
                                index == 4 ? 'FR' :
                                index == 5 ? 'SA' : 'SU';
                
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isActive ? accentColor : surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: isActive ? themeProvider.accentTextColor : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      isActive 
                        ? Icon(Icons.check_circle, color: accentColor, size: 14)
                        : const SizedBox(height: 14),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusAreas() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final secondaryTextColor = themeProvider.isDarkMode 
        ? Colors.white70 
        : Colors.black87;
    
    // Expanded list of focus areas
    final focusAreas = [
      'Mental toughness', 
      'Discipline', 
      'Responsibility', 
      'Visualization', 
      'Concentration', 
      'Goal setting', 
      'Resilience', 
      'Mindfulness', 
      'Flow state', 
      'Leadership'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Focus Areas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: focusAreas.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    focusAreas[index],
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  backgroundColor: surfaceColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCourses(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    
    // If courses are empty, show loading indicator
    if (contentProvider.courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        height: 240,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      );
    }
    
    // Get the first two courses
    final courses = contentProvider.courses.take(2).toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 240,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (courses.isNotEmpty) CourseCard(
                  title: courses[0].title,
                  sport: courses[0].focusAreas.isNotEmpty ? courses[0].focusAreas.first : 'All Sports',
                  level: courses[0].tags.isNotEmpty ? courses[0].tags.first : 'Intermediate',
                  duration: '${courses[0].durationMinutes ~/ 60}h ${courses[0].durationMinutes % 60}m',
                  progress: 0.3,
                  imageUrl: courses[0].thumbnailUrl,
                  onTap: () {
                    // Navigate to course details
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(
                          courseId: courses[0].id,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                if (courses.length > 1) CourseCard(
                  title: courses[1].title,
                  sport: courses[1].focusAreas.isNotEmpty ? courses[1].focusAreas.first : 'Basketball',
                  level: courses[1].tags.isNotEmpty ? courses[1].tags.first : 'Advanced',
                  duration: '${courses[1].durationMinutes ~/ 60}h ${courses[1].durationMinutes % 60}m',
                  progress: 0.6,
                  imageUrl: courses[1].thumbnailUrl,
                  onTap: () {
                    // Navigate to course details
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(
                          courseId: courses[1].id,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context, {
    required String title,
    required String description,
    required String imageUrl,
  }) {
    final cardWidth = MediaQuery.of(context).size.width * 0.65;
    
    return GestureDetector(
      onTap: () {
        // Navigate to course detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              courseId: 'course1', // Replace with actual course ID when available
            ),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Image with placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF333333),
                    width: double.infinity,
                    height: double.infinity,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 48,
                    ),
                  );
                },
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB4FF00),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Read More',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // White circle
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartYourDay(BuildContext context) {
    final containerWidth = MediaQuery.of(context).size.width - 32; // Full width minus padding
    final containerHeight = containerWidth * 0.5; // Make height 50% of width for a better aspect ratio
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start Your Day',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              final imageUrl = 'https://picsum.photos/800/800?random=50';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AudioPlayerScreen(
                    title: 'Daily Focus Session',
                    subtitle: 'Morning Mental Preparation',
                    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                    imageUrl: imageUrl,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: containerWidth,
                height: containerHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                ),
                child: Stack(
                  children: [
                    // Background image with fade-in effect
                    Positioned.fill(
                      child: FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: 'https://picsum.photos/800/400?random=50',
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 300),
                      ),
                    ),
                    
                    // Gradient overlay for better text readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                              Colors.black.withOpacity(0.9),
                            ],
                            stops: const [0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                    
                    // Content overlay
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Focus Session',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Morning Mental Preparation • 10 min',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Play button
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB4FF00),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFB4FF00).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.play_arrow,
                                        color: Colors.black,
                                        size: 18,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Play',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Bookmark button
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.bookmark_border,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Session type indicator
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFB4FF00), width: 1),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Color(0xFFB4FF00),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build recommendation cards with actual course data
  Widget _buildCoursesSection() {
    final contentProvider = Provider.of<ContentProvider>(context);
    final courses = contentProvider.courses;
    
    if (courses.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Take up to 3 courses
    final displayCourses = courses.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Continue Learning',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayCourses.length,
            itemBuilder: (context, index) {
              final course = displayCourses[index];
              return Padding(
                padding: EdgeInsets.only(right: index < displayCourses.length - 1 ? 16 : 0),
                child: CourseCard(
                  title: course.title,
                  sport: course.focusAreas.isNotEmpty ? course.focusAreas.first : 'All Sports',
                  level: course.tags.isNotEmpty ? course.tags.first : 'Beginner',
                  duration: '${course.durationMinutes ~/ 60}h ${course.durationMinutes % 60}m',
                  progress: 0.3, // Dummy progress for now
                  imageUrl: course.thumbnailUrl,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(
                          courseId: course.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CourseCard extends StatelessWidget {
  final String title;
  final String sport;
  final String level;
  final String duration;
  final double progress;
  final String imageUrl;
  final VoidCallback onTap;

  const CourseCard({
    Key? key,
    required this.title,
    required this.sport,
    required this.level,
    required this.duration,
    required this.progress,
    required this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.accentColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor; 
    final surfaceColor = Theme.of(context).colorScheme.surface;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 220, // Reduced height to fix overflow
        margin: const EdgeInsets.only(right: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: imageUrl,
                    width: 280,
                    height: 140,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 280,
                        height: 140,
                        color: surfaceColor,
                        child: Icon(
                          Icons.image_not_supported,
                          color: secondaryTextColor,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
                
                // Level badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      level,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Duration badge
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      duration,
                      style: TextStyle(
                        color: themeProvider.accentTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Course info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.fitness_center, color: secondaryTextColor, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          sport,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
} 