import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../screens/home/audio_player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (!audioProvider.showMiniPlayer) return const SizedBox.shrink();

        final audio = audioProvider.currentAudio;
        if (audio == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioPlayerScreen(audio: audio),
              ),
            );
          },
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
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
                // Thumbnail
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(audio.thumbnailUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Title and controls
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // Title
                        Expanded(
                          child: Text(
                            audio.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Controls
                        IconButton(
                          icon: Icon(
                            audioProvider.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () => audioProvider.togglePlayPause(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 