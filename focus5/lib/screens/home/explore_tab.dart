import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:focus5/models/article_model.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/providers/coach_provider.dart';
import 'package:focus5/providers/content_provider.dart';
import 'package:focus5/providers/theme_provider.dart';
import '../../screens/home/article_detail_screen.dart';
import 'coach_profile_screen.dart';
import 'package:focus5/screens/explore/focus_area_courses_screen.dart';
import 'package:focus5/screens/home/course_detail_screen.dart';
import 'package:focus5/services/firebase_config_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../providers/user_provider.dart';
import '../../constants/theme.dart';
import 'articles_list_screen.dart';
import '../../services/paywall_service.dart';
import '../explore/focus_area_courses_screen.dart';
import '../../widgets/article/article_card.dart';
import '../../widgets/course/course_card.dart';
import '../../widgets/course/featured_course_card.dart';
import 'all_coaches_screen.dart';
import '../../utils/image_utils.dart';
import '../../utils/app_icons.dart'; // Import the app icons utility
import '../../widgets/status_bar.dart'; // Import the StatusBar
import 'package:focus5/screens/home/all_courses_screen.dart'; // Add import for the new screen

class ExploreTab extends StatefulWidget {
  const ExploreTab({Key? key}) : super(key: key);

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isLoading = false;
  int _selectedTabIndex = 0;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _coaches = [];
  bool _loadingCoaches = true;
  String? _coachesError;
  
  late TabController _tabController;
  final FirebaseConfigService _configService = FirebaseConfigService();
  Map<String, dynamic> _appConfig = {};
  bool _loadingConfig = true;
  
  final List<String> _categories = [
    'All',
    'Focus',
    'Visualization',
    'Relaxation',
    'Mindfulness',
    'Recovery'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    // Initialize content data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      // *** Always call initContent to handle loading of all content types ***
      contentProvider.initContent(null); 

      // Load coaches separately as before
      final coachProvider = Provider.of<CoachProvider>(context, listen: false);
      coachProvider.loadCoaches();
      
      // Load app configuration for section ordering
      _loadAppConfig();
    });
  }
  
  Future<void> _loadAppConfig() async {
    try {
      final config = await _configService.getAppConfig();
      setState(() {
        _appConfig = config;
        _loadingConfig = false;
      });
      debugPrint('Loaded app config: $config');
    } catch (e) {
      debugPrint('Error loading app config: $e');
      setState(() {
        _appConfig = {
          'section_order': [
            'focus_areas',
            'featured_courses',
            'articles',
            'trending_courses',
            'coaches'
          ]
        };
        _loadingConfig = false;
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final contentProvider = Provider.of<ContentProvider>(context); // Get content provider

    // Check loading state for content
    if (contentProvider.isLoading) {
       return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          ListView( // Removed the _isLoading ternary, handle loading above
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 64, bottom: 80), // Add padding for StatusBar and bottom
                children: [
                  // Coaches section (increased height)
                  _buildCoachesSection(),
                  const SizedBox(height: 20), // <<< Reduced spacing (was 32)

                  // Featured section (assuming this is featured courses)
                  _buildFeaturedCoursesSection(), // Renamed from _buildFeaturedSection
                  const SizedBox(height: 32), // Add spacing

                  // Trending Courses Section (Used Courses Grid before)
                  _buildTrendingCoursesSection(), // Renamed from _buildCoursesGrid
                  const SizedBox(height: 32), // Add spacing

                  // Articles section (Replaced Modules/Focus Areas)
                  _buildArticlesSection(),
                ],
              ),

          // Status Bar
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: StatusBar(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCoachesSection() {
    final coachProvider = Provider.of<CoachProvider>(context);
    final coaches = coachProvider.coaches;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Limit to 5 coaches for the horizontal list
    final displayedCoaches = coaches.take(5).toList();

    if (coachProvider.isLoading && displayedCoaches.isEmpty) {
      return Container(
        height: 180, // Adjusted height for loading state
        child: Center(child: CircularProgressIndicator(color: themeProvider.accentColor)),
      );
    }

    if (coachProvider.error != null && displayedCoaches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading coaches: ${coachProvider.error}', style: TextStyle(color: Colors.red)),
      );
    }

    if (displayedCoaches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Coaches',
                style: TextStyle(
                  fontSize: 20, // Slightly smaller title
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllCoachesScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: themeProvider.accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 264, // *** Increased height for coach cards (220 * 1.2) ***
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: displayedCoaches.length, // Use limited list
            itemBuilder: (context, index) {
              final coach = displayedCoaches[index];
              return Container(
                width: 192, // *** Increased width for coach cards (160 * 1.2) ***
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CoachProfileScreen(
                          coachId: coach.id,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias, // Ensures content respects rounded corners
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack( // Use Stack for image background and text overlay
                      fit: StackFit.expand,
                      children: [
                        // Coach image as background
                        ImageUtils.networkImageWithFallback(
                          imageUrl: coach.profileImageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover, // Cover the card area
                          errorColor: Colors.grey.shade300,
                          backgroundColor: Colors.grey.shade100,
                        ),
                        // Gradient overlay for text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                            ),
                          ),
                        ),
                        // Coach name at the bottom
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Text(
                            coach.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
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
  
  Widget _buildTrendingCoursesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final contentProvider = Provider.of<ContentProvider>(context);
    final courses = contentProvider.courses; // Assuming this gets all/trending courses
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (courses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limit to 6 courses for the grid
    final displayedCourses = courses.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Adjusted top padding
          child: Row( // Wrap title in a Row
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align title and button
            children: [
              Text(
                'Trending Courses', // Updated title
                style: TextStyle(
                  fontSize: 20, // Consistent title size
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton( // Add the View All button
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllCoursesScreen(), // Navigate to the new screen
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: themeProvider.accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260, // <<< Increased height for the horizontal list (was 220)
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: displayedCourses.length,
            itemBuilder: (context, index) {
              final course = displayedCourses[index];
              // Use CourseCard, assuming it's adapted for horizontal display below
              // Pass a specific width to the card
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CourseCard(
                  course: course,
                  isPurchased: userProvider.hasPurchasedCourse(course.id),
                  cardWidth: MediaQuery.of(context).size.width * 0.65, // Example width 
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildArticlesSection() {
    final contentProvider = Provider.of<ContentProvider>(context);
    final articles = contentProvider.articles; // Assumes articles are loaded by initContent
    final textColor = Theme.of(context).colorScheme.onBackground;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Sort articles by published date (newest first) and take top 5
    articles.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
    final displayedArticles = articles.take(5).toList();

    if (contentProvider.isLoading && displayedArticles.isEmpty) {
      return Container(
        height: 250, // Placeholder height during load
        child: Center(child: CircularProgressIndicator(color: themeProvider.accentColor)),
      );
    }

    if (contentProvider.errorMessage != null && displayedArticles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading articles: ${contentProvider.errorMessage}', style: TextStyle(color: Colors.red)),
      );
    }

    if (displayedArticles.isEmpty) {
      return const SizedBox.shrink(); // Hide section if no articles
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Adjusted top padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Articles',
                style: TextStyle(
                  fontSize: 20, // Consistent title size
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArticlesListScreen(), // Navigate to all articles
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: themeProvider.accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280, // *** Keep article section height moderate ***
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: displayedArticles.length,
            itemBuilder: (context, index) {
              final article = displayedArticles[index];
              // Use ArticleCard - ensure it's designed for horizontal lists or adjust width here
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75, // *** Adjusted width to be relative and slightly smaller to prevent overflow ***
                  child: ArticleCard(article: article),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeaturedCoursesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final contentProvider = Provider.of<ContentProvider>(context);
    final courses = contentProvider.getFeaturedCourses();
    
    if (courses.isEmpty) {
      return const SizedBox.shrink(); // Hide if no courses
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Adjusted top padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Courses',
                style: TextStyle(
                  fontSize: 20, // Consistent title size
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to a 'View All Courses' screen if it exists
                },
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: themeProvider.accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320, // *** Increased height for featured courses list ***
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16),
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseCard(course);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildCourseCard(Course course) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final isDarkMode = themeProvider.isDarkMode;
    
    // *** Increased width for featured course card ***
    final cardWidth = MediaQuery.of(context).size.width * 0.85; // Made slightly wider

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
        width: cardWidth, // *** Use calculated width ***
        margin: const EdgeInsets.only(right: 20, bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
                    image: course.imageUrl,
                    height: 180, // *** Increased image height ***
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180, // *** Increased image height ***
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
                if (course.premium)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            size: 14,
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
                
                // Focus Points Badge
                if (course.focusPointsCost > 0 && !course.premium)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeProvider.accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcons.getFocusPointIcon(
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.focusPointsCost}',
                            style: const TextStyle(
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course title
                  Text(
                    course.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Course meta info (lessons, duration)
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${course.modules.length} lessons',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${course.duration} mins',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress indicator
                  LinearProgressIndicator(
                    value: 0.0, // No progress initially
                    backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(themeProvider.accentColor),
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