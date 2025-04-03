import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../models/content_models.dart';
import '../../widgets/article/article_card.dart';
import 'articles_list_screen.dart';
import '../../utils/image_utils.dart';

class CoachProfileScreen extends StatefulWidget {
  final Map<String, dynamic> coach;

  const CoachProfileScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    image: widget.coach['imageUrl'],
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
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
                    widget.coach['name'],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.coach['location'] ?? 'Location not specified',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Experience
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.coach['experience'] ?? 'Experience not specified',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Coach bio
                  Text(
                    widget.coach['bio'] ?? 'No bio available',
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
                        // This will be replaced with TidyCal link from Firebase
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking functionality will be implemented with Firebase'),
                          ),
                        );
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
    final podcasts = widget.coach['podcasts'] as List? ?? [];
    
    if (podcasts.isEmpty) {
      return const Center(
        child: Text('No podcasts available', style: TextStyle(color: Colors.white70)),
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
    final modules = widget.coach['modules'] as List? ?? [];
    
    if (modules.isEmpty) {
      return const Center(
        child: Text('No modules available', style: TextStyle(color: Colors.white70)),
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
    final coachId = widget.coach['id'] ?? '';
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
                          tag: widget.coach['name'],
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
    final courses = widget.coach['courses'] as List? ?? [];
    
    if (courses.isEmpty) {
      return const Center(
        child: Text('No courses available', style: TextStyle(color: Colors.white70)),
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
                  course['imageUrl'] ?? 'https://picsum.photos/400/200?random=${index + 10}',
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
                      course['title'] ?? 'Unnamed Course',
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
                          course['duration'] ?? 'Unknown duration',
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
                          '${course['lessons'] ?? 0} lessons',
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
                          // Navigate to course
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