import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../services/basic_video_service.dart';

class BasicPlayerScreen extends StatefulWidget {
  const BasicPlayerScreen({Key? key}) : super(key: key);

  @override
  State<BasicPlayerScreen> createState() => _BasicPlayerScreenState();
}

class _BasicPlayerScreenState extends State<BasicPlayerScreen> {
  bool _showControls = true;
  Timer? _hideTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Force landscape mode for fullscreen videos
    _setFullScreenMode(true);
    
    // Auto-hide controls after a few seconds
    _resetHideTimer();
  }
  
  @override
  void dispose() {
    // Return to normal orientation
    _setFullScreenMode(false);
    _hideTimer?.cancel();
    super.dispose();
  }
  
  void _setFullScreenMode(bool isFullScreen) {
    if (isFullScreen) {
      // Enter full screen and force landscape
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Exit full screen and allow all orientations
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }
  
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _resetHideTimer();
      } else {
        _hideTimer?.cancel();
      }
    });
  }
  
  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<BasicVideoService>(
        builder: (context, videoService, child) {
          if (videoService.videoController == null || 
              !videoService.videoController!.value.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }
          
          return GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              children: [
                // Video player
                Center(
                  child: AspectRatio(
                    aspectRatio: videoService.videoController!.value.aspectRatio,
                    child: VideoPlayer(videoService.videoController!),
                  ),
                ),
                
                // Video controls overlay
                if (_showControls)
                  _buildControls(videoService),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildControls(BasicVideoService videoService) {
    final screenSize = MediaQuery.of(context).size;
    
    return GestureDetector(
      // Prevent the parent's tap from being triggered
      onTap: () {
        _resetHideTimer();
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top bar with title and close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Video title area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          videoService.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (videoService.subtitle.isNotEmpty)
                          Text(
                            videoService.subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            
            // Center area with playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rewind button
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  onPressed: () {
                    videoService.seekBackward(seconds: 10);
                    _resetHideTimer();
                  },
                ),
                
                const SizedBox(width: 16),
                
                // Play/Pause button
                IconButton(
                  iconSize: 56,
                  icon: Icon(
                    videoService.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    videoService.togglePlayPause();
                    _resetHideTimer();
                  },
                ),
                
                const SizedBox(width: 16),
                
                // Forward button
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  onPressed: () {
                    videoService.seekForward(seconds: 10);
                    _resetHideTimer();
                  },
                ),
              ],
            ),
            
            // Bottom bar with progress and other controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Custom progress bar
                  _buildProgressBar(videoService),
                  
                  const SizedBox(height: 8),
                  
                  // Time and fullscreen button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Current time / total time
                      Text(
                        '${_formatDuration(videoService.position)} / ${_formatDuration(videoService.duration)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      
                      // Volume button
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.white),
                        onPressed: () {
                          // TODO: Add volume controls
                          _resetHideTimer();
                        },
                      ),
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
  
  Widget _buildProgressBar(BasicVideoService videoService) {
    return StreamBuilder<Duration>(
      stream: videoService.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? videoService.position;
        final duration = videoService.duration;
        
        double value = 0.0;
        if (duration.inMilliseconds > 0) {
          value = position.inMilliseconds / duration.inMilliseconds;
        }
        
        return GestureDetector(
          onHorizontalDragStart: (details) {
            _hideTimer?.cancel();
          },
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final dx = details.localPosition.dx;
            final width = box.size.width;
            
            double newValue = dx / width;
            if (newValue < 0) newValue = 0;
            if (newValue > 1) newValue = 1;
            
            final newPosition = Duration(milliseconds: (newValue * duration.inMilliseconds).round());
            
            // Update the UI with current drag position
            setState(() {
              // Just update the UI, don't seek yet
              value = newValue;
            });
          },
          onHorizontalDragEnd: (details) {
            final newPosition = Duration(milliseconds: (value * duration.inMilliseconds).round());
            videoService.seekTo(newPosition);
            _resetHideTimer();
          },
          onTapUp: (details) {
            final box = context.findRenderObject() as RenderBox;
            final dx = details.localPosition.dx;
            final width = box.size.width;
            
            double newValue = dx / width;
            if (newValue < 0) newValue = 0;
            if (newValue > 1) newValue = 1;
            
            final newPosition = Duration(milliseconds: (newValue * duration.inMilliseconds).round());
            videoService.seekTo(newPosition);
            _resetHideTimer();
          },
          child: Container(
            height: 20,
            width: double.infinity,
            color: Colors.transparent,
            child: Center(
              child: Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Stack(
                  children: [
                    // Progress bar
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    // Draggable thumb
                    Positioned(
                      left: value * MediaQuery.of(context).size.width - 24,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
} 