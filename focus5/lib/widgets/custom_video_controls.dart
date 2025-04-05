import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/media_provider.dart';

class CustomVideoControls extends StatefulWidget {
  final VoidCallback onClose;

  const CustomVideoControls({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  bool _showControls = true;
  bool _dragging = false;
  double _currentSliderValue = 0.0;
  Timer? _hideTimer;
  MediaProvider? _mediaProvider;

  @override
  void initState() {
    super.initState();
    _resetHideTimer();
    
    // We'll subscribe to the position stream in didChangeDependencies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateFromProvider();
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    _updateFromProvider();
    // Start listening to position changes
    _mediaProvider?.positionStream.listen((position) {
      if (mounted && !_dragging) {
        setState(() {
          _currentSliderValue = position;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
  
  void _updateFromProvider() {
    final mediaProvider = _mediaProvider;
    if (mediaProvider != null && mounted) {
      setState(() {
        _currentSliderValue = mediaProvider.currentPosition;
      });
    }
  }
  
  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && !_dragging) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }
  
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _resetHideTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context);
    final duration = mediaProvider.totalDuration;
    
    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Background overlay when controls are visible
          if (_showControls)
            Container(
              color: Colors.black.withOpacity(0.4),
            ),
            
          // Controls
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
                
                // Center play/pause button
                Expanded(
                  child: Center(
                    child: IconButton(
                      iconSize: 60,
                      icon: Icon(
                        mediaProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        mediaProvider.togglePlayPause();
                        _resetHideTimer();
                      },
                    ),
                  ),
                ),
                
                // Bottom controls with seek bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  color: Colors.black.withOpacity(0.6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Time indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_currentSliderValue),
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      
                      // Slider for seeking
                      SliderTheme(
                        data: SliderThemeData(
                          thumbColor: Colors.white,
                          activeTrackColor: const Color(0xFFB4FF00),
                          inactiveTrackColor: Colors.grey.shade600,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                          trackHeight: 4.0,
                          overlayColor: const Color(0xFFB4FF00).withOpacity(0.3),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                        ),
                        child: Slider(
                          value: _currentSliderValue.clamp(0.0, duration),
                          min: 0.0,
                          max: duration,
                          onChanged: (value) {
                            setState(() {
                              _currentSliderValue = value;
                              _dragging = true;
                            });
                            _resetHideTimer();
                          },
                          onChangeStart: (_) {
                            setState(() {
                              _dragging = true;
                            });
                            _resetHideTimer();
                          },
                          onChangeEnd: (value) {
                            // Show seeking indicator
                            setState(() {
                              _dragging = false;
                            });
                            
                            // Use the stored provider reference for safety
                            final mediaProvider = _mediaProvider ?? Provider.of<MediaProvider>(context, listen: false);
                            
                            // CRITICAL FIX: Ensure position value is used correctly
                            debugPrint('Slider change ended at position: $value');
                            
                            // Use the exact slider value for better precision
                            mediaProvider.seekTo(value);
                            
                            // Immediately update our slider value for better UI responsiveness
                            setState(() {
                              _currentSliderValue = value;
                            });
                            
                            _resetHideTimer();
                          },
                        ),
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
  
  String _formatDuration(double seconds) {
    final int mins = (seconds / 60).floor();
    final int secs = (seconds % 60).floor();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
} 