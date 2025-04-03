import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/audio_provider.dart';
import '../screens/home/audio_player_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  late AudioProvider _audioProvider;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely store a reference to the provider
    _audioProvider = Provider.of<AudioProvider>(context, listen: true);
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Check if we have a valid provider reference
      if (_audioProvider == null) {
        // If not, try to get it once more
        try {
          _audioProvider = Provider.of<AudioProvider>(context, listen: false);
        } catch (e) {
          // If still failing, return empty widget
          return const SizedBox.shrink();
        }
      }
      
      // Don't show mini player if it's not active or if full screen player is open
      if (!_audioProvider.isPlaying || _audioProvider.isFullScreenPlayerOpen) {
        return const SizedBox.shrink();
      }
      
      return Positioned(
        left: 0,
        right: 0,
        bottom: 80, // Position above bottom nav bar
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Find the nearest Navigator
              Navigator.maybeOf(context)?.push(
                MaterialPageRoute(
                  builder: (context) => AudioPlayerScreen(
                    title: _audioProvider.title ?? 'Daily Focus Session',
                    subtitle: _audioProvider.subtitle ?? 'Morning Mental Preparation',
                    audioUrl: _audioProvider.audioUrl ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                    imageUrl: _audioProvider.imageUrl,
                  ),
                ),
              );
            },
            child: Container(
              height: 65,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFB4FF00).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      bottomLeft: Radius.circular(32),
                    ),
                    child: Image.network(
                      _audioProvider.imageUrl ?? 'https://picsum.photos/60/60?random=42',
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 65,
                          height: 65,
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        );
                      },
                    ),
                  ),
                  // Title and subtitle
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _audioProvider.title ?? 'Daily Focus Session',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _audioProvider.subtitle ?? 'Morning Mental Preparation',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Small progress indicator
                          const SizedBox(height: 4),
                          Builder(
                            builder: (context) {
                              // Recalculate the progress value to ensure it updates
                              final progress = _audioProvider.currentPosition / 
                                (_audioProvider.totalDuration > 0 ? _audioProvider.totalDuration : 1);
                              
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 2,
                                  backgroundColor: Colors.grey[800],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB4FF00)),
                                ),
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Controls
                  IconButton(
                    icon: Icon(
                      _audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: const Color(0xFFB4FF00),
                    ),
                    onPressed: () {
                      _audioProvider.togglePlayPause();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      _audioProvider.closeMiniPlayer();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      // Catch any exceptions to prevent app crashes
      debugPrint('Error in MiniPlayer build: $e');
      return const SizedBox.shrink();
    }
  }
} 