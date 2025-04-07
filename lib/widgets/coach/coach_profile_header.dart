import 'package:flutter/material.dart';

class CoachProfileHeader extends StatelessWidget {
  final String name;
  final String title;
  final String imageUrl;
  final String bio;
  final List<String> specializations;

  const CoachProfileHeader({
    Key? key,
    required this.name,
    required this.title,
    required this.imageUrl,
    required this.bio,
    required this.specializations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement a proper Coach Profile Header UI
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColorLight, // Placeholder background
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(imageUrl),
            onBackgroundImageError: (e, s) => const Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          Text(name, style: Theme.of(context).textTheme.headlineSmall),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(bio, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
} 