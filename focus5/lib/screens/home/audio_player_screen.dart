import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'dart:async';

import '../../providers/audio_provider.dart';
import '../../models/content_models.dart';
import 'package:provider/provider.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String audioUrl;
  final String? imageUrl;
  final DailyAudio? audioData;

  const AudioPlayerScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    this.audioUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    this.imageUrl,
    this.audioData,
  }) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _currentPosition = 0;
  double _totalDuration = 1;
  late AnimationController _animationController;
  bool _disposed = false;
  AudioProvider? _audioProvider;
  
  // Simulate audio playback for demo purposes
  Timer? _playbackTimer;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
  }
  
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // Initialize the animation controller immediately
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Tell the provider the full screen player is open and initialize audio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;  // Check if widget is still mounted
      
      try {
        if (_audioProvider != null) {
          _audioProvider!.setFullScreenPlayerOpen(true);
        }
        _initAudioPlayer();
      } catch (e) {
        debugPrint('Error in post frame callback: $e');
      }
    });
  }
  
  Future<void> _initAudioPlayer() async {
    if (!mounted) return;  // Check if widget is still mounted
    
    try {
      // For demo, we won't actually load the audio
      // await _audioPlayer.setUrl(widget.audioUrl);
      
      // Instead, set a dummy duration
      _totalDuration = 179; // 2:59 in seconds
      
      _audioPlayer.playerStateStream.listen((state) {
        if (!mounted) return;  // Check if widget is still mounted
        if (state.playing != _isPlaying) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });
      
      _audioPlayer.positionStream.listen((position) {
        if (!mounted) return;  // Check if widget is still mounted
        setState(() {
          _currentPosition = position.inSeconds.toDouble();
        });
      });
      
      // Simulate playback with a timer instead of using actual audio
      if (mounted) {
        _startSimulatedPlayback();
      }
      
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  void _startSimulatedPlayback() {
    _togglePlayPause();
  }
  
  void _togglePlayPause() {
    if (!mounted || _disposed) return;
    
    try {
      if (_audioProvider == null) return;
      
      setState(() {
        _isPlaying = !_isPlaying;
        
        if (_isPlaying) {
          _animationController.forward();
          // Update the audio provider
          _audioProvider!.startAudio(
            widget.title, 
            widget.subtitle, 
            widget.audioUrl,
            widget.imageUrl ?? 'https://picsum.photos/800/800?random=42',
            audioData: widget.audioData,
          );
          
          // Start playback simulation
          _playbackTimer?.cancel();
          _playbackTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
            if (!mounted || _disposed) {
              timer.cancel();
              return;
            }
            
            setState(() {
              if (_currentPosition < _totalDuration) {
                _currentPosition += 1;
              } else {
                _currentPosition = 0;
                if (mounted && !_disposed) {
                  _togglePlayPause(); // Auto-pause when finished
                }
              }
            });
          });
        } else {
          _animationController.reverse();
          // Pause in the provider
          _audioProvider!.pauseAudio();
          // Stop simulation
          _playbackTimer?.cancel();
        }
      });
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }
  
  String _formatDuration(double seconds) {
    final int mins = (seconds / 60).floor();
    final int secs = (seconds % 60).floor();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _disposed = true;
    _playbackTimer?.cancel();
    
    // Don't call methods on AudioProvider directly during dispose
    // Instead schedule it for after the current frame
    if (_audioProvider != null) {
      final provider = _audioProvider;
      Future.microtask(() {
        provider?.setFullScreenPlayerOpen(false);
      });
    }
    
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.network(
              widget.imageUrl ?? 'https://picsum.photos/800/800?random=42',
              fit: BoxFit.cover,
            ),
          ),
          
          // Gradient overlay for better visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 0.9],
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFFB4FF00),
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // Title and subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 4),
                
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Timer display
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      SizedBox(
                        height: 20,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                            thumbColor: const Color(0xFFB4FF00),
                            activeTrackColor: const Color(0xFFB4FF00),
                            inactiveTrackColor: Colors.white24,
                            overlayColor: const Color(0x29B4FF00),
                          ),
                          child: Slider(
                            value: _currentPosition,
                            min: 0.0,
                            max: _totalDuration,
                            onChanged: (value) {
                              setState(() {
                                _currentPosition = value;
                              });
                            },
                            onChangeEnd: (value) {
                              // Seek to the new position
                              // _audioPlayer.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Playback controls
                Padding(
                  padding: const EdgeInsets.only(top: 32.0, bottom: 48.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 40),
                        onPressed: () {
                          // Skip backwards 10 seconds
                          final newPosition = _currentPosition - 10;
                          setState(() {
                            _currentPosition = newPosition < 0 ? 0 : newPosition;
                          });
                          // _audioPlayer.seek(Duration(seconds: _currentPosition.toInt()));
                        },
                      ),
                      const SizedBox(width: 24),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB4FF00),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB4FF00).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: _animationController,
                            color: Colors.black,
                            size: 40,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.forward_30, color: Colors.white, size: 40),
                        onPressed: () {
                          // Skip forward 30 seconds
                          final newPosition = _currentPosition + 30;
                          setState(() {
                            _currentPosition = newPosition > _totalDuration ? _totalDuration : newPosition;
                          });
                          // _audioPlayer.seek(Duration(seconds: _currentPosition.toInt()));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 