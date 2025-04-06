import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/content_models.dart';
import 'video_player_screen.dart';
import 'audio_player_screen.dart';
import '../../constants/theme.dart';

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({Key? key}) : super(key: key);

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMedia();
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
      await contentProvider.loadMediaContent();
    } catch (e) {
      // Handle error
      print('Error loading media content: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        title: const Text(
          'Media Library',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
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
          
          // Tab bar for Videos and Audio
          Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: accentColor,
              ),
              labelColor: Colors.black,
              unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Videos'),
                Tab(text: 'Audio'),
              ],
              onTap: (index) {
                setState(() {
                  // Reset selected category when changing tabs
                  _selectedCategory = 'All';
                });
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
                      // Videos tab
                      _buildVideoList(contentProvider),
                      
                      // Audio tab
                      _buildAudioList(contentProvider),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        selectedColor: accentColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
      ),
    );
  }
  
  Widget _buildVideoList(ContentProvider contentProvider) {
    final videos = contentProvider.videos;
    
    // Filter by category if not "All"
    final filteredVideos = _selectedCategory == 'All'
        ? videos
        : videos.where((video) => 
            video.categories.contains(_selectedCategory)).toList();
    
    if (filteredVideos.isEmpty) {
      return Center(
        child: Text(
          'No videos available in this category',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDarkMode 
                ? Colors.white70 
                : Colors.black54,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredVideos.length,
      itemBuilder: (context, index) {
        final video = filteredVideos[index];
        return _buildMediaCard(
          title: video.title,
          description: video.description,
          duration: video.duration,
          xpReward: video.xpReward,
          instructor: video.instructor,
          categories: video.categories,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(video: video),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildAudioList(ContentProvider contentProvider) {
    final audios = contentProvider.audios;
    
    // Filter by category if not "All"
    final filteredAudios = _selectedCategory == 'All'
        ? audios
        : audios.where((audio) => 
            audio.categories.contains(_selectedCategory)).toList();
    
    if (filteredAudios.isEmpty) {
      return Center(
        child: Text(
          'No audio content available in this category',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDarkMode 
                ? Colors.white70 
                : Colors.black54,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredAudios.length,
      itemBuilder: (context, index) {
        final audio = filteredAudios[index];
        return _buildMediaCard(
          title: audio.title,
          description: audio.description,
          duration: audio.duration,
          xpReward: audio.xpReward,
          instructor: audio.instructor,
          categories: audio.categories,
          isAudio: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioPlayerScreen(audio: audio),
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
    bool isAudio = false,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
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
                ),
              ),
              IconButton(
                icon: Icon(
                  isAudio ? Icons.play_circle_filled : Icons.play_arrow,
                  size: 64,
                  color: accentColor,
                ),
                onPressed: onTap,
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
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Metadata row
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      instructor,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${duration ~/ 60} min',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$xpReward XP',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Category chips
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
                            ? Border.all(color: accentColor, width: 1)
                            : null,
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          color: category == _selectedCategory
                              ? accentColor
                              : (isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 