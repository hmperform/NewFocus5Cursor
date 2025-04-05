import 'dart:async';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service class that manages video playback throughout the app,
/// supporting both mini player and full screen modes with seamless transitions.
class BetterVideoService with ChangeNotifier {
  // Player controller
  BetterPlayerController? _controller;
  
  // Player configuration
  final BetterPlayerConfiguration _playerConfig = BetterPlayerConfiguration(
    aspectRatio: 16 / 9,
    fit: BoxFit.cover,
    autoPlay: true,
    looping: false,
    handleLifecycle: true,
    autoDispose: false,
    controlsConfiguration: BetterPlayerControlsConfiguration(
      enableFullscreen: true,
      enableSubtitles: false,
      enablePlaybackSpeed: true,
      enableSkips: true,
      enableAudioTracks: false,
      enableOverflowMenu: false,
      enablePlayPause: true,
      enableMute: true,
      enableProgressBar: true,
      enableProgressText: true,
      progressBarHandleColor: Colors.green,
      controlBarColor: Colors.black.withOpacity(0.5),
    ),
  );

  // Video metadata
  String _title = '';
  String _subtitle = '';
  String _thumbnailUrl = '';
  bool _isFullScreen = false;
  bool _isPlaying = false;
  bool _showMiniPlayer = false;
  String _videoUrl = '';
  double _aspectRatio = 16 / 9;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  // Stream controllers for better state management
  final StreamController<Duration> _positionStreamController = StreamController<Duration>.broadcast();
  Stream<Duration> get positionStream => _positionStreamController.stream;

  // Getters
  BetterPlayerController? get controller => _controller;
  String get title => _title;
  String get subtitle => _subtitle;
  String get thumbnailUrl => _thumbnailUrl;
  String get videoUrl => _videoUrl;
  bool get isFullScreen => _isFullScreen;
  bool get isPlaying => _isPlaying;
  bool get showMiniPlayer => _showMiniPlayer && !_isFullScreen;
  double get aspectRatio => _aspectRatio;
  Duration get position => _position;
  Duration get duration => _duration;

  // Initialize with an existing video URL
  Future<void> initializePlayer({
    required String videoUrl,
    required String title,
    required String subtitle,
    String thumbnailUrl = '', 
    Duration? startPosition,
  }) async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    _videoUrl = videoUrl;
    _title = title;
    _subtitle = subtitle;
    _thumbnailUrl = thumbnailUrl;

    // Create data source
    BetterPlayerDataSource dataSource;
    if (videoUrl.startsWith('http')) {
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        videoUrl,
        cacheConfiguration: BetterPlayerCacheConfiguration(useCache: true),
      );
    } else if (videoUrl.startsWith('asset')) {
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.asset,
        videoUrl,
      );
    } else {
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        videoUrl,
      );
    }

    // Create player controller
    _controller = BetterPlayerController(_playerConfig, betterPlayerDataSource: dataSource);
    await _controller!.setupDataSource(dataSource);
    
    // Setup listeners
    _setupEventListeners();

    // Set start position if provided
    if (startPosition != null) {
      await _controller!.seekTo(startPosition);
    }
    
    _isPlaying = true;
    _showMiniPlayer = true;
    notifyListeners();

    // Cache the current video details
    _cacheVideoData();
  }

  // Setup event listeners for the player
  void _setupEventListeners() {
    if (_controller == null) return;

    _controller!.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
        _position = event.parameters?["progress"] as Duration? ?? Duration.zero;
        _positionStreamController.add(_position);
      } else if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
        _aspectRatio = _controller!.videoPlayerController!.value.aspectRatio;
        _duration = _controller!.videoPlayerController!.value.duration;
        notifyListeners();
      } else if (event.betterPlayerEventType == BetterPlayerEventType.play) {
        _isPlaying = true;
        notifyListeners();
      } else if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
        _isPlaying = false;
        notifyListeners();
      } else if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
        _isPlaying = false;
        notifyListeners();
      }
    });
  }

  // Toggle play/pause state
  void togglePlayPause() {
    if (_controller == null) return;
    
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  // Seek to specific position
  Future<void> seekTo(Duration position) async {
    if (_controller == null) return;
    
    await _controller!.seekTo(position);
    _position = position;
    _positionStreamController.add(_position);
    _cacheVideoData();
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

  // Close and dispose player
  Future<void> closePlayer() async {
    if (_controller != null) {
      await _controller!.pause();
      _showMiniPlayer = false;
      _isPlaying = false;
      notifyListeners();
      _cacheVideoData();
    }
  }

  // Completely dispose player when no longer needed
  Future<void> disposePlayer() async {
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
    }
    _showMiniPlayer = false;
    _isPlaying = false;
    notifyListeners();
  }

  // Cache current video data for persistence
  Future<void> _cacheVideoData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      prefs.setString('video_url', _videoUrl);
      prefs.setString('video_title', _title);
      prefs.setString('video_subtitle', _subtitle);
      prefs.setString('video_thumbnail', _thumbnailUrl);
      prefs.setInt('video_position', _position.inMilliseconds);
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
          await _controller?.pause();
          _isPlaying = false;
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
    _controller?.dispose();
    _positionStreamController.close();
    super.dispose();
  }
} 