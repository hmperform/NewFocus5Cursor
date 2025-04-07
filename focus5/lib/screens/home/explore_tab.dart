import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

import '../../providers/user_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/coach_provider.dart';
import '../../constants/theme.dart';
import '../../models/content_models.dart';
import 'course_detail_screen.dart';
import 'coach_profile_screen.dart';
import 'articles_list_screen.dart';
import '../../services/paywall_service.dart';
import 'article_detail_screen.dart';
import '../explore/focus_area_courses_screen.dart';
import '../../widgets/article/article_card.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({Key? key}) : super(key: key);

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isLoading = false;
  int _selectedTabIndex = 0;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _coaches = [];
  bool _loadingCoaches = true;
  String? _coachesError;
  
  late TabController _tabController;
  
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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    // Initialize content data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      // *** Always call initContent to handle loading of all content types ***
      contentProvider.initContent(null); 

      // *** REMOVED redundant checks and calls ***
      // if (contentProvider.courses.isEmpty) {
      //   contentProvider.initContent(null);
      // }
      // if (contentProvider.articles.isEmpty) {
      //  contentProvider.loadArticles(); // REMOVED
      // }

      // Load coaches separately as before
      final coachProvider = Provider.of<CoachProvider>(context, listen: false);
      coachProvider.loadCoaches();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
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
    final accentColor = themeProvider.accentColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final secondaryTextColor = themeProvider.isDarkMode 
        ? Colors.grey 
        : Colors.grey.shade700;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with search
          SliverAppBar(
            backgroundColor: backgroundColor,
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                child: Text(
                  'Explore',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search topics, coaches, modules...',
                      hintStyle: TextStyle(color: secondaryTextColor),
                      prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: Icon(Icons.close, color: secondaryTextColor),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _isSearching = false;
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isSearching = value.isNotEmpty;
                        _handleSearch(value);
                      });
                    },
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SliverList(
            delegate: SliverChildListDelegate([
              // Coaches Section - Now first
              _buildCoachesSection(),
              
              // Featured Courses Section - Now second
              _buildFeaturedCoursesSection(),
              
              // Focus Areas (Modules) Section - Now third
              _buildModulesSection(),
              
              // Renamed Articles Section to Trending Courses - Now last
              _buildTrendingCoursesSection(),
              
              const SizedBox(height: 80), // Bottom padding
            ]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCoachesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    
    // Use CoachProvider instead of directly querying Firestore
    final coachProvider = Provider.of<CoachProvider>(context);
    final coaches = coachProvider.coaches;
    final isLoading = coachProvider.isLoading;
    final error = coachProvider.error;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Coaches',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement navigation to All Coaches Screen
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => const AllCoachesScreen()),
                  // );
                  log('Navigate to All Coaches');
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
        
        if (isLoading)
          SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                color: themeProvider.accentColor,
              ),
            ),
          )
        else if (error != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading coaches: $error',
              style: TextStyle(color: Colors.red.shade300),
            ),
          )
        else if (coaches.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No coaches available at this time',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16),
              scrollDirection: Axis.horizontal,
              itemCount: coaches.length,
              itemBuilder: (context, index) {
                final coach = coaches[index];
                
                return GestureDetector(
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
                  child: Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        // Coach image
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: NetworkImage(
                            coach.profileImageUrl.isNotEmpty
                              ? coach.profileImageUrl
                              : 'https://via.placeholder.com/70',
                          ),
                          onBackgroundImageError: (exception, stackTrace) {
                            // Log the error if the image fails to load
                            print('Error loading coach image for ${coach.name}: $exception');
                          },
                          backgroundColor: Colors.grey.shade200,
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Coach info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                coach.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                coach.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
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
                child: Text('See All', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ),
            ],
          ),
        ),
        // Use ListView.builder for potentially many articles
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling within the parent scroll view
          itemCount: articles.length > 3 ? 3 : articles.length, // Show max 3 articles here
          itemBuilder: (context, index) {
            final article = articles[index];
            return ArticleCard(article: article); // Correctly using the imported ArticleCard widget
          },
        ),
        const SizedBox(height: 24),
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
} 