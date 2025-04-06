import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/coach_model.dart';
import '../../providers/coach_provider.dart';
import '../../utils/image_utils.dart';

class CoachProfileScreen extends StatefulWidget {
  final String coachId;

  const CoachProfileScreen({
    Key? key,
    required this.coachId,
  }) : super(key: key);

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  CoachModel? _coach;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _audioModules = [];
  List<Map<String, dynamic>> _articles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCoachData();
  }

  Future<void> _loadCoachData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final coachProvider = Provider.of<CoachProvider>(context, listen: false);
      
      // Load coach details
      final coach = await coachProvider.getCoachById(widget.coachId);
      if (coach == null) {
        throw Exception('Coach not found');
      }
      
      // Load coach content
      final courses = await coachProvider.getCoachCourses(widget.coachId);
      final audioModules = await coachProvider.getCoachAudioModules(widget.coachId);
      final articles = await coachProvider.getCoachArticles(widget.coachId);
      
      setState(() {
        _coach = coach;
        _courses = courses;
        _audioModules = audioModules;
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB4FF00),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
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
                )
              : _coach == null
                  ? const Center(
                      child: Text(
                        'Coach not found',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        // App bar with coach header image
                        SliverAppBar(
                          expandedHeight: 200,
                          pinned: true,
                          backgroundColor: Colors.transparent,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Header image
                                _coach!.headerImageUrl.isNotEmpty
                                    ? Image.network(
                                        _coach!.headerImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: const Color(0xFF2A2A2A),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFF2A2A2A),
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
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          leading: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          actions: [
                            if (_coach!.isVerified)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        // Coach info
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile image and name
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Profile image
                                    ImageUtils.avatarWithFallback(
                                      imageUrl: _coach!.profileImageUrl,
                                      radius: 40,
                                      name: _coach!.name,
                                      backgroundColor: const Color(0xFF2A2A2A),
                                      textColor: Colors.white70,
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Name and title
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _coach!.name,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _coach!.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Specialties
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _coach!.specialties.map((specialty) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        specialty,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Bio
                                const Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _coach!.bio,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Credentials
                                if (_coach!.credentials.isNotEmpty) ...[
                                  const Text(
                                    'Credentials',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...(_coach!.credentials.map((credential) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFFB4FF00),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              credential,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList()),
                                  const SizedBox(height: 24),
                                ],
                                
                                // Book a session button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _launchUrl(_coach!.bookingUrl);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFB4FF00),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'BOOK A SESSION',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Social links
                                _buildSocialLinks(),
                                
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        
                        // Tab bar for content
                        SliverPersistentHeader(
                          delegate: _SliverAppBarDelegate(
                            TabBar(
                              controller: _tabController,
                              indicatorColor: const Color(0xFFB4FF00),
                              indicatorWeight: 3,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white60,
                              tabs: const [
                                Tab(text: 'Courses'),
                                Tab(text: 'Audio'),
                                Tab(text: 'Articles'),
                              ],
                            ),
                          ),
                          pinned: true,
                        ),
                        
                        // Tab content
                        SliverFillRemaining(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Courses tab
                              _buildCoursesTab(),
                              
                              // Audio tab
                              _buildAudioTab(),
                              
                              // Articles tab
                              _buildArticlesTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildSocialLinks() {
    final links = <Widget>[];
    
    if (_coach!.instagramUrl != null && _coach!.instagramUrl!.isNotEmpty) {
      links.add(
        IconButton(
          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
          onPressed: () => _launchUrl(_coach!.instagramUrl!),
          tooltip: 'Instagram',
        ),
      );
    }
    
    if (_coach!.twitterUrl != null && _coach!.twitterUrl!.isNotEmpty) {
      links.add(
        IconButton(
          icon: const Icon(Icons.flutter_dash, color: Colors.white),
          onPressed: () => _launchUrl(_coach!.twitterUrl!),
          tooltip: 'Twitter',
        ),
      );
    }
    
    if (_coach!.linkedinUrl != null && _coach!.linkedinUrl!.isNotEmpty) {
      links.add(
        IconButton(
          icon: const Icon(Icons.work_outline, color: Colors.white),
          onPressed: () => _launchUrl(_coach!.linkedinUrl!),
          tooltip: 'LinkedIn',
        ),
      );
    }
    
    if (_coach!.websiteUrl != null && _coach!.websiteUrl!.isNotEmpty) {
      links.add(
        IconButton(
          icon: const Icon(Icons.language, color: Colors.white),
          onPressed: () => _launchUrl(_coach!.websiteUrl!),
          tooltip: 'Website',
        ),
      );
    }
    
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: links),
      ],
    );
  }

  Widget _buildCoursesTab() {
    if (_courses.isEmpty) {
      return const Center(
        child: Text(
          'No courses available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // Navigate to course detail screen
              // Using course['id'] or similar
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course image
                if (course['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      course['imageUrl'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: const Color(0xFF2A2A2A),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Course info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'] ?? 'Untitled Course',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (course['description'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          course['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioTab() {
    if (_audioModules.isEmpty) {
      return const Center(
        child: Text(
          'No audio modules available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _audioModules.length,
      itemBuilder: (context, index) {
        final audio = _audioModules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // Navigate to audio player screen
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Audio thumbnail or play icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.headphones,
                      color: Color(0xFFB4FF00),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Audio info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio['title'] ?? 'Untitled Audio',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (audio['duration'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${audio['duration']} min',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Play button
                  IconButton(
                    icon: const Icon(
                      Icons.play_circle_fill,
                      color: Color(0xFFB4FF00),
                      size: 36,
                    ),
                    onPressed: () {
                      // Play audio
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArticlesTab() {
    if (_articles.isEmpty) {
      return const Center(
        child: Text(
          'No articles available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // Navigate to article detail screen
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Article image (optional)
                if (article['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      article['imageUrl'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: const Color(0xFF2A2A2A),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Article info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['title'] ?? 'Untitled Article',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (article['summary'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          article['summary'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (article['date'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          article['date'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF121212),
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
} 