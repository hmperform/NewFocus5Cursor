import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';

class AudioProvider extends ChangeNotifier {
  // Audio player instance
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Current audio details
  String? _title;
  String? _subtitle;
  String? _audioUrl;
  String? _imageUrl;
  bool _isPlaying = false;
  bool _showMiniPlayer = false;
  bool _isFullScreenPlayerOpen = false;
  double _currentPosition = 0;
  double _totalDuration = 179; // Default to 2:59 in seconds
  bool _isInitialized = false;
  
  // Timer for simulated playback
  Timer? _playbackTimer;

  // Getters
  String? get title => _title;
  String? get subtitle => _subtitle;
  String? get audioUrl => _audioUrl;
  String? get imageUrl => _imageUrl;
  bool get isPlaying => _isPlaying;
  bool get showMiniPlayer => _showMiniPlayer;
  bool get isFullScreenPlayerOpen => _isFullScreenPlayerOpen;
  double get currentPosition => _currentPosition;
  double get totalDuration => _totalDuration;
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isInitialized => _isInitialized;
  DailyAudio? get currentAudio => _currentAudio;
  
  // Reference to last played audio for resuming
  DailyAudio? _currentAudio;

  AudioProvider() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position.inSeconds.toDouble();
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration.inSeconds.toDouble();
        notifyListeners();
      }
    });
  }

  // Initialize audio with cached data if available
  Future<void> initializeAudio() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to load cached audio state
      final cachedTitle = prefs.getString('audio_title');
      final cachedSubtitle = prefs.getString('audio_subtitle');
      final cachedUrl = prefs.getString('audio_url');
      final cachedImageUrl = prefs.getString('audio_image_url');
      final cachedPosition = prefs.getDouble('audio_position') ?? 0.0;
      
      // If we have cached audio data, restore it
      if (cachedTitle != null && cachedUrl != null) {
        _title = cachedTitle;
        _subtitle = cachedSubtitle;
        _audioUrl = cachedUrl;
        _imageUrl = cachedImageUrl;
        _currentPosition = cachedPosition;
        
        // Don't auto-play, just prepare the player
        _isPlaying = false;
        _showMiniPlayer = false;
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }
  
  // Start simulated playback timer
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

  // Start playing audio and show mini player
  Future<void> startAudio(
    String title,
    String subtitle,
    String audioUrl,
    String imageUrl, {
    DailyAudio? audioData,
  }) async {
    if (_disposed) return;
    
    _title = title;
    _subtitle = subtitle;
    _audioUrl = audioUrl;
    _imageUrl = imageUrl;
    _isPlaying = true;
    _showMiniPlayer = !_isFullScreenPlayerOpen;
    
    if (audioData != null) {
      _currentAudio = audioData;
    }
    
    // Cache the current audio data
    _cacheAudioData();
    
    // Start simulated playback
    _startPlaybackSimulation();
    
    // Use microtask to avoid calling during widget tree build/disposal
    Future.microtask(() {
      notifyListeners();
    });
  }

  // Cache current audio data for persistence
  Future<void> _cacheAudioData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_title != null) prefs.setString('audio_title', _title!);
      if (_subtitle != null) prefs.setString('audio_subtitle', _subtitle!);
      if (_audioUrl != null) prefs.setString('audio_url', _audioUrl!);
      if (_imageUrl != null) prefs.setString('audio_image_url', _imageUrl!);
      prefs.setDouble('audio_position', _currentPosition);
    } catch (e) {
      debugPrint('Error caching audio data: $e');
    }
  }

  // Pause the current audio
  void pauseAudio() {
    if (_disposed) return;
    
    _isPlaying = false;
    // _audioPlayer.pause();
    
    // Cache current position
    _cacheAudioData();
    
    // Use microtask to avoid calling during widget tree build/disposal
    Future.microtask(() {
      notifyListeners();
    });
  }

  // Resume the current audio
  void resumeAudio() {
    if (_disposed) return;
    
    _isPlaying = true;
    // _audioPlayer.play();
    
    // Restart simulated playback
    _startPlaybackSimulation();
    
    // Use microtask to avoid calling during widget tree build/disposal
    Future.microtask(() {
      notifyListeners();
    });
  }

  // Toggle play/pause
  void togglePlayPause() {
    if (_disposed) return;
    
    if (_isPlaying) {
      pauseAudio();
      _stopPlaybackSimulation();
    } else {
      resumeAudio();
    }
  }

  // Close the mini player
  void closeMiniPlayer() {
    if (_disposed) return;
    
    _isPlaying = false;
    _showMiniPlayer = false;
    // _audioPlayer.stop();
    
    // Stop simulated playback
    _stopPlaybackSimulation();
    
    // Use microtask to avoid calling during widget tree build/disposal
    Future.microtask(() {
      notifyListeners();
    });
  }

  // Seek to a specific position
  void seekTo(double seconds) {
    if (_disposed) return;
    
    // _audioPlayer.seek(Duration(seconds: seconds.toInt()));
    _currentPosition = seconds;
    
    // Cache updated position
    _cacheAudioData();
    
    notifyListeners();
  }

  // Add disposed flag to prevent callbacks after disposal
  bool _disposed = false;
  
  @override
  void dispose() {
    _disposed = true;
    _playbackTimer?.cancel();
    _audioPlayer.dispose();
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
    _showMiniPlayer = _isPlaying && !isOpen;
    
    // Use microtask to avoid calling during widget tree build/disposal
    Future.microtask(() {
      notifyListeners();
    });
  }
}

// Simple model class for DailyAudio to support typescript in this file
class DailyAudio {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String imageUrl;
  
  DailyAudio({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.imageUrl,
  });
} 