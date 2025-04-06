import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../providers/content_provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';

import '../../models/content_models.dart';
import '../../models/coach_model.dart';
import '../../models/user_model.dart';

import '../../constants/theme.dart';
import '../../services/coach_booking_service.dart';
import '../../utils/image_utils.dart';

import '../../widgets/article/article_card.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/focus_area_chip.dart';

import 'articles_list_screen.dart';
import 'coach_detail_screen.dart';
import 'coach_sessions_screen.dart';
import 'course_detail_screen.dart';

class CoachProfileScreen extends StatefulWidget {
  final String coachId;

  const CoachProfileScreen({
    Key? key,
    required this.coachId,
  }) : super(key: key);

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  CoachModel? _coach;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCoachData();
  }
  
  Future<void> _loadCoachData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final coachProvider = Provider.of<CoachProvider>(context, listen: false);
      final coach = await coachProvider.getCoachById(widget.coachId);
      
      setState(() {
        _coach = coach;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading coach data: $e');
      setState(() {
        _error = 'Failed to load coach data: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB4FF00)),
          ),
        ),
      );
    }
    
    if (_error != null || _coach == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Coach Details', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Failed to load coach data',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadCoachData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB4FF00),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Coach header with image
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.45,
            backgroundColor: Colors.transparent,
            pinned: false,
            floating: false,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Coach image
                  FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: _coach!.profileImageUrl.isNotEmpty 
                      ? _coach!.profileImageUrl
                      : 'https://via.placeholder.com/400',
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading coach image: $error');
                      return Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.person, color: Colors.white54, size: 100),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                          Colors.black,
                        ],
                        stops: const [0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Coach info and booking button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coach name
                  Text(
                    _coach!.name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title/Role
                  Text(
                    _coach!.title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Coach bio
                  Text(
                    _coach!.bio,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Booking button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_coach!.bookingUrl.isNotEmpty) {
                          // Launch booking URL
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening booking page...')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking is not available for this coach'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB4FF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Book 1:1 Coaching Call',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Podcasts'),
                      Tab(text: 'Modules'),
                      Tab(text: 'Articles'),
                      Tab(text: 'Courses'),
                    ],
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: const Color(0xFFB4FF00),
                    indicatorWeight: 3,
                  ),
                ],
              ),
            ),
          ),
          
          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Podcasts tab
                _buildPodcastsList(),
                
                // Modules tab
                _buildModulesList(),
                
                // Articles tab
                _buildArticlesList(),
                
                // Courses tab
                _buildCoursesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPodcastsList() {
    // We don't have podcasts in the model yet, so load them from the ContentProvider
    final contentProvider = Provider.of<ContentProvider>(context);
    final podcasts = contentProvider.getMediaByCoach(_coach!.id, 'audio') ?? [];
    
    if (podcasts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No podcasts available from this coach yet',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: podcasts.length,
      itemBuilder: (context, index) {
        final podcast = podcasts[index];
        
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                podcast['imageUrl'] ?? 'https://picsum.photos/100/100?random=1',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              podcast['title'] ?? 'Unnamed Podcast',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              podcast['duration'] ?? 'Unknown duration',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            trailing: const Icon(
              Icons.play_circle_outline,
              color: Color(0xFFB4FF00),
              size: 36,
            ),
            onTap: () {
              // Play podcast
            },
          ),
        );
      },
    );
  }
  
  Widget _buildModulesList() {
    // We don't have modules in the model yet, so load them from the ContentProvider
    final contentProvider = Provider.of<ContentProvider>(context);
    final modules = contentProvider.getMediaByCoach(_coach!.id, 'video') ?? [];
    
    if (modules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No modules available from this coach yet',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        
        return Container(
          decoration: BoxDecoration(
            color: _getModuleColor(index),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      module['title'] ?? 'Unnamed Module',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${module['lessons'] ?? 0} lessons',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildArticlesList() {
    final contentProvider = Provider.of<ContentProvider>(context);
    final coachId = _coach!.id;
    final articles = contentProvider.getArticlesByAuthor(coachId);
    
    if (articles.isEmpty) {
      return const Center(
        child: Text('No articles available', style: TextStyle(color: Colors.white70)),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Articles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: articles.length > 3 ? 3 : articles.length,
            itemBuilder: (context, index) {
              return ArticleListCard(article: articles[index]);
            },
          ),
          if (articles.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to all articles by this coach
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticlesListScreen(
                          tag: _coach!.name,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'See all articles',
                    style: TextStyle(
                      color: Color(0xFFB4FF00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCoursesList() {
    // We don't have courses in the model yet, so we'll need to fetch them
    final contentProvider = Provider.of<ContentProvider>(context);
    final courses = contentProvider.getCoursesByCoach(_coach!.id) ?? [];
    
    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No courses available from this coach yet',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  course.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              
              // Course info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white60,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.durationMinutes} min',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.menu_book,
                          color: Colors.white60,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.modules.length} modules',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to course detail screen
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('View Course'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Color _getModuleColor(int index) {
    final colors = [
      const Color(0xFF4A5CFF), // Blue
      const Color(0xFF53B175), // Green
      const Color(0xFFFF8700), // Orange
      const Color(0xFFFF5757), // Red
      const Color(0xFF9747FF), // Purple
      const Color(0xFF00C1AC), // Teal
    ];
    
    return colors[index % colors.length];
  }
} 