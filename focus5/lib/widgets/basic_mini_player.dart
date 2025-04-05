import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../services/basic_video_service.dart';
import '../screens/basic_player_screen.dart';

class BasicMiniPlayer extends StatefulWidget {
  final double bottomPadding;

  const BasicMiniPlayer({Key? key, this.bottomPadding = 80}) : super(key: key);

  @override
  State<BasicMiniPlayer> createState() => _BasicMiniPlayerState();
}

class _BasicMiniPlayerState extends State<BasicMiniPlayer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPlaybackState();
    });
  }

  // Periodically check playback state to ensure continuity
  void _checkPlaybackState() {
    if (!mounted) return;
    
    final videoService = Provider.of<BasicVideoService>(context, listen: false);
    
    // Ensure video is playing if it should be
    if (videoService.isPlaying && 
        videoService.videoController != null &&
        !videoService.videoController!.value.isPlaying) {
      videoService.videoController!.play();
    }
    
    // Schedule next check
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _checkPlaybackState();
      }
    });
  }

  void _openFullScreenPlayer() {
    final videoService = Provider.of<BasicVideoService>(context, listen: false);
    
    if (videoService.videoController == null) return;
    
    // Set state to fullscreen
    videoService.setFullScreen(true);
    
    // Navigate to full screen player
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BasicPlayerScreen(),
      ),
    ).then((_) {
      // Reset state when returning
      if (mounted) {
        videoService.setFullScreen(false);
        _checkPlaybackState();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<BasicVideoService>(
      builder: (context, videoService, child) {
        // Don't show mini player if no video or if explicitly hidden
        if (videoService.videoController == null || 
            !videoService.showMiniPlayer ||
            videoService.isFullScreen) {
          return const SizedBox.shrink();
        }

        return _buildMiniPlayer(videoService);
      },
    );
  }

  Widget _buildMiniPlayer(BasicVideoService videoService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: 64,
      width: screenWidth,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _openFullScreenPlayer,
        child: Row(
          children: [
            // Thumbnail or live video
            SizedBox(
              width: 64,
              height: 64,
              child: _buildThumbnail(videoService),
            ),
            
            // Title and subtitle
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      videoService.title,
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
                      videoService.subtitle,
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
            
            // Backward 10 seconds button
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(
                  Icons.replay_10,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  videoService.seekBackward(seconds: 10);
                },
              ),
            ),
            
            // Play/Pause button
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: IconButton(
                icon: Icon(
                  videoService.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  videoService.togglePlayPause();
                },
              ),
            ),
            
            // Forward 10 seconds button
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(
                  Icons.forward_10,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  videoService.seekForward(seconds: 10);
                },
              ),
            ),
            
            // Close button
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
                  videoService.closePlayer();
                },
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BasicVideoService videoService) {
    if (videoService.videoController != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoService.videoController!.value.size.width,
              height: videoService.videoController!.value.size.height,
              child: VideoPlayer(videoService.videoController!),
            ),
          ),
        ),
      );
    } else {
      // Fallback to static thumbnail
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: videoService.thumbnailUrl.isNotEmpty
            ? Image.network(
                videoService.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.videocam,
                      color: Colors.white54,
                      size: 30,
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey[800],
                child: const Icon(
                  Icons.videocam,
                  color: Colors.white54,
                  size: 30,
                ),
              ),
      );
    }
  }
} 