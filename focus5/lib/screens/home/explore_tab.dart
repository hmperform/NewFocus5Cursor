import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:focus5/models/article_model.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/providers/coach_provider.dart';
import 'package:focus5/providers/content_provider.dart';
import 'package:focus5/providers/theme_provider.dart';
import '../../screens/home/article_detail_screen.dart';
import '../../screens/coach/coach_profile_screen.dart';
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
    
    return Scaffold(
      body: Stack(
        children: [
          _isLoading 
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeProvider.accentColor,
                  ),
                ),
              )
            : ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 64), // Add padding for StatusBar
                children: [
                  // Coaches section (moved to top)
                  _buildCoachesSection(),
                  
                  // Featured section
                  _buildFeaturedSection(),
                  
                  // Courses grid
                  _buildCoursesGrid(),
                  
                  // Focus areas
                  _buildModulesSection(),
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
  
  List<Widget> _buildOrderedSections() {
    if (_loadingConfig) {
      return [
        const SizedBox(height: 40),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 80),
      ];
    }
    
    // Always show coaches first, regardless of config
    final List<Widget> orderedSections = [
      _buildCoachesSection(),
      const SizedBox(height: 24), // Add spacing after coaches
    ];
    
    // Get section order from app config for other sections
    final List<dynamic> sectionOrder = 
        _appConfig['section_order'] as List<dynamic>? ?? 
        ['focus_areas', 'featured_courses', 'articles', 'trending_courses'];
    
    // Map section IDs to their builder methods (excluding coaches since it's already added)
    final Map<String, Widget> sectionWidgets = {
      'focus_areas': _buildModulesSection(),
      'featured_courses': _buildFeaturedCoursesSection(),
      'articles': _buildArticlesSection(),
      'trending_courses': _buildTrendingCoursesSection(),
    };
    
    // Add remaining sections in configured order
    for (final sectionId in sectionOrder) {
      if (sectionId != 'coaches' && sectionWidgets.containsKey(sectionId)) {
        orderedSections.add(sectionWidgets[sectionId]!);
      }
    }
    
    // Add bottom padding
    orderedSections.add(const SizedBox(height: 80));
    
    return orderedSections;
  }
  
  Widget _buildCoachesSection() {
    final coachProvider = Provider.of<CoachProvider>(context);
    final coaches = coachProvider.coaches;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (coaches.isEmpty) {
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
                  fontSize: 24, // Larger font size
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
          height: 280, // Increased height for larger coach cards
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: coaches.length,
            itemBuilder: (context, index) {
              final coach = coaches[index];
              return Container(
                width: MediaQuery.of(context).size.width * 0.5,
                margin: const EdgeInsets.only(right: 16),
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
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coach image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            coach.profileImageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 50),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coach.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                coach.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ),
        ),
      ],
    );
  }
  
  Widget _buildTrendingCoursesSection() {
    final contentProvider = Provider.of<ContentProvider>(context);
    final courses = contentProvider.courses; // Get all courses
    final isLoading = contentProvider.isLoading;
    final error = contentProvider.errorMessage;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Handle loading and error states specifically for courses
    if (isLoading && courses.isEmpty) {
      return Container(
        height: 260, // Approx height for course cards
        child: Center(child: CircularProgressIndicator(color: themeProvider.accentColor)),
      );
    } 

    if (error != null && courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading courses: $error', style: TextStyle(color: Colors.red)),
      );
    }

    if (courses.isEmpty) {
      return const SizedBox.shrink(); // No courses to show
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16), // Match padding of other sections
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending Courses', // UPDATED TITLE
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              // Optional: Add a "View All" button if needed
              // TextButton(...)
            ],
          ),
        ),
        // Use horizontal ListView similar to Featured Courses
        SizedBox(
          height: 260, // Match height of _buildFeaturedCoursesSection
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16),
            scrollDirection: Axis.horizontal,
            itemCount: courses.length, // Show all courses
            itemBuilder: (context, index) {
              final course = courses[index];
              // Reuse the existing course card builder from Featured Courses
              return _buildCourseCard(course); 
            },
          ),
        ),
         const SizedBox(height: 24), // Add spacing after the section
      ],
    );
  }
  
  Widget _buildArticlesSection() {
    final contentProvider = Provider.of<ContentProvider>(context);
    final articles = contentProvider.articles;
    final isLoading = contentProvider.isLoading;
    final error = contentProvider.errorMessage;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (isLoading && articles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } 

    if (error != null && articles.isEmpty) {
      return Center(child: Text('Error loading articles: $error', style: TextStyle(color: Colors.red)));
    }

    if (articles.isEmpty) {
      return const SizedBox.shrink(); // No articles to show
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add top spacing to separate from previous section
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Articles',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/articles-list');
                },
                child: Text('See All', style: TextStyle(color: themeProvider.accentColor)),
              ),
            ],
          ),
        ),
        // Replace vertical ListView with horizontal SizedBox and ListView
        SizedBox(
          height: 300, // Adjusted height for the article cards
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              
              // Create a card with proper sizing for horizontal scrolling
              final formattedDate = DateFormat('MMM d, yyyy').format(article.publishedDate);
              final userProvider = Provider.of<UserProvider>(context);
              final isCompleted = userProvider.completedArticleIds.contains(article.id);
              
              return GestureDetector(
                onTap: () async {
                  // Check if user has access or show paywall
                  final paywallService = PaywallService();
                  final hasAccess = await paywallService.showPaywallIfNeeded(
                    context,
                    source: 'article',
                  );
                  
                  // If user has access, navigate to article
                  if (hasAccess && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(articleId: article.id),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: isCompleted 
                        ? Border.all(color: Colors.green, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Article image
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: ImageUtils.networkImageWithFallback(
                              imageUrl: article.thumbnailUrl,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              backgroundColor: const Color(0xFF2A2A2A),
                              errorColor: Colors.white54,
                            ),
                          ),
                          if (isCompleted)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      // Article info
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Author info
                            Row(
                              children: [
                                ImageUtils.avatarWithFallback(
                                  imageUrl: article.authorImageUrl,
                                  radius: 12,
                                  name: article.authorName,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    article.authorName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Date and read time
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${article.readTimeMinutes} min read',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
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
            },
          ),
        ),
        // Add more bottom spacing
        const SizedBox(height: 40),
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Courses',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement navigation to All Courses Screen
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const AllCoursesScreen(),
                  //   ),
                  // );
                  log('Navigate to All Courses');
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
          height: 260,
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
        width: 280,
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
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
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
  
  Widget _buildModulesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final contentProvider = Provider.of<ContentProvider>(context);
    final modules = contentProvider.courses.expand((course) => course.modules).toList();
    
    if (modules.isEmpty) {
      return const SizedBox.shrink(); // Hide if no modules
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
                'Focus Areas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement navigation to All Modules Screen
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => const AllModulesScreen()),
                  // );
                  log('Navigate to All Modules');
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
          height: 160,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16),
            scrollDirection: Axis.horizontal,
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              
              return GestureDetector(
                onTap: () {
                  // Navigate to the focus area courses screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FocusAreaCoursesScreen(
                        focusArea: module.categories.isNotEmpty ? module.categories.first : module.title,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16, bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: module.imageUrl ?? 'https://via.placeholder.com/300',
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      
                      // Gradient overlay
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Module title
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                module.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    
    // Skip rendering this section if there are no featured courses and it's still loading
    if (contentProvider.isLoading && contentProvider.featuredCourses.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Skip rendering if there are no featured courses even after loading
    if (!contentProvider.isLoading && contentProvider.featuredCourses.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Featured',
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: contentProvider.featuredCourses.length,
            itemBuilder: (context, index) {
              final course = contentProvider.featuredCourses[index];
              return FeaturedCourseCard(
                course: course,
                isPurchased: userProvider.hasPurchasedCourse(course.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesGrid() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Explore Courses',
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        contentProvider.allCourses.isEmpty
            ? Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: contentProvider.allCourses.length,
                itemBuilder: (context, index) {
                  final course = contentProvider.allCourses[index];
                  return CourseCard(
                    course: course,
                    isPurchased: userProvider.hasPurchasedCourse(course.id),
                  );
                },
              ),
      ],
    );
  }
} 