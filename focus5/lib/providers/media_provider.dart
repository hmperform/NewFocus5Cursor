import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  
  // Timer for simulated playback
  Timer? _playbackTimer;

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
  
  // Reference to last played media item for resuming
  MediaItem? _currentMediaItem;

  MediaProvider() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
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

  // Initialize video controller
  Future<void> _initVideoController(String videoUrl) async {
    // Dispose previous controller if exists
    await _videoController?.dispose();
    
    // Create new controller
    if (videoUrl.startsWith('assets/')) {
      _videoController = VideoPlayerController.asset(videoUrl);
    } else {
      _videoController = VideoPlayerController.network(videoUrl);
    }
    
    // Initialize and add listeners
    await _videoController!.initialize();
    _totalDuration = _videoController!.value.duration.inSeconds.toDouble();
    
    _videoController!.addListener(() {
      if (_mediaType == MediaType.video && _videoController != null) {
        _currentPosition = _videoController!.value.position.inSeconds.toDouble();
        _isPlaying = _videoController!.value.isPlaying;
        notifyListeners();
      }
    });
    
    notifyListeners();
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
        _mediaType = cachedMediaType == 'video' ? MediaType.video : MediaType.audio;
        
        // Don't auto-play, just prepare the player
        _isPlaying = false;
        _showMiniPlayer = false;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      return Future.value(); // Ensure we complete the Future
    } catch (e) {
      debugPrint('Error initializing media: $e');
      _isInitialized = true; // Set to initialized even on error to prevent retries
      notifyListeners();
      return Future.value(); // Complete the Future even on error
    }
  }
  
  // Start simulated playback timer (used for demo/placeholder when real playback is not available)
  void _startPlaybackSimulation() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      
      if (_isPlaying) {
        _currentPosition += 1;
        if (_currentPosition >= _totalDuration) {
          _currentPosition = 0;
        }
        notifyListeners();
      }
    });
  }
  
  // Stop simulated playback timer
  void _stopPlaybackSimulation() {
    _playbackTimer?.cancel();
  }

  // Start playing media and show mini player
  Future<void> startMedia(
    String title,
    String subtitle,
    String mediaUrl,
    String imageUrl,
    MediaType mediaType, {
    MediaItem? mediaData,
  }) async {
    if (_disposed) return;
    
    _title = title;
    _subtitle = subtitle;
    _mediaUrl = mediaUrl;
    _imageUrl = imageUrl;
    _mediaType = mediaType;
    _currentMediaItem = mediaData;
    _isBuffering = true;
    
    try {
      if (mediaType == MediaType.audio) {
        // Initialize audio player if it doesn't exist
        _audioPlayer ??= AudioPlayer();
        await _audioPlayer?.setUrl(mediaUrl);
        await _audioPlayer?.play();
        _isPlaying = true;
        _showMiniPlayer = true;
        
        // Start tracking audio position
        _startAudioPositionTracking();
      } else if (mediaType == MediaType.video) {
        // Dispose of any existing controller
        await _videoController?.dispose();
        
        debugPrint('Loading video from $mediaUrl');
        
        try {
          if (kIsWeb) {
            // For web, use a fixed video that's known to work
            debugPrint('Running in web browser, using network video');
            final fallbackUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
            _videoController = VideoPlayerController.network(fallbackUrl);
          } else if (mediaUrl.startsWith('http')) {
            _videoController = VideoPlayerController.network(mediaUrl);
          } else {
            // For assets (local files) - parse the path properly
            _videoController = VideoPlayerController.asset(mediaUrl);
            debugPrint('Created asset video controller for $mediaUrl');
          }
          
          // Detailed log before initialization
          debugPrint('Initializing video controller...');
          
          // Initialize with extra error details
          try {
            await _videoController!.initialize();
            debugPrint('Video initialized successfully with duration: ${_videoController!.value.duration.inSeconds}s');
            
            _totalDuration = _videoController!.value.duration.inSeconds.toDouble();
            await _videoController!.play();
            _isPlaying = true;
            
            // Start position tracking for video
            _startVideoPositionTracking();
          } catch (initError) {
            debugPrint('Video initialization failed with error: $initError');
            rethrow;
          }
        } catch (e) {
          debugPrint('Video controller creation error: $e');
          
          if (kIsWeb) {
            // Even the fallback failed, show an error
            debugPrint('Both primary and fallback videos failed. Web browsers have strict format requirements.');
            _isBuffering = false;
            rethrow;
          } else {
            rethrow; // Re-throw on non-web platforms
          }
        }
      }
      
      _isBuffering = false;
      notifyListeners();
    } catch (e) {
      _isBuffering = false;
      debugPrint('Error initializing media: $e');
      // Create more helpful error message
      if (e is PlatformException) {
        debugPrint('Platform error: ${e.message}');
      }
      rethrow;
    }
  }

  // Start tracking audio position with a timer
  void _startAudioPositionTracking() {
    _stopAudioPositionTracking(); // Stop any existing timer first
    
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      
      if (_audioPlayer != null && _audioPlayer!.playing) {
        // Position is accessed directly, not as a Future
        final position = _audioPlayer!.position;
        _currentPosition = position.inSeconds.toDouble();
        notifyListeners();
      }
    });
  }
  
  // Stop the audio position tracking timer
  void _stopAudioPositionTracking() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }
  
  // Start tracking video position with a timer
  void _startVideoPositionTracking() {
    _stopVideoPositionTracking(); // Stop any existing timer first
    
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      
      if (_videoController != null && _videoController!.value.isPlaying) {
        _currentPosition = _videoController!.value.position.inSeconds.toDouble();
        notifyListeners();
      }
    });
  }
  
  // Stop the video position tracking timer
  void _stopVideoPositionTracking() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  // Cache current media data for persistence
  Future<void> _cacheMediaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      prefs.setString('media_title', _title);
      prefs.setString('media_subtitle', _subtitle);
      prefs.setString('media_url', _mediaUrl);
      prefs.setString('media_image_url', _imageUrl);
      prefs.setDouble('media_position', _currentPosition);
      prefs.setString('media_type', _mediaType == MediaType.video ? 'video' : 'audio');
    } catch (e) {
      debugPrint('Error caching media data: $e');
    }
  }

  // Pause the current media
  Future<void> pauseMedia() async {
    if (_disposed) return;
    
    _isPlaying = false;
    
    if (_mediaType == MediaType.audio) {
      // In a real app: await _audioPlayer?.pause();
      _stopPlaybackSimulation();
    } else if (_mediaType == MediaType.video && _videoController != null) {
      await _videoController!.pause();
    }
    
    // Cache current position
    _cacheMediaData();
    
    // Use microtask to avoid calling during widget tree build/disposal
    Future.microtask(() {
      notifyListeners();
    });
  }

  // Resume the current media
  Future<void> resumeMedia() async {
    if (_disposed) return;
    
    _isPlaying = true;
    
    if (_mediaType == MediaType.audio) {
      // In a real app: await _audioPlayer?.play();
      _startPlaybackSimulation();
    } else if (_mediaType == MediaType.video && _videoController != null) {
      await _videoController!.play();
    }
    
    // Use microtask to avoid calling during widget tree build/disposal
    Future.microtask(() {
      notifyListeners();
    });
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_disposed) return;
    
    if (_isPlaying) {
      await pauseMedia();
    } else {
      await resumeMedia();
    }
  }

  // Close the mini player - completely stop playback
  Future<void> closeMiniPlayer() async {
    if (_disposed) return;
    
    // Stop playing and hide mini player
    _isPlaying = false;
    _showMiniPlayer = false;
    
    if (_mediaType == MediaType.audio) {
      // Stop audio playback
      await _audioPlayer?.pause();
      await _audioPlayer?.seek(Duration.zero);
      _stopAudioPositionTracking();
    } else if (_mediaType == MediaType.video && _videoController != null) {
      // Dispose video controller
      await _videoController!.pause();
      await _videoController!.dispose();
      _videoController = null;
      _stopVideoPositionTracking();
    }
    
    // Use microtask to avoid calling during widget tree build/disposal
    Future.microtask(() {
      notifyListeners();
    });
  }

  // Seek to a specific position
  Future<void> seekTo(double seconds) async {
    if (_disposed) return;
    
    if (_mediaType == MediaType.audio) {
      // In a real app: await _audioPlayer?.seek(Duration(seconds: seconds.toInt()));
      _currentPosition = seconds;
    } else if (_mediaType == MediaType.video && _videoController != null) {
      await _videoController!.seekTo(Duration(seconds: seconds.toInt()));
    }
    
    // Cache updated position
    _cacheMediaData();
    
    notifyListeners();
  }

  // Add disposed flag to prevent callbacks after disposal
  bool _disposed = false;
  
  @override
  void dispose() {
    _disposed = true;
    _playbackTimer?.cancel();
    _audioPlayer?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // Format duration for display (MM:SS)
  String formatDuration(double seconds) {
    final int mins = (seconds / 60).floor();
    final int secs = (seconds % 60).floor();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  // Set full screen player state
  void setFullScreenPlayerOpen(bool isOpen) {
    if (_isFullScreenPlayerOpen == isOpen) return; // No change needed
    
    _isFullScreenPlayerOpen = isOpen;
    
    // When closing full screen player, show mini player and keep playing
    // Don't touch the playback state - just update the UI
    if (!isOpen) {
      _showMiniPlayer = _isPlaying ? true : false;
    }
    
    // Use microtask to avoid calling during widget tree build/disposal
    Future.microtask(() {
      notifyListeners();
    });
  }
} 