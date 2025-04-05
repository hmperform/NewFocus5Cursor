import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus5/services/better_video_service.dart';
import 'package:focus5/screens/better_player_screen.dart';
import 'package:better_player/better_player.dart';

class BetterMiniPlayer extends StatefulWidget {
  final double bottomPadding;

  const BetterMiniPlayer({Key? key, this.bottomPadding = 80}) : super(key: key);

  @override
  State<BetterMiniPlayer> createState() => _BetterMiniPlayerState();
}

class _BetterMiniPlayerState extends State<BetterMiniPlayer> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _checkPlaybackState();
  }

  // Periodically check playback state to ensure continuity
  void _checkPlaybackState() {
    if (!mounted) return;
    
    final videoService = Provider.of<BetterVideoService>(context, listen: false);
    
    // Ensure playback continues if it should be playing
    if (videoService.isPlaying && 
        videoService.controller != null &&
        !videoService.controller!.isPlaying()!) {
      videoService.controller!.play();
    }
    
    // Schedule next check
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _checkPlaybackState();
      }
    });
  }

  void _openFullScreenPlayer() {
    final videoService = Provider.of<BetterVideoService>(context, listen: false);
    
    // Open full screen player without stopping playback
    videoService.setFullScreen(true);
    
    // Navigate to full screen player while maintaining playback
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BetterPlayerScreen(),
      ),
    ).then((_) {
      // When returning from full screen, reset fullscreen flag
      if (mounted) {
        videoService.setFullScreen(false);
        _checkPlaybackState();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<BetterVideoService>(
      builder: (context, videoService, child) {
        // Don't show mini player if no media or if explicitly hidden
        if (videoService.controller == null || 
            !videoService.showMiniPlayer ||
            videoService.isFullScreen) {
          return const SizedBox.shrink();
        }

        return _buildMiniPlayer(videoService);
      },
    );
  }

  Widget _buildMiniPlayer(BetterVideoService videoService) {
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
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail or video preview
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
      ),
    );
  }

  Widget _buildThumbnail(BetterVideoService videoService) {
    // Live video thumbnail
    if (videoService.controller != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: BetterPlayer(
            controller: videoService.controller!,
            key: ValueKey('mini_player_${videoService.videoUrl}'),
          ),
        ),
      );
    } else {
      // Static thumbnail image
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: videoService.thumbnailUrl.isNotEmpty
            ? Image.network(
                videoService.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.movie, color: Colors.white54),
                ),
              )
            : Container(
                color: Colors.grey[800],
                child: const Icon(Icons.movie, color: Colors.white54),
              ),
      );
    }
  }
} 