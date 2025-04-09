import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/screens/home/course_detail_screen.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:transparent_image/transparent_image.dart';

class CourseGallery extends StatefulWidget {
  final String title;
  final List<Course> courses;
  final VoidCallback? onViewAllPressed;

  const CourseGallery({
    Key? key,
    required this.title,
    required this.courses,
    this.onViewAllPressed,
  }) : super(key: key);

  @override
  _CourseGalleryState createState() => _CourseGalleryState();
}

class _CourseGalleryState extends State<CourseGallery> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.courses.isEmpty) {
      return const SizedBox.shrink();
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onViewAllPressed != null)
                TextButton(
                  onPressed: widget.onViewAllPressed,
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: themeProvider.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: themeProvider.accentColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 350, // Adjusted height for course card content
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.courses.length,
            itemBuilder: (context, index) {
              final course = widget.courses[index];
              final bool isActive = index == _currentPage;
              final double scale = isActive ? 1.0 : 0.9;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                margin: EdgeInsets.only(right: 8, left: 8, top: isActive ? 0 : 15, bottom: isActive ? 0 : 15),
                transform: Matrix4.identity()..scale(scale),
                transformAlignment: Alignment.center,
                child: _buildCourseCard(context, course),
              );
            },
          ),
        ),
        // Dots Indicator
        if (widget.courses.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.courses.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? themeProvider.accentColor
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onSurface; // Use onSurface for better contrast
    // final secondaryTextColor = themeProvider.secondaryTextColor;

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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  SizedBox(
                    height: 180, // Fixed height for image area
                    width: double.infinity,
                    child: FadeInImage.memoryNetwork(
                      placeholder: kTransparentImage,
                      image: course.thumbnailUrl, // Use thumbnailUrl
                      fit: BoxFit.cover,
                      height: 180,
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey.shade200, // Placeholder color
                          child: const Icon(Icons.image, color: Colors.grey, size: 40),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay for text visibility
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Course Title on Image
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      course.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator Row
                  Row(
                    children: [
                      ClipOval(
                        child: course.creatorImageUrl.isNotEmpty // Use creatorImageUrl
                            ? Image.network(
                                course.creatorImageUrl, // Use creatorImageUrl
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 24,
                                    height: 24,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.person, color: Colors.white, size: 16),
                                  );
                                },
                              )
                            : Container(
                                width: 24,
                                height: 24,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.person, color: Colors.white, size: 16),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        course.creatorName, // Use creatorName
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Lessons and Duration Row
                  Row(
                    children: [
                      Icon(Icons.play_circle_outline, size: 16, color: textColor.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text('${course.lessonsList.length} Lessons', style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12)), // Use lessonsList
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: textColor.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text('${course.durationMinutes} mins', style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12)), // Use durationMinutes
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tags Row (optional)
                  if (course.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: course.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeProvider.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: themeProvider.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
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