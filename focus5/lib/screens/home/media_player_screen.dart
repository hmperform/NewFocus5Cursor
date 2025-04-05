import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart' as progress_bar;
import 'dart:async';
import 'package:provider/provider.dart';

import '../../providers/media_provider.dart';
import '../../models/content_models.dart';

class MediaPlayerScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String mediaUrl;
  final String? imageUrl;
  final MediaItem? mediaItem;
  final MediaType mediaType;

  const MediaPlayerScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.mediaUrl,
    required this.mediaType,
    this.imageUrl,
    this.mediaItem,
  }) : super(key: key);

  @override
  State<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen> {
  late MediaProvider _mediaProvider;
  bool _showControls = true;
  bool _disposed = false;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize media after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      _mediaProvider.setFullScreenPlayerOpen(true);
      _initializeMedia();
      
      // We're removing the auto-hide functionality to keep controls visible
    });
  }

  Future<void> _initializeMedia() async {
    try {
      await _mediaProvider.startMedia(
        widget.title,
        widget.subtitle,
        widget.mediaUrl,
        widget.imageUrl ?? 'https://picsum.photos/800/800?random=42',
        widget.mediaType,
        mediaData: widget.mediaItem,
      );
    } catch (e) {
      debugPrint('Error initializing media: $e');
      if (mounted) {
        // On error, notify the user but don't close the screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing media: ${e.toString().split(':').first}'),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Make sure controls stay visible so the user can go back
        setState(() {
          _showControls = true;
        });
      }
    }
  }

  void _toggleControls() {
    // Keep this method but make it just toggle the controls on/off without auto-hiding
    if (widget.mediaType == MediaType.video) {
      setState(() {
        _showControls = !_showControls;
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _playbackTimer?.cancel();
    
    // Don't pause media when leaving, just update the full screen state
    // and be sure this doesn't happen during widget disposal
    if (_mediaProvider != null) {
      final provider = _mediaProvider;
      Future.microtask(() {
        // This will update the UI state without affecting playback
        provider?.setFullScreenPlayerOpen(false);
      });
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media content area - makes the whole area tappable
          GestureDetector(
            onTap: _toggleControls,
            child: Center(
              child: widget.mediaType == MediaType.video
                  ? _buildVideoPlayer()
                  : _buildAudioPlayer(),
            ),
          ),
          
          // Always show the back button at the top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Back button - always visible
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Only show title if controls are visible
                  if (_showControls)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.subtitle,
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
                ],
              ),
            ),
          ),
          
          // Always show playback controls at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildPlaybackControls(),
          ),
          
          // Show the full controls overlay if _showControls is true
          if (_showControls && widget.mediaType == MediaType.video)
            _buildFullScreenControls(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        if (provider.isBuffering) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        } else if (provider.videoController != null && 
                  provider.videoController!.value.isInitialized) {
          return AspectRatio(
            aspectRatio: provider.videoController!.value.aspectRatio,
            child: VideoPlayer(provider.videoController!),
          );
        } else {
          // Show fallback UI in case of error
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "We're having trouble playing this video. The video format may not be supported in your browser.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Image.network(
                  widget.imageUrl ?? 'https://picsum.photos/500/300?random=42',
                  fit: BoxFit.cover,
                  width: 280,
                  height: 160,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 280,
                      height: 160,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.videocam_off,
                        color: Colors.white54,
                        size: 48,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildAudioPlayer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Album artwork
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Consumer<MediaProvider>(
        builder: (context, provider, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              progress_bar.ProgressBar(
                progress: Duration(seconds: provider.currentPosition.toInt()),
                buffered: Duration(seconds: provider.currentPosition.toInt()),
                total: Duration(seconds: provider.totalDuration > 0 
                    ? provider.totalDuration.toInt() 
                    : 100),
                onSeek: (duration) => provider.seekTo(duration.inSeconds.toDouble()),
                thumbColor: const Color(0xFFB4FF00),
                progressBarColor: const Color(0xFFB4FF00),
                baseBarColor: Colors.white24,
                bufferedBarColor: Colors.white38,
                timeLabelTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Rewind button
                  IconButton(
                    icon: const Icon(Icons.replay_10, 
                      color: Colors.white, size: 32),
                    onPressed: () {
                      final newPosition = (provider.currentPosition - 10)
                          .clamp(0.0, provider.totalDuration);
                      provider.seekTo(newPosition);
                    },
                  ),
                  
                  // Play/pause button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFB4FF00).withOpacity(0.9),
                    ),
                    child: IconButton(
                      iconSize: 42,
                      icon: Icon(
                        provider.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                      ),
                      onPressed: () => provider.togglePlayPause(),
                    ),
                  ),
                  
                  // Forward button
                  IconButton(
                    icon: const Icon(Icons.forward_10, 
                      color: Colors.white, size: 32),
                    onPressed: () {
                      final newPosition = (provider.currentPosition + 10)
                          .clamp(0.0, provider.totalDuration);
                      provider.seekTo(newPosition);
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Full screen overlay controls
  Widget _buildFullScreenControls() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with title (Back button is handled separately)
            const SizedBox(height: 60), // Space for the back button
            
            const Spacer(),
            
            // Bottom area is reserved for the permanent playback controls
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
} 