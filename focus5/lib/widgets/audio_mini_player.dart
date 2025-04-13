import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/audio_provider.dart';
import '../screens/home/audio_player_screen.dart';
import '../models/content_models.dart';

class AudioMiniPlayer extends StatefulWidget {
  final double bottomPadding;

  const AudioMiniPlayer({Key? key, this.bottomPadding = 80}) : super(key: key);

  @override
  State<AudioMiniPlayer> createState() => _AudioMiniPlayerState();
}

class _AudioMiniPlayerState extends State<AudioMiniPlayer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPlaybackState();
    });
  }

  // Periodically check playback state to ensure continuity
  void _checkPlaybackState() {
    if (!mounted) return;
    
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    
    // Ensure audio is playing if it should be
    if (audioProvider.isPlaying && audioProvider.audioPlayer.playing) {
      audioProvider.audioPlayer.play();
    }
    
    // Schedule next check
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _checkPlaybackState();
      }
    });
  }

  void _openFullScreenPlayer() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final audio = audioProvider.currentAudio;
    
    if (audio == null) return;
    
    // Navigate to full screen player
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AudioPlayerScreen(
          audio: audio,
          currentDay: 1, // You'll need to get this from your UserProvider
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        // Don't show mini player if no audio or if explicitly hidden
        if (!audioProvider.showMiniPlayer || audioProvider.isFullScreenPlayerOpen) {
          return const SizedBox.shrink();
        }

        return _buildMiniPlayer(audioProvider);
      },
    );
  }

  Widget _buildMiniPlayer(AudioProvider audioProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: 64,
      width: screenWidth,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _openFullScreenPlayer,
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: audioProvider.imageUrl != null
                  ? Image.network(
                      audioProvider.imageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.audiotrack,
                            color: Colors.white54,
                            size: 30,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.audiotrack,
                        color: Colors.white54,
                        size: 30,
                      ),
                    ),
            ),
            
            // Title and subtitle
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      audioProvider.title ?? 'Unknown Title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      audioProvider.subtitle ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // Backward 10 seconds button
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(
                  Icons.replay_10,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final position = audioProvider.audioPlayer.position;
                  final newPosition = position - const Duration(seconds: 10);
                  audioProvider.audioPlayer.seek(newPosition);
                },
              ),
            ),
            
            // Play/Pause button
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: IconButton(
                icon: Icon(
                  audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  audioProvider.togglePlayPause();
                },
              ),
            ),
            
            // Forward 10 seconds button
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(
                  Icons.forward_10,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final position = audioProvider.audioPlayer.position;
                  final newPosition = position + const Duration(seconds: 10);
                  if (newPosition <= audioProvider.audioPlayer.duration!) {
                    audioProvider.audioPlayer.seek(newPosition);
                  }
                },
              ),
            ),
            
            // Close button
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(
                  Icons.close, 
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  audioProvider.closeMiniPlayer();
                },
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
} 