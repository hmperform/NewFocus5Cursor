import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:transparent_image/transparent_image.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/media_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/audio_module_provider.dart';
import '../../constants/theme.dart';
import '../../models/content_models.dart';
import '../../widgets/status_bar.dart'; // Import the StatusBar
import '../../widgets/daily_streak_widget.dart';
import 'course_detail_screen.dart';
import 'audio_player_screen.dart';
import 'media_player_screen.dart';
import '../../utils/basic_video_helper.dart';
import '../../utils/image_utils.dart';
import '../../utils/app_icons.dart'; // Import the app icons utility
// import '../../constants/dummy_data.dart'; // Commented out unused import
// import '../../widgets/loaders/loading_indicator.dart'; // Commented out unused import
// import '../../widgets/quick_action_card.dart'; // Commented out unused import
// import '../../widgets/sections/section_header.dart'; // Commented out unused import

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  List<Course> _featuredCourses = [];
  List<dynamic> _recentMedia = []; // Combine recent videos and audios
  // final List<String> quickActions = DummyData.quickActions;
  // final List<Map<String, dynamic>> forYouItems = DummyData.forYouItems;

  bool _isLoadingFeatured = true;
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    
    // Wait until build completes before loading content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeLoadContent();
      
      // Preload daily videos in the background
      _preloadFeaturedVideos();
    });
  }

  Future<void> _preloadFeaturedVideos() async {
    try {
      // Get the featured video URL from 'Is All Self-Criticism Bad?'
      final featuredVideoUrl = 'gs://focus-5-app.firebasestorage.app/modules/day3bouncebackcourse.mp4';
      
      // Also preload a couple of videos from DummyData for Media tab
      final List<String> additionalVideos = [];
      // if (DummyData.dummyMediaItems.isNotEmpty) { // Commented out DummyData usage
      //   for (var item in DummyData.dummyMediaItems) {
      //     if (item.mediaType == MediaType.video && 
      //         additionalVideos.length < 2 && // Limit to 2 additional videos
      //         !additionalVideos.contains(item.mediaUrl)) {
      //       additionalVideos.add(item.mediaUrl);
      //     }
      //   }
      // } // Commented out DummyData usage
      
      // Create combined list with featured video first
      final videosToPreload = [featuredVideoUrl, ...additionalVideos];
      
      // Preload all videos
      await BasicVideoHelper.preloadVideos(
        context: context,
        videoUrls: videosToPreload,
      );
      
      debugPrint('Preloaded ${videosToPreload.length} videos successfully');
    } catch (e) {
      debugPrint('Error preloading videos: $e');
    }
  }

  Future<void> _safeLoadContent() {
    if (!mounted) return Future.value();
    
    setState(() {
      _isLoading = true;
    });
    
    // Create a completer to track when loading is complete
    final completer = Completer<void>();
    
    // Safe load with timeout
    Future.delayed(Duration.zero, () async {
      try {
        await _loadDashboardContent();
        completer.complete();
      } catch (e) {
        print('Error loading dashboard: $e');
        completer.complete(); // Complete the future even on error
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
    
    // Safety timeout
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
    
    return completer.future;
  }

  // Load content in a separate method
  Future<void> _loadDashboardContent() async {
    try {
      // Get providers safely
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        print('DashboardTab: User not logged in, skipping content load.');
        return;
      }
      
      // Load core content if needed
      if (contentProvider.courses.isEmpty) {
        try {
          await Future.microtask(() => null); // Delay to prevent build conflicts
          if (mounted) {
            await contentProvider.initContent(userId);
          }
        } catch (e) {
          print('Content initialization error: $e');
        }
      }
      
      // Audio module loading is now handled by AudioModuleProvider constructor/update
      /*
      try {
        print('DashboardTab: Loading current audio module...');
        await audioModuleProvider.loadCurrentAudioModule(userId);
        print('DashboardTab: Finished loading audio module.');
      } catch (e) {
        print('Audio refresh error: $e');
      }
      */
    } catch (e) {
      print('Dashboard loading error: $e');
    }
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
    
    // Get theme-aware colors
    final accentColor = themeProvider.accentColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    // Simplified build with overlay for loading
    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        color: accentColor,
        backgroundColor: surfaceColor,
        onRefresh: () {
          return _safeLoadContent();
        },
        child: Stack(
          children: [
            // Main content
            ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 64), // Add padding for StatusBar
              children: [
                const SizedBox(height: 8),
                _buildDayStreak(),
                _buildStartYourDay(context),
                _buildRecentCourses(),
                _buildFeaturedCourses(context),
                const SizedBox(height: 24),
              ],
            ),
            
            // Add StatusBar at the top
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: StatusBar(),
            ),
            
            // Loading indicator overlay
            if (_isLoading)
              Container(
                color: backgroundColor.withOpacity(0.6),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayStreak() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    
    // If user data isn't loaded yet, show a loading placeholder
    if (user == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }
    
    // Use the streak value from user data and the updated DailyStreakWidget
    return DailyStreakWidget(
      currentStreak: user.streak,
      longestStreak: user.longestStreak,
      lastLoginDate: user.lastLoginDate,
      lastActive: user.lastActive,
    );
  }

  Widget _buildRecentCourses() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final contentProvider = Provider.of<ContentProvider>(context);
    
    // Determine how many courses are featured (max 2)
    final int featuredCount = contentProvider.courses.length >= 2 ? 2 : contentProvider.courses.length;
    
    // Get courses for the "Recent" list, skipping those shown in "Featured"
    final recentCourses = contentProvider.courses.skip(featuredCount).take(4).toList();

    if (contentProvider.isLoading && recentCourses.isEmpty && featuredCount == 0) { // Only show loading if nothing else is loaded
      return Container(
        height: 230, // Adjusted height? Check UI
        child: Center(child: CircularProgressIndicator(color: themeProvider.accentColor)),
      );
    } else if (recentCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Recent Courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recentCourses.length,
            itemBuilder: (context, index) {
              final course = recentCourses[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
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
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: FadeInImage.memoryNetwork(
                            placeholder: kTransparentImage,
                            image: course.thumbnailUrl,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            imageErrorBuilder: (ctx, err, st) => Container(
                              height: 100,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            course.title,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
                  courseId: courses[0].id,
                  title: courses[0].title,
                  description: courses[0].description,
                  imageUrl: courses[0].thumbnailUrl,
                  durationMinutes: courses[0].durationMinutes,
                  lessonsCount: courses[0].lessonsList.length,
                  creatorName: courses[0].creatorName,
                  creatorImageUrl: courses[0].creatorImageUrl,
                  premium: courses[0].premium,
                  focusPointsCost: courses[0].focusPointsCost,
                ),
                const SizedBox(width: 16),
                if (courses.length > 1) CourseCard(
                  courseId: courses[1].id,
                  title: courses[1].title,
                  description: courses[1].description,
                  imageUrl: courses[1].thumbnailUrl,
                  durationMinutes: courses[1].durationMinutes,
                  lessonsCount: courses[1].lessonsList.length,
                  creatorName: courses[1].creatorName,
                  creatorImageUrl: courses[1].creatorImageUrl,
                  premium: courses[1].premium,
                  focusPointsCost: courses[1].focusPointsCost,
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
              course: null,
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
    final contentProvider = Provider.of<ContentProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    final audioModule = contentProvider.todayAudio;

    if (contentProvider.isLoading && audioModule == null) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    }

    if (audioModule == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Text(
          'No daily content available today.', 
          style: TextStyle(color: secondaryTextColor)
        ),
      );
    }

    final containerWidth = MediaQuery.of(context).size.width - 32;
    final containerHeight = 170.0; // Increased height for card
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Start Your Day',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioPlayerScreen(
                  audio: audioModule,
                  currentDay: Provider.of<UserProvider>(context, listen: false).user?.totalLoginDays ?? 1,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 220, // Increased height for more square appearance
            width: containerWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black,
                  const Color(0xFF2A6C00)
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(20), // Increased padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DAILY AUDIO tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DAILY AUDIO',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        audioModule.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24, // Increased font size
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Description
                      Text(
                        audioModule.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14, // Increased font size
                        ),
                        maxLines: 2, // Show 2 lines instead of 1
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // Duration and XP
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 22, // Slightly larger icon
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${audioModule.durationMinutes} min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.star,
                            color: accentColor,
                            size: 20, // Slightly larger icon
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${audioModule.xpReward} XP',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
      ],
    );
  }

  // Daily video section
  Widget _buildDailyVideo(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    final textColor = Theme.of(context).colorScheme.onBackground;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final accentColor = themeProvider.accentColor;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    // Get the featured video - now using Firebase Storage URL
    final featuredVideo = MediaItem(
      id: 'bounce_back_video',
      title: 'Is All Self-Criticism Bad?',
      description: 'Learn essential techniques to manage self-criticism and build mental resilience',
      mediaType: MediaType.video,
      // Firebase Storage URL
      mediaUrl: 'gs://focus-5-app.firebasestorage.app/modules/day3bouncebackcourse.mp4',
      imageUrl: 'https://picsum.photos/500/300?random=42',
      creatorId: 'coach5',
      creatorName: 'Morgan Taylor',
      durationMinutes: 5,
      focusAreas: ['Resilience', 'Mental Toughness'],
      xpReward: 30,
      datePublished: DateTime.now().subtract(const Duration(days: 1)),
      universityExclusive: false,
      universityAccess: null,
      category: 'Resilience',
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Video",
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Video card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () {
              BasicVideoHelper.playVideo(
                context: context,
                videoUrl: featuredVideo.mediaUrl,
                title: featuredVideo.title,
                subtitle: featuredVideo.description,
                thumbnailUrl: featuredVideo.imageUrl,
                mediaItem: featuredVideo,
                openFullscreen: true,
              );
            },
            child: Container(
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
                  // Video thumbnail
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16/9,
                          child: Image.network(
                            featuredVideo.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[800],
                                child: const Center(
                                  child: Icon(
                                    Icons.videocam,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Play button overlay
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withOpacity(0.8),
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: themeProvider.accentTextColor,
                          size: 32,
                        ),
                      ),
                      
                      // Duration badge
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${featuredVideo.durationMinutes} min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Video details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          featuredVideo.title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Description
                        Text(
                          featuredVideo.description,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Coach info and XP reward
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              featuredVideo.creatorName,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.star_outline,
                              size: 16,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${featuredVideo.xpReward} XP',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
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
        ),
      ],
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
                  courseId: course.id,
                  title: course.title,
                  description: course.description,
                  imageUrl: course.thumbnailUrl,
                  durationMinutes: course.durationMinutes,
                  lessonsCount: course.lessonsList.length,
                  creatorName: course.creatorName,
                  creatorImageUrl: course.creatorImageUrl,
                  premium: course.premium,
                  focusPointsCost: course.focusPointsCost,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMediaSection() {
    final contentProvider = Provider.of<ContentProvider>(context);
    final List<dynamic> recentMedia = []; // Replace DummyData
    // Fetch recent media, e.g., last 5 videos/audios
    // recentMedia.addAll(contentProvider.videos.take(3)); 
    // recentMedia.addAll(contentProvider.audios.take(2));
    // recentMedia.shuffle(); // Optional: Mix them up

    if (recentMedia.isEmpty) {
      return const SizedBox.shrink(); // Return empty space if no media
    }

    // TODO: Implement the UI for displaying recent media items
    return Column(
      // Add children here based on recentMedia list
      children: [], // Placeholder
    ); // Close Column
  } // Close _buildRecentMediaSection

  Widget _buildForYouSection() {
    // Return an empty container to satisfy the return type
    return Container();
  }

  // Add these variables to the _DashboardTabState class
  // Add a method to get a DailyAudio instance and totalLoginDays
  DailyAudio? get audioModule => Provider.of<ContentProvider>(context, listen: false).todayAudio;
  int get totalLoginDays => Provider.of<UserProvider>(context, listen: false).user?.totalLoginDays ?? 1;
} // Close _DashboardTabState class

// Moved CourseCard class definition outside _DashboardTabState
class CourseCard extends StatelessWidget {
  final String courseId;
  final String title;
  final String description;
  final String imageUrl;
  final int durationMinutes;
  final int lessonsCount;
  final String creatorName;
  final String creatorImageUrl;
  final bool premium;
  final int focusPointsCost;

  const CourseCard({
    Key? key,
    required this.courseId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.durationMinutes,
    required this.lessonsCount,
    required this.creatorName,
    required this.creatorImageUrl,
    required this.premium,
    this.focusPointsCost = 0,
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              courseId: courseId,
              course: null,
            ),
          ),
        );
      },
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
                      'Intermediate',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Focus Points badge
                if (focusPointsCost > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          AppIcons.getFocusPointIcon(
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$focusPointsCost',
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
                      '${durationMinutes ~/ 60}h ${durationMinutes % 60}m',
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
                          'Basketball',
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