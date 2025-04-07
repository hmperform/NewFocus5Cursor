import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../providers/content_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContentProvider>(context, listen: false).refreshTodayAudio();
    });
  }

  Future<void> _loadAudioSessions() async {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    
    // Simulate loading delay for demo purposes
    await Future.delayed(const Duration(milliseconds: 500));
    
    final todayAudio = contentProvider.todayAudio;
    
    setState(() {
      _audioSessions = todayAudio != null ? [todayAudio] : [];
      _filteredSessions = todayAudio != null ? [todayAudio] : [];
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
          (audio) => userProvider.user?.completedAudios.contains(audio.id) ?? false
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
    final userProvider = Provider.of<UserProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color iconColor = isDarkMode ? Colors.white : Colors.black54;

    final todayAudio = contentProvider.todayAudio;
    // final hasCompleted = userProvider.hasCompletedAudio(todayAudio?.id ?? ''); // Commented out: Method doesn't exist in UserProvider

    final hasCompletedToday = userProvider.user?.completedAudios.contains(todayAudio?.id ?? '') ?? false;
    // final hasCompleted = userProvider.hasCompletedAudio(todayAudio?.id ?? ''); // Commented out: Method doesn't exist in UserProvider

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: contentProvider.isLoading && todayAudio == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => contentProvider.refreshTodayAudio(),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (contentProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Error: ${contentProvider.errorMessage}',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    // Today's Audio Section
                    if (todayAudio != null)
                      _buildTodaysAudioSection(context, todayAudio, hasCompletedToday, iconColor, textColor)
                    else
                       _buildNoAudioAvailable(context, textColor),
                    
                    const SizedBox(height: 24),

                    // Browse Categories Section
                    Text('Browse Categories', style: theme.textTheme.headlineSmall?.copyWith(color: textColor)),
                    const SizedBox(height: 16),
                    _buildCategoryGrid(context, iconColor),

                    const SizedBox(height: 24),
                    
                    // Your Library Section (Example - Adapt based on actual library data)
                    Text('Your Library', style: theme.textTheme.headlineSmall?.copyWith(color: textColor)),
                    const SizedBox(height: 16),
                    _buildLibraryList(context, iconColor, textColor),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTodaysAudioSection(BuildContext context, DailyAudio audio, bool hasCompleted, Color iconColor, Color textColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final accentTextColor = themeProvider.accentTextColor;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => _showAudioDetails(context, audio.id),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor,
                accentColor.withOpacity(0.7),
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
                  color: accentTextColor.withOpacity(0.2),
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
                        color: accentTextColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Featured',
                        style: TextStyle(
                          color: accentTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Title and details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio.title,
                          style: TextStyle(
                            color: accentTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${audio.durationMinutes} min • ${audio.category}',
                          style: TextStyle(
                            color: accentTextColor.withOpacity(0.9),
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
                            color: accentTextColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: accentColor,
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

  Widget _buildNoAudioAvailable(BuildContext context, Color textColor) {
    return Center(
      child: Text(
        'No audio available for today',
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, Color iconColor) {
    final categories = ['All', 'Focus', 'Breathing', 'Visualization', 'Completed'];
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    
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
              backgroundColor: themeProvider.isDarkMode 
                ? Theme.of(context).colorScheme.surface 
                : Colors.grey[200],
              selectedColor: accentColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected 
                  ? accentColor
                  : Theme.of(context).colorScheme.onBackground,
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

  Widget _buildLibraryList(BuildContext context, Color iconColor, Color textColor) {
    return Expanded(
      child: _filteredSessions.isEmpty
        ? Center(
            child: Text(
              'No audio sessions found',
              style: TextStyle(color: textColor),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _filteredSessions.length,
            itemBuilder: (context, index) {
              final audio = _filteredSessions[index];
              return _buildAudioListItem(context, audio, iconColor, textColor);
            },
          ),
    );
  }

  Widget _buildAudioListItem(BuildContext context, DailyAudio audio, Color iconColor, Color textColor) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isCompleted = userProvider.user?.completedAudios.contains(audio.id) ?? false;
    final accentColor = themeProvider.accentColor;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAudioDetails(context, audio.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${audio.durationMinutes} min • ${DateFormat.MMMd().format(audio.datePublished)}',
                      style: TextStyle(
                        color: secondaryTextColor,
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
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: accentColor,
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

  void _showAudioDetails(BuildContext context, String audioId) {
    // Find the audio session from the loaded list using firstWhereOrNull
    final DailyAudio? audio = _audioSessions.firstWhereOrNull(
      (item) => item.id == audioId
    );

    if (audio == null) {
      print('Audio with ID $audioId not found in loaded sessions');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(audio.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(audio.description),
              const SizedBox(height: 10),
              Text('By: ${audio.creatorName}'),
              Text('Duration: ${audio.durationMinutes} min'),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text('Play Now'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/audio-player', arguments: audio);
                },
              )
            ],
          ),
        );
      },
    );
  }
} 