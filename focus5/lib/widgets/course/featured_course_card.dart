import 'package:flutter/material.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/utils/app_icons.dart';
import 'package:focus5/screens/home/course_detail_screen.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class FeaturedCourseCard extends StatelessWidget {
  final Course course;
  final bool isPurchased;
  
  const FeaturedCourseCard({
    Key? key,
    required this.course,
    required this.isPurchased,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final accentColor = themeProvider.accentColor;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(courseId: course.id),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: course.courseThumbnail.isNotEmpty ? course.courseThumbnail : course.imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 40),
                      );
                    },
                  ),
                ),
                
                // Featured badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Featured',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Purchase or Premium badge
                if (isPurchased || course.premium)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPurchased ? Colors.green : Colors.amber[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPurchased ? 'Purchased' : 'Premium',
                        style: const TextStyle(
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Creator name
                  Text(
                    'By ${course.creatorName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Bottom row with duration and focus points
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: textColor.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '${course.durationMinutes} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      const Spacer(),
                      if (course.focusPointsCost > 0 && !isPurchased)
                        Row(
                          children: [
                            AppIcons.getFocusPointIcon(width: 16, height: 16),
                            const SizedBox(width: 2),
                            Text(
                              '${course.focusPointsCost}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
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
    );
  }
} 