import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/content_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/content_models.dart';
import 'audio_player_screen.dart';

class AudioTab extends StatefulWidget {
  const AudioTab({Key? key}) : super(key: key);

  @override
  State<AudioTab> createState() => _AudioTabState();
}

class _AudioTabState extends State<AudioTab> {
  bool _isLoading = true;
  List<DailyAudio> _audioSessions = [];
  List<DailyAudio> _filteredSessions = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadAudioSessions();
  }

  Future<void> _loadAudioSessions() async {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    
    // Simulate loading delay for demo purposes
    await Future.delayed(const Duration(milliseconds: 500));
    
    final sessions = contentProvider.getDailyAudio();
    
    setState(() {
      _audioSessions = sessions;
      _filteredSessions = sessions;
      _isLoading = false;
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      
      if (category == 'All') {
        _filteredSessions = _audioSessions;
      } else if (category == 'Completed') {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        _filteredSessions = _audioSessions.where(
          (audio) => userProvider.hasCompletedAudio(audio.id)
        ).toList();
      } else {
        _filteredSessions = _audioSessions.where(
          (audio) => audio.category == category
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Daily Audio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Mental training sessions to enhance your focus',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Category filters
            _buildCategoryFilters(),
            
            // Featured audio
            _buildFeaturedAudio(),
            
            // Audio list
            Expanded(
              child: _filteredSessions.isEmpty
                ? Center(
                    child: Text(
                      'No audio sessions found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _filteredSessions.length,
                    itemBuilder: (context, index) {
                      final audio = _filteredSessions[index];
                      return _buildAudioListItem(audio);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = ['All', 'Focus', 'Breathing', 'Visualization', 'Completed'];
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _filterByCategory(category),
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedAudio() {
    // Get the first Focus session for featured
    final featuredAudio = _audioSessions.firstWhere(
      (audio) => audio.category == 'Focus',
      orElse: () => _audioSessions.first,
    );
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => _navigateToAudioPlayer(featuredAudio.id),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.headphones,
                  size: 150,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Title and details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          featuredAudio.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${featuredAudio.durationMinutes} min • ${featuredAudio.category}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    // Play button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioListItem(DailyAudio audio) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isCompleted = userProvider.hasCompletedAudio(audio.id);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToAudioPlayer(audio.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _getCategoryColor(audio.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(audio.category),
                    color: _getCategoryColor(audio.category),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Title and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${audio.durationMinutes} min • ${DateFormat.MMMd().format(audio.datePublished)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Completed status or play button
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 16,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Focus':
        return Colors.blue;
      case 'Breathing':
        return Colors.green;
      case 'Visualization':
        return Colors.purple;
      case 'Mindfulness':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Focus':
        return Icons.center_focus_strong;
      case 'Breathing':
        return Icons.air;
      case 'Visualization':
        return Icons.remove_red_eye;
      case 'Mindfulness':
        return Icons.spa;
      default:
        return Icons.headphones;
    }
  }

  void _navigateToAudioPlayer(String audioId) {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final audio = contentProvider.getAudioById(audioId);
    
    if (audio != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(
            title: audio.title,
            subtitle: audio.description,
            audioUrl: audio.audioUrl,
            imageUrl: audio.imageUrl,
          ),
        ),
      );
    }
  }
} 