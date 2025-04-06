import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
import 'all_coaches_screen.dart';
import 'all_courses_screen.dart';
import 'all_modules_screen.dart';
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
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _coaches = [];
  bool _loadingCoaches = true;
  
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
      
      _loadCoaches();
    });
  }
  
  Future<void> _loadCoaches() async {
    try {
      setState(() {
        _loadingCoaches = true;
      });
      
      final QuerySnapshot coachesSnapshot = await _firestore
          .collection('coaches')
          .where('isActive', isEqualTo: true)
          .limit(10)
          .get();
      
      if (coachesSnapshot.docs.isEmpty) {
        // If no coaches found in Firestore, use dummy data
        setState(() {
          _coaches = DummyData.dummyCoaches;
          _loadingCoaches = false;
        });
        return;
      }
      
      final List<Map<String, dynamic>> loadedCoaches = coachesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Coach',
          'title': data['title'] ?? 'Mental Performance Coach',
          'specialization': data['specialization'] ?? 'Performance',
          'description': data['description'] ?? 'No description available',
          'imageUrl': data['imageUrl'] ?? 'https://via.placeholder.com/300',
          'rating': data['rating'] ?? 4.8,
          'reviews': data['reviews'] ?? 24,
          'price': data['price'] ?? 99,
          'isActive': data['isActive'] ?? true,
        };
      }).toList();
      
      setState(() {
        _coaches = loadedCoaches;
        _loadingCoaches = false;
      });
    } catch (e) {
      debugPrint('Error loading coaches: $e');
      // Fallback to dummy data on error
      setState(() {
        _coaches = DummyData.dummyCoaches;
        _loadingCoaches = false;
      });
    }
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
          height: MediaQuery.of(context).size.height * 0.33, // 1/3 of screen height
          child: _loadingCoaches
              ? Center(child: CircularProgressIndicator())
              : _coaches.isEmpty
                  ? Center(
                      child: Text(
                        'No coaches available',
                        style: TextStyle(color: textColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _coaches.length,
                      itemBuilder: (context, index) {
                        final coach = _coaches[index];
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
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.person, size: 50),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      coach['specialization'] ?? 'Performance',
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
            
            const SizedBox(height: 10),
            
            // Coach name
            Text(
              coach['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Coach title
            Text(
              coach['title'],
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 6),
            
            // Rating
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${coach['rating']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${coach['reviews']})',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildArticlesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final contentProvider = Provider.of<ContentProvider>(context);
    final articles = contentProvider.articles;
    
    if (articles.isEmpty) {
      return const SizedBox.shrink(); // Hide if no articles
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
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16),
            scrollDirection: Axis.horizontal,
            itemCount: articles.length > 5 ? 5 : articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ArticleCard(
                  article: article,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllCoursesScreen(),
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
                        '${course.lessons.length} lessons',
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
    final modules = contentProvider.getModules();
    
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllModulesScreen(),
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
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length > 4 ? 4 : modules.length, // Show max 4 modules in grid
          itemBuilder: (context, index) {
            final module = modules[index];
            return _buildModuleCard(module);
          },
        ),
      ],
    );
  }
  
  Widget _buildModuleCard(Module module) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return GestureDetector(
      onTap: () {
        // Navigate to module content
      },
      child: Container(
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
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: module.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    module.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${module.audioCount} audio tracks',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
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
    final isDark = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Popular Topics',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final bool isSelected = index == _selectedTabIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? themeProvider.accentColor 
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSelected 
                            ? (isDark ? Colors.black : Colors.white) 
                            : textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
} 