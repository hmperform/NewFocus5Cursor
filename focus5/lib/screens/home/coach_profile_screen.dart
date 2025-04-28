import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/content_provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/content_models.dart';

import '../../models/coach_model.dart' as coachModel;
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
import '../../screens/home/article_detail_screen.dart';
import '../../screens/home/audio_player_screen.dart';
import '../../providers/audio_provider.dart';

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
  coachModel.Coach? _coach;
  String? _error;
  List<DailyAudio> _coachModules = [];
  List<Article> _coachArticles = [];
  List<Course> _coachCourses = [];
  bool _loadingContent = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      _loadCoachAndContent();
    });
  }
  
  Future<void> _loadCoachAndContent() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingContent = true;
      _error = null;
    });

    try {
      final coachProvider = Provider.of<CoachProvider>(context, listen: false);
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      
      final coach = await coachProvider.getCoachById(widget.coachId);
      if (!mounted) return;
      setState(() {
        _coach = coach;
        _isLoading = false;
      });

      if (_coach != null) {
        _coachModules = await contentProvider.getDailyAudiosByCoach(_coach!.id);
        _coachArticles = await contentProvider.getArticlesByCoach(_coach!.id);
        _coachCourses = await contentProvider.getCoursesByCoach(_coach!.id);
        
        if (!mounted) return;
        setState(() {
          _loadingContent = false;
        });
      } else {
        throw Exception('Coach data is null after fetch.');
      }

    } catch (e) {
      debugPrint('Error loading coach data or content: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load coach data or content: $e';
        _isLoading = false;
        _loadingContent = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
      throw 'Could not launch $urlString';
    }
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
                onPressed: _loadCoachAndContent,
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
                  // Gradient overlay - RESTORED AND MODIFIED HERE
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent, // Start transparent
                          Colors.black,       // Become fully black sooner
                          Colors.black,       // Stay black
                        ],
                        stops: const [0.5, 0.9, 1.0], // Start fade at 50%, fully black by 90%-100%
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
              padding: const EdgeInsets.all(20.0), // Restore original padding
              child: Column( // Restore original Column structure
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
                        if (_coach!.bookingUrl != null && _coach!.bookingUrl.isNotEmpty) {
                          _launchURL(_coach!.bookingUrl);
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
  
  Widget _buildModulesList() {
    if (_loadingContent) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFB4FF00)));
    }
    if (_coachModules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No modules available from this coach yet',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _coachModules.length,
      itemBuilder: (context, index) {
        final module = _coachModules[index];
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageUtils.networkImageWithFallback(
                imageUrl: module.thumbnail,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              module.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${module.durationMinutes} min • ${module.focusAreas.isNotEmpty ? module.focusAreas.first : 'Audio'}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.play_circle_outline, color: Color(0xFFB4FF00), size: 32),
            onTap: () {
              final audioProvider = context.read<AudioProvider>();
              final audioObject = Audio(
                id: module.id,
                title: module.title,
                subtitle: module.focusAreas.join(', '),
                description: module.description,
                imageUrl: module.thumbnail,
                audioUrl: module.audioUrl,
                sequence: 0,
                slideshowImages: [module.slideshow1, module.slideshow2, module.slideshow3]
                    .where((s) => s.isNotEmpty).toList(),
                sourceType: AudioSource.daily,
              );
              
              // audioProvider.startAudioPlayback(audioObject);
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Pass the DailyAudio object and a placeholder for currentDay
                  builder: (context) => AudioPlayerScreen(audio: module, currentDay: 0), 
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildArticlesList() {
    if (_loadingContent) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFB4FF00)));
    }
    if (_coachArticles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No articles available from this coach yet',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _coachArticles.length,
      itemBuilder: (context, index) {
        final originalArticle = _coachArticles[index];
        
        // Create a new Article instance with author details overridden by the current coach
        final displayArticle = originalArticle.copyWithAuthorDetails(
          name: _coach!.name, // Use current coach's name
          imageUrl: _coach!.profileImageUrl, // Use current coach's image
        );
        
        // Use the ArticleListCard widget with the modified article data
        return ArticleListCard(article: displayArticle);
      },
    );
  }
  
  Widget _buildCoursesList() {
    if (_loadingContent) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFB4FF00)));
    }
    if (_coachCourses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No courses available from this coach yet',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _coachCourses.length,
      itemBuilder: (context, index) {
        final course = _coachCourses[index];
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageUtils.networkImageWithFallback(
                imageUrl: course.courseThumbnail.isNotEmpty ? course.courseThumbnail : course.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              course.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${course.lessonsList.length} lessons • ${course.durationMinutes} min',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
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
          ),
        );
      },
    );
  }
} 