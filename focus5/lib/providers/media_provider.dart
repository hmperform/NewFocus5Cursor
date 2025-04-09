import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/media_completion_service.dart';

class MediaProvider extends ChangeNotifier {
  // Media player instances
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;

  // Current media details
  String _title = '';
  String _subtitle = '';
  String _mediaUrl = '';
  String _imageUrl = '';
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _showMiniPlayer = false;
  bool _isFullScreenPlayerOpen = false;
  double _currentPosition = 0;
  double _totalDuration = 0;
  bool _isInitialized = false;
  MediaType _mediaType = MediaType.audio;
  
  // Store the last valid position for recovery
  double _lastValidPosition = 0;
  
  // Forward skip limit tracking
  int _forwardSkipCount = 0;
  final int _maxForwardSkips = 10;
  
  // Flags for state control
  bool _isTransitioning = false;
  bool _disposed = false;

  // Getters
  String get title => _title;
  String get subtitle => _subtitle;
  String get mediaUrl => _mediaUrl;
  String get imageUrl => _imageUrl;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get showMiniPlayer => _showMiniPlayer && !_isFullScreenPlayerOpen;
  bool get isFullScreenPlayerOpen => _isFullScreenPlayerOpen;
  double get currentPosition => _currentPosition;
  double get totalDuration => _totalDuration;
  AudioPlayer? get audioPlayer => _audioPlayer;
  VideoPlayerController? get videoController => _videoController;
  bool get isInitialized => _isInitialized;
  MediaItem? get currentMediaItem => _currentMediaItem;
  MediaType get mediaType => _mediaType;
  
  // Skip limit getters
  int get forwardSkipCount => _forwardSkipCount;
  int get maxForwardSkips => _maxForwardSkips;
  bool get hasReachedForwardSkipLimit => _forwardSkipCount >= _maxForwardSkips;
  
  // Reference to last played media item for resuming
  MediaItem? _currentMediaItem;
  
  // Stream controllers for better state management
  final StreamController<double> _positionStreamController = StreamController<double>.broadcast();
  Stream<double> get positionStream => _positionStreamController.stream;

  // Additional flags for seek logic
  bool _isSeeking = false;

  // Flag to pause notifications during disposal
  bool _pauseNotificationsFlag = false;

  // Media completion service
  final MediaCompletionService _mediaCompletionService = MediaCompletionService();
  
  MediaProvider() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    
    _audioPlayer?.playerStateStream.listen((state) {
      if (_mediaType == MediaType.audio) {
        _isPlaying = state.playing;
        _isBuffering = state.processingState == ProcessingState.loading || 
                      state.processingState == ProcessingState.buffering;
        notifyListeners();
      }
    });

    _audioPlayer?.positionStream.listen((position) {
      if (_mediaType == MediaType.audio) {
        _currentPosition = position.inSeconds.toDouble();
        _lastValidPosition = _currentPosition; // Store valid position
        _positionStreamController.add(_currentPosition);
        notifyListeners();
      }
    });

    _audioPlayer?.durationStream.listen((duration) {
      if (duration != null && _mediaType == MediaType.audio) {
        _totalDuration = duration.inSeconds.toDouble();
        notifyListeners();
      }
    });
  }

  // Initialize media with cached data if available
  Future<void> initializeMedia() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to load cached media state
      final cachedTitle = prefs.getString('media_title');
      final cachedSubtitle = prefs.getString('media_subtitle');
      final cachedUrl = prefs.getString('media_url');
      final cachedImageUrl = prefs.getString('media_image_url');
      final cachedPosition = prefs.getDouble('media_position') ?? 0.0;
      final cachedMediaType = prefs.getString('media_type') ?? 'audio';
      
      // If we have cached media data, restore it
      if (cachedTitle != null && cachedUrl != null) {
        _title = cachedTitle;
        _subtitle = cachedSubtitle ?? '';
        _mediaUrl = cachedUrl;
        _imageUrl = cachedImageUrl ?? '';
        _currentPosition = cachedPosition;
        _lastValidPosition = cachedPosition;
        _mediaType = cachedMediaType == 'video' ? MediaType.video : MediaType.audio;
        
        // Don't auto-play, just prepare the player
        _isPlaying = false;
        _showMiniPlayer = false;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      return Future.value();
    } catch (e) {
      debugPrint('Error initializing media: $e');
      _isInitialized = true;
      notifyListeners();
      return Future.value();
    }
  }

  // Start playing media and show mini player
  Future<void> startMedia(
    String title,
    String subtitle,
    String mediaUrl,
    String imageUrl,
    MediaType mediaType, {
    MediaItem? mediaData,
    double startPosition = 0.0,
  }) async {
    if (_disposed) return;
    
    // Reset skip counter when starting new media
    _forwardSkipCount = 0;
    
    // Set media metadata
    _title = title;
    _subtitle = subtitle;
    _mediaUrl = mediaUrl;
    _imageUrl = imageUrl;
    _mediaType = mediaType;
    _currentMediaItem = mediaData;
    _isBuffering = true;
    
    // Reset position state
    _currentPosition = startPosition;
    _lastValidPosition = startPosition;
    
    try {
      if (mediaType == MediaType.audio) {
        await _initializeAudioPlayback(mediaUrl, startPosition);
      } else if (mediaType == MediaType.video) {
        await _initializeVideoPlayback(mediaUrl, startPosition);
      }
      
      _isBuffering = false;
      notifyListeners();
      
      // Cache the media data for later
      _cacheMediaData();
    } catch (e) {
      _isBuffering = false;
      debugPrint('Error initializing media: $e');
      if (e is PlatformException) {
        debugPrint('Platform error: ${e.message}');
      }
      rethrow;
    }
  }
  
  // Initialize audio playback
  Future<void> _initializeAudioPlayback(String mediaUrl, double startPosition) async {
    // Close any video playback
    await _disposeVideoControllers();
    
    // Initialize audio player if it doesn't exist
    _audioPlayer ??= AudioPlayer();
    
    // Set the audio source and play
    await _audioPlayer?.setUrl(mediaUrl);
    if (startPosition > 0) {
      await _audioPlayer?.seek(Duration(seconds: startPosition.toInt()));
    }
    await _audioPlayer?.play();
    _isPlaying = true;
    _showMiniPlayer = true;
    
    debugPrint('Audio playback started: $mediaUrl at position $startPosition');

    // Add code to periodically track completion
    // Create a Timer that updates completion status every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_disposed || _audioPlayer == null) {
        timer.cancel();
        return;
      }
      
      if (_currentMediaItem != null) {
        trackMediaCompletion('');  // Will be updated with actual userId when used
      }
    });
  }
  
  // Initialize video playback with optimized loading
  Future<void> _initializeVideoPlayback(String mediaUrl, double startPosition) async {
    // Dispose any existing video controllers
    await _disposeVideoControllers();
    
    // Set buffering state to true immediately
    _isBuffering = true;
    notifyListeners();
    
    // Pause audio playback if active
    if (_audioPlayer != null && _audioPlayer!.playing) {
      await _audioPlayer?.pause();
    }
    
    debugPrint('🟡 Loading video from $mediaUrl at position $startPosition');
    
    // CRITICAL FIX: Immediately update current position for UI consistency
    _currentPosition = startPosition;
    _lastValidPosition = startPosition;
    
    int retryCount = 0;
    const maxRetries = 2;

    try {
      // Reset initialization flag
      _isInitialized = false;
      
      // OPTIMIZATION: Use lower quality settings for faster loading
      final videoPlayerOptions = VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: true,
      );
      
      // Create video controller with more robust setup
      debugPrint('🟡 Creating VideoPlayerController for: $mediaUrl');
      
      // Function to create controller - for retry purposes
      Future<void> createAndInitializeController() async {
        if (mediaUrl.startsWith('assets/')) {
          _videoController = VideoPlayerController.asset(
            mediaUrl,
            videoPlayerOptions: videoPlayerOptions,
          );
        } else if (mediaUrl.startsWith('http')) {
          _videoController = VideoPlayerController.network(
            mediaUrl,
            videoPlayerOptions: videoPlayerOptions,
            httpHeaders: {
              'Range': 'bytes=0-',
              'Connection': 'keep-alive',
            },
          );
        } else {
          debugPrint('🔴 Unsupported video URL format: $mediaUrl');
          throw Exception('Unsupported video URL format');
        }

        debugPrint('🟡 Starting video controller initialization...');
        
        // Set a timeout for initialization
        await _videoController!.initialize().timeout(
          const Duration(seconds: 20), // Increased timeout
          onTimeout: () {
            debugPrint('🔴 Video initialization timed out after 20 seconds.');
            throw Exception('Video initialization timed out');
          },
        );
        
        debugPrint('🟢 Video controller initialized successfully! Duration: ${_videoController!.value.duration.inSeconds}s');
        _isInitialized = true;
        _totalDuration = _videoController!.value.duration.inSeconds.toDouble();
      }
      
      // Try with retry mechanism
      while (retryCount <= maxRetries) {
        try {
          await createAndInitializeController();
          break; // Exit loop if successful
        } catch (e) {
          retryCount++;
          if (retryCount > maxRetries) {
            debugPrint('🔴 Failed to initialize video after $maxRetries retries: $e');
            rethrow;
          }
          debugPrint('🟠 Retry $retryCount/$maxRetries for video initialization...');
          await Future.delayed(const Duration(milliseconds: 500)); // Brief pause before retry
        }
      }
      
      // OPTIMIZATION: Show the UI immediately - don't wait for complete initialization
      notifyListeners();
      
      // Add position listener
      _videoController!.addListener(_onVideoPositionChanged);
      
      // Set volume
      await _videoController!.setVolume(1.0);
      
      // CRITICAL FIX: Seek to position BEFORE starting playback
      if (startPosition > 0) {
        debugPrint('🟡 Seeking to position: $startPosition seconds...');
        await _videoController!.seekTo(Duration(seconds: startPosition.toInt()));
        // Wait a moment for the seek to complete
        await Future.delayed(const Duration(milliseconds: 100));
        debugPrint('🟢 Seek complete.');
      }
      
      // Start playback
      debugPrint('🟡 Attempting to start video playback...');
      await _videoController!.play();
      _isPlaying = true;
      _showMiniPlayer = true;
      
      // CRITICAL FIX: Force update position stream with our initial position
      _positionStreamController.add(startPosition);
      debugPrint('🟢 Video playback initiated successfully');
      
      // Add code to periodically track completion
      // Create a Timer that updates completion status every 10 seconds
      Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_disposed || _videoController == null) {
          timer.cancel();
          return;
        }
        
        if (_currentMediaItem != null) {
          trackMediaCompletion('');  // Will be updated with actual userId when used
        }
      });
      
    } catch (e) {
      debugPrint('🔴 Error setting up video controller: $e');
      await _disposeVideoControllers(); // Ensure cleanup on error
      rethrow; // Rethrow to signal failure
    } finally {
      // Always ensure buffering state is reset
      _isBuffering = false;
      // Notify listeners unless disposed
      if (!_disposed) {
        notifyListeners();
      }
      debugPrint('🟡 Video initialization process complete (Success or Error).');
    }
  }
  
  // Track video position changes
  void _onVideoPositionChanged() {
    // CRITICAL: Ignore updates while seeking
    if (_isSeeking || _disposed || _videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    
    if (_videoController != null && _videoController!.value.isInitialized) {
      final newPosition = _videoController!.value.position.inSeconds.toDouble();
      
      // Only update if position is valid (avoid jumps to zero)
      if ((newPosition > 0 || _currentPosition == 0) && newPosition >= 0) {
        _currentPosition = newPosition;
        _lastValidPosition = newPosition; // Store last valid position
        _positionStreamController.add(_currentPosition);
        
        // Check if video is buffering
        final isBuffering = _videoController!.value.isBuffering;
        if (isBuffering != _isBuffering) {
          _isBuffering = isBuffering;
          if (!_pauseNotificationsFlag) {
            notifyListeners();
          }
        }
        
        // Update play status
        final newIsPlaying = _videoController!.value.isPlaying;
        if (newIsPlaying != _isPlaying) {
          _isPlaying = newIsPlaying;
          if (!_pauseNotificationsFlag) {
            notifyListeners();
          }
        }
      }
    }
  }

  // Pause notifications (used during disposal)
  void pauseNotifications() {
    _pauseNotificationsFlag = true;
    
    // Remove listener from video controller to prevent updates during disposal
    if (_videoController != null && !_disposed) {
      try {
        _videoController!.removeListener(_onVideoPositionChanged);
      } catch (e) {
        debugPrint('Error removing video controller listener: $e');
      }
    }
  }

  // Resume notifications (if needed)
  void resumeNotifications() {
    _pauseNotificationsFlag = false;
    
    // Re-add listener if controller exists
    if (_videoController != null && !_disposed && _videoController!.value.isInitialized) {
      try {
        _videoController!.addListener(_onVideoPositionChanged);
      } catch (e) {
        debugPrint('Error adding video controller listener: $e');
      }
    }
  }

  // Dispose video controllers
  Future<void> _disposeVideoControllers() async {
    if (_videoController != null) {
      // Always remove listener first
      _videoController!.removeListener(_onVideoPositionChanged);
      
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  // Cache current media data for persistence
  Future<void> _cacheMediaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      prefs.setString('media_title', _title);
      prefs.setString('media_subtitle', _subtitle);
      prefs.setString('media_url', _mediaUrl);
      prefs.setString('media_image_url', _imageUrl);
      prefs.setDouble('media_position', _currentPosition > 0 ? _currentPosition : _lastValidPosition);
      prefs.setString('media_type', _mediaType == MediaType.video ? 'video' : 'audio');
    } catch (e) {
      debugPrint('Error caching media data: $e');
    }
  }

  // Pause the current media
  Future<void> pauseMedia() async {
    if (_disposed || !_isPlaying) return;
    
    _isPlaying = false;
    
    try {
      if (_mediaType == MediaType.audio && _audioPlayer != null) {
        await _audioPlayer?.pause();
      } else if (_mediaType == MediaType.video && _videoController != null) {
        await _videoController!.pause();
      }
      
      // Cache current position
      _cacheMediaData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing media: $e');
    }
  }

  // Resume the current media
  Future<void> resumeMedia() async {
    if (_disposed || _isPlaying) return;
    
    try {
      if (_mediaType == MediaType.audio && _audioPlayer != null) {
        await _audioPlayer?.play();
        _isPlaying = true;
      } else if (_mediaType == MediaType.video && _videoController != null) {
        // Ensure proper volume
        await _videoController!.setVolume(1.0);
        await _videoController!.play();
        _isPlaying = true;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming media: $e');
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_disposed) return;
    
    try {
      if (_isPlaying) {
        if (_mediaType == MediaType.video && _videoController != null) {
          await _videoController!.pause();
        } else if (_mediaType == MediaType.audio && _audioPlayer != null) {
          await _audioPlayer!.pause();
        }
        _isPlaying = false;
      } else {
        if (_mediaType == MediaType.video && _videoController != null) {
          await _videoController!.play();
        } else if (_mediaType == MediaType.audio && _audioPlayer != null) {
          await _audioPlayer!.play();
        }
        _isPlaying = true;
      }
      
      debugPrint('Toggled play state: $_isPlaying');
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  // Seek to a specific position - simplified for reliability
  Future<void> seekTo(double seconds) async {
    if (_disposed) return;
    
    // Clamp position between 0 and total duration
    final targetSeconds = seconds.clamp(0.0, _totalDuration);
    debugPrint('🔵 Seeking to $targetSeconds seconds (Total duration: $_totalDuration)');
    
    try {
      // CRITICAL: Prevent listener updates during seek
      _isSeeking = true;
      // Show buffering during seek for better user feedback
      _isBuffering = true;
      notifyListeners();
      
      // IMPORTANT: Update our internal position immediately
      _currentPosition = targetSeconds;
      _lastValidPosition = targetSeconds;
      // Push to the stream immediately so UI updates right away
      _positionStreamController.add(targetSeconds);
      
      if (_mediaType == MediaType.audio && _audioPlayer != null) {
        // For audio, simple seek operation
        await _audioPlayer?.seek(Duration(seconds: targetSeconds.toInt()));
      } else if (_mediaType == MediaType.video && _videoController != null) {
        // For video, we need to make sure seeking works reliably
        if (!_videoController!.value.isInitialized) {
          debugPrint('🔵 Cannot seek, video controller not initialized');
          _isSeeking = false;
          _isBuffering = false;
          return;
        }
        
        final wasPlaying = _videoController!.value.isPlaying;
        
        // Always pause first for reliable seeking
        if (wasPlaying) {
          debugPrint('🔵 Pausing video for reliable seeking');
          await _videoController!.pause();
        }
        
        // CRITICAL FIX: Use exact millisecond precision for seeking
        debugPrint('🔵 Performing video seek to $targetSeconds seconds');
        // Convert seconds to milliseconds for more precise seeking
        final milliseconds = (targetSeconds * 1000).toInt();
        await _videoController!.seekTo(Duration(milliseconds: milliseconds));
        
        // Add a small delay to allow the controller to update its position value
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Force a position update to ensure UI consistency
        _currentPosition = targetSeconds;
        _lastValidPosition = targetSeconds;
        _positionStreamController.add(_currentPosition);
        
        // Resume playback if it was playing before
        if (wasPlaying) {
          debugPrint('🔵 Resuming video after seek');
          await _videoController!.play();
        }
        
        // Verify the seek worked
        debugPrint('🔵 Video position after seek: ${_videoController!.value.position.inMilliseconds/1000}s');
      }
      
      // Cache updated position
      _cacheMediaData();
      
      // Clear buffering state
      _isBuffering = false;
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error seeking to $seconds: $e');
      // Make sure we don't lose our position even if seek fails
      _positionStreamController.add(_lastValidPosition);
      // Clear buffering state on error
      _isBuffering = false;
      notifyListeners();
    } finally {
      // CRITICAL: Allow listener updates again
      _isSeeking = false;
    }
  }

  // Skip forward by specified seconds
  Future<void> skipForward(double seconds) async {
    if (hasReachedForwardSkipLimit) {
      // Don't increment or seek if limit reached
      // The UI will handle showing the message
      return;
    }
    
    // Increment skip counter
    _forwardSkipCount++;
    debugPrint('Forward skip count: $_forwardSkipCount/$_maxForwardSkips');
    
    // Perform the seek
    final newPosition = _currentPosition + seconds;
    await seekTo(newPosition);
  }

  // Skip backward by specified seconds
  Future<void> skipBackward(double seconds) async {
    final newPosition = _currentPosition - seconds;
    await seekTo(newPosition);
  }

  // Set current position (used by external components)
  void setCurrentPosition(double position) {
    if (position >= 0 && position <= _totalDuration) {
      _currentPosition = position;
      _lastValidPosition = position;
    }
  }

  // Close the mini player - completely stop playback
  Future<void> closeMiniPlayer() async {
    if (_disposed) return;
    
    debugPrint('Closing mini player, was playing: $_isPlaying');
    
    // Stop playing and hide mini player
    _isPlaying = false;
    _showMiniPlayer = false;
    
    try {
      if (_mediaType == MediaType.audio && _audioPlayer != null) {
        await _audioPlayer?.pause();
        await _audioPlayer?.seek(Duration.zero);
      } else if (_mediaType == MediaType.video) {
        await _disposeVideoControllers();
      }
      
      // Cache current position before closing
      _cacheMediaData();
      
      // Use microtask to avoid calling during widget tree build/disposal
      Future.microtask(() {
        if (!_disposed) {
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Error closing mini player: $e');
    }
  }

  // Set full screen player state
  Future<void> setFullScreenPlayerOpen(bool isOpen) async {
    if (_isFullScreenPlayerOpen == isOpen || _isTransitioning || _disposed) return;
    
    _isTransitioning = true;
    
    debugPrint('Setting full screen player open: $isOpen, isPlaying: $_isPlaying, position: $_currentPosition');
    
    try {
      // Save current playback state before transition
      final wasPlaying = _isPlaying;
      final currentPos = _currentPosition;
      
      if (!isOpen) {
        // Going from full screen to mini player
        _showMiniPlayer = true;
        
        // Now that playback is ensured, update the fullscreen state
        _isFullScreenPlayerOpen = isOpen;
        
        debugPrint('🔴 FORCING mini player to show: $_showMiniPlayer, wasPlaying: $wasPlaying');
        
        // The mini player will handle continuing playback via its own state 
        // management - don't try to force play here which could cause dispose errors
      } else {
        // Going from mini player to full screen
        _isFullScreenPlayerOpen = isOpen;
      }
      
      // Use microtask to avoid calling notifyListeners during build/disposal
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          _isTransitioning = false;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Error transitioning full screen state: $e');
      _isTransitioning = false;
      _isFullScreenPlayerOpen = isOpen;  // Set state even in case of error
      notifyListeners();
    }
  }

  // Format duration for display (MM:SS)
  String formatDuration(double seconds) {
    final int mins = (seconds / 60).floor();
    final int secs = (seconds % 60).floor();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  // Public methods
  
  // Explicitly play the current media
  Future<void> play() async {
    if (_disposed) return;
    
    try {
      if (_mediaType == MediaType.video && _videoController != null) {
        debugPrint('Explicitly playing video');
        await _videoController!.play();
        _isPlaying = true;
        notifyListeners();
      } else if (_mediaType == MediaType.audio && _audioPlayer != null) {
        debugPrint('Explicitly playing audio');
        await _audioPlayer!.play();
        _isPlaying = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error playing media: $e');
    }
  }
  
  // Direct state control - to avoid async issues with togglePlayPause
  void setPlayingState(bool isPlaying) {
    if (_disposed) return;
    
    debugPrint('Directly setting playing state to: $isPlaying');
    _isPlaying = isPlaying;
    notifyListeners();
  }
  
  // Completely stop media playback
  Future<void> stopMedia() async {
    if (_disposed) return;
    
    debugPrint('Stopping media playback');
    _isPlaying = false;
    _showMiniPlayer = false;
    
    try {
      if (_mediaType == MediaType.video) {
        await _disposeVideoControllers();
      } else if (_mediaType == MediaType.audio && _audioPlayer != null) {
        await _audioPlayer?.pause();
        await _audioPlayer?.seek(Duration.zero);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping media: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    
    // Use microtask to ensure disposal happens after current frame
    Future.microtask(() {
      _audioPlayer?.dispose();
      // Make sure video controller is disposed directly now
      if (_videoController != null) {
        _videoController!.removeListener(_onVideoPositionChanged);
        _videoController!.dispose();
        _videoController = null;
      }
      _positionStreamController.close();
    });
    
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_pauseNotificationsFlag && !_disposed) {
      super.notifyListeners();
    }
  }

  // Track media completion
  Future<void> trackMediaCompletion(String userId) async {
    if (_currentMediaItem == null || _disposed) return;
    
    try {
      final String mediaId = _currentMediaItem!.id;
      double currentPos = _currentPosition;
      double totalDur = _totalDuration;
      
      // For video, get position directly from controller for accuracy
      if (_mediaType == MediaType.video && _videoController != null) {
        currentPos = _videoController!.value.position.inSeconds.toDouble();
        totalDur = _videoController!.value.duration.inSeconds.toDouble();
      }
      
      // Track progress
      await _mediaCompletionService.trackMediaProgress(
        userId, 
        mediaId, 
        currentPos, 
        totalDur,
        _mediaType
      );
    } catch (e) {
      debugPrint('Error tracking media completion: $e');
    }
  }
  
  // Check if media has been completed
  Future<bool> isMediaCompleted(String userId, String mediaId) async {
    return await _mediaCompletionService.isMediaCompleted(userId, mediaId);
  }
} 