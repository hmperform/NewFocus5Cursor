import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/content_models.dart';
// import 'video_player_screen.dart'; // Target of URI doesn't exist
// import 'audio_player_screen.dart'; // Target of URI doesn't exist
import '../../constants/theme.dart';
import '../../providers/audio_provider.dart'; // <<< Import AudioProvider
// import '../courses/course_details_screen.dart'; // TODO: Uncomment and adjust path if needed
// import '../articles/article_reader_screen.dart'; // TODO: Uncomment and adjust path if needed
import '../home/course_detail_screen.dart'; // <<< ADD Import for CourseDetailScreen
import '../article/article_detail_screen.dart'; // <<< ADD Import for ArticleDetailScreen (assumed)
import '../../utils/image_utils.dart';

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({Key? key}) : super(key: key);

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String _searchQuery = '';
  
  // Add state variables for filtered lists
  List<DailyAudio> _filteredAudios = [];
  List<Course> _filteredCourses = [];
  List<Article> _filteredArticles = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedia().then((_) => _runFilter()); // Run filter initially after load
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      // Call individual loading methods
      await contentProvider.loadCourses(); 
      await contentProvider.loadAudioModules();
      await contentProvider.loadArticles();
      // TODO: Ensure coaches are loaded if needed for lookup (e.g., add contentProvider.loadCoaches() if it exists)

      // Assign initial full lists from provider's getters
      _filteredAudios = contentProvider.audioModules; // Use getter
      _filteredCourses = contentProvider.courses;    // Use getter
      _filteredArticles = contentProvider.articles;   // Use getter
    } catch (e) {
      print('Error loading media content: $e');
      // Handle error appropriately
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // New function to handle filtering based on search and category
  void _runFilter() {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    List<DailyAudio> audios = contentProvider.audios;
    List<Course> courses = contentProvider.courses;
    List<Article> articles = contentProvider.articles;

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      String query = _searchQuery.toLowerCase();
      audios = audios.where((a) => a.title.toLowerCase().contains(query) || a.description.toLowerCase().contains(query)).toList();
      courses = courses.where((c) => c.title.toLowerCase().contains(query) || c.description.toLowerCase().contains(query)).toList();
      articles = articles.where((a) => a.title.toLowerCase().contains(query) || a.content.toLowerCase().contains(query)).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      audios = audios.where((a) => a.focusAreas.contains(_selectedCategory)).toList();
      courses = courses.where((c) => c.focusAreas.contains(_selectedCategory)).toList();
      articles = articles.where((a) => a.focusAreas.contains(_selectedCategory)).toList();
    }

    setState(() {
      _filteredAudios = audios;
      _filteredCourses = courses;
      _filteredArticles = articles;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final secondaryTextColor = themeProvider.isDarkMode ? Colors.grey : Colors.grey.shade700;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        title: Text(
          'Media Library',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Explore audio and video content to enhance your mental training',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for content...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                _runFilter(); // Run filter on change
              },
            ),
          ),
          
          // Tab bar for Modules, Courses, Articles
          Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.primary,
              ),
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: secondaryTextColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Modules'),
                Tab(text: 'Courses'),
                Tab(text: 'Articles'),
              ],
              onTap: (index) {
                setState(() {
                  _selectedCategory = 'All'; // Reset selected category
                });
                _runFilter(); // Re-run filter when tab changes (to reset category filter)
              },
            ),
          ),
          
          // Category filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Row(
              children: [
                _buildCategoryChip('All'),
                _buildCategoryChip('Focus'),
                _buildCategoryChip('Resilience'),
                _buildCategoryChip('Visualization'),
                _buildCategoryChip('Mental Toughness'),
                _buildCategoryChip('Confidence'),
              ],
            ),
          ),
          
          // Content display
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildModulesList(),
                      _buildCoursesList(),
                      _buildArticlesList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        // Improved Styling:
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        selectedColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold, // Always bold
          color: isSelected 
                 ? (Theme.of(context).colorScheme.onPrimary) // High contrast on primary
                 : (isDarkMode ? Colors.white70 : Colors.black87), // Good contrast for unselected
        ),
        checkmarkColor: Theme.of(context).colorScheme.onPrimary, // Ensure checkmark is visible
        side: isSelected 
              ? BorderSide.none // No border when selected
              : BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!), // Subtle border when not selected
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
          _runFilter(); // Run filter when category changes
        },
      ),
    );
  }
  
  Widget _buildModulesList() {
    if (_filteredAudios.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? 'No modules matching "$_searchQuery" in this category'
              : 'No modules available in this category',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDarkMode 
                ? Colors.white70 
                : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredAudios.length,
      itemBuilder: (context, index) {
        final audio = _filteredAudios[index];
        String coachName = 'Unknown Coach';
        try {
            final coachData = contentProvider.coaches.firstWhere(
              (c) => c['id'] == audio.creatorName.id, 
              orElse: () => {},
            );
            if (coachData.isNotEmpty) {
              coachName = coachData['name'] as String? ?? 'Unknown Coach';
            }
          } catch (e) {
            print('Error looking up coach for audio ${audio.id}: $e');
          }
        
        return _buildMediaCard(
          title: audio.title,
          description: audio.description,
          duration: audio.durationMinutes,
          xpReward: audio.xpReward,
          instructor: coachName,
          categories: audio.focusAreas,
          imageUrl: audio.thumbnail,
          item: audio,
          onTap: () {
             print('Tapped Audio Module: ${audio.title}');
             // Use AudioProvider to play
             Provider.of<AudioProvider>(context, listen: false).startAudioPlayback(audio);
             // Optional: Navigate to a dedicated full player screen
             // Navigator.push(context, MaterialPageRoute(builder: (context) => FullAudioPlayerScreen()));
          },
        );
      },
    );
  }
  
  Widget _buildCoursesList() {
    if (_filteredCourses.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? 'No courses matching "$_searchQuery" in this category'
              : 'No courses available in this category',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDarkMode 
                ? Colors.white70 
                : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return _buildMediaCard(
          title: course.title,
          description: course.description,
          duration: course.durationMinutes,
          xpReward: course.xpReward,
          instructor: course.creatorName,
          categories: course.focusAreas,
          imageUrl: course.thumbnailUrl,
          item: course,
           onTap: () {
             print('Tapped Course: ${course.title}');
             // Navigate to Course Details Screen
             Navigator.push(
               context,
               MaterialPageRoute(
                 // Pass courseId, can also pass the full course object if preferred by the screen
                 builder: (context) => CourseDetailScreen(courseId: course.id, course: course),
               ),
             );
             // ScaffoldMessenger.of(context).showSnackBar(
             //     SnackBar(content: Text('Navigate to Course: ${course.title} (Not Implemented)'))
             // ); 
          },
        );
      },
    );
  }
  
  Widget _buildArticlesList() {
    if (_filteredArticles.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? 'No articles matching "$_searchQuery" in this category'
              : 'No articles available in this category',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDarkMode 
                ? Colors.white70 
                : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredArticles.length,
      itemBuilder: (context, index) {
        final article = _filteredArticles[index];
        return _buildMediaCard(
          title: article.title,
          description: article.content,
          duration: article.readTimeMinutes,
          xpReward: 0,
          instructor: article.authorName ?? 'Unknown Author',
          categories: article.focusAreas,
          imageUrl: article.thumbnail,
          item: article,
          onTap: () {
            debugPrint('Tapped Article: ${article.title}');
            Navigator.push(
              context,
              MaterialPageRoute(
                // Pass parameters required by article/article_detail_screen.dart
                builder: (context) => ArticleDetailScreen(
                  title: article.title,
                  imageUrl: article.thumbnail, // Use thumbnail
                  content: article.content, // Pass content
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildMediaCard({
    required String title,
    required String description,
    required int duration,
    required int xpReward,
    required String instructor,
    required List<String> categories,
    required VoidCallback onTap,
    String? imageUrl,
    required dynamic item,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final bool isAudio = item is DailyAudio;
    final bool isCourse = item is Course;
    final bool isArticle = item is Article;

    String durationLabel = '';
    if (isArticle) {
      durationLabel = '$duration min read';
    } else if (duration > 0) {
      durationLabel = '${duration} min'; // Assuming durationMinutes for others
    }

    IconData playIcon = Icons.play_arrow; // Default
    if (isAudio) playIcon = Icons.play_circle_filled;
    if (isArticle) playIcon = Icons.article_outlined;
    if (isCourse) playIcon = Icons.school_outlined;

    print("Building card for: $title, Type: ${item.runtimeType}");

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with play button
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: imageUrl != null && imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                          // Optional: Add error builder for NetworkImage
                        )
                      : null,
                ),
                 // Display icon only if no image or image fails (optional)
                 child: imageUrl == null || imageUrl.isEmpty
                 ? Icon(playIcon, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.7))
                 : null,
              ),
               // Play/Open Button overlay
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    onTap: onTap,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          playIcon,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Content details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 3, // Limit description lines
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Metadata row
                Row(
                  children: [
                    Icon(
                      // Choose icon based on type
                      isArticle ? Icons.person_outline : Icons.mic_none_outlined,
                      size: 16,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                    const SizedBox(width: 4),
                    Expanded( // Allow instructor name to wrap if long
                      child: Text(
                        instructor,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8), // Spacer
                    if (durationLabel.isNotEmpty) ...[
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        durationLabel,
                         style: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                    if (xpReward > 0) ...[
                      const Spacer(), // Push XP to the right if duration is shown
                      Icon(
                        Icons.star_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$xpReward XP',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Category chips
                if (categories.isNotEmpty)
                 Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(30),
                          border: category == _selectedCategory
                              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1)
                              : null,
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            color: category == _selectedCategory
                                ? Theme.of(context).colorScheme.primary
                                : (isDarkMode ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  const SizedBox.shrink(), // Hide Wrap if no categories
              ],
            ),
          ),
        ],
      ),
    );
  }
} 