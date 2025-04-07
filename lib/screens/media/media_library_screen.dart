import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/content_models.dart';
// Removed imports for video_player_screen.dart and audio_player_screen.dart

class MediaLibraryScreen extends StatefulWidget {
  // ... existing code ...
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    // ... existing code ...
    final Color primaryColor = Theme.of(context).colorScheme.primary; // Use primary color

    // Replace accentColor with primaryColor where used
    // Example:
    // TabBar(
    //   indicatorColor: primaryColor,
    //   labelColor: primaryColor,
    // );
    // ... rest of build method ...
  }

  Widget _buildMediaGrid(List<dynamic> mediaList) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    // ... grid build logic ...
    // Replace accentColor with primaryColor
  }

  Widget _buildMediaListItem(dynamic mediaItem) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    // ... list item build logic ...
    // Replace accentColor with primaryColor
    // Replace Navigator push for video/audio player with TODOs or placeholders
    // onTap: () {
          // if (mediaItem is VideoLesson) {
          //   // TODO: Navigate to Video Player
          // } else if (mediaItem is AudioLesson) {
          //   // TODO: Navigate to Audio Player
          // }
       // },
  }
} 