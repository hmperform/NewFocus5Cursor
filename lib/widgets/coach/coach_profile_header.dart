import 'package:flutter/material.dart';

class CoachProfileHeader extends StatelessWidget {
  final String name;
  final String title;
  final String imageUrl;
  final String bio;
  final String specialization;
  final String experience;
  final double rating;
  final int reviewCount;

  const CoachProfileHeader({
    Key? key,
    required this.name,
    required this.title,
    required this.imageUrl,
    required this.bio,
    required this.specialization,
    required this.experience,
    this.rating = 0.0,
    this.reviewCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColorLight.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Coach Image
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(imageUrl),
            onBackgroundImageError: (e, s) => Container(
              child: const Icon(Icons.person, size: 60, color: Colors.white54),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name and Title
          Text(
            name, 
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          
          Text(
            title, 
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Rating
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '$rating',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($reviewCount reviews)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Specialization and Experience
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Chip(
                label: Text(specialization),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(experience),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bio - with max lines to prevent oversized header
          Text(
            bio, 
            textAlign: TextAlign.center, 
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3, 
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 