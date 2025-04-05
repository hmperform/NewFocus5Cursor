import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/media_provider.dart';
import 'package:focus5/models/content_models.dart';
import 'package:video_player/video_player.dart';
import 'package:focus5/widgets/custom_video_controls.dart';

class MediaPlayerScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String mediaUrl;
  final String? imageUrl;
  final MediaType mediaType;
  final MediaItem? mediaItem;
  final double startPosition;

  const MediaPlayerScreen({
    Key? key, 
    required this.title,
    required this.subtitle,
    required this.mediaUrl,
    required this.mediaType,
    this.imageUrl,
    this.mediaItem,
    this.startPosition = 0.0,
  }) : super(key: key);

  @override
  State<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen> {
  MediaProvider? _mediaProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setFullScreenMode(true);
      
      // Log start position for debugging
      debugPrint('🔴 Media player opening with startPosition: ${widget.startPosition}');
      
      // Initialize media in the provider
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      mediaProvider.setFullScreenPlayerOpen(true);
      
      // Start media playback
      mediaProvider.startMedia(
        widget.title,
        widget.subtitle,
        widget.mediaUrl,
        widget.imageUrl ?? 'https://picsum.photos/800/800?random=42',
        widget.mediaType,
        mediaData: widget.mediaItem,
        startPosition: widget.startPosition,
      ).then((_) {      
        // Verify position after initialization 
        debugPrint('🔴 Media initialized, current position: ${mediaProvider.currentPosition}');
      }).catchError((error) {
        debugPrint("🔴 Error starting media in MediaPlayerScreen: $error");
        // Handle error, maybe show a message
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store the provider reference for safe usage in dispose
    _mediaProvider = Provider.of<MediaProvider>(context, listen: false);
  }

  @override
  void dispose() {
    // Ensure we set the mode back to normal
    _setFullScreenMode(false);
    
    // IMPORTANT: First update MediaProvider state before disposing FlickManager
    if (_mediaProvider != null) {
      // Stop listening for video position changes before disposing
      _mediaProvider!.pauseNotifications();
    }

    super.dispose();
  }

  void _setFullScreenMode(bool isFullScreen) {
    if (isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _handleBackPress() {
    // Use the stored provider reference for safety
    final mediaProvider = _mediaProvider;
    
    if (mediaProvider == null) {
      // If provider not available, just exit
      Navigator.of(context).pop();
      return;
    }
    
    // CRITICAL: Record current play state before transition
    final wasPlaying = mediaProvider.isPlaying;
    final currentPosition = mediaProvider.currentPosition;
    
    // Log the current state for debugging
    debugPrint('🔴 Exiting full screen, isPlaying: $wasPlaying, position: $currentPosition');
    
    // THEN set fullscreen to false AFTER ensuring playback continues
    mediaProvider.setFullScreenPlayerOpen(false);
    
    // Exit the screen
    Navigator.of(context).pop();
  }

  Widget _buildVideoPlayer(MediaProvider mediaProvider) {
    if (mediaProvider.videoController == null) {
      debugPrint('Video player screen: videoController is null, showing loading animation');
      return _buildLoadingAnimation();
    }
    
    if (!mediaProvider.videoController!.value.isInitialized) {
      debugPrint('Video player screen: videoController not initialized, showing loading animation');
      return _buildLoadingAnimation();
    }
    
    debugPrint('Video player: videoController is initialized with duration: ${mediaProvider.videoController!.value.duration.inSeconds}s, isPlaying: ${mediaProvider.videoController!.value.isPlaying}');

    // Calculate video dimensions to fill screen
    final size = MediaQuery.of(context).size;
    final videoRatio = mediaProvider.videoController!.value.aspectRatio;
    final screenRatio = size.width / size.height;
    
    // Determine dimensions to fill screen while keeping aspect ratio
    double videoWidth;
    double videoHeight;
    
    // IMPROVED LAYOUT: Always fill the screen width in portrait mode
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    if (isPortrait) {
      // In portrait, always fill width and zoom if needed
      videoWidth = size.width;
      videoHeight = videoWidth / videoRatio;
      
      // If video height is less than screen height, scale up to fill (zoom in)
      if (videoHeight < size.height) {
        final scale = size.height / videoHeight;
        videoHeight = size.height;
        videoWidth = videoWidth * scale;
      }
    } else {
      // In landscape, use the original logic
      if (screenRatio > videoRatio) {
        // Screen is wider than video, so fill by width
        videoWidth = size.width;
        videoHeight = videoWidth / videoRatio;
      } else {
        // Screen is taller than video, so fill by height
        videoHeight = size.height;
        videoWidth = videoHeight * videoRatio;
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Display
        Center(
          child: ClipRect(  // Add ClipRect to prevent overflow
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: VideoPlayer(mediaProvider.videoController!),
            ),
          ),
        ),
        
        // Custom Controls layer
        CustomVideoControls(onClose: _handleBackPress),
        
        // Loading overlay
        if (mediaProvider.isBuffering) // Keep loading overlay if needed
          _buildLoadingAnimation(),
      ],
    );
  }

  Widget _buildLoadingAnimation() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBackPress();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<MediaProvider>(
          builder: (context, mediaProvider, child) {
            if (mediaProvider.isBuffering) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (widget.mediaType == MediaType.video) {
              return _buildVideoPlayer(mediaProvider);
            } else {
              // For audio, just show a simple interface
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Album artwork
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          widget.imageUrl ?? 'https://picsum.photos/800/800?random=42',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white54,
                                size: 80,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Simple play/pause button
                    IconButton(
                      icon: Icon(
                        mediaProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 64,
                      ),
                      onPressed: () => mediaProvider.togglePlayPause(),
                    ),
                    
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _handleBackPress,
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
} 