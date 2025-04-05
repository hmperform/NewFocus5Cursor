import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../constants/dummy_data.dart';
import '../../models/content_models.dart';
import '../../providers/theme_provider.dart';
import '../../providers/media_provider.dart';
import '../../screens/home/media_player_screen.dart';

class MediaTab extends StatefulWidget {
  const MediaTab({Key? key}) : super(key: key);

  @override
  State<MediaTab> createState() => _MediaTabState();
}

class _MediaTabState extends State<MediaTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['All', 'Focus', 'Resilience', 'Visualization', 'Mindfulness'];
  String _selectedCategory = 'All';
  
  // Media lists
  List<MediaItem> _allMedia = [];
  List<MediaItem> _filteredMedia = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMediaContent();
  }
  
  void _loadMediaContent() {
    // In a real app, this would come from a provider or API
    _allMedia = DummyData.dummyMediaItems;
    _filterMedia();
  }
  
  void _filterMedia() {
    if (_selectedCategory == 'All') {
      _filteredMedia = _allMedia;
    } else {
      _filteredMedia = _allMedia.where((media) => media.category == _selectedCategory).toList();
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final accentColor = themeProvider.accentColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Media Library',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore audio and video content to enhance your mental training',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Tab selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: accentColor,
                ),
                labelColor: themeProvider.accentTextColor,
                unselectedLabelColor: textColor,
                tabs: const [
                  Tab(text: 'Videos'),
                  Tab(text: 'Audio'),
                ],
              ),
            ),
          ),
          
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _categories.map((category) {
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _filterMedia();
                      });
                    },
                    backgroundColor: Theme.of(context).cardColor,
                    selectedColor: accentColor,
                    checkmarkColor: themeProvider.accentTextColor,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? themeProvider.accentTextColor 
                          : textColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Media content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Videos tab
                _buildMediaList(true),
                
                // Audio tab
                _buildMediaList(false),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMediaList(bool isVideoTab) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    
    // Filter by media type (video or audio)
    final mediaList = _filteredMedia.where(
      (media) => isVideoTab 
          ? media.mediaType == MediaType.video 
          : media.mediaType == MediaType.audio
    ).toList();
    
    if (mediaList.isEmpty) {
      return Center(
        child: Text(
          'No ${isVideoTab ? 'videos' : 'audio'} available in this category',
          style: TextStyle(color: textColor.withOpacity(0.7)),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final media = mediaList[index];
        return _buildMediaCard(media, isVideoTab);
      },
    );
  }
  
  Widget _buildMediaCard(MediaItem media, bool isVideo) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _playMedia(media),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button overlay
            Stack(
              alignment: Alignment.center,
              children: [
                // Thumbnail image
                AspectRatio(
                  aspectRatio: isVideo ? 16/9 : 2/1,
                  child: Image.asset(
                    media.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: Icon(
                            isVideo ? Icons.videocam : Icons.music_note,
                            color: Colors.white54,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Play button overlay
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeProvider.accentColor.withOpacity(0.9),
                  ),
                  child: Icon(
                    isVideo ? Icons.play_arrow : Icons.headphones,
                    color: themeProvider.accentTextColor,
                    size: 30,
                  ),
                ),
              ],
            ),
            
            // Content details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    media.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    media.description,
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Metadata row
                  Row(
                    children: [
                      // Creator
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: textColor.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        media.creatorName,
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // Duration
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: textColor.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${media.durationMinutes} min',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // XP reward
                      Icon(
                        Icons.star_outline,
                        size: 16,
                        color: textColor.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${media.xpReward} XP',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  // Category chips
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          media.category,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: themeProvider.accentColor.withOpacity(0.2),
                        labelStyle: TextStyle(color: themeProvider.accentColor),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      ...media.focusAreas.take(2).map((area) => Chip(
                        label: Text(
                          area,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        labelStyle: TextStyle(color: textColor),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _playMedia(MediaItem media) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaPlayerScreen(
          title: media.title,
          subtitle: media.description,
          mediaUrl: media.mediaUrl,
          mediaType: media.mediaType,
          imageUrl: media.imageUrl,
          mediaItem: media,
        ),
      ),
    );
  }
} 