import 'package:flutter/material.dart';
import '../../models/content_models.dart';

class MediaCard extends StatelessWidget {
  final MediaItem mediaItem;
  final VoidCallback? onTap;

  const MediaCard({
    Key? key,
    required this.mediaItem,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    // Use MediaType enum from MediaItem instead of LessonType
    if (mediaItem.type == MediaType.video) {
      icon = Icons.videocam;
    } else if (mediaItem.type == MediaType.audio) {
      icon = Icons.headphones;
    } else {
      icon = Icons.article;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Media image
                mediaItem.imageUrl.isNotEmpty
                    ? Image.network(
                        mediaItem.imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                        child: Icon(icon, size: 50, color: Colors.grey.shade600),
                      ),
                
                // Play button overlay for videos/audio
                if (mediaItem.type == MediaType.video || mediaItem.type == MediaType.audio)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      mediaItem.type == MediaType.video ? Icons.play_arrow : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mediaItem.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: mediaItem.creatorImageUrl.isNotEmpty
                            ? NetworkImage(mediaItem.creatorImageUrl)
                            : null,
                        child: mediaItem.creatorImageUrl.isEmpty
                            ? const Icon(Icons.person, size: 12)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mediaItem.creatorName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 