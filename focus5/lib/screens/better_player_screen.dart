import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:focus5/services/better_video_service.dart';
import 'package:better_player/better_player.dart';

class BetterPlayerScreen extends StatefulWidget {
  const BetterPlayerScreen({Key? key}) : super(key: key);

  @override
  State<BetterPlayerScreen> createState() => _BetterPlayerScreenState();
}

class _BetterPlayerScreenState extends State<BetterPlayerScreen> {
  late BetterVideoService _videoService;
  
  @override
  void initState() {
    super.initState();
    _setFullScreenMode(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _videoService = Provider.of<BetterVideoService>(context, listen: false);
    
    // Configure player for full screen
    if (_videoService.controller != null) {
      // Ensure video is playing if it should be
      if (_videoService.isPlaying && !_videoService.controller!.isPlaying()!) {
        _videoService.controller!.play();
      }
      
      // Update player configuration for full screen
      _videoService.controller!.setControlsEnabled(true);
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
    // Exit full screen mode
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
        body: Consumer<BetterVideoService>(
          builder: (context, videoService, child) {
            if (videoService.controller == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return _buildVideoPlayer(videoService);
          },
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(BetterVideoService videoService) {
    final size = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    // For proper full-screen video in any orientation
    return Stack(
      children: [
        // Video Player
        LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Container(
                width: isPortrait ? size.width : null,
                height: isPortrait ? null : size.height,
                child: AspectRatio(
                  aspectRatio: isPortrait
                      ? videoService.controller!.videoPlayerController!.value.aspectRatio
                      : videoService.controller!.videoPlayerController!.value.aspectRatio,
                  child: BetterPlayer(
                    controller: videoService.controller!,
                  ),
                ),
              ),
            );
          },
        ),
        
        // Custom back button overlay in case native controls are hidden
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
      ],
    );
  }
} 