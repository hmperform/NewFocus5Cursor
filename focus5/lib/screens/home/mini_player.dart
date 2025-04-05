import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:focus5/providers/media_provider.dart';
import 'package:focus5/models/media_item.dart';
import 'package:focus5/screens/home/media_player_screen.dart';

class MiniPlayer extends StatefulWidget {
  final double bottomPadding;

  const MiniPlayer({Key? key, this.bottomPadding = 80}) : super(key: key);

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // Check playback state after a brief delay to allow UI to settle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 100), () {
        _checkPlaybackState();
      });
    });
  }

  // Check and fix playback state if needed
  void _checkPlaybackState() {
    if (!mounted) return;
    
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    
    // If video should be playing but isn't, force it to play
    if (mediaProvider.isPlaying && 
        mediaProvider.mediaType == MediaType.video && 
        mediaProvider.videoController != null &&
        mediaProvider.videoController!.value.isInitialized &&
        !mediaProvider.videoController!.value.isPlaying) {
      debugPrint('🔴 Mini player FORCING playback to continue');
      // Try multiple approaches to ensure playback works
      mediaProvider.videoController!.play()
        .then((_) => debugPrint('✅ Direct video controller play() succeeded'))
        .catchError((e) {
          debugPrint('❌ Direct controller play failed: $e, trying provider.play()');
          mediaProvider.play();
        });
    }
    
    // Set up periodic check to ensure playback continues
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        _checkPlaybackState();
      }
    });
  }

  void _openFullScreenPlayer() {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    
    // Check if media is available to play
    if (mediaProvider.selectedMedia == null) {
      return;
    }
    
    // Remember if media was playing to maintain state across navigation
    final wasPlaying = mediaProvider.isPlaying;
    
    // CRITICAL FIX: Store the current position to prevent restart
    final currentPosition = mediaProvider.currentPosition;
    debugPrint('🔴 Opening full screen player at position: $currentPosition');
    
    // Navigate to full screen player
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaPlayerScreen(
          title: mediaProvider.title,
          subtitle: mediaProvider.subtitle,
          mediaUrl: mediaProvider.mediaUrl,
          mediaType: mediaProvider.mediaType,
          imageUrl: mediaProvider.imageUrl,
          mediaItem: mediaProvider.selectedMedia,
          startPosition: currentPosition, // CRITICAL: Pass current position
        ),
      ),
    ).then((_) {
      // When returning from full screen, check playback state
      Future.microtask(() => _checkPlaybackState());
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        // Don't show mini player if no media or if explicitly hidden
        if (mediaProvider.selectedMedia == null || 
            !mediaProvider.showMiniPlayer ||
            mediaProvider.isFullScreenPlayerOpen) {
          return const SizedBox.shrink();
        }

        return _buildMiniPlayer(mediaProvider);
      },
    );
  }

  Widget _buildMiniPlayer(MediaProvider mediaProvider) {
    // Log mini player appearance for debugging
    debugPrint('Building mini player, isPlaying: ${mediaProvider.isPlaying}');
    
    // Ensure video is playing if it should be - CRITICAL FOR SEAMLESS PLAYBACK
    if (mediaProvider.isPlaying && 
        mediaProvider.mediaType == MediaType.video && 
        mediaProvider.videoController != null && 
        mediaProvider.videoController!.value.isInitialized &&
        !mediaProvider.videoController!.value.isPlaying) {
      // Use microtask to avoid calling during build
      Future.microtask(() {
        debugPrint('Mini player enforcing playback continuation');
        mediaProvider.play();
      });
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Positioned(
      bottom: widget.bottomPadding,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: _openFullScreenPlayer,
        child: Container(
          height: 64,
          width: screenWidth,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail or video preview - fixed width
              SizedBox(
                width: 64,
                height: 64,
                child: _buildMediaThumbnail(mediaProvider),
              ),
              
              // Title and subtitle - use Expanded to prevent overflow
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mediaProvider.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mediaProvider.subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Play/Pause button - fixed width, no padding
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(
                    mediaProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    mediaProvider.togglePlayPause();
                  },
                ),
              ),
              
              // Close button - fixed width, no padding  
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: IconButton(
                  icon: const Icon(
                    Icons.close, 
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    mediaProvider.stopMedia();
                  },
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail(MediaProvider mediaProvider) {
    if (mediaProvider.mediaType == MediaType.video && 
        mediaProvider.videoController != null && 
        mediaProvider.videoController!.value.isInitialized) {
      
      // Make sure video is playing if it should be
      if (mediaProvider.isPlaying && !mediaProvider.videoController!.value.isPlaying) {
        debugPrint('👀 Mini player thumbnail detected video should be playing but isn\'t');
        Future.microtask(() => mediaProvider.play());
      }
      
      // For video, show a live thumbnail from the video
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: SizedBox(
          width: 64,
          height: 64,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: mediaProvider.videoController!.value.size.width,
                height: mediaProvider.videoController!.value.size.height,
                child: VideoPlayer(mediaProvider.videoController!),
              ),
            ),
          ),
        ),
      );
    } else {
      // For audio or when video controller not available, show image
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: Image.network(
          mediaProvider.imageUrl ?? 'https://picsum.photos/64/64?random=1',
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 64,
              height: 64,
              color: Colors.grey[800],
              child: const Icon(Icons.music_note, color: Colors.white54),
            );
          },
        ),
      );
    }
  }
} 