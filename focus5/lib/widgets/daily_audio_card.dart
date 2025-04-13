import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/daily_audio_provider.dart';
import 'package:focus5/screens/home/audio_player_screen.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/services/user_service.dart';

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
          onTap: () {
            debugPrint('[AudioModuleCard] onTap triggered for audio: ${audio.title} (ID: ${audio.id})');
            final audioProvider = Provider.of<AudioProvider>(context, listen: false);
            final currentPlayingAudioId = audioProvider.currentAudio?.id;
            debugPrint('[AudioModuleCard] Current playing audio ID in provider: $currentPlayingAudioId');

            if (currentPlayingAudioId != audio.id) {
              debugPrint('[AudioModuleCard] Starting new audio via provider.');
              final basicAudio = Audio(
                  id: audio.id,
                  title: audio.title,
                  subtitle: audio.focusAreas.join(', '),
                  audioUrl: audio.audioUrl,
                  imageUrl: audio.thumbnail,
                  slideshowImages: [audio.slideshow1, audio.slideshow2, audio.slideshow3].where((s) => s.isNotEmpty).toList(),
              );
              // Using await here might be important if startAudioFromDaily does async work before UI update
              audioProvider.startAudioFromDaily(basicAudio); 
            } else {
               debugPrint('[AudioModuleCard] Tapped audio is already playing.');
            }

            debugPrint('[AudioModuleCard] Setting full screen player open and navigating...');
            audioProvider.setFullScreenPlayerOpen(true); // Explicitly set before navigating
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioPlayerScreen(
                  audio: audio,
                  currentDay: totalLoginDays,
                ),
              ),
            );
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