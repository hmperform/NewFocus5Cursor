import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/basic_video_service.dart';
import '../models/content_models.dart';
import '../screens/basic_player_screen.dart';

class BasicVideoHelper {
  /// Play a video using the BasicVideoService
  static Future<void> playVideo({
    required BuildContext context,
    required String videoUrl,
    required String title,
    required String subtitle,
    String? thumbnailUrl,
    MediaItem? mediaItem,
    bool openFullscreen = true,
  }) async {
    final videoService = Provider.of<BasicVideoService>(context, listen: false);
    
    // Initialize the video player
    await videoService.initializePlayer(
      videoUrl: videoUrl,
      title: title,
      subtitle: subtitle,
      thumbnailUrl: thumbnailUrl ?? '',
      mediaItem: mediaItem,
    );
    
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