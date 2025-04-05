import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/better_video_service.dart';
import '../models/content_models.dart';
import '../screens/better_player_screen.dart';

class VideoHelper {
  /// Play a video using the BetterVideoService
  static Future<void> playVideo({
    required BuildContext context,
    required String videoUrl,
    required String title,
    required String subtitle,
    String? thumbnailUrl,
    MediaItem? mediaItem,
    bool openFullscreen = true,
  }) async {
    final videoService = Provider.of<BetterVideoService>(context, listen: false);
    
    // Initialize the player with the video
    await videoService.initializePlayer(
      videoUrl: videoUrl,
      title: title,
      subtitle: subtitle,
      thumbnailUrl: thumbnailUrl ?? '',
      startPosition: Duration.zero,
    );
    
    // Open fullscreen player if requested
    if (openFullscreen) {
      videoService.setFullScreen(true);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const BetterPlayerScreen(),
        ),
      ).then((_) {
        // Reset fullscreen flag when returning
        videoService.setFullScreen(false);
      });
    }
  }
  
  /// Continue playing an existing video in fullscreen
  static void openFullscreenPlayer(BuildContext context) {
    final videoService = Provider.of<BetterVideoService>(context, listen: false);
    
    if (videoService.controller == null) return;
    
    videoService.setFullScreen(true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BetterPlayerScreen(),
      ),
    ).then((_) {
      videoService.setFullScreen(false);
    });
  }
} 