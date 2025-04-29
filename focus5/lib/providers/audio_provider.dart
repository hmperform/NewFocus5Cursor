import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' hide AudioSource;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Audio? _currentAudio;
  Lesson? _originalLesson;
  DailyAudio? _originalDailyAudio;
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
  AudioSource _audioSource = AudioSource.unknown;
  String? _courseTitleForCache;

  Audio? get currentAudio => _currentAudio;
  Lesson? get originalLesson => _originalLesson;
  DailyAudio? get originalDailyAudio => _originalDailyAudio;
  bool get showMiniPlayer => _showMiniPlayer && !_isFullScreenPlayerOpen && _currentAudio != null;
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
  AudioSource get audioSource => _audioSource;
  String? get courseTitleForCache => _courseTitleForCache;

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

    // Consider loading sourceType and courseTitle from cache in initializeAudio too
    initializeAudio(); 
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
      final cachedSourceTypeName = prefs.getString('audio_source_type');
      final cachedCourseTitle = prefs.getString('audio_course_title');
      
      // If we have cached audio data, restore it
      if (cachedTitle != null && cachedUrl != null) {
        _title = cachedTitle;
        _subtitle = cachedSubtitle;
        _audioUrl = cachedUrl;
        _imageUrl = cachedImageUrl;
        _currentPosition = cachedPosition;
        _audioSource = cachedSourceTypeName != null
            ? AudioSource.values.firstWhere((e) => e.name == cachedSourceTypeName, orElse: () => AudioSource.unknown)
            : AudioSource.unknown;
        _courseTitleForCache = cachedCourseTitle;

        // Reconstruct _currentAudio from cached data if needed for consistency
        _currentAudio = Audio(
           id: cachedUrl,
           title: _title!,
           subtitle: _subtitle ?? '',
           description: '',
           imageUrl: _imageUrl ?? '',
           audioUrl: _audioUrl!,
           sequence: 0,
           slideshowImages: [],
           sourceType: _audioSource,
           courseTitle: _courseTitleForCache,
        );
        
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

  Future<void> startAudioPlayback(dynamic originalMediaObject) async {
    String mediaId;
    AudioSource sourceType;
    Audio audioForProvider;

    // <<< Logging Start >>>
    debugPrint('[AudioProvider] startAudioPlayback invoked with object type: ${originalMediaObject.runtimeType}');
    // <<< Logging End >>>

    // Determine type and create the generic Audio object for the provider state
    if (originalMediaObject is Lesson) {
      debugPrint('[AudioProvider] Starting playback for Lesson: ${originalMediaObject.title}');
      _originalLesson = originalMediaObject;
      _originalDailyAudio = null; // Clear the other type
      sourceType = AudioSource.lesson;
      mediaId = originalMediaObject.id;

      audioForProvider = Audio(
        id: originalMediaObject.id,
        title: originalMediaObject.title,
        subtitle: originalMediaObject.courseTitle ?? 'Course Lesson', // Use course title
        audioUrl: originalMediaObject.audioUrl ?? '',
        imageUrl: originalMediaObject.thumbnailUrl ?? '',
        description: originalMediaObject.description ?? '',
        slideshowImages: originalMediaObject.slideshowImages ?? [],
        sourceType: sourceType,
        courseTitle: originalMediaObject.courseTitle, // Store explicit course title
        sequence: originalMediaObject.sortOrder,
      );
    } else if (originalMediaObject is DailyAudio) {
      debugPrint('[AudioProvider] Starting playback for DailyAudio: ${originalMediaObject.title}');
      _originalDailyAudio = originalMediaObject;
      _originalLesson = null; // Clear the other type
      sourceType = AudioSource.daily;
      mediaId = originalMediaObject.id;

      audioForProvider = Audio(
        id: originalMediaObject.id,
        title: originalMediaObject.title,
        subtitle: originalMediaObject.focusAreas.join(', '), // Use focus areas
        audioUrl: originalMediaObject.audioUrl,
        imageUrl: originalMediaObject.thumbnail,
        description: originalMediaObject.description,
        slideshowImages: [originalMediaObject.slideshow1, originalMediaObject.slideshow2, originalMediaObject.slideshow3]
            .where((s) => s.isNotEmpty)
            .toList(),
        sourceType: sourceType,
        courseTitle: null, // No course title for daily
        sequence: 0, // Daily audio likely doesn't have sequence
      );
    } else if (originalMediaObject is Audio) {
      // Direct Audio object handling - use it directly
      debugPrint('[AudioProvider] Starting playback for Audio object: ${originalMediaObject.title}');
      audioForProvider = originalMediaObject;
      mediaId = originalMediaObject.id;
      sourceType = originalMediaObject.sourceType;
      
      // Set appropriate original object reference based on the source type
      if (sourceType == AudioSource.daily) {
        _originalDailyAudio = null; // We don't have the original object
        _originalLesson = null;
      } else if (sourceType == AudioSource.lesson) {
        _originalLesson = null; // We don't have the original object
        _originalDailyAudio = null;
      } else {
        _originalLesson = null;
        _originalDailyAudio = null;
      }
    } else {
      debugPrint('[AudioProvider] Error: startAudioPlayback called with unknown type: ${originalMediaObject.runtimeType}');
      return; // Or throw error
    }

    // <<< Logging Start >>>
    debugPrint('[AudioProvider] Determined mediaId: $mediaId, sourceType: $sourceType');
    debugPrint('[AudioProvider] Audio URL from object: ${audioForProvider.audioUrl}');
    // <<< Logging End >>>

    // Check if it's the same audio already
    if (_currentAudio?.id == mediaId) {
      // <<< Logging Start >>>
      debugPrint('[AudioProvider] Same audio (ID: $mediaId) already loaded/playing. Ensuring mini player is shown.');
      // <<< Logging End >>>
      _showMiniPlayer = true;
      notifyListeners();
      return;
    }

    // Validate Audio URL before proceeding
    if (audioForProvider.audioUrl.isEmpty) {
       // <<< Logging Start >>>
       debugPrint('[AudioProvider] CRITICAL ERROR: Audio URL is empty for media ID: $mediaId. Aborting playback.');
       // <<< Logging End >>>
       // Maybe reset state or throw?
       stop(); // Stop to clear potentially invalid state
       return;
    }

    // --- Proceed with playback setup --- 
    try {
      // <<< Logging Start >>>
      debugPrint('[AudioProvider] Setting up new audio (ID: $mediaId)');
      // <<< Logging End >>>
      _currentAudio = audioForProvider; // Store the generic Audio object
      _title = _currentAudio!.title;
      _subtitle = _currentAudio!.subtitle;
      _audioUrl = _currentAudio!.audioUrl;
      _imageUrl = _currentAudio!.imageUrl;
      _audioSource = _currentAudio!.sourceType;
      _courseTitleForCache = _currentAudio!.courseTitle; // Use courseTitle from generic Audio
      
      _currentPosition = 0.0;
      
      // Log the exact URL being used to diagnose issues
      // <<< Logging Start >>>
      debugPrint('[AudioProvider] Preparing to set URL in player: $_audioUrl');
      // <<< Logging End >>>
      
      try {
        // Try to prevalidate the URL before passing to the player
        if (_audioUrl!.startsWith('http')) {
          // <<< Logging Start >>>
          debugPrint('[AudioProvider] Attempting to play remote URL: $_audioUrl');
          // <<< Logging End >>>
          // Try with explicit content-type and cache control headers
          await _player.setUrl(
            _audioUrl!,
            headers: {
              'Content-Type': 'audio/mpeg',
              'Cache-Control': 'no-cache',
              'Access-Control-Allow-Origin': '*',
            },
          );
        } else {
          // <<< Logging Start >>>
          debugPrint('[AudioProvider] Attempting to play local/asset URL: $_audioUrl');
          // <<< Logging End >>>
          // For non-http URLs (like asset:// or file://)
          await _player.setUrl(_audioUrl!);
        }
        
        // <<< Logging Start >>>
        debugPrint('[AudioProvider] Successfully set URL in player. Preparing to play.');
        // <<< Logging End >>>
        await _player.seek(Duration.zero);
        await _player.play();
      } catch (urlError) {
        // <<< Logging Start >>>
        debugPrint('[AudioProvider] CRITICAL ERROR setting URL or starting playback: $urlError');
        // <<< Logging End >>>
        // More detailed error handling for URL loading failures
        debugPrint('[AudioProvider] Failed to load URL: $urlError');
        
        if (urlError.toString().contains('404') || urlError.toString().contains('not found')) {
          debugPrint('[AudioProvider] Audio file not found. Check if the file exists at: $_audioUrl');
        } else if (urlError.toString().contains('permission') || urlError.toString().contains('denied')) {
          debugPrint('[AudioProvider] Permission denied accessing audio file. Check Firebase Storage rules.');
        } else if (urlError.toString().contains('network') || urlError.toString().contains('connection')) {
          debugPrint('[AudioProvider] Network error. Check your internet connection.');
        } else if (urlError.toString().contains('CORS') || urlError.toString().contains('cross-origin')) {
          debugPrint('[AudioProvider] CORS error. Firebase Storage CORS settings may need to be configured.');
        }
        
        // Try alternative URL format if it's a Firebase Storage URL
        if (_audioUrl!.contains('firebasestorage.googleapis.com')) {
          debugPrint('[AudioProvider] Attempting alternative Firebase Storage URL format');
          
          // Try to simplify the URL by removing query parameters
          String cleanUrl = _audioUrl!;
          if (cleanUrl.contains('?')) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf('?'));
            debugPrint('[AudioProvider] Trying with simplified URL: $cleanUrl');
            
            try {
              await _player.setUrl(cleanUrl);
              await _player.seek(Duration.zero);
              await _player.play();
              // Success with clean URL, update the stored URL
              _audioUrl = cleanUrl;
              debugPrint('[AudioProvider] Success with simplified URL');
            } catch (e) {
              debugPrint('[AudioProvider] Also failed with simplified URL: $e');
              
              // Final attempt - try with a direct download URL format
              if (cleanUrl.contains('/o/')) {
                // Try to convert to a download URL format
                final String directUrl = cleanUrl.replaceFirst('/o/', '/v0/b/') + '?alt=media';
                debugPrint('[AudioProvider] Trying with direct download URL: $directUrl');
                
                try {
                  await _player.setUrl(directUrl);
                  await _player.seek(Duration.zero);
                  await _player.play();
                  // Success with direct URL, update the stored URL
                  _audioUrl = directUrl;
                  debugPrint('[AudioProvider] Success with direct download URL');
                } catch (finalError) {
                  debugPrint('[AudioProvider] All URL attempts failed: $finalError');
                  rethrow; // Rethrow the final error after all attempts
                }
              } else {
                rethrow; // Rethrow if not a standard Firebase path
              }
            }
          } else {
            rethrow; // Rethrow if no query parameters to strip
          }
        } else {
          rethrow; // Rethrow if not a Firebase Storage URL
        }
      }

      _isPlaying = true;
      _showMiniPlayer = true;
      _isInitialized = true;
      
      _cacheAudioData(); // Cache uses the generic _currentAudio fields
      
      // <<< Logging Start >>>
      debugPrint('[AudioProvider] Playback setup successful for $mediaId. isPlaying=$_isPlaying, showMiniPlayer=$_showMiniPlayer');
      // <<< Logging End >>>
      notifyListeners();
    } catch (e) {
      // <<< Logging Start >>>
      debugPrint('[AudioProvider] CATCH BLOCK: Unhandled error during startAudioPlayback for $mediaId: $e');
      debugPrint('[AudioProvider] Resetting audio provider state due to error.');
      // <<< Logging End >>>
      _currentAudio = null;
      _originalLesson = null;
      _originalDailyAudio = null;
      _title = null;
      _subtitle = null;
      _audioUrl = null;
      _imageUrl = null;
      _audioSource = AudioSource.unknown;
      _courseTitleForCache = null;
      _isPlaying = false;
      _showMiniPlayer = false;
      _isInitialized = false; // Consider if this should be true or false on error
      notifyListeners();
      rethrow; // Rethrow the error to signal failure
    }
  }

  Future<void> startAudio(
    String title,
    String subtitle,
    String audioUrl,
    String imageUrl, {
    MediaItem? audioData,
    AudioSource sourceType = AudioSource.unknown,
    String? courseTitle,
  }) async {
    if (_disposed) return;

    final basicAudio = Audio(
      id: audioData?.id ?? audioUrl,
      title: title,
      subtitle: subtitle,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      description: audioData?.description ?? subtitle,
      sequence: 0,
      slideshowImages: [],
      sourceType: sourceType,
      courseTitle: courseTitle,
    );

    // Call the main playback logic, but pass the generic object
    // This means originalLesson/originalDailyAudio won't be set
    await startAudioPlayback(basicAudio); 
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
       if ((previousPosition - _currentPosition).abs() > 0.1) {
          debugPrint('[AudioProvider] Position Stream: currentPosition=${_currentPosition.toStringAsFixed(1)}s');
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
      prefs.setString('audio_source_type', _audioSource.name);
      if (_courseTitleForCache != null) {
         prefs.setString('audio_course_title', _courseTitleForCache!); 
      } else {
         prefs.remove('audio_course_title');
      }

      debugPrint('[AudioProvider] Caching audio data: title=$_title, pos=$_currentPosition, source=$_audioSource');
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

  Future<void> stop() async {
    debugPrint('[AudioProvider] Stopping audio...');
    await _player.stop();
    _currentAudio = null;
    _originalLesson = null;
    _originalDailyAudio = null;
    _title = null;
    _subtitle = null;
    _audioUrl = null;
    _imageUrl = null;
    _currentPosition = 0;
    _isPlaying = false;
    _showMiniPlayer = false; // Ensure mini-player is hidden on stop
    _isFullScreenPlayerOpen = false; // Ensure full screen is marked closed
    _audioSource = AudioSource.unknown;
    _courseTitleForCache = null;
    
    _clearCachedAudioData(); // Clear cache on explicit stop
    
    notifyListeners();
  }
  
  // Method to close just the mini-player (used by mini-player's close button)
  void closeMiniPlayer() {
     debugPrint('[AudioProvider] Closing mini-player explicitly.');
     // Explicitly call stop() to ensure full state reset and cache clearing
     stop(); 
     // _showMiniPlayer = false; // Old logic, now handled by stop()
     // notifyListeners(); // Old logic, now handled by stop()
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
    // <<< Logging Start >>>
    debugPrint('[AudioProvider] dispose() called. Cancelling timers and disposing player.');
    // <<< Logging End >>>
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
    // <<< LOGGING START >>>
    debugPrint('[AudioProvider] setFullScreenPlayerOpen called with: $isOpen. Current source: $_audioSource, Current audio ID: ${_currentAudio?.id}');
    // <<< LOGGING END >>>
    
    bool needsNotify = _isFullScreenPlayerOpen != isOpen; // Only notify if value changes
    _isFullScreenPlayerOpen = isOpen;
    
    // --- MODIFIED LOGIC --- 
    if (!isOpen) {
      // Closing full screen - ALWAYS stop audio and hide mini-player now
      debugPrint('[AudioProvider] Full screen closed. Stopping audio and hiding mini-player (mini-player disabled).');
      stop(); // Stop also resets state and hides mini-player
      needsNotify = false; // Stop() already notifies
    } else {
      // When opening full screen, hide the mini player immediately
      debugPrint('[AudioProvider] Full screen opened. Hiding mini-player.');
      _showMiniPlayer = false;
      needsNotify = true;
    }
    // --- END MODIFIED LOGIC ---
    
    if (needsNotify) {
      notifyListeners();
    }
  }

  void setCurrentAudio(Audio audio) {
    _currentAudio = audio;
    _imageUrl = audio.imageUrl;
    _title = audio.title;
    _subtitle = audio.subtitle;
    _audioSource = audio.sourceType; // Update source if set directly
    _courseTitleForCache = audio.courseTitle;
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

  Future<void> _clearCachedAudioData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('audio_title');
      await prefs.remove('audio_subtitle');
      await prefs.remove('audio_url');
      await prefs.remove('audio_image_url');
      await prefs.remove('audio_position');
      await prefs.remove('audio_source_type');
      await prefs.remove('audio_course_title');
      debugPrint('[AudioProvider] Clearing cached audio data.');
    } catch (e) {
      debugPrint('Error clearing cached audio data: $e');
    }
  }
} 