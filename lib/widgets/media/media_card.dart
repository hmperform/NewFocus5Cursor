import 'package:flutter/material.dart';
import 'package:focus5/models/content_models.dart'; // Assuming you have a Media model

class MediaCard extends StatelessWidget {
  final dynamic mediaItem; // Could be Video, Audio, Article etc.
  final VoidCallback onTap;

  const MediaCard({
    Key? key,
    required this.mediaItem,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = 'Media Item';
    IconData icon = Icons.play_circle_outline;

    // Determine title and icon based on mediaItem type
    if (mediaItem is Lesson) {
      title = mediaItem.title;
      icon = mediaItem.type == LessonType.video ? Icons.videocam : Icons.headphones;
    } else if (mediaItem is Article) {
      title = mediaItem.title;
      icon = Icons.article;
    }
    // Add more types if needed

    // TODO: Implement a proper Media Card UI
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 