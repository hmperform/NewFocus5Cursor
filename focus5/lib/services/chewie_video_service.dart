import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';

/// A service class that manages video playback throughout the app,
/// supporting both mini player and full screen modes with seamless transitions.
class ChewieVideoService with ChangeNotifier {
  // Video player controllers
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  
  // Video metadata
  String _title = '';
  String _subtitle = '';
  String _thumbnailUrl = '';
  bool _isFullScreen = false;
  bool _isPlaying = false;
  bool _showMiniPlayer = false;
  String _videoUrl = '';
  MediaItem? _currentMediaItem;

  // Stream controller for position updates
  final StreamController<Duration> _positionStreamController = StreamController<Duration>.broadcast();
  Stream<Duration> get positionStream => _positionStreamController.stream;
  
  // Timer for position updates
  Timer? _positionTimer;

  // Getters
  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  String get title => _title;
  String get subtitle => _subtitle;
  String get thumbnailUrl => _thumbnailUrl;
  String get videoUrl => _videoUrl;
  bool get isFullScreen => _isFullScreen;
  bool get isPlaying => _isPlaying;
  bool get showMiniPlayer => _showMiniPlayer && !_isFullScreen;
  MediaItem? get currentMediaItem => _currentMediaItem;
  Duration get position => _videoController?.value.position ?? Duration.zero;
  Duration get duration => _videoController?.value.duration ?? Duration.zero;
  double get aspectRatio => _videoController?.value.aspectRatio ?? 16/9;

  // Initialize with video URL
  Future<void> initializePlayer({
    required String videoUrl,
    required String title,
    required String subtitle,
    String thumbnailUrl = '',
    MediaItem? mediaItem,
    Duration? startPosition,
  }) async {
    // Dispose existing controllers
    await _disposeControllers();
    
    _title = title;
    _subtitle = subtitle;
    _thumbnailUrl = thumbnailUrl;
    _videoUrl = videoUrl;
    _currentMediaItem = mediaItem;
    
    try {
      // Create video controller
      if (videoUrl.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else if (videoUrl.startsWith('asset')) {
        _videoController = VideoPlayerController.asset(videoUrl);
      } else {
        // Default to file
        _videoController = VideoPlayerController.asset(videoUrl);
      }
      
      // Initialize video controller
      await _videoController!.initialize();
      
      // Set volume and create position listener
      await _videoController!.setVolume(1.0);
      _startPositionTimer();
      
      // Set initial position if provided
      if (startPosition != null && startPosition > Duration.zero) {
        await _videoController!.seekTo(startPosition);
      }
      
      // Configure Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        placeholder: Center(
          child: CircularProgressIndicator(),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.green,
          handleColor: Colors.green,
          backgroundColor: Colors.grey[800]!,
          bufferedColor: Colors.grey,
        ),
        showOptions: false,
        hideControlsTimer: const Duration(seconds: 2),
        showControlsOnInitialize: false,
      );
      
      // Start playback
      await _videoController!.play();
      _isPlaying = true;
      _showMiniPlayer = true;
      
      // Cache video data
      _cacheVideoData();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing video: $e');
      await _disposeControllers();
      rethrow;
    }
  }
  
  // Start a timer to regularly update the current position
  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        _positionStreamController.add(_videoController!.value.position);
        
        // Update playing state if changed
        final isCurrentlyPlaying = _videoController!.value.isPlaying;
        if (_isPlaying != isCurrentlyPlaying) {
          _isPlaying = isCurrentlyPlaying;
          notifyListeners();
        }
      }
    });
  }

  // Toggle play/pause state
  Future<void> togglePlayPause() async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    if (_isPlaying) {
      await _videoController!.pause();
    } else {
      await _videoController!.play();
    }
    
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  // Regular seekTo method that delegates to the robust implementation
  Future<void> seekTo(Duration position) async {
    await robustSeekTo(position);
  }

  // Robust seek method that ensures the position is maintained by using pause/play technique
  Future<void> robustSeekTo(Duration position) async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    debugPrint('ROBUST_SEEK: Attempting to seek to ${position.inSeconds}.${position.inMilliseconds % 1000}s');
    
    // Save current playback state
    final wasPlaying = _videoController!.value.isPlaying;
    
    // Always pause before seeking (critical for seek stability)
    if (wasPlaying) {
      await _videoController!.pause();
    }
    
    // Perform the seek
    await _videoController!.seekTo(position);
    
    // Allow a small delay for the seek to complete
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Verify the position and retry if needed (max 3 times)
    int retryCount = 0;
    const maxRetries = 3;
    bool seekSuccessful = false;
    
    while (retryCount < maxRetries && !seekSuccessful) {
      final currentPosition = _videoController!.value.position;
      
      // Check if the seek was successful (with some tolerance)
      if ((currentPosition - position).inMilliseconds.abs() < 500) {
        seekSuccessful = true;
        debugPrint('ROBUST_SEEK: Seek successful on attempt ${retryCount + 1}');
      } else {
        retryCount++;
        debugPrint('ROBUST_SEEK: Retry $retryCount - current position is ${currentPosition.inSeconds}.${currentPosition.inMilliseconds % 1000}s');
        
        // Try again
        await _videoController!.seekTo(position);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    // Resume playback if it was playing before
    if (wasPlaying) {
      await _videoController!.play();
      
      // Set up a verification timer to ensure the position isn't lost after resuming playback
      Timer(const Duration(milliseconds: 300), () {
        if (_videoController != null && _videoController!.value.isInitialized) {
          final verifyPosition = _videoController!.value.position;
          
          // If position reverted substantially, try seeking one more time while playing
          if ((verifyPosition - position).inMilliseconds.abs() > 1000 && 
              verifyPosition.inMilliseconds < position.inMilliseconds) {
            debugPrint('ROBUST_SEEK: Position reverted after play, applying final correction');
            _videoController!.seekTo(position);
          }
        }
      });
    }
    
    // Update the position stream
    _positionStreamController.add(_videoController!.value.position);
    _cacheVideoData();
  }

  // Direct seek method - recreates the controller to enforce position
  Future<void> directSeekTo(Duration position) async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    debugPrint('DIRECT_SEEK: Attempting to seek to ${position.inSeconds}.${position.inMilliseconds % 1000}s');
    
    // Save current playback state and URL
    final wasPlaying = _videoController!.value.isPlaying;
    final videoUrl = _videoUrl;
    
    // Always pause before operations
    if (wasPlaying) {
      await _videoController!.pause();
    }
    
    try {
      // Dispose of the existing controllers
      if (_chewieController != null) {
        _chewieController!.dispose();
        _chewieController = null;
      }
      
      if (_videoController != null) {
        final oldController = _videoController;
        _videoController = null;
        await oldController!.dispose();
      }
      
      // Create a new controller with the specified position
      if (videoUrl.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
          ),
        );
      } else if (videoUrl.startsWith('asset')) {
        _videoController = VideoPlayerController.asset(videoUrl);
      } else {
        _videoController = VideoPlayerController.asset(videoUrl);
      }
      
      // Initialize and set position
      await _videoController!.initialize();
      await _videoController!.seekTo(position);
      
      // Create a new Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: wasPlaying,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        placeholder: Center(
          child: CircularProgressIndicator(),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.green,
          handleColor: Colors.green,
          backgroundColor: Colors.grey[800]!,
          bufferedColor: Colors.grey,
        ),
        showOptions: false,
        hideControlsTimer: const Duration(seconds: 2),
        showControlsOnInitialize: false,
      );
      
      // Resume playback if needed
      if (wasPlaying) {
        await _videoController!.play();
      }
      
      // Update position stream
      _positionStreamController.add(position);
      _cacheVideoData();
      
      // Notify listeners to rebuild UI
      notifyListeners();
      
      // Verify position
      await Future.delayed(const Duration(milliseconds: 300), () {
        if (_videoController != null && _videoController!.value.isInitialized) {
          final currentPos = _videoController!.value.position;
          debugPrint('DIRECT_SEEK: Position after recreation is ${currentPos.inSeconds}.${currentPos.inMilliseconds % 1000}s');
        }
      });
      
      return;
    } catch (e) {
      debugPrint('DIRECT_SEEK: Error during seek: $e');
      // If recreation fails, try normal seek
      await robustSeekTo(position);
    }
  }

  // Now let's update seekForward and seekBackward to use the direct seek
  Future<void> seekForward({int seconds = 10}) async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    final beforePosition = _videoController!.value.position;
    debugPrint('SEEK_FORWARD: Before position: ${beforePosition.inSeconds}.${beforePosition.inMilliseconds % 1000}s');
    
    final newPosition = _videoController!.value.position + Duration(seconds: seconds);
    // Make sure we don't go past the end of the video
    final cappedPosition = newPosition.inMilliseconds < duration.inMilliseconds 
        ? newPosition 
        : duration;
    
    debugPrint('SEEK_FORWARD: Target position: ${cappedPosition.inSeconds}.${cappedPosition.inMilliseconds % 1000}s');
    
    // Use our direct seek method for more reliability
    await directSeekTo(cappedPosition);
    
    // Log the immediate position after seeking
    final afterPosition = _videoController!.value.position;
    debugPrint('SEEK_FORWARD: After position: ${afterPosition.inSeconds}.${afterPosition.inMilliseconds % 1000}s');
    
    // Check again after a delay to see if position changed
    await Future.delayed(const Duration(milliseconds: 500), () {
      if (_videoController != null && _videoController!.value.isInitialized) {
        final delayedPosition = _videoController!.value.position;
        debugPrint('SEEK_FORWARD: Delayed position (after 500ms): ${delayedPosition.inSeconds}.${delayedPosition.inMilliseconds % 1000}s');
        
        if (delayedPosition.inMilliseconds < afterPosition.inMilliseconds - 1000) {
          debugPrint('SEEK_FORWARD ERROR: Position reverted from ${afterPosition.inSeconds}.${afterPosition.inMilliseconds % 1000}s to ${delayedPosition.inSeconds}.${delayedPosition.inMilliseconds % 1000}s');
        }
      }
    });
  }
  
  // Seek backward by specified seconds
  Future<void> seekBackward({int seconds = 10}) async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    final beforePosition = _videoController!.value.position;
    debugPrint('SEEK_BACKWARD: Before position: ${beforePosition.inSeconds}.${beforePosition.inMilliseconds % 1000}s');
    
    final newPosition = _videoController!.value.position - Duration(seconds: seconds);
    // Make sure we don't go before the start of the video
    final cappedPosition = newPosition.inMilliseconds > 0 
        ? newPosition 
        : Duration.zero;
    
    debugPrint('SEEK_BACKWARD: Target position: ${cappedPosition.inSeconds}.${cappedPosition.inMilliseconds % 1000}s');
    
    // Use our direct seek method for more reliability
    await directSeekTo(cappedPosition);
    
    // Log the immediate position after seeking
    final afterPosition = _videoController!.value.position;
    debugPrint('SEEK_BACKWARD: After position: ${afterPosition.inSeconds}.${afterPosition.inMilliseconds % 1000}s');
    
    // Check again after a delay to see if position changed
    await Future.delayed(const Duration(milliseconds: 500), () {
      if (_videoController != null && _videoController!.value.isInitialized) {
        final delayedPosition = _videoController!.value.position;
        debugPrint('SEEK_BACKWARD: Delayed position (after 500ms): ${delayedPosition.inSeconds}.${delayedPosition.inMilliseconds % 1000}s');
        
        if (delayedPosition.inMilliseconds < afterPosition.inMilliseconds - 1000 && delayedPosition.inMilliseconds != 0) {
          debugPrint('SEEK_BACKWARD ERROR: Position reverted from ${afterPosition.inSeconds}.${afterPosition.inMilliseconds % 1000}s to ${delayedPosition.inSeconds}.${delayedPosition.inMilliseconds % 1000}s');
        }
      }
    });
  }

  // Set fullscreen state
  void setFullScreen(bool isFullScreen) {
    if (_isFullScreen == isFullScreen) return;
    
    _isFullScreen = isFullScreen;
    notifyListeners();
    
    if (!isFullScreen) {
      _showMiniPlayer = true;
    }
    
    _cacheVideoData();
  }

  // Show/hide mini player
  void setShowMiniPlayer(bool show) {
    if (_showMiniPlayer == show) return;
    
    _showMiniPlayer = show;
    notifyListeners();
  }

  // Close player (stop playback but keep controller)
  Future<void> closePlayer() async {
    if (_videoController != null) {
      await _videoController!.pause();
      _isPlaying = false;
      _showMiniPlayer = false;
      notifyListeners();
      _cacheVideoData();
    }
  }

  // Dispose controllers
  Future<void> _disposeControllers() async {
    _positionTimer?.cancel();
    
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
    
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  // Cache current video data for persistence
  Future<void> _cacheVideoData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      prefs.setString('video_url', _videoUrl);
      prefs.setString('video_title', _title);
      prefs.setString('video_subtitle', _subtitle);
      prefs.setString('video_thumbnail', _thumbnailUrl);
      prefs.setInt('video_position', _videoController?.value.position.inMilliseconds ?? 0);
      prefs.setBool('video_playing', _isPlaying);
    } catch (e) {
      debugPrint('Error caching video data: $e');
    }
  }

  // Restore previous video session
  Future<bool> restorePreviousSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final videoUrl = prefs.getString('video_url');
      final title = prefs.getString('video_title');
      final subtitle = prefs.getString('video_subtitle');
      final thumbnail = prefs.getString('video_thumbnail');
      final position = prefs.getInt('video_position');
      final playing = prefs.getBool('video_playing');
      
      if (videoUrl != null && title != null) {
        await initializePlayer(
          videoUrl: videoUrl,
          title: title,
          subtitle: subtitle ?? '',
          thumbnailUrl: thumbnail ?? '',
          startPosition: position != null ? Duration(milliseconds: position) : null,
        );
        
        if (playing == false) {
          await _videoController?.pause();
          _isPlaying = false;
          notifyListeners();
        }
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error restoring video session: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _disposeControllers();
    _positionStreamController.close();
    super.dispose();
  }
} 