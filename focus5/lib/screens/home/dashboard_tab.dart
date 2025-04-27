import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:transparent_image/transparent_image.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math'; // Import for random selection
import 'package:shared_preferences/shared_preferences.dart'; // Import for persistence
import 'package:intl/intl.dart'; // Import for date formatting

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
import 'article_detail_screen.dart'; // Import Article Detail Screen
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
  Course? _dailyCourse; // State for daily course
  Article? _dailyArticle; // State for daily article
  bool _dailySelectionMadeForToday = false; // Flag to track selection

  // Keys for SharedPreferences
  static const String _prefsKeyDailyCourseId = 'daily_course_id';
  static const String _prefsKeyDailyArticleId = 'daily_article_id';
  static const String _prefsKeyLastSelectionDate = 'last_selection_date';

  @override
  void initState() {
    super.initState();
    _dailySelectionMadeForToday = false; // Reset flag on init
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
      // Reset daily items temporarily during refresh
      _dailyCourse = null;
      _dailyArticle = null;
      _dailySelectionMadeForToday = false; // Reset flag on refresh
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
        completer.completeError(e); // Propagate error
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
    
    // Safety timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading && !completer.isCompleted) {
         print("Dashboard loading timed out.");
         setState(() {
          _isLoading = false;
         });
        completer.complete(); // Complete to avoid hanging
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
      
      // 1. Ensure core content (courses, articles) is loaded
      if (contentProvider.courses.isEmpty || contentProvider.articles.isEmpty) {
         debugPrint("DashboardTab: Core content empty, initializing...");
        try {
          await contentProvider.initContent(userId);
           debugPrint("DashboardTab: Core content initialized. Courses: ${contentProvider.courses.length}, Articles: ${contentProvider.articles.length}");
        } catch (e) {
          print('Content initialization error: $e');
           // If init fails, we might not have content for daily selection
           // Handle this gracefully later (e.g., show message)
        }
      } else {
         debugPrint("DashboardTab: Core content already loaded. Courses: ${contentProvider.courses.length}, Articles: ${contentProvider.articles.length}");
      }
      
      if (!mounted) return; // Check mount status after async gap

      // 2. Handle Daily Selection Logic
      await _updateDailySelection(contentProvider);

    } catch (e) {
      print('Dashboard loading error: $e');
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard content: ${e.toString()}'))
        );
      }
    }
  }

  Future<void> _updateDailySelection(ContentProvider contentProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastSelectionDate = prefs.getString(_prefsKeyLastSelectionDate);

    String? savedCourseId;
    String? savedArticleId;

    bool selectNew = false; // Default to false, only set true if needed
    bool isToday = lastSelectionDate == todayString;

    if (isToday) {
      savedCourseId = prefs.getString(_prefsKeyDailyCourseId);
      savedArticleId = prefs.getString(_prefsKeyDailyArticleId);
      if (savedCourseId != null && savedArticleId != null) {
        selectNew = false;
        debugPrint("DashboardTab: Using saved daily selection for $todayString");
      } else {
         debugPrint("DashboardTab: Date matches but IDs potentially missing, checking available content before deciding selection path.");
         // Check if saved IDs exist
         if (savedCourseId == null || savedArticleId == null) {
            // If IDs are missing, we might need to select new *if* content is available
             bool courseContentAvailable = contentProvider.courses.isNotEmpty;
             bool articleContentAvailable = contentProvider.articles.isNotEmpty;

             if ((savedCourseId == null && courseContentAvailable) || (savedArticleId == null && articleContentAvailable)) {
                 selectNew = true;
                 debugPrint("DashboardTab: Missing saved IDs and content available. Marking for new selection.");
             } else {
                 // Missing IDs but no content yet, wait for potential future load.
                 selectNew = false;
                 debugPrint("DashboardTab: Missing saved IDs but no corresponding content available yet.");
             }
         } else {
            // Saved IDs exist, use the saved path
            selectNew = false;
         }
      }
    } else {
       debugPrint("DashboardTab: Last selection date ($lastSelectionDate) doesn't match today ($todayString), selecting new.");
       selectNew = true;
    }

    Course? newDailyCourse = _dailyCourse; // Start with current state
    Article? newDailyArticle = _dailyArticle;
    bool dataChanged = false;

    final allCourses = contentProvider.courses;
    final allArticles = contentProvider.articles;

    if (selectNew) {
      debugPrint("DashboardTab: Entering selectNew block.");
      bool courseSelected = false;
      bool articleSelected = false;

      // Select new random items
      if (allCourses.isNotEmpty) {
        final random = Random();
        newDailyCourse = allCourses[random.nextInt(allCourses.length)];
        await prefs.setString(_prefsKeyDailyCourseId, newDailyCourse.id);
         debugPrint("DashboardTab: Selected new daily course: ${newDailyCourse.id}");
        courseSelected = true;
        dataChanged = true;
      } else {
         debugPrint("DashboardTab: No courses available to select randomly.");
         // Ensure course ID is cleared if none available
         if (prefs.containsKey(_prefsKeyDailyCourseId)) {
            await prefs.remove(_prefsKeyDailyCourseId);
         }
         if (_dailyCourse != null) dataChanged = true; // Data changed if we cleared a previously held course
         newDailyCourse = null; // Explicitly set to null
      }

      if (allArticles.isNotEmpty) {
        final random = Random();
        newDailyArticle = allArticles[random.nextInt(allArticles.length)];
        await prefs.setString(_prefsKeyDailyArticleId, newDailyArticle.id);
         debugPrint("DashboardTab: Selected new daily article: ${newDailyArticle.id}");
        articleSelected = true;
        dataChanged = true;
      } else {
         debugPrint("DashboardTab: No articles available to select randomly.");
          // Ensure article ID is cleared if none available
         if (prefs.containsKey(_prefsKeyDailyArticleId)) {
            await prefs.remove(_prefsKeyDailyArticleId);
         }
         if (_dailyArticle != null) dataChanged = true; // Data changed if we cleared a previously held article
         newDailyArticle = null; // Explicitly set to null
      }

      // Update the selection date only if we successfully selected at least one item
      if (courseSelected || articleSelected) {
        await prefs.setString(_prefsKeyLastSelectionDate, todayString);
        debugPrint("DashboardTab: Updated selection date to $todayString after selecting new items.");
      } else {
        debugPrint("DashboardTab: Selection failed (no content?), cleared date to allow retry.");
      }

    } else {
      // Find items based on saved IDs for today
      debugPrint("DashboardTab: Entering load from saved ID block for date $lastSelectionDate (Today: $todayString).");
      bool foundSavedCourse = false;
      bool foundSavedArticle = false;

      // Only try to load if the state doesn't already have it
      if (_dailyCourse == null && savedCourseId != null) {
          try {
             newDailyCourse = allCourses.firstWhere((c) => c.id == savedCourseId);
             dataChanged = true;
          } catch (e) {
             debugPrint("DashboardTab: Saved course ID $savedCourseId not found, clearing.");
             prefs.remove(_prefsKeyDailyCourseId); // Clear invalid ID
             prefs.remove(_prefsKeyLastSelectionDate); // Force re-selection next time
             newDailyCourse = null; // Ensure it's null if not found
          } finally {
             if (newDailyCourse != null) foundSavedCourse = true;
          }
      } else if (_dailyCourse != null) {
          foundSavedCourse = true; // Already have it in state
      }
 
      // Only try to load if the state doesn't already have it
      if (_dailyArticle == null && savedArticleId != null) {
          try {
             newDailyArticle = allArticles.firstWhere((a) => a.id == savedArticleId);
             dataChanged = true;
          } catch (e) {
             debugPrint("DashboardTab: Saved article ID $savedArticleId not found, clearing.");
             prefs.remove(_prefsKeyDailyArticleId); // Clear invalid ID
             prefs.remove(_prefsKeyLastSelectionDate); // Force re-selection next time
             newDailyArticle = null; // Ensure it's null if not found
          } finally {
             if (newDailyArticle != null) foundSavedArticle = true;
          }
      } else if (_dailyArticle != null) {
          foundSavedArticle = true; // Already have it in state
      }
 
      // Check if we successfully loaded items based on saved IDs *for today*
      if (isToday) {
          if (foundSavedCourse || foundSavedArticle) {
            debugPrint("DashboardTab: Loaded/validated items based on saved IDs for today. CourseFound: $foundSavedCourse, ArticleFound: $foundSavedArticle");
          } else if (savedCourseId != null || savedArticleId != null) {
            // We had saved IDs for today, but couldn't find the items
            debugPrint("DashboardTab: Had saved IDs for today, but failed to find items. Content available? C:${contentProvider.courses.isNotEmpty}, A:${contentProvider.articles.isNotEmpty}");
            // Force re-selection logic if content exists now and we didn't find saved items
            if (contentProvider.courses.isNotEmpty || contentProvider.articles.isNotEmpty) {
                debugPrint("DashboardTab: Content is now available, forcing re-selection attempt.");
                await prefs.remove(_prefsKeyLastSelectionDate); // Clear date to trigger selectNew path
                await _updateDailySelection(contentProvider); // Re-run selection
                return; // Exit this run
            } else {
               debugPrint("DashboardTab: No content available to re-select.");
            }
          }
      } else {
        // This path means selectNew was false, but the date didn't match today - indicates a logic issue or stale state.
        // Force a re-selection for today.
         debugPrint("DashboardTab: Date matched but failed to find saved items. Will attempt reselection if content is available.");
        await prefs.remove(_prefsKeyLastSelectionDate);
        await _updateDailySelection(contentProvider); // Re-run selection
        return; // Exit this run
      }
    }

    // Update state if mounted
    if (mounted && dataChanged) { // Only call setState if data actually changed
      setState(() {
        _dailyCourse = newDailyCourse;
        _dailyArticle = newDailyArticle;
      });
    }

    // Update completion flag separately, based on the *current* state and available content
    if (mounted) {
        // Determine if selection is complete for today based on available content
        bool courseRequirementMet = !contentProvider.courses.isNotEmpty || (contentProvider.courses.isNotEmpty && newDailyCourse != null);
        bool articleRequirementMet = !contentProvider.articles.isNotEmpty || (contentProvider.articles.isNotEmpty && newDailyArticle != null);

        // Check if the selection attempt actually ran for today's date or a new selection was made
        // (Using selectNew and isToday flags calculated at the start of the function)
        bool attemptedToday = (selectNew || isToday);

        // Calculate the final completion state based on whether requirements are met for an attempt made today
        bool finalCompletionState = attemptedToday && courseRequirementMet && articleRequirementMet;

        // Only update the flag via setState if its state needs to change
        if (finalCompletionState != _dailySelectionMadeForToday) {
           debugPrint("DashboardTab: Updating _dailySelectionMadeForToday = $finalCompletionState (Was: $_dailySelectionMadeForToday). Attempted: $attemptedToday, CourseMet: $courseRequirementMet, ArticleMet: $articleRequirementMet");
            setState(() {
              _dailySelectionMadeForToday = finalCompletionState;
            });
          } else {
              debugPrint("DashboardTab: Flag _dailySelectionMadeForToday ($finalCompletionState) already correct. No update needed.");
          }
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

    // Only trigger if loading is done and selection isn't complete
    if (!_isLoading && !_dailySelectionMadeForToday) {
      bool needsCourse = contentProvider.courses.isNotEmpty && _dailyCourse == null;
      bool needsArticle = contentProvider.articles.isNotEmpty && _dailyArticle == null;

      // Trigger update if the flag is false and we need either item
      if (needsCourse || needsArticle) {
        debugPrint("DashboardTab [Build Trigger 1]: Triggering update check. NeedsCourse: $needsCourse, NeedsArticle: $needsArticle, Flag: $_dailySelectionMadeForToday");
        // Use post-frame callback to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Re-check conditions inside callback for safety
          if (mounted && !_dailySelectionMadeForToday) {
            bool stillNeedsCourseCB = contentProvider.courses.isNotEmpty && _dailyCourse == null;
            bool stillNeedsArticleCB = contentProvider.articles.isNotEmpty && _dailyArticle == null;
            if (stillNeedsCourseCB || stillNeedsArticleCB) {
              debugPrint("DashboardTab [Callback 1]: Re-running selection logic. StillNeedsC: $stillNeedsCourseCB, StillNeedsA: $stillNeedsArticleCB");
              _updateDailySelection(contentProvider); 
            }
          }
        });
      }
    }

    // --- Add SECOND check specifically for articles loaded later ---
    if (!_isLoading && contentProvider.articles.isNotEmpty && _dailyArticle == null) {
      // This checks if articles are loaded but not yet in the state, 
      // potentially because the first selection attempt happened too early.
      debugPrint("DashboardTab [Build Trigger 2]: Articles available but not in state. Triggering potential update.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dailyArticle == null && contentProvider.articles.isNotEmpty) { // Re-check in callback
           debugPrint("DashboardTab [Callback 2]: Re-running selection logic specifically for missing article.");
           _updateDailySelection(contentProvider);
        }
      });
    }
    // --- End second check ---

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
              padding: const EdgeInsets.only(top: 64, bottom: 16), // Add padding for StatusBar and bottom
              children: [
                const SizedBox(height: 8),
                _buildTopSection(context, MediaQuery.of(context).size.width),
                _buildDayStreak(),
                _buildStartYourDay(context),
                if (_dailyCourse != null) _buildDailyCourse(context, _dailyCourse!),
                if (_dailyArticle != null) _buildDailyArticle(context, _dailyArticle!),
                const SizedBox(height: 24), // Keep some bottom padding
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

  Widget _buildTopSection(BuildContext context, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Dashboard",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Daily Streak Widget removed - it's already displayed in _buildDayStreak
      ],
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
    return DailyStreakWidget(showStreak: true);
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

  Widget _buildDailyCourse(BuildContext context, Course course) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text(
              "Course of the Day",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              margin: EdgeInsets.zero, // Use padding outside the card
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias, // Clip the image
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(courseId: course.id),
                    ),
                  );
                },
                child: Row(
                  children: [
                    // Image
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: ImageUtils.networkImageWithFallback(
                        imageUrl: course.thumbnailUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        backgroundColor: Colors.grey[300],
                        errorColor: Colors.grey[600],
                      ),
                    ),
                    // Text Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              course.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              course.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 16, color: accentColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${course.durationMinutes} min',
                                   style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accentColor, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                AppIcons.getFocusPointIcon(
                                  width: 16,
                                  height: 16,
                                  color: accentColor
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${course.xpReward} XP',
                                   style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accentColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
         ],
      ),
    );
  }

  Widget _buildDailyArticle(BuildContext context, Article article) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;

     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text(
              "Article of the Day",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  // Ensure article author details are potentially loaded before navigating
                   // (Article model has copyWithAuthorDetails, but fetching logic might be in ContentProvider or ArticleDetailScreen itself)
                   // For now, just navigate. ArticleDetailScreen should handle fetching author if needed.
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => ArticleDetailScreen(articleId: article.id),
                     ),
                   );
                },
                 child: Row(
                   children: [
                     // Image
                     SizedBox(
                       width: 100,
                       height: 100,
                       child: ImageUtils.networkImageWithFallback(
                         imageUrl: article.thumbnail,
                         width: 100,
                         height: 100,
                         fit: BoxFit.cover,
                         backgroundColor: Colors.grey[300],
                         errorColor: Colors.grey[600],
                       ),
                     ),
                     // Text Content
                     Expanded(
                       child: Padding(
                         padding: const EdgeInsets.all(12.0),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Text(
                               article.title,
                               style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                             ),
                             const SizedBox(height: 4),
                             // Consider showing author name if available and loaded
                             // Text(
                             //   article.authorName ?? 'Author loading...', // Placeholder if name isn't loaded yet
                             //   style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                             //   maxLines: 1,
                             //   overflow: TextOverflow.ellipsis,
                             // ),
                             // const SizedBox(height: 4),
                             Text(
                               // Displaying tags or focus areas might be better than content snippet here
                               article.tags.isNotEmpty ? article.tags.take(3).join(', ') : (article.focusAreas.isNotEmpty ? article.focusAreas.take(3).join(', ') : 'Insightful read'),
                               style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                             ),
                             const SizedBox(height: 8),
                             Row(
                               children: [
                                 Icon(Icons.timer_outlined, size: 16, color: accentColor),
                                 const SizedBox(width: 4),
                                 Text(
                                   '${article.readTimeMinutes} min read',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accentColor, fontWeight: FontWeight.w600),
                                 ),
                               ],
                             ),
                           ],
                         ),
                       ),
                     ),
                   ],
                 ),
              ),
            ),
         ],
      ),
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