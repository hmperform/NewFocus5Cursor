import 'package:flutter/material.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/utils/app_icons.dart';
import 'package:focus5/screens/home/course_detail_screen.dart';
import 'package:transparent_image/transparent_image.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final bool isPurchased;
  final double? cardWidth;
  
  const CourseCard({
    Key? key,
    required this.course,
    required this.isPurchased,
    this.cardWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final double effectiveWidth = cardWidth ?? MediaQuery.of(context).size.width * 0.65;
    
    return SizedBox(
      width: effectiveWidth,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(courseId: course.id),
            ),
          );
        },
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Course image
              Stack(
                children: [
                  // Image
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: FadeInImage.memoryNetwork(
                      placeholder: kTransparentImage,
                      image: course.thumbnailUrl.isNotEmpty ? course.thumbnailUrl : course.imageUrl,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 40),
                        );
                      },
                    ),
                  ),
                  
                  // Purchase badge
                  if (isPurchased)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Purchased',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Premium badge
                  if (course.premium && !isPurchased)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Course details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Duration and Focus Points Cost
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Duration on the left
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 14, color: textColor.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              '${course.durationMinutes} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        
                        // Focus Points Cost on the right (if applicable)
                        if (course.focusPointsCost > 0 && !isPurchased)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcons.getFocusPointIcon(width: 14, height: 14),
                              const SizedBox(width: 2),
                              Text(
                                '${course.focusPointsCost}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                         ? Colors.grey[400]
                                         : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 