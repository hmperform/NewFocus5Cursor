import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Audio? _currentAudio;
  bool _showMiniPlayer = false;
  bool _isPlaying = false;
  String? _title;
  String? _subtitle;
  String? _audioUrl;
  String? _imageUrl;
  bool _isFullScreenPlayerOpen = false;
  double _currentPosition = 0;
  double _totalDuration = 179; // Default to 2:59 in seconds
  bool _isInitialized = false;
  Timer? _playbackTimer;

  Audio? get currentAudio => _currentAudio;
  bool get showMiniPlayer => _showMiniPlayer;
  bool get isPlaying => _isPlaying;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  String? get title => _title;
  String? get subtitle => _subtitle;
  String? get audioUrl => _audioUrl;
  String? get imageUrl => _imageUrl;
  bool get isFullScreenPlayerOpen => _isFullScreenPlayerOpen;
  double get currentPosition => _currentPosition;
  double get totalDuration => _totalDuration;
  AudioPlayer get audioPlayer => _player;
  bool get isInitialized => _isInitialized;

  AudioProvider() {
    debugPrint('[AudioProvider] Initializing...');
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _player.positionStream.listen((position) {
      _currentPosition = position.inSeconds.toDouble();
      notifyListeners();
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration.inSeconds.toDouble();
        notifyListeners();
      }
    });

    _listenToPlayerStreams(); // Moved listener setup here
  }

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
      
      return Future.value(); // Ensure we complete the Future
    } catch (e) {
      debugPrint('Error initializing audio: $e');
      _isInitialized = true; // Set to initialized even on error to prevent retries
      notifyListeners();
      return Future.value(); // Complete the Future even on error
    }
  }
  
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
  
  void _stopPlaybackSimulation() {
    _playbackTimer?.cancel();
  }

  Future<void> startAudioFromDaily(Audio audio) async {
    debugPrint('[AudioProvider] startAudioFromDaily called for ID: ${audio.id}');
    
    // If the same audio is already playing, just ensure mini player is shown
    if (_currentAudio?.id == audio.id) {
      debugPrint('[AudioProvider] Same audio already playing, ensuring mini player is shown');
      _showMiniPlayer = true;
      notifyListeners();
      return;
    }

    try {
      // Set metadata first
      _currentAudio = audio;
      _title = audio.title;
      _subtitle = audio.subtitle;
      _audioUrl = audio.audioUrl;
      _imageUrl = audio.imageUrl;
      
      // Initialize audio
      await _player.setUrl(audio.audioUrl);
      await _player.play();
      
      // Update state after successful initialization
      _isPlaying = true;
      _showMiniPlayer = true;
      _isInitialized = true;
      
      // Cache the audio data
      _cacheAudioData();
      
      debugPrint('[AudioProvider] Audio started successfully: ${audio.id}');
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioProvider] Error starting audio: $e');
      // Reset state on error
      _currentAudio = null;
      _isPlaying = false;
      _showMiniPlayer = false;
      _isInitialized = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> startAudio(
    String title,
    String subtitle,
    String audioUrl,
    String imageUrl, {
    MediaItem? audioData,
  }) async {
    if (_disposed) return;

    // Create a basic Audio object
    final basicAudio = Audio(
      id: audioData?.id ?? audioUrl, // Use audioUrl as ID if no MediaItem
      title: title,
      subtitle: subtitle,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      description: audioData?.description ?? subtitle,
      sequence: 0, // Default value
      slideshowImages: [], // Default value
    );

    await startAudioFromDaily(basicAudio);
  }

  void _listenToPlayerStreams() {
    debugPrint('[AudioProvider] Setting up player stream listeners.');
    _player.playerStateStream.listen((state) {
      if (_disposed) return;
      final previousPlaying = _isPlaying;
      _isPlaying = state.playing;
      if (previousPlaying != _isPlaying) {
         debugPrint('[AudioProvider] Player State Changed: isPlaying=$_isPlaying, processingState=${state.processingState}');
         notifyListeners();
      }
    });

    _player.positionStream.listen((position) {
      if (_disposed) return;
       final previousPosition = _currentPosition;
      _currentPosition = position.inSeconds.toDouble();
       if ((previousPosition - _currentPosition).abs() > 0.1) { // Log only significant changes
          debugPrint('[AudioProvider] Position Stream: currentPosition=${_currentPosition.toStringAsFixed(1)}s');
          // No notifyListeners here, handled by player state potentially
       }
    });

    _player.durationStream.listen((duration) {
      if (_disposed) return;
      if (duration != null) {
        final previousDuration = _totalDuration;
        _totalDuration = duration.inSeconds.toDouble();
        if (previousDuration != _totalDuration) {
           debugPrint('[AudioProvider] Duration Stream: totalDuration=${_totalDuration.toStringAsFixed(1)}s');
           notifyListeners();
        }
      }
    });
  }

  Future<void> _cacheAudioData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_title != null) prefs.setString('audio_title', _title!);
      if (_subtitle != null) prefs.setString('audio_subtitle', _subtitle!);
      if (_audioUrl != null) prefs.setString('audio_url', _audioUrl!);
      if (_imageUrl != null) prefs.setString('audio_image_url', _imageUrl!);
      prefs.setDouble('audio_position', _currentPosition);
      debugPrint('[AudioProvider] Caching audio data: title=$_title, pos=$_currentPosition');
    } catch (e) {
      debugPrint('Error caching audio data: $e');
    }
  }

  Future<void> togglePlayPause() async {
    debugPrint('[AudioProvider] togglePlayPause called. Current state: isPlaying=$_isPlaying');
    if (_disposed) return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      // Check if we need to load the URL first
      if (_player.processingState == ProcessingState.idle || _player.processingState == ProcessingState.completed) {
        if (_audioUrl != null) {
          try {
            await _player.setUrl(_audioUrl!);
            await _player.play();
          } catch (e) {
            print('Error setting URL on resume: $e');
            _isPlaying = false; // Keep state as paused
          }
        } else {
          _isPlaying = false; // Cannot play without URL
        }
      } else {
         await _player.play();
      }
    }
    // State update (_isPlaying) is handled by the playerStateStream listener

    // Cache current state
    _cacheAudioData();

    // No need to call notifyListeners() here, stream listeners handle it
  }

  void closeMiniPlayer() {
    debugPrint('[AudioProvider] closeMiniPlayer called.');
    if (_disposed || _isFullScreenPlayerOpen) return; // Don't close if in full screen

    // Stop playback first
    _player.stop();
    _isPlaying = false;
    
    // Reset state in correct order
    _showMiniPlayer = false;
    _currentPosition = 0;
    _totalDuration = 0;
    
    // Clear current audio last to ensure proper cleanup
    _currentAudio = null;
    
    // Clear cached data
    _clearCachedAudioData();

    debugPrint('[AudioProvider] Mini player closed and state reset');
    notifyListeners();
  }

  Future<void> _clearCachedAudioData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('audio_title');
      await prefs.remove('audio_subtitle');
      await prefs.remove('audio_url');
      await prefs.remove('audio_image_url');
      await prefs.remove('audio_position');
      debugPrint('[AudioProvider] Clearing cached audio data.');
    } catch (e) {
      debugPrint('Error clearing cached audio data: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_disposed) return;
    
    await _player.seek(position);
    _currentPosition = position.inSeconds.toDouble();
    notifyListeners();
  }

  Future<void> seekRelative(Duration offset) async {
    if (_disposed) return;
    
    final currentSeconds = _currentPosition.toInt();
    final offsetSeconds = offset.inSeconds;
    final newSeconds = (currentSeconds + offsetSeconds)
        .clamp(0, _totalDuration.toInt());
    await seekTo(Duration(seconds: newSeconds));
  }

  // Add disposed flag to prevent callbacks after disposal
  bool _disposed = false;
  
  @override
  void dispose() {
    debugPrint('[AudioProvider] Disposing...');
    _disposed = true;
    _playbackTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  String formatDuration(double seconds) {
    final int mins = (seconds / 60).floor();
    final int secs = (seconds % 60).floor();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  void setFullScreenPlayerOpen(bool isOpen) {
    debugPrint('[AudioProvider] setFullScreenPlayerOpen called with: $isOpen. Current state: isFullScreen=$_isFullScreenPlayerOpen');
    
    // Don't do anything if the state isn't actually changing
    if (_isFullScreenPlayerOpen == isOpen) {
      debugPrint('[AudioProvider] No state change needed, returning');
      return;
    }
    
    _isFullScreenPlayerOpen = isOpen;
    
    // When closing full screen, ensure mini player shows if audio is active
    if (!isOpen && _currentAudio != null) {
      debugPrint('[AudioProvider] Exiting full screen with active audio, showing mini player');
      _showMiniPlayer = true;
      
      // If audio was playing, ensure it continues
      if (_isPlaying && !_player.playing) {
        debugPrint('[AudioProvider] Resuming playback after full screen close');
        _player.play();
      }
    } else if (isOpen) {
      // When opening full screen, temporarily hide mini player
      _showMiniPlayer = false;
    }
    
    debugPrint('[AudioProvider] Updated state: isFullScreen=$_isFullScreenPlayerOpen, showMiniPlayer=$_showMiniPlayer, currentAudio ID=${_currentAudio?.id}, isPlaying=$_isPlaying');
    notifyListeners();
  }

  void setCurrentAudio(Audio audio) {
    _currentAudio = audio;
    _imageUrl = audio.imageUrl;
    _title = audio.title;
    _subtitle = audio.subtitle;
    notifyListeners();
  }

  void showFullScreenPlayer() {
    _isFullScreenPlayerOpen = true;
    notifyListeners();
  }

  void hideFullScreenPlayer() {
    _isFullScreenPlayerOpen = false;
    notifyListeners();
  }

  void showMiniPlayerIfNeeded() {
    if (_currentAudio != null && !_isFullScreenPlayerOpen) {
      _showMiniPlayer = true;
      notifyListeners();
    }
  }

  void hideMiniPlayer() {
    _showMiniPlayer = false;
    notifyListeners();
  }

  Future<void> skipForward() async {
    if (_disposed) return;
    
    final newPosition = _currentPosition + 10;
    if (newPosition <= _totalDuration) {
      await seekTo(Duration(seconds: newPosition.toInt()));
    }
  }

  Future<void> skipBackward() async {
    if (_disposed) return;
    
    final newPosition = _currentPosition - 10;
    if (newPosition >= 0) {
      await seekTo(Duration(seconds: newPosition.toInt()));
    }
  }
} 