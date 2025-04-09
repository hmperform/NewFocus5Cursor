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
    Function(String mediaId)? onMediaCompleted,
  }) async {
    // Create a stable context reference
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    final navigatorContext = context;
    final videoService = Provider.of<BasicVideoService>(navigatorContext, listen: false);
    
    // Store BuildContext state to check validity later
    final isMounted = Navigator.of(navigatorContext).mounted;
    
    // Set the completion callback if provided
    if (onMediaCompleted != null) {
      videoService.setCompletionCallback(onMediaCompleted);
    }
    
    bool success = false;

    try {
      // Check if this video was already preloaded
      final firebaseStorageService = FirebaseStorageService();
      String actualVideoUrl = videoUrl;
      
      // Get Firebase Storage download URL if needed and not preloaded
      if (!videoService.isVideoPreloaded(videoUrl)) {
        actualVideoUrl = await firebaseStorageService.getVideoUrl(videoUrl);
        
        if (actualVideoUrl.isEmpty) {
          // Simply navigate back since we can't display the video
          if (isMounted && Navigator.of(navigatorContext).canPop()) {
            Navigator.of(navigatorContext).pop();
          }
          return;
        }
      }

      // Initialize the video player
      success = await videoService.initializePlayer(
        videoUrl: actualVideoUrl,
        title: title ?? 'Video',
        subtitle: subtitle ?? '',
        thumbnailUrl: thumbnailUrl ?? '',
        mediaItem: mediaItem,
      );

      if (!success) {
        // Handle failure gracefully
        if (isMounted && Navigator.of(navigatorContext).canPop()) {
          Navigator.of(navigatorContext).pop();
        }
        return;
      }

      // Set up completion tracking
      if (mediaItem != null && success) {
        videoService.setCompletionCallback(onMediaCompleted ?? (_) {});
      }

      // Open in fullscreen if requested and successful
      if (openFullscreen && success) {
        videoService.setFullScreen(true);
        
        // Navigate to the BasicPlayerScreen
        if (isMounted) {
          await Navigator.push(
            navigatorContext,
            MaterialPageRoute(
              builder: (context) => const BasicPlayerScreen(),
            ),
          );
          
          // Reset fullscreen state after returning
          videoService.setFullScreen(false);
          
          // Always navigate back after the video completes
          if (Navigator.of(navigatorContext).canPop()) {
            Navigator.of(navigatorContext).pop();
          }
        }
      }
    } catch (e) {
      debugPrint('Error playing video: $e');
      
      // Ensure we navigate back on error
      if (isMounted && Navigator.of(navigatorContext).canPop()) {
        Navigator.of(navigatorContext).pop();
      }
    }
  }

  // Helper method to show error dialog - make it context-safe
  static void _showErrorDialog(BuildContext context, String message) {
    // Check if context is still valid before showing dialog
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
      // Context is not valid, just log the error
      debugPrint('Cannot show error dialog: $message (context is no longer valid)');
      return;
    }
    
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // If dialog fails, just log the error
      debugPrint('Failed to show error dialog: $e - Original error: $message');
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
} 