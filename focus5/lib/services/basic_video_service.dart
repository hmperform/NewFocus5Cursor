import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';

/// A service class that manages video playback using only the core video_player package
class BasicVideoService with ChangeNotifier {
  // Video player controller
  VideoPlayerController? _videoController;
  
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
  
  // Dispose method for cleanup
  @override
  void dispose() {
    _closePositionTimer();
    _disposeController();
    _positionStreamController.close();
    super.dispose();
  }

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
    await _disposeController();
    
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
      
      // Start playback
      await _videoController!.play();
      _isPlaying = true;
      _showMiniPlayer = true;
      
      // Cache video data
      _cacheVideoData();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing video: $e');
      await _disposeController();
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
  
  void _closePositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
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

  // Seek forward by specified seconds
  Future<void> seekForward({int seconds = 10}) async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    final current = _videoController!.value.position;
    final target = current + Duration(seconds: seconds);
    
    debugPrint('SEEK_FORWARD: Before position: ${current.inSeconds}.${current.inMilliseconds % 1000}s');
    debugPrint('SEEK_FORWARD: Target position: ${target.inSeconds}.${target.inMilliseconds % 1000}s');
    
    await seekTo(target);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_videoController != null && _videoController!.value.isInitialized) {
        final position = _videoController!.value.position;
        debugPrint('SEEK_FORWARD: Delayed position (after 500ms): ${position.inSeconds}.${position.inMilliseconds % 1000}s');
      }
    });
  }

  // Seek backward by specified seconds
  Future<void> seekBackward({int seconds = 10}) async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    final current = _videoController!.value.position;
    final target = current - Duration(seconds: seconds);
    
    // Ensure we don't go below 0
    final targetPosition = target.inMilliseconds < 0 
        ? Duration.zero 
        : target;
    
    await seekTo(targetPosition);
  }

  // Generic seek method
  Future<void> seekTo(Duration position) async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    debugPrint('SEEK: Attempting to seek to ${position.inSeconds}.${position.inMilliseconds % 1000}s');
    
    // Save current playback state
    final wasPlaying = _videoController!.value.isPlaying;
    
    try {
      // Pause before seeking for better accuracy
      if (wasPlaying) {
        await _videoController!.pause();
      }
      
      // Perform seek
      await _videoController!.seekTo(position);
      
      // Small delay to let seek complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Resume if it was playing
      if (wasPlaying) {
        await _videoController!.play();
      }
      
      // Notify position update
      _positionStreamController.add(_videoController!.value.position);
      _cacheVideoData();
      
    } catch (e) {
      debugPrint('Error during seek: $e');
      if (wasPlaying) {
        _videoController?.play();
      }
    }
  }

  // Set fullscreen state
  void setFullScreen(bool fullscreen) {
    _isFullScreen = fullscreen;
    notifyListeners();
  }

  // Close the player and clean up
  Future<void> closePlayer() async {
    _showMiniPlayer = false;
    notifyListeners();
    
    // Wait a bit to let animations complete before disposing
    await Future.delayed(const Duration(milliseconds: 300));
    await _disposeController();
  }

  // Dispose controllers
  Future<void> _disposeController() async {
    _closePositionTimer();
    
    try {
      if (_videoController != null) {
        await _videoController!.dispose();
        _videoController = null;
      }
    } catch (e) {
      debugPrint('Error disposing video controller: $e');
    }
    
    _isPlaying = false;
  }

  // Cache the current video data for possible restoration
  Future<void> _cacheVideoData() async {
    try {
      if (_videoUrl.isEmpty || _title.isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('last_video_url', _videoUrl);
      await prefs.setString('last_video_title', _title);
      await prefs.setString('last_video_subtitle', _subtitle);
      await prefs.setString('last_video_thumbnail', _thumbnailUrl);
      
      // Save position for resuming
      if (_videoController != null && _videoController!.value.isInitialized) {
        final position = _videoController!.value.position;
        if (position.inSeconds > 0) {
          await prefs.setInt('last_video_position', position.inMilliseconds);
        }
      }
    } catch (e) {
      debugPrint('Error caching video data: $e');
    }
  }
} 