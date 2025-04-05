import 'dart:async';
import 'dart:ui';  // Add this import for ImageFilter
import 'dart:math' as math; // Add this import for math.max
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
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  BasicVideoService? _videoService;
  
  @override
  void initState() {
    super.initState();
    
    // Force landscape mode for fullscreen videos
    _setFullScreenMode(true);
    
    // Auto-hide controls after a few seconds
    _resetHideTimer();
    
    // Store video service reference for later use in dispose
    _videoService = Provider.of<BasicVideoService>(context, listen: false);
    
    // Current position will be updated by the video service directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentPosition = _videoService!.position;
        });
        
        // Subscribe to position updates
        _positionSubscription = _videoService!.positionStream.listen((position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    // Return to normal orientation without stopping playback
    _setFullScreenMode(false);
    _hideTimer?.cancel();
    _positionSubscription?.cancel();
    
    // Store the isPlaying state before disposing
    final isCurrentlyPlaying = _videoService?.isPlaying ?? false;
    
    // Complete dispose first
    super.dispose();
    
    // Then schedule mini player visibility update for next frame
    if (_videoService != null && isCurrentlyPlaying) {
      // Use microtask to avoid widget tree locked errors
      Future.microtask(() {
        _videoService!.setMiniPlayerVisibility(true);
      });
    }
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
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
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
          
          return Stack(
            children: [
              // Video player (full screen with cover fit)
              AbsorbPointer(
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: videoService.videoController!.value.size.width,
                      height: videoService.videoController!.value.size.height,
                      child: VideoPlayer(videoService.videoController!),
                    ),
                  ),
                ),
              ),
              
              // Transparent overlay for tap detection
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleControls,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              
              // Simple video controls overlay
              if (_showControls)
                _buildSimpleControls(videoService),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSimpleControls(BasicVideoService videoService) {
    final duration = videoService.duration;
    final position = _currentPosition;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.2), // Light shading for controls visibility
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top bar - just a close button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildGlassButton(
                  icon: Icons.close,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          
          // Bottom section with playback controls and time indicators
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row of controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back 10 seconds
                      _buildGlassButton(
                        icon: Icons.replay_10_rounded,
                        onTap: () => videoService.seekBackward(seconds: 10),
                      ),
                      
                      const SizedBox(width: 32),
                      
                      // Play/Pause (larger)
                      _buildGlassButton(
                        icon: videoService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 48,
                        onTap: () => videoService.togglePlayPause(),
                      ),
                      
                      const SizedBox(width: 32),
                      
                      // Forward 10 seconds
                      _buildGlassButton(
                        icon: Icons.forward_10_rounded,
                        onTap: () => videoService.seekForward(seconds: 10),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Time indicators (without slider)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGlassButton({
    required IconData icon,
    double size = 36,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        _resetHideTimer();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size * 1.5,
            height: size * 1.5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: size,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 