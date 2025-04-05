import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import '../services/chewie_video_service.dart';

class ChewiePlayerScreen extends StatefulWidget {
  const ChewiePlayerScreen({Key? key}) : super(key: key);

  @override
  State<ChewiePlayerScreen> createState() => _ChewiePlayerScreenState();
}

class _ChewiePlayerScreenState extends State<ChewiePlayerScreen> {
  late ChewieVideoService _videoService;
  
  @override
  void initState() {
    super.initState();
    _setFullScreenMode(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _videoService = Provider.of<ChewieVideoService>(context, listen: false);
    
    // Ensure video is playing if it should be
    if (_videoService.isPlaying && 
        _videoService.videoController != null && 
        !_videoService.videoController!.value.isPlaying) {
      _videoService.videoController!.play();
    }
  }

  @override
  void dispose() {
    _setFullScreenMode(false);
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
    _videoService.setFullScreen(false);
    Navigator.of(context).pop();
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
        body: Consumer<ChewieVideoService>(
          builder: (context, videoService, child) {
            if (videoService.chewieController == null || 
                videoService.videoController == null ||
                !videoService.videoController!.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return _buildVideoPlayer(videoService);
          },
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(ChewieVideoService videoService) {
    final size = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    // Create a custom Chewie controller specifically for fullscreen
    if (videoService.chewieController != null) {
      return Stack(
        children: [
          // Video Player
          Center(
            child: AspectRatio(
              aspectRatio: isPortrait ? videoService.aspectRatio : videoService.aspectRatio,
              child: Chewie(
                controller: videoService.chewieController!,
              ),
            ),
          ),
          
          // Custom back button (in case system buttons are hidden)
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: _handleBackPress,
              ),
            ),
          ),
          
          // Add custom seek buttons (positioned differently based on orientation)
          Positioned(
            bottom: isPortrait ? 70 : 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Backward 10 seconds button
                Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      videoService.seekBackward(seconds: 10);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.replay_10, 
                        color: Colors.white,
                        size: isPortrait ? 36 : 24,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: isPortrait ? 80 : 40),
                
                // Forward 10 seconds button
                Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      videoService.seekForward(seconds: 10);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.forward_10,
                        color: Colors.white, 
                        size: isPortrait ? 36 : 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return const Center(
        child: Text(
          'Error loading video player',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }
} 