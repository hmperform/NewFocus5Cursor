import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/daily_audio_provider.dart';
import 'package:focus5/screens/home/audio_player_screen.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/services/user_service.dart';
import 'package:focus5/providers/audio_provider.dart';

class AudioModuleCard extends StatelessWidget {
  const AudioModuleCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioModuleProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final audio = provider.currentAudioModule;
        if (audio == null) {
          return const SizedBox.shrink();
        }

        final userService = Provider.of<UserService>(context, listen: false);
        final totalLoginDays = userService.currentUser?.totalLoginDays ?? 0;

        return GestureDetector(
          onTap: () async {
            debugPrint('[AudioModuleCard] onTap triggered for audio: ${audio.title} (ID: ${audio.id})');
            final audioProvider = Provider.of<AudioProvider>(context, listen: false);
            final currentPlayingAudioId = audioProvider.currentAudio?.id;
            debugPrint('[AudioModuleCard] Current playing audio ID in provider: $currentPlayingAudioId');

            try {
              // If this is the currently playing audio, just open the full screen player
              if (currentPlayingAudioId == audio.id) {
                debugPrint('[AudioModuleCard] Opening full screen for currently playing audio');
                audioProvider.setFullScreenPlayerOpen(true);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioPlayerScreen(
                      audio: audio,
                      currentDay: totalLoginDays,
                    ),
                  ),
                );
                return;
              }

              // If it's a different audio, start playing it using the new method
              debugPrint('[AudioModuleCard] Starting new audio via provider.');
              await audioProvider.startAudioPlayback(audio);

              // Only navigate if we're still mounted and the audio was successfully started
              if (!context.mounted) return;
              if (audioProvider.currentAudio?.id == audio.id) {
                debugPrint('[AudioModuleCard] Audio started successfully, opening full screen player');
                audioProvider.setFullScreenPlayerOpen(true);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioPlayerScreen(
                      audio: audio,
                      currentDay: totalLoginDays,
                    ),
                  ),
                );
              } else {
                debugPrint('[AudioModuleCard] Audio failed to start or was interrupted');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to start audio playback')),
                );
              }
            } catch (e) {
              debugPrint('[AudioModuleCard] Error handling audio tap: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error playing audio: $e')),
                );
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(audio.thumbnail),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AUDIO MODULE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Day ${totalLoginDays}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    audio.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    audio.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${audio.durationMinutes} min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 