import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../providers/user_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';
import '../../models/content_models.dart';
import '../../constants/dummy_data.dart';
import '../../widgets/article/article_card.dart';
import 'course_detail_screen.dart';
import 'coach_profile_screen.dart';
import 'articles_list_screen.dart';
import '../../services/paywall_service.dart';
import 'article_detail_screen.dart';

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
    
    // Initialize content with dummy data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      if (contentProvider.courses.isEmpty) {
        contentProvider.initContent(null);
      }
      if (contentProvider.articles.isEmpty) {
        contentProvider.loadArticles();
      }
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: _handleSearch,
                  ),
                ),
              ),
            ),
          ),
          
          // Coaches section
          SliverToBoxAdapter(
            child: _buildCoachesSection(),
          ),
          
          // Featured articles section
          SliverToBoxAdapter(
            child: _buildArticlesSection(),
          ),
          
          // Featured courses section
          SliverToBoxAdapter(
            child: _buildFeaturedCoursesSection(),
          ),
          
          // Focus areas / modules section
          SliverToBoxAdapter(
            child: _buildModulesSection(),
          ),
          
          // Course Topics Section
          SliverToBoxAdapter(
            child: _buildCourseTopicsSection(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCoachesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coaches',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all coaches
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.33, // 1/3 of screen height
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            scrollDirection: Axis.horizontal,
            itemCount: DummyData.dummyCoaches.length,
            itemBuilder: (context, index) {
              final coach = DummyData.dummyCoaches[index];
              return _buildCoachCard(coach);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildCoachCard(Map<String, dynamic> coach) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoachProfileScreen(coach: coach),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach image with specialization tag
            Stack(
              children: [
                // Coach photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: coach['imageUrl'],
                    width: 170,
                    height: 210,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 170,
                        height: 210,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          color: Colors.white54,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
                
                // Specialization tag
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      coach['specialization'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Coach name
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 4),
              child: Text(
                coach['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modules',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all modules
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _buildModuleCard('Mental Toughness', Colors.blue.shade700),
              _buildModuleCard('Motivation Mastery', Colors.green.shade700),
              _buildModuleCard('Focus Training', Colors.purple.shade700),
              _buildModuleCard('Team Leadership', Colors.orange.shade700),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildModuleCard(String title, Color color) {
    return GestureDetector(
      onTap: () {
        // Find a course related to this module
        final contentProvider = Provider.of<ContentProvider>(context, listen: false);
        
        // Make sure courses are loaded
        if (contentProvider.courses.isEmpty) {
          contentProvider.initContent(null);
        }
        
        // Find a course that matches this module's topic
        final relatedCourses = contentProvider.courses.where((course) {
          return course.title.contains(title) || 
                 course.focusAreas.any((area) => area.contains(title)) ||
                 title.contains(course.title);
        }).toList();
        
        if (relatedCourses.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(
                courseId: relatedCourses.first.id,
              ),
            ),
          );
        } else {
          // Fallback to showing a message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No modules available for $title yet. Check back soon!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCourseTopicsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Course Topics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all course topics
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _buildTopicCard('Mental Toughness', Colors.teal.shade600),
              _buildTopicCard('Power Mindset', Colors.green.shade600),
              _buildTopicCard('Focus Training', Colors.blue.shade600),
              _buildTopicCard('Team Dynamics', Colors.orange.shade600),
              _buildTopicCard('Motivation', Colors.purple.shade600),
            ],
          ),
        ),
        const SizedBox(height: 32), // Bottom padding
      ],
    );
  }
  
  Widget _buildTopicCard(String topic, Color color) {
    return GestureDetector(
      onTap: () {
        // Navigate to filtered courses
        final contentProvider = Provider.of<ContentProvider>(context, listen: false);
        
        // Make sure we have content initialized
        if (contentProvider.courses.isEmpty) {
          contentProvider.initContent(null);
        }
        
        final courses = contentProvider.getCoursesForFocusArea(topic);
        
        // Check if we found courses for this topic
        if (courses.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(
                courseId: courses.first.id,
              ),
            ),
          );
        } else {
          // Show a message if no courses found for this topic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No courses found for $topic yet. Check back soon!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            topic,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeaturedCoursesSection() {
    final contentProvider = Provider.of<ContentProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final courses = contentProvider.courses;
    
    if (courses.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
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
                  // Navigate to courses tab
                  DefaultTabController.of(context)?.animateTo(2);
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: courses.length > 5 ? 5 : courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return GestureDetector(
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
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: surfaceColor,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course image
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: course.thumbnailUrl,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.image_not_supported,
                                color: secondaryTextColor,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                      // Course info
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              course.creatorName,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 12,
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
  
  Widget _buildArticlesSection() {
    final contentProvider = Provider.of<ContentProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final featuredArticles = contentProvider.getFeaturedArticles();
    
    if (featuredArticles.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Articles',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArticlesListScreen(),
                    ),
                  );
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: featuredArticles.length,
            itemBuilder: (context, index) {
              final article = featuredArticles[index];
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
                        builder: (context) => ArticleDetailScreen(
                          articleId: article.id,
                        ),
                      ),
                    );
                  }
                },
                child: ArticleCard(article: article),
              );
            },
          ),
        ),
      ],
    );
  }
} 