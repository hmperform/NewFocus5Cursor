import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart' hide AudioSource;
import 'package:transparent_image/transparent_image.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/providers/user_provider.dart';
import 'package:focus5/services/media_completion_service.dart';
import 'dart:async'; // Added for StreamSubscription
import 'dart:math' as math;
import 'package:focus5/providers/audio_provider.dart';
import '../post_completion_screen.dart'; // May need adjustment based on desired flow
import 'dart:ui'; // Import for ImageFilter

class LessonAudioPlayerScreen extends StatefulWidget {
  final Lesson lesson;
  final String courseTitle;

  const LessonAudioPlayerScreen({
    Key? key,
    required this.lesson,
    required this.courseTitle,
  }) : super(key: key);

  @override
  State<LessonAudioPlayerScreen> createState() => _LessonAudioPlayerScreenState();
}

class _LessonAudioPlayerScreenState extends State<LessonAudioPlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _slideshowController;
  int _currentSlideIndex = 0;
  bool _isCompleted = false; // Local completion state for UI, not the official one
  StreamSubscription<PlayerState>? _playerStateSubscription; // Subscription for completion
  late AudioProvider _audioProviderInstance; // <<< ADDED: Store provider instance

  List<String> _slideshowImages = [];

  // Add waveform data if available in Lesson model, otherwise null
  // List<double>? _waveformData = widget.lesson.waveformData; // Assuming Lesson might have waveform data
  // int _waveformResolution = widget.lesson.waveformResolution ?? 100; // Assuming Lesson might have resolution
  // For now, assume no waveform data for lessons
  final List<double>? _waveformData = null;
  final int _waveformResolution = 100;
  double _waveformProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // <<< ADDED: Get and store provider instance >>>
    _audioProviderInstance = Provider.of<AudioProvider>(context, listen: false);
    
    // <<< LOGGING START >>>
    debugPrint('[LessonAudioPlayerScreen] initState: isFullScreenPlayerOpen=${_audioProviderInstance.isFullScreenPlayerOpen}');
    // <<< LOGGING END >>>
    
    debugPrint('[LessonAudioPlayerScreen] initState for lesson: ${widget.lesson.title} (ID: ${widget.lesson.id})');

    // Use the stored instance from now on in initState
    _audioProviderInstance.setFullScreenPlayerOpen(true); 

    // Initialize slideshow images from Lesson object
    // Assuming lesson object has a slideshowImages field similar to the JSON example
    _slideshowImages = widget.lesson.slideshowImages ?? []; // Use lesson.slideshowImages

    _slideshowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Simple 10s interval like daily audio
    )..addListener(() {
        if (_slideshowImages.isNotEmpty && _slideshowController.isCompleted) {
          setState(() {
            _currentSlideIndex = (_currentSlideIndex + 1) % _slideshowImages.length;
          });
          _slideshowController.forward(from: 0.0);
        }
      });

    // Start audio playback and listen for completion
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Pass the stored instance
      await _initializeAndPlayAudio(_audioProviderInstance);
      _listenForCompletion(_audioProviderInstance);
    });
  }

  Future<void> _initializeAndPlayAudio(AudioProvider audioProvider) async {
    debugPrint('[LessonAudioPlayerScreen] Starting audio playback for lesson ID: ${widget.lesson.id}');
    if (widget.lesson.audioUrl == null || widget.lesson.audioUrl!.isEmpty) {
       debugPrint('[LessonAudioPlayerScreen] No audio URL found for lesson ID: ${widget.lesson.id}');
       if (mounted) { // Check if mounted before showing SnackBar/popping
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('No audio available for this lesson')),
         );
         Navigator.of(context).pop();
       }
       return;
    }

    try {
      // Only initialize audio if it's not already playing the same track
      if (audioProvider.currentAudio?.id != widget.lesson.id) {
        // Create a generic Audio object for the provider - NO LONGER NEEDED HERE
        // final audio = Audio(
        //   id: widget.lesson.id,
        //   title: widget.lesson.title,
        //   subtitle: widget.courseTitle, 
        //   audioUrl: widget.lesson.audioUrl!,
        //   imageUrl: widget.lesson.thumbnailUrl ?? '',
        //   description: widget.lesson.description ?? '',
        //   slideshowImages: _slideshowImages,
        //   sequence: widget.lesson.sortOrder, 
        //   sourceType: AudioSource.lesson,   
        //   courseTitle: widget.courseTitle, 
        // );

        // await audioProvider.startAudioPlayback(audio); // OLD CALL
        await audioProvider.startAudioPlayback(widget.lesson); // <-- PASS ORIGINAL LESSON
        debugPrint('[LessonAudioPlayerScreen] Audio playback started successfully via provider');
      } else {
        // If same audio, ensure it's playing and full screen state is correct
        if (!audioProvider.isPlaying) {
           audioProvider.audioPlayer.play();
        }
        audioProvider.setFullScreenPlayerOpen(true); // Ensure full screen state
        debugPrint('[LessonAudioPlayerScreen] Same audio already managed by provider, ensuring playback and full screen.');
      }

      if (audioProvider.isPlaying && _slideshowImages.isNotEmpty) {
        _slideshowController.forward();
      }
    } catch (e) {
      debugPrint('[LessonAudioPlayerScreen] Error starting audio: $e');
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: ${e.toString()}')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _listenForCompletion(AudioProvider audioProvider) {
    _playerStateSubscription?.cancel(); // Cancel previous subscription if any
    _playerStateSubscription = audioProvider.audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        debugPrint('[LessonAudioPlayerScreen] Audio completed for lesson ID: ${widget.lesson.id}');
        _markMediaAsCompleted();
        setState(() {
          _isCompleted = true; // Update local UI state if needed
        });
        // Optionally, navigate away or show completion message
        // Example: navigate to post completion screen or back
        // _navigateToCompletion();
      }

      // Handle slideshow based on play state
       if (_slideshowImages.isNotEmpty) {
          if (state.playing) {
            _slideshowController.forward();
          } else {
            _slideshowController.stop();
          }
       }
    });
  }

  Future<void> _markMediaAsCompleted() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) {
      debugPrint('[LessonAudioPlayerScreen] User ID is null, cannot mark media as completed.');
      return;
    }

    final mediaCompletionService = MediaCompletionService();
    try {
      await mediaCompletionService.markMediaCompleted(
        userId,
        widget.lesson.id,
        MediaType.audio, // Make sure MediaType enum includes 'audio'
      );
      debugPrint('[LessonAudioPlayerScreen] Marked media as completed for lesson: ${widget.lesson.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio completed! You can now mark the lesson as finished.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('[LessonAudioPlayerScreen] Error marking media as completed: $e');
    }
  }

  void _navigateToCompletion() {
    // Example: Navigate back or to a specific completion screen
     if (mounted) {
       // Maybe pop? Or navigate to a course summary?
       // Navigator.of(context).pop();

       // Or navigate to a generic post-completion screen if applicable
       /*
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(
           builder: (context) => PostCompletionScreen(
             title: widget.lesson.title,
             completionText: "You've completed this audio lesson!",
             xpEarned: 50, // Example XP
           ),
         ),
       );
       */
     }
  }


  @override
  void dispose() {
    debugPrint('[LessonAudioPlayerScreen] dispose');
    _slideshowController.dispose();
    _playerStateSubscription?.cancel(); // Cancel subscription

    // <<< MODIFIED: Use stored provider instance, removed context lookup >>>
    // Inform the provider that the full screen player is closing *only if*
    // this specific audio instance is the one currently managed by the provider.
    // Avoid resetting if another audio was started in the meantime.
     if (_audioProviderInstance.currentAudio?.id == widget.lesson.id) {
       _audioProviderInstance.setFullScreenPlayerOpen(false);
       // Decide if you want to stop the audio or let it continue in mini-player
       // _audioProviderInstance.stop(); // Uncomment to stop audio when screen is closed
     }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer for reactive UI updates based on AudioProvider state
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        // <<< LOGGING START >>>
        debugPrint('[LessonAudioPlayerScreen] Build: isFullScreenPlayerOpen=${audioProvider.isFullScreenPlayerOpen}');
        // <<< LOGGING END >>>

        // Ensure the provider's current audio matches this lesson's audio
        // This check might be needed if the user navigates away and back quickly
        // or if background audio changes state.
        final bool isCurrentAudio = audioProvider.currentAudio?.id == widget.lesson.id;
        final String displayTitle = isCurrentAudio ? (audioProvider.title ?? widget.lesson.title) : widget.lesson.title;
        final double currentPosition = isCurrentAudio ? audioProvider.position.inSeconds.toDouble() : 0.0;
        final double totalDuration = isCurrentAudio ? (audioProvider.duration.inSeconds.toDouble() > 0 ? audioProvider.duration.inSeconds.toDouble() : (widget.lesson.durationMinutes * 60).toDouble()) : (widget.lesson.durationMinutes * 60).toDouble();
        final bool isPlaying = isCurrentAudio && audioProvider.isPlaying;

        // Update waveform progress
        _waveformProgress = totalDuration > 0 ? currentPosition / totalDuration : 0.0;

        // Determine slideshow image URL
        String? currentSlideUrl;
        if (_slideshowImages.isNotEmpty && _currentSlideIndex < _slideshowImages.length) {
             currentSlideUrl = _slideshowImages[_currentSlideIndex];
        } else if (widget.lesson.thumbnailUrl != null && widget.lesson.thumbnailUrl!.isNotEmpty) {
            currentSlideUrl = widget.lesson.thumbnailUrl; // Fallback to lesson thumbnail
        }

        // <<< --- UI Refactoring Start --- >>>
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full screen slideshow background
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: currentSlideUrl != null
                      ? FadeInImage.memoryNetwork(
                          key: ValueKey<String>(currentSlideUrl), // Key for animation
                          placeholder: kTransparentImage,
                          image: currentSlideUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                           imageErrorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50))),
                        )
                      : Container(color: Colors.grey[900], child: const Center(child: Icon(Icons.music_note, color: Colors.grey, size: 100))), // Placeholder if no image
                ),
              ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),
              ),

              // Content Area
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: Column(
                      children: [
                        // Custom AppBar (Title + Back Button)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: _handleBackButton,
                              ),
                              Expanded(
                                child: Text(
                                  displayTitle, // Use lesson title
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18, // Slightly smaller than daily
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 48), // To balance the IconButton
                            ],
                          ),
                        ),

                         // Time Display
                        Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Fit content
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDuration(Duration(seconds: currentPosition.toInt())),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const Text(
                                ' / ',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              Text(
                                _formatDuration(Duration(seconds: totalDuration.toInt())),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(), // Pushes controls to the bottom half

                        // Waveform Display
                        Container(
                          height: 60, // Define a height for the waveform area
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Use placeholder as Lesson model doesn't have waveform data
                              return _buildPlaceholderWaveform(constraints.maxWidth);
                              // return _buildActualWaveform(constraints.maxWidth);
                            },
                          ),
                        ),

                        // Glassmorphic Controls
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(25.0),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.replay_10, color: Colors.white, size: 35),
                                    onPressed: isCurrentAudio ? () => audioProvider.audioPlayer.seek(audioProvider.position - const Duration(seconds: 10)) : null,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 65,
                                    ),
                                    onPressed: isCurrentAudio
                                      ? () {
                                          if (isPlaying) {
                                            audioProvider.audioPlayer.pause();
                                          } else {
                                            audioProvider.audioPlayer.play();
                                          }
                                        }
                                      : null,
                                  ),
                                  IconButton(
                                    // Match daily audio - forward 10 seconds
                                    icon: const Icon(Icons.forward_10, color: Colors.white, size: 35),
                                    onPressed: isCurrentAudio ? () => audioProvider.audioPlayer.seek(audioProvider.position + const Duration(seconds: 10)) : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Description Area (Optional - check if lesson description exists)
                        if (widget.lesson.description != null && widget.lesson.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0, left: 16, right: 16, bottom: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(15.0),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Text(
                                    widget.lesson.description!,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        // <<< --- UI Refactoring End --- >>>
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _handleBackButton() {
    // <<< MODIFIED: Remove redundant state change call >>>
    // final audioProvider = Provider.of<AudioProvider>(context, listen: false); // No longer needed here
    // audioProvider.setFullScreenPlayerOpen(false); // Removed - handled by dispose
    Navigator.of(context).pop();
  }

  // Waveform building logic (copied and adapted from AudioPlayerScreen)
  // Build waveform using actual data if available
  Widget _buildActualWaveform(double width) {
    if (_waveformData == null || _waveformData!.isEmpty) {
      return _buildPlaceholderWaveform(width);
    }

    final totalSamples = _waveformData!.length;
    final barCount = (width / 4).floor(); // Adjust density as needed
    final samplesPerBar = (totalSamples / barCount).floor();
    final barWidth = width / (barCount * 2); // Give some spacing

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(barCount, (index) {
        final startIndex = index * samplesPerBar;
        final endIndex = (startIndex + samplesPerBar).clamp(0, totalSamples);
        if (startIndex >= endIndex) return SizedBox.shrink();

        double amplitude = 0;
        int count = 0;
        for (int i = startIndex; i < endIndex; i++) {
          amplitude += _waveformData![i].abs();
          count++;
        }
        amplitude = count > 0 ? amplitude / count : 0;

        // Normalize amplitude to bar height (0-40) and cast to double
        final height = (amplitude * 40).clamp(2, 40).toDouble();
        final isActive = index / barCount <= _waveformProgress;

        return Container(
          width: barWidth,
          height: height,
          margin: EdgeInsets.symmetric(horizontal: barWidth / 2),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  // Placeholder waveform when no data is available
  Widget _buildPlaceholderWaveform(double width) {
    final barCount = (width / 4).floor();
    final barWidth = width / (barCount * 2);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(barCount, (index) {
        // Generate a simple sine wave pattern and cast to double
        final height = (20 + (20 * math.sin(index * 0.2)).abs()).toDouble();
        final isActive = index / barCount <= _waveformProgress;

        return Container(
          width: barWidth,
          height: height,
          margin: EdgeInsets.symmetric(horizontal: barWidth / 2),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// Ensure MediaType enum in media_completion_service.dart (or wherever it's defined) includes 'audio'
/*
enum MediaType { video, audio, article, quiz } // Example
*/ 