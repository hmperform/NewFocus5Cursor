import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../providers/media_provider.dart';
import '../models/content_models.dart';
import '../screens/home/media_player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context);
    
    // Only show if there's media loaded, it's playing, and full screen is closed
    final shouldShow = mediaProvider.showMiniPlayer && 
                       mediaProvider.title != null &&
                       !mediaProvider.isFullScreenPlayerOpen;
    
    if (!shouldShow) {
      return const SizedBox.shrink(); // Don't show anything
    }
    
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          if (mediaProvider.title == null) return;
          
          // Navigate to media player screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaPlayerScreen(
                title: mediaProvider.title!,
                subtitle: mediaProvider.subtitle!,
                mediaUrl: mediaProvider.mediaUrl!,
                imageUrl: mediaProvider.imageUrl,
                mediaType: mediaProvider.mediaType,
                mediaItem: mediaProvider.currentMediaItem,
              ),
            ),
          );
        },
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 72,
                height: 72,
                child: mediaProvider.imageUrl != null
                    ? Image.network(
                        mediaProvider.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: Icon(
                              mediaProvider.mediaType == MediaType.audio
                                  ? Icons.music_note
                                  : Icons.videocam,
                              color: Colors.white54,
                              size: 32,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                          size: 32,
                        ),
                      ),
              ),
            ),
            
            // Title and subtitle
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mediaProvider.title ?? 'Unknown',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mediaProvider.subtitle ?? '',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // Play/pause button
            IconButton(
              icon: Icon(
                mediaProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                color: textColor,
              ),
              onPressed: () {
                mediaProvider.togglePlayPause();
              },
            ),
            
            // Close button
            IconButton(
              icon: Icon(Icons.close, color: textColor),
              onPressed: () {
                mediaProvider.closeMiniPlayer();
              },
            ),
          ],
        ),
      ),
    );
  }
} 