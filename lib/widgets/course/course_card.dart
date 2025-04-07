import 'package:flutter/material.dart';
import 'package:focus5/models/content_models.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const CourseCard({
    Key? key,
    required this.course,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement a proper Course Card UI
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(course.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              // Add other course details (image, duration, etc.)
            ],
          ),
        ),
      ),
    );
  }
} 