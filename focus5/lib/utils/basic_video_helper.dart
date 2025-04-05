import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/basic_video_service.dart';
import '../models/content_models.dart';
import '../screens/basic_player_screen.dart';
import '../services/firebase_storage_service.dart';

class BasicVideoHelper {
  /// Preload a video from Firebase Storage without playing it
  static Future<void> preloadVideo({
    required BuildContext context,
    required String videoUrl,
  }) async {
    try {
      final videoService = Provider.of<BasicVideoService>(context, listen: false);
      final firebaseStorageService = FirebaseStorageService();
      
      // Get Firebase Storage download URL if needed
      final actualVideoUrl = await firebaseStorageService.getVideoUrl(videoUrl);
      
      if (actualVideoUrl.isNotEmpty) {
        // Preload the video
        await videoService.preloadVideo(actualVideoUrl);
      }
    } catch (e) {
      debugPrint('Error preloading video: $e');
    }
  }
  
  /// Preload multiple videos at once
  static Future<void> preloadVideos({
    required BuildContext context,
    required List<String> videoUrls,
  }) async {
    try {
      final videoService = Provider.of<BasicVideoService>(context, listen: false);
      final firebaseStorageService = FirebaseStorageService();
      final List<String> actualUrls = [];
      
      // Get all download URLs first
      for (final url in videoUrls) {
        final actualUrl = await firebaseStorageService.getVideoUrl(url);
        if (actualUrl.isNotEmpty) {
          actualUrls.add(actualUrl);
        }
      }
      
      // Then preload them all
      if (actualUrls.isNotEmpty) {
        await videoService.preloadVideos(actualUrls);
      }
    } catch (e) {
      debugPrint('Error preloading videos: $e');
    }
  }

  /// Play a video using Firebase Storage
  static Future<void> playVideo({
    required BuildContext context,
    required String videoUrl,
    String? title,
    String? subtitle,
    String? thumbnailUrl,
    MediaItem? mediaItem,
    bool openFullscreen = true,
  }) async {
    final videoService = Provider.of<BasicVideoService>(context, listen: false);
    
    // Show loading indicator while preparing video
    final loadingDialog = _showLoadingDialog(context);
    
    try {
      // Check if this video was already preloaded
      final firebaseStorageService = FirebaseStorageService();
      String actualVideoUrl = videoUrl;
      
      // Get Firebase Storage download URL if needed and not preloaded
      if (!videoService.isVideoPreloaded(videoUrl)) {
        actualVideoUrl = await firebaseStorageService.getVideoUrl(videoUrl);
        
        if (actualVideoUrl.isEmpty) {
          // Hide loading dialog
          Navigator.of(context, rootNavigator: true).pop();
          
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load video. Please try again later.')),
          );
          return;
        }
      }
      
      // Initialize the video player
      await videoService.initializePlayer(
        videoUrl: actualVideoUrl,
        title: title ?? 'Video',
        subtitle: subtitle ?? '',
        thumbnailUrl: thumbnailUrl ?? '',
        mediaItem: mediaItem,
      );
      
      // Hide loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      // Open fullscreen player if requested
      if (openFullscreen) {
        videoService.setFullScreen(true);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const BasicPlayerScreen(),
          ),
        ).then((_) {
          videoService.setFullScreen(false);
        });
      }
    } catch (e) {
      // Hide loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing video: ${e.toString()}')),
      );
    }
  }
  
  /// Continue playing current video in fullscreen
  static void openFullscreenPlayer(BuildContext context) {
    final videoService = Provider.of<BasicVideoService>(context, listen: false);
    
    if (videoService.videoController == null) return;
    
    videoService.setFullScreen(true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BasicPlayerScreen(),
      ),
    ).then((_) {
      videoService.setFullScreen(false);
    });
  }
  
  /// Show a loading dialog while the video is being prepared
  static AlertDialog _showLoadingDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
    
    return alert;
  }
} 