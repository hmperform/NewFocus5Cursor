import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/providers/user_provider.dart';
import 'package:focus5/services/media_completion_service.dart';
import 'dart:math' as math;
import 'package:focus5/providers/audio_provider.dart';

class AudioPlayerScreen extends StatefulWidget {
  final DailyAudio audio;
  final int currentDay;

  const AudioPlayerScreen({
    Key? key,
    required this.audio,
    required this.currentDay,
  }) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _slideshowController;
  int _currentSlideIndex = 0;
  int _skipCount = 0;
  bool _isCompleted = false;
  double _waveformProgress = 0.0;

  final List<String> _slideshowImages = [];

  @override
  void initState() {
    super.initState();
    debugPrint('[AudioPlayerScreen] initState for audio: ${widget.audio.title} (ID: ${widget.audio.id})');
    
    // Get the provider and ensure it's ready
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.setFullScreenPlayerOpen(true);
    
    // Initialize slideshow
    _slideshowImages.addAll([
      widget.audio.slideshow1,
      widget.audio.slideshow2,
      widget.audio.slideshow3,
    ].where((s) => s.isNotEmpty).toList());

    _slideshowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (_slideshowController.isCompleted) {
          setState(() {
            _currentSlideIndex = (_currentSlideIndex + 1) % _slideshowImages.length;
          });
          _slideshowController.forward(from: 0.0);
        }
      });

    // Start audio playback
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('[AudioPlayerScreen] Starting audio playback...');
      try {
        final audioProvider = Provider.of<AudioProvider>(context, listen: false);
        // Only initialize audio if it's not already playing the same track
        if (audioProvider.currentAudio?.id != widget.audio.id) {
          // Convert DailyAudio to Audio
          final audio = Audio(
            id: widget.audio.id,
            title: widget.audio.title,
            subtitle: widget.audio.focusAreas.join(', '),
            audioUrl: widget.audio.audioUrl,
            imageUrl: widget.audio.thumbnail,
            description: widget.audio.description,
            sequence: 0,
            slideshowImages: [
              widget.audio.slideshow1,
              widget.audio.slideshow2,
              widget.audio.slideshow3,
            ].where((s) => s.isNotEmpty).toList(),
          );
          
          await audioProvider.startAudioFromDaily(audio);
          debugPrint('[AudioPlayerScreen] Audio playback started successfully');
        } else {
          debugPrint('[AudioPlayerScreen] Same audio already playing, skipping initialization');
        }
        
        if (audioProvider.isPlaying) {
          _slideshowController.forward();
        }
      } catch (e) {
        debugPrint('[AudioPlayerScreen] Error starting audio: $e');
      }
    });
  }

  void _markAsCompleted() {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    if (userId != null) {
      final mediaCompletionService = MediaCompletionService();
      mediaCompletionService.markMediaCompleted(userId, widget.audio.id, MediaType.audio);
    }
  }

  void _togglePlayPause() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.togglePlayPause();
    
    if (audioProvider.isPlaying) {
      _slideshowController.forward();
    } else {
      _slideshowController.stop();
    }
  }

  void _skipForward() {
    if (_skipCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum skip limit reached')),
      );
      return;
    }

    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.seekRelative(const Duration(seconds: 30));
    _skipCount++;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  void dispose() {
    debugPrint('[AudioPlayerScreen] Disposing screen for audio ID: ${widget.audio.id}');
    
    // Tell the provider the full screen is closing
    Provider.of<AudioProvider>(context, listen: false).setFullScreenPlayerOpen(false);
    debugPrint('[AudioPlayerScreen] Called setFullScreenPlayerOpen(false) on provider.');

    // Dispose local resources
    _slideshowController.dispose();
    debugPrint('[AudioPlayerScreen] Slideshow controller disposed.');
    
    super.dispose();
    debugPrint('[AudioPlayerScreen] super.dispose() called.');
  }

  // Add logging to back button press
  void _handleBackButton() {
    debugPrint('[AudioPlayerScreen] Back button pressed.');
    Provider.of<AudioProvider>(context, listen: false).setFullScreenPlayerOpen(false);
    Navigator.pop(context);
  }

  // Custom waveform widget
  Widget _buildWaveform() {
    return SizedBox(
      height: 80,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final waveformData = widget.audio.waveformData;
          final resolution = widget.audio.waveformResolution;
          
          // If no waveform data, show a placeholder
          if (waveformData.isEmpty) {
            return _buildPlaceholderWaveform(width);
          }
          
          // Calculate number of bars based on resolution and width
          final barCount = (width / 4).floor(); // One bar every 4 pixels
          final barWidth = width / (barCount * 2);
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(barCount, (index) {
              // Calculate the sample index based on the waveform resolution
              final sampleIndex = (index * resolution / barCount).floor();
              final sampleIndexNext = ((index + 1) * resolution / barCount).floor();
              
              // Get the average amplitude for this segment
              double amplitude = 0;
              int count = 0;
              for (int i = sampleIndex; i < sampleIndexNext && i < waveformData.length; i++) {
                amplitude += waveformData[i].abs();
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
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        debugPrint('[AudioPlayerScreen] Build method. Provider state: isPlaying=${audioProvider.isPlaying}, showMiniPlayer=${audioProvider.showMiniPlayer}, isFullScreen=${audioProvider.isFullScreenPlayerOpen}, currentAudioId=${audioProvider.currentAudio?.id}');
        
        // Calculate waveform progress from provider state
        _waveformProgress = audioProvider.totalDuration > 0 
            ? audioProvider.currentPosition / audioProvider.totalDuration 
            : 0.0;
            
        // Check for completion
        if (!_isCompleted && audioProvider.currentPosition >= audioProvider.totalDuration && audioProvider.totalDuration > 0) {
          _isCompleted = true;
          _markAsCompleted();
        }

        // Original Scaffold structure
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full screen slideshow
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: FadeInImage.memoryNetwork(
                    key: ValueKey(_currentSlideIndex),
                    placeholder: kTransparentImage,
                    image: _slideshowImages[_currentSlideIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
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
              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Back button and title
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                              widget.audio.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // Time display
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatDuration(Duration(seconds: audioProvider.currentPosition.toInt())),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            _formatDuration(Duration(seconds: audioProvider.totalDuration.toInt())),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Waveform with glassmorphic effect
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      padding: const EdgeInsets.all(16.0),
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
                      child: _buildWaveform(),
                    ),

                    // Controls with glassmorphic effect
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(30),
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildGlassButton(
                            icon: Icons.replay_10,
                            onPressed: () {
                              final newPosition = audioProvider.currentPosition - 10;
                              if (newPosition >= 0) {
                                audioProvider.seekTo(Duration(seconds: newPosition.toInt()));
                              }
                            },
                          ),
                          _buildGlassButton(
                            icon: audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 48,
                            onPressed: _togglePlayPause,
                          ),
                          _buildGlassButton(
                            icon: Icons.forward_10,
                            onPressed: () {
                              final newPosition = audioProvider.currentPosition + 10;
                              if (newPosition <= audioProvider.totalDuration) {
                                audioProvider.seekTo(Duration(seconds: newPosition.toInt()));
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // Description with glassmorphic effect
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
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
                      child: Text(
                        widget.audio.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 24,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: onPressed,
      ),
    );
  }
} 