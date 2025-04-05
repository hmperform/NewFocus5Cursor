import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:video_player/video_player.dart';

import '../providers/media_provider.dart';
import '../models/content_models.dart';
import '../screens/home/media_player_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _playbackCheckTimer;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    _controller.forward();
    
    // Check playback state after a brief delay to ensure UI is settled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkPlaybackState();
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check playback when dependencies change
    _ensurePlaybackContinuity();
  }
  
  void _ensurePlaybackContinuity() {
    // Cancel any existing timer
    _playbackCheckTimer?.cancel();
    
    // Schedule a check after the widget is built
    _playbackCheckTimer = Timer(Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      
      // Check if video should be playing but isn't
      if (mediaProvider.mediaType == MediaType.video && 
          mediaProvider.isPlaying && 
          mediaProvider.videoController != null && 
          mediaProvider.videoController!.value.isInitialized &&
          !mediaProvider.videoController!.value.isPlaying) {
        
        debugPrint('🔴 Mini player detected video should be playing but isn\'t - forcing play');
        mediaProvider.videoController!.play();
      }
      
      // Schedule regular checks
      _scheduleRegularPlaybackChecks();
    });
  }
  
  void _scheduleRegularPlaybackChecks() {
    // Cancel any existing timer
    _playbackCheckTimer?.cancel();
    
    // Set up periodic check to ensure playback continues
    _playbackCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      
      // Only check when the mini player is visible
      if (mediaProvider.showMiniPlayer && 
          mediaProvider.mediaType == MediaType.video && 
          mediaProvider.isPlaying && 
          mediaProvider.videoController != null && 
          mediaProvider.videoController!.value.isInitialized &&
          !mediaProvider.videoController!.value.isPlaying) {
        
        debugPrint('🔴 Periodic check: Mini player detected video should be playing but isn\'t - forcing play');
        mediaProvider.videoController!.play();
      }
    });
  }

  // Check if video should be playing but isn't, and force it to play
  void _checkPlaybackState() {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    
    if (mediaProvider.mediaType == MediaType.video && 
        mediaProvider.isPlaying && 
        mediaProvider.videoController != null && 
        mediaProvider.videoController!.value.isInitialized &&
        !mediaProvider.videoController!.value.isPlaying) {
      
      // If video should be playing but isn't, force it
      debugPrint('🔴 Mini player detected video should be playing but isn\'t - forcing play');
      mediaProvider.videoController!.play();
      
      // Set up a periodic check to ensure playback continues
      Timer.periodic(Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        // Check playback state again
        final provider = Provider.of<MediaProvider>(context, listen: false);
        if (provider.isPlaying && 
            provider.videoController != null && 
            provider.videoController!.value.isInitialized &&
            !provider.videoController!.value.isPlaying) {
          
          // Force playback to continue
          provider.videoController!.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _playbackCheckTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context);
    
    // Simplified visibility check - only check if mini player should be shown and we're not in full screen
    final shouldShow = mediaProvider.showMiniPlayer && !mediaProvider.isFullScreenPlayerOpen;
    
    debugPrint('Mini player visibility check: showMiniPlayer=${mediaProvider.showMiniPlayer}, isFullScreen=${mediaProvider.isFullScreenPlayerOpen}, shouldShow=$shouldShow');
    
    if (!shouldShow) {
      return const SizedBox.shrink(); // Don't show anything
    }
    
    final textColor = Theme.of(context).colorScheme.onBackground;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        // Glassmorphism effect
        color: isDarkMode 
            ? Colors.black.withOpacity(0.5) 
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0xFFB4FF00).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
        // Border for the glass effect
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.1) 
              : Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        // Backdrop filter for blur effect
        backgroundBlendMode: BlendMode.overlay,
      ),
      // Add backdrop filter for blur
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              // Progress indicator at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 2,
                  width: double.infinity,
                  color: Colors.transparent,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: mediaProvider.totalDuration > 0 
                        ? (mediaProvider.currentPosition / mediaProvider.totalDuration).clamp(0.0, 1.0)
                        : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFB4FF00),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Main content
              GestureDetector(
                onTap: () {
                  if (mediaProvider.title.isEmpty) return;
                  
                  // Store the current position and state
                  final currentPosition = mediaProvider.currentPosition;
                  final isPlaying = mediaProvider.isPlaying;
                  debugPrint('Opening full screen from mini player. Position: $currentPosition, Playing: $isPlaying');
                  
                  // Navigate to media player screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MediaPlayerScreen(
                        title: mediaProvider.title,
                        subtitle: mediaProvider.subtitle,
                        mediaUrl: mediaProvider.mediaUrl,
                        imageUrl: mediaProvider.imageUrl,
                        mediaType: mediaProvider.mediaType,
                        mediaItem: mediaProvider.currentMediaItem,
                        startPosition: currentPosition,
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
                        child: mediaProvider.imageUrl.isNotEmpty
                            ? Image.network(
                                mediaProvider.imageUrl,
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
                                child: Icon(
                                  mediaProvider.mediaType == MediaType.audio
                                      ? Icons.music_note
                                      : Icons.videocam,
                                  color: Colors.white54,
                                  size: 32,
                                ),
                              ),
                      ),
                    ),
                    
                    // Title and subtitle with position
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mediaProvider.title,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    mediaProvider.subtitle,
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Current position / total duration
                                Text(
                                  '${mediaProvider.formatDuration(mediaProvider.currentPosition)} / ${mediaProvider.formatDuration(mediaProvider.totalDuration)}',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.5),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Play/pause button
                    _buildPlayPauseButton(mediaProvider),
                    
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(MediaProvider mediaProvider) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          mediaProvider.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          debugPrint('Mini player play state toggled: ${!mediaProvider.isPlaying}');
          mediaProvider.togglePlayPause();
        },
      ),
    );
  }

  // Open full screen player
  void _openFullScreenPlayer(BuildContext context, MediaProvider mediaProvider) {
    // Get current position and play state before transition
    final currentPosition = mediaProvider.currentPosition;
    final isPlaying = mediaProvider.isPlaying;
    
    debugPrint('Opening full screen from mini player. Position: $currentPosition, Playing: $isPlaying');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaPlayerScreen(
          title: mediaProvider.title,
          subtitle: mediaProvider.subtitle,
          mediaUrl: mediaProvider.mediaUrl,
          imageUrl: mediaProvider.imageUrl,
          mediaType: mediaProvider.mediaType,
          mediaItem: mediaProvider.currentMediaItem,
          startPosition: currentPosition, // Use current position to resume from same point
        ),
      ),
    );
  }
} 