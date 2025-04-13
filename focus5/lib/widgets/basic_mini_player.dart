import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../services/basic_video_service.dart';
import '../screens/basic_player_screen.dart';
import '../providers/audio_provider.dart';
import '../screens/home/audio_player_screen.dart';
import '../models/content_models.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _checkPlaybackState() {
    if (!mounted) return;
    
    final videoService = Provider.of<BasicVideoService>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    
    // Check video playback
    if (videoService.isPlaying && 
        videoService.videoController != null &&
        !videoService.videoController!.value.isPlaying) {
      videoService.videoController!.play();
    }
    
    // Check audio playback
    if (audioProvider.isPlaying && !audioProvider.audioPlayer.playing) {
      audioProvider.audioPlayer.play();
    }
    
    // Schedule next check
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _checkPlaybackState();
      }
    });
  }

  void _openFullScreenPlayer(BuildContext context, {bool isVideo = false}) {
    if (isVideo) {
      final videoService = Provider.of<BasicVideoService>(context, listen: false);
      if (videoService.videoController == null) return;
      
      videoService.setFullScreen(true);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const BasicPlayerScreen(),
        ),
      ).then((_) {
        if (mounted) {
          videoService.setFullScreen(false);
          _checkPlaybackState();
        }
      });
    } else {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final audio = audioProvider.currentAudio;
      if (audio == null) return;
      
      audioProvider.setFullScreenPlayerOpen(true);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(
            audio: DailyAudio(
              id: audio.id,
              title: audio.title,
              description: audio.description,
              audioUrl: audio.audioUrl,
              thumbnail: audio.imageUrl,
              slideshow1: audio.slideshowImages.isNotEmpty ? audio.slideshowImages[0] : '',
              slideshow2: audio.slideshowImages.length > 1 ? audio.slideshowImages[1] : '',
              slideshow3: audio.slideshowImages.length > 2 ? audio.slideshowImages[2] : '',
              creatorId: FirebaseFirestore.instance.doc('coaches/default'),
              creatorName: FirebaseFirestore.instance.doc('coaches/default'),
              focusAreas: [audio.subtitle ?? ''],
              durationMinutes: 10,
              xpReward: 50,
              universityExclusive: false,
              createdAt: DateTime.now(),
              datePublished: DateTime.now(),
            ),
            currentDay: 1,
          ),
        ),
      ).then((_) {
        if (mounted) {
          audioProvider.setFullScreenPlayerOpen(false);
          _checkPlaybackState();
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<BasicVideoService, AudioProvider>(
      builder: (context, videoService, audioProvider, child) {
        // Show video mini player
        if (videoService.videoController != null && 
            videoService.showMiniPlayer &&
            !videoService.isFullScreen) {
          return _buildGlassMorphicMiniPlayer(
            title: videoService.title,
            subtitle: videoService.subtitle,
            thumbnailWidget: _buildVideoThumbnail(videoService),
            isPlaying: videoService.isPlaying,
            onPlayPause: () => videoService.togglePlayPause(),
            onBackward: () => videoService.seekBackward(seconds: 10),
            onForward: () => videoService.seekForward(seconds: 10),
            onClose: () => videoService.closePlayer(),
            onTap: () => _openFullScreenPlayer(context, isVideo: true),
          );
        }
        
        // Show audio mini player
        if (audioProvider.currentAudio != null && 
            audioProvider.showMiniPlayer &&
            !audioProvider.isFullScreenPlayerOpen) {
          return _buildGlassMorphicMiniPlayer(
            title: audioProvider.title ?? '',
            subtitle: audioProvider.subtitle ?? '',
            thumbnailWidget: _buildAudioThumbnail(audioProvider),
            isPlaying: audioProvider.isPlaying,
            onPlayPause: () => audioProvider.togglePlayPause(),
            onBackward: () => audioProvider.seekRelative(const Duration(seconds: -10)),
            onForward: () => audioProvider.seekRelative(const Duration(seconds: 10)),
            onClose: () => audioProvider.closeMiniPlayer(),
            onTap: () => _openFullScreenPlayer(context),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGlassMorphicMiniPlayer({
    required String title,
    required String subtitle,
    required Widget thumbnailWidget,
    required bool isPlaying,
    required VoidCallback onPlayPause,
    required VoidCallback onBackward,
    required VoidCallback onForward,
    required VoidCallback onClose,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: widget.bottomPadding,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 64,
            width: screenWidth,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    // Thumbnail
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: thumbnailWidget,
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
                              title,
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
                              subtitle,
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
                    
                    // Control buttons
                    _buildControlButton(Icons.replay_10, onBackward),
                    _buildControlButton(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      onPlayPause,
                    ),
                    _buildControlButton(Icons.forward_10, onForward),
                    _buildControlButton(Icons.close, onClose),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildVideoThumbnail(BasicVideoService videoService) {
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
    }
    return const SizedBox.shrink();
  }

  Widget _buildAudioThumbnail(AudioProvider audioProvider) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        bottomLeft: Radius.circular(12),
      ),
      child: Image.network(
        audioProvider.imageUrl ?? '',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[900],
            child: const Icon(
              Icons.music_note,
              color: Colors.white54,
              size: 32,
            ),
          );
        },
      ),
    );
  }
} 