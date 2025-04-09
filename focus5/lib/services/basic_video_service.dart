import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';
import '../services/firebase_storage_service.dart';
import '../services/media_completion_service.dart';

/// A service class that manages video playback using only the core video_player package
class BasicVideoService with ChangeNotifier {
  // Video player controller
  VideoPlayerController? _videoController;
  
  // Cache for preloaded controllers
  final Map<String, VideoPlayerController> _preloadedControllers = {};
  
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

  // Completion callback
  Function(String mediaId)? _completionCallback;
  
  // Media completion service
  final MediaCompletionService _mediaCompletionService = MediaCompletionService();
  
  // Completion state tracking
  bool _hasMarkedAsCompleted = false;

  // Forward skip limit tracking
  int _forwardSkipCount = 0;
  final int _maxForwardSkips = 10;

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
  bool get isInitialized => _videoController != null && _videoController!.value.isInitialized;
  bool get isBuffering => _videoController != null && _videoController!.value.isBuffering;
  int get forwardSkipCount => _forwardSkipCount;
  bool get hasReachedForwardSkipLimit => _forwardSkipCount >= _maxForwardSkips;
  
  // Check if a video is already preloaded
  bool isVideoPreloaded(String videoUrl) {
    return _preloadedControllers.containsKey(videoUrl);
  }
  
  // Explicitly set mini player visibility
  void setMiniPlayerVisibility(bool show) {
    _showMiniPlayer = show;
    notifyListeners();
  }

  // Dispose method for cleanup
  @override
  void dispose() {
    _closePositionTimer();
    _disposeController();
    
    // Clean up all preloaded controllers
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _preloadedControllers.clear();
    
    _positionStreamController.close();
    super.dispose();
  }

  // Preload a video without playing it
  Future<void> preloadVideo(String videoUrl) async {
    if (_preloadedControllers.containsKey(videoUrl)) {
      // Already preloaded
      return;
    }
    
    try {
      debugPrint('Preloading video: $videoUrl');
      VideoPlayerController controller;
      
      if (videoUrl.startsWith('http')) {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else if (videoUrl.startsWith('asset')) {
        controller = VideoPlayerController.asset(
          videoUrl,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else if (videoUrl.startsWith('gs://')) {
        // Handle Firebase Storage URLs
        try {
          final firebaseStorageService = FirebaseStorageService();
          final downloadUrl = await firebaseStorageService.getVideoUrl(videoUrl);
          if (downloadUrl.isNotEmpty) {
            controller = VideoPlayerController.networkUrl(
              Uri.parse(downloadUrl),
              videoPlayerOptions: VideoPlayerOptions(
                mixWithOthers: false,
                allowBackgroundPlayback: false,
              ),
            );
          } else {
            throw Exception('Failed to get download URL for Firebase Storage video');
          }
        } catch (e) {
          debugPrint('Error getting Firebase Storage URL: $e');
          return; // Skip preloading on error
        }
      } else {
        // Default to file
        controller = VideoPlayerController.asset(
          videoUrl,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      }
      
      // Initialize controller without playing
      await controller.initialize();
      
      // Store in preloaded controllers
      _preloadedControllers[videoUrl] = controller;
      
      debugPrint('Video preloaded successfully: $videoUrl');
    } catch (e) {
      debugPrint('Error preloading video: $e');
    }
  }
  
  // Preload a set of videos (for batch preloading)
  Future<void> preloadVideos(List<String> videoUrls) async {
    for (final url in videoUrls) {
      await preloadVideo(url);
    }
  }

  // Initialize with video URL, using preloaded controller if available
  // Returns true if initialization was successful, false otherwise.
  Future<bool> initializePlayer({
    required String videoUrl,
    required String title,
    required String subtitle,
    required String thumbnailUrl,
    MediaItem? mediaItem,
    Duration? startPosition,
  }) async {
    // Clean up any existing controller first
    await _disposeController();
    
    // Reset forward skip counter for new video
    _forwardSkipCount = 0;
    _hasMarkedAsCompleted = false;
    
    // Set video metadata
    _videoUrl = videoUrl;
    _title = title;
    _subtitle = subtitle;
    _thumbnailUrl = thumbnailUrl;
    _currentMediaItem = mediaItem;
    
    try {
      // Check if we have a preloaded controller
      if (_preloadedControllers.containsKey(videoUrl)) {
        debugPrint('Using preloaded controller for: $videoUrl');
        _videoController = _preloadedControllers.remove(videoUrl);
        
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
        return true; // Initialization successful
      }
      
      // No preloaded controller, create a new one
      if (videoUrl.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else if (videoUrl.startsWith('asset')) {
        _videoController = VideoPlayerController.asset(
          videoUrl,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else if (videoUrl.startsWith('gs://')) {
        // Handle Firebase Storage URLs
        try {
          final firebaseStorageService = FirebaseStorageService();
          final downloadUrl = await firebaseStorageService.getVideoUrl(videoUrl);
          if (downloadUrl.isNotEmpty) {
            _videoController = VideoPlayerController.networkUrl(
              Uri.parse(downloadUrl),
              videoPlayerOptions: VideoPlayerOptions(
                mixWithOthers: false,
                allowBackgroundPlayback: false,
              ),
            );
          } else {
            throw Exception('Failed to get download URL for Firebase Storage video');
          }
        } catch (e) {
          debugPrint('Error getting Firebase Storage URL: $e');
          // Don't use a placeholder, just fail initialization
          // _videoController = VideoPlayerController.asset('assets/videos/placeholder.mp4');
          _videoController = null; // Ensure controller is null on error
        }
      } else {
        // Default to file (or handle other cases if needed)
        // Consider if this case is actually expected/possible
        try {
             _videoController = VideoPlayerController.asset(
              videoUrl,
              videoPlayerOptions: VideoPlayerOptions(
                mixWithOthers: false,
                allowBackgroundPlayback: false,
              ),
             );
        } catch (e) {
             debugPrint('Error initializing asset/file video: $e');
             _videoController = null;
        }
      }
      
      // If controller couldn't be created (e.g., Firebase error)
      if (_videoController == null) {
          _cleanUpOnError();
          return false;
      }

      // Initialize video controller
      await _videoController!.initialize();
      
      // Set volume and create position listener
      await _videoController!.setVolume(1.0); // Standard volume to avoid distortion
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
      return true; // Initialization successful
      
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      _cleanUpOnError();
      return false; // Initialization failed
    }
  }
  
  // Start a timer to regularly update the current position
  void _startPositionTimer() {
    _closePositionTimer();
    
    // Create a timer that fires 4 times per second
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return;
      }
      
      final position = _videoController!.value.position;
      _positionStreamController.add(position);
      
      // Add the _checkCompletion call here:
      _checkCompletion();
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
    
    // Check if we've reached the skip limit
    if (_forwardSkipCount >= _maxForwardSkips) {
      // Don't perform the seek, just return
      // The UI will handle showing a message
      return;
    }
    
    // Increment skip counter
    _forwardSkipCount++;
    debugPrint('Forward skip count: $_forwardSkipCount/$_maxForwardSkips');
    
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
    
    try {
      // Perform seek directly without pausing first
      await _videoController!.seekTo(position);
      
      // Notify position update
      _positionStreamController.add(position);
      
    } catch (e) {
      debugPrint('Error during seek: $e');
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

  // Helper to clean up state on initialization error
  void _cleanUpOnError() {
    _disposeController(); // Dispose if partially initialized
    _title = '';
    _subtitle = '';
    _thumbnailUrl = '';
    _videoUrl = '';
    _currentMediaItem = null;
    _isPlaying = false;
    _showMiniPlayer = false;
    notifyListeners();
  }

  // Set completion callback
  void setCompletionCallback(Function(String mediaId) callback) {
    _completionCallback = callback;
  }

  // Check if a video should be marked as completed
  void _checkCompletion() {
    if (_videoController == null || _currentMediaItem == null || _hasMarkedAsCompleted) {
      return;
    }
    
    final currentPosition = _videoController!.value.position.inSeconds.toDouble();
    final totalDuration = _videoController!.value.duration.inSeconds.toDouble();
    
    // Consider completed if watched 90% of video
    if (totalDuration > 0 && currentPosition >= (totalDuration * 0.9)) {
      _hasMarkedAsCompleted = true;
      
      // Track in MediaCompletionService
      _mediaCompletionService.markMediaCompleted('', _currentMediaItem!.id, MediaType.video);
      
      // Trigger callback if set
      if (_completionCallback != null) {
        _completionCallback!(_currentMediaItem!.id);
      }
      
      debugPrint('Video marked as completed: ${_currentMediaItem!.id}');
    }
  }

  // Clean method to properly handle exiting a video
  Future<void> cleanupBeforeExit() async {
    debugPrint('Cleaning up video resources before exit...');
    
    // Pause video if playing
    if (_isPlaying && _videoController != null) {
      try {
        await _videoController!.pause();
        _isPlaying = false;
      } catch (e) {
        debugPrint('Error pausing video during cleanup: $e');
      }
    }
    
    // Cache current position
    await _cacheVideoData();
    
    // Update mini player visibility (before navigation)
    _showMiniPlayer = false;
    
    // Notify listeners about state changes
    notifyListeners();
    
    debugPrint('Video resources cleanup completed');
  }
} 