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

// Data class to hold selected state for Selector2
class _MiniPlayerData {
  final bool shouldShowAudio;
  final bool shouldShowVideo;

  // Audio data
  final String? audioId; // Needed for debugging/key
  final String? audioTitle;
  final String? audioSubtitle;
  final String? audioImageUrl; // For thumbnail
  final bool isAudioPlaying;

  // Video data
  final String? videoTitle;
  final String? videoSubtitle;
  final VideoPlayerController? videoController; // For thumbnail
  final bool isVideoPlaying;

  _MiniPlayerData({
    required this.shouldShowAudio,
    required this.shouldShowVideo,
    this.audioId,
    this.audioTitle,
    this.audioSubtitle,
    this.audioImageUrl,
    required this.isAudioPlaying,
    this.videoTitle,
    this.videoSubtitle,
    this.videoController,
    required this.isVideoPlaying,
  });

  // Equality operator for Selector2 optimization
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MiniPlayerData &&
          runtimeType == other.runtimeType &&
          shouldShowAudio == other.shouldShowAudio &&
          shouldShowVideo == other.shouldShowVideo &&
          audioId == other.audioId &&
          audioTitle == other.audioTitle &&
          audioSubtitle == other.audioSubtitle &&
          audioImageUrl == other.audioImageUrl &&
          isAudioPlaying == other.isAudioPlaying &&
          videoTitle == other.videoTitle &&
          videoSubtitle == other.videoSubtitle &&
          // Comparing controllers directly might be problematic if internal state changes often.
          // Consider comparing controller existence or relevant value properties if needed.
          videoController?.textureId == other.videoController?.textureId &&
          isVideoPlaying == other.isVideoPlaying;

  @override
  int get hashCode => Object.hash(
        shouldShowAudio,
        shouldShowVideo,
        audioId,
        audioTitle,
        audioSubtitle,
        audioImageUrl,
        isAudioPlaying,
        videoTitle,
        videoSubtitle,
        videoController?.textureId, // Use a stable property for hash
        isVideoPlaying,
      );
}

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
      // Audio Logic
      debugPrint('[BasicMiniPlayer] _openFullScreenPlayer called for AUDIO.');
      final navigator = Navigator.of(context);
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final audio = audioProvider.currentAudio;
      if (audio == null) {
        debugPrint('[BasicMiniPlayer] _openFullScreenPlayer: audio is null, returning.');
        return;
      }
      debugPrint('[BasicMiniPlayer] _openFullScreenPlayer: Current audio ID: ${audio.id}');

      // Delay setting the provider state until after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (!mounted) return;
         debugPrint('[BasicMiniPlayer] _openFullScreenPlayer (post-frame): Setting fullScreenPlayerOpen(true).');
         audioProvider.setFullScreenPlayerOpen(true);

         // Create the DailyAudio object for the screen
         final dailyAudio = DailyAudio(
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
         );

         debugPrint('[BasicMiniPlayer] _openFullScreenPlayer (post-frame): Pushing AudioPlayerScreen route using saved navigator...');
         navigator.push(
           MaterialPageRoute(
             builder: (context) => AudioPlayerScreen(
               audio: dailyAudio,
               currentDay: 1,
             ),
           ),
         ).then((_) {
           debugPrint('[BasicMiniPlayer] _openFullScreenPlayer: AudioPlayerScreen was popped.');
         });
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Use Selector2 for optimized rebuilds
    return Selector2<AudioProvider, BasicVideoService, _MiniPlayerData>(
      selector: (context, audioProvider, videoService) {
        // Select only the data needed for the build logic
        final audio = audioProvider.currentAudio;
        final showAudio = audioProvider.showMiniPlayer &&
                           !audioProvider.isFullScreenPlayerOpen &&
                           audio != null;
        final showVideo = videoService.showMiniPlayer &&
                           !videoService.isFullScreen &&
                           videoService.videoController != null;

        return _MiniPlayerData(
          shouldShowAudio: showAudio,
          shouldShowVideo: showVideo,
          // Audio data (only if needed)
          audioId: showAudio ? audio?.id : null,
          audioTitle: showAudio ? audioProvider.title : null, // Or audio.title
          audioSubtitle: showAudio ? audioProvider.subtitle : null, // Or audio.subtitle
          audioImageUrl: showAudio ? audio?.imageUrl : null,
          isAudioPlaying: showAudio ? audioProvider.isPlaying : false,
          // Video data (only if needed)
          videoTitle: showVideo ? videoService.title : null,
          videoSubtitle: showVideo ? videoService.subtitle : null,
          videoController: showVideo ? videoService.videoController : null,
          isVideoPlaying: showVideo ? videoService.isPlaying : false,
        );
      },
      builder: (context, data, child) {
        // The builder now uses the selected data object
        debugPrint('[BasicMiniPlayer] Selector Build: showAudio=${data.shouldShowAudio}, showVideo=${data.shouldShowVideo}');

        if (data.shouldShowAudio) {
             debugPrint('[BasicMiniPlayer] Building audio mini player for ID: ${data.audioId}');
             return _buildGlassMorphicMiniPlayer(
                key: ValueKey('audio_${data.audioId}'), // Add key for stability
                title: data.audioTitle ?? '',
                subtitle: data.audioSubtitle ?? '',
                thumbnailWidget: _buildAudioThumbnailFromUrl(data.audioImageUrl),
                isPlaying: data.isAudioPlaying,
                onPlayPause: () => context.read<AudioProvider>().togglePlayPause(),
                onBackward: () => context.read<AudioProvider>().seekRelative(const Duration(seconds: -10)),
                onForward: () => context.read<AudioProvider>().seekRelative(const Duration(seconds: 10)),
                onClose: () => context.read<AudioProvider>().closeMiniPlayer(),
                onTap: () {
                  debugPrint('[BasicMiniPlayer] onTap detected for audio mini player.');
                  _openFullScreenPlayer(context);
                },
             );
        } else if (data.shouldShowVideo) {
           debugPrint('[BasicMiniPlayer] Building video mini player');
           return _buildGlassMorphicMiniPlayer(
             key: ValueKey('video_${data.videoController?.textureId}'), // Add key
             title: data.videoTitle ?? '',
             subtitle: data.videoSubtitle ?? '',
             thumbnailWidget: _buildVideoThumbnailFromController(data.videoController),
             isPlaying: data.isVideoPlaying,
             onPlayPause: () => context.read<BasicVideoService>().togglePlayPause(),
             onBackward: () => context.read<BasicVideoService>().seekBackward(seconds: 10),
             onForward: () => context.read<BasicVideoService>().seekForward(seconds: 10),
             onClose: () => context.read<BasicVideoService>().closePlayer(),
             onTap: () => _openFullScreenPlayer(context, isVideo: true),
           );
        } else {
           debugPrint('[BasicMiniPlayer] Building SizedBox.shrink (no mini player to show).');
           return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildGlassMorphicMiniPlayer({
    Key? key,
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
      key: key,
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
    final imageUrl = audioProvider.currentAudio?.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.music_note, size: 30),
        ),
      );
    } else {
      return const SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Icon(Icons.music_note, size: 30)));
    }
  }

  Widget _buildVideoThumbnailFromController(VideoPlayerController? controller) {
    if (controller != null && controller.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: SizedBox(
          width: 48,
          height: 48,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      );
    } else {
      // Placeholder for video thumbnail if needed
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(child: Icon(Icons.videocam, size: 30, color: Colors.white70)),
      );
    }
  }

  Widget _buildAudioThumbnailFromUrl(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.music_note, size: 30, color: Colors.white70),
        ),
      );
    } else {
      return const SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Icon(Icons.music_note, size: 30, color: Colors.white70)));
    }
  }
}

// Define a const placeholder widget
class _AudioPlaceholder extends StatelessWidget {
  const _AudioPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey[900],
      child: const Icon(
        Icons.music_note,
        color: Colors.white54,
        size: 32,
      ),
    );
  }
} 