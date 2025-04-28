import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // Import dart:math for random selection
import 'package:focus5/screens/home/course_detail_screen.dart'; // Import CourseDetailScreen
import '../more/games_screen.dart';
import '../more/journal_screen.dart';
import '../media/media_library_screen.dart';
import '../../providers/theme_provider.dart';
import '../../providers/content_provider.dart'; // Import ContentProvider
import '../../models/content_models.dart'; // Import Course model
import '../../constants/theme.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    final List<Course> allCourses = contentProvider.courses; // Get all courses

    // Select up to 3 random courses
    final random = Random();
    List<Course> randomCourses = [];
    if (allCourses.isNotEmpty) {
      final indices = <int>{}; // Use a set to ensure unique indices
      while (indices.length < 3 && indices.length < allCourses.length) {
        indices.add(random.nextInt(allCourses.length));
      }
      randomCourses = indices.map((index) => allCourses[index]).toList();
    }

    // Theme-aware colors
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardBackgroundColor = Theme.of(context).colorScheme.surface;
    final accentColor = themeProvider.accentColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'More',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main categories with icons
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Games
                  _buildMenuItem(
                    context,
                    'Mind Games',
                    Icons.games,
                    Colors.blue.shade300,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GamesScreen(),
                        ),
                      );
                    },
                  ),
                  
                  // Journal
                  _buildMenuItem(
                    context,
                    'Journal',
                    Icons.book,
                    Colors.orange.shade300,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JournalScreen(),
                        ),
                      );
                    },
                  ),
                  
                  // Media Library
                  _buildMenuItem(
                    context,
                    'Media Library',
                    Icons.library_music,
                    Colors.green.shade300,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MediaLibraryScreen(),
                        ),
                      );
                    },
                  ),
                  
                  // Replaced Settings with Help & Support
                  _buildMenuItem(
                    context,
                    'Help & Support',
                    Icons.help_outline,
                    Colors.purple.shade300,
                    () {
                      // Show help dialog or navigate to help screen
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Help & Support'),
                          content: const Text(
                            'Need assistance? Contact us at support@focus5.com or visit our help center.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // --- New "More Courses" section ---
              if (randomCourses.isNotEmpty) ...[
                Text(
                  'More Courses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: randomCourses.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final course = randomCourses[index];
                      return _buildCourseCard(
                        context: context,
                        course: course,
                        backgroundColor: cardBackgroundColor,
                        accentColor: accentColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        cardWidth: MediaQuery.of(context).size.width * 0.6,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ] else if (contentProvider.isLoading) ...[ // Show loading indicator
                 const Center(child: CircularProgressIndicator()),
                 const SizedBox(height: 32),
              ] else ...[ // Show message if no courses are available
                 Center(child: Text('No courses available.', style: TextStyle(color: secondaryTextColor))),
                 const SizedBox(height: 32),
              ],

              // Bottom spacing
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required Course course, // Use Course object
    required Color backgroundColor,
    required Color accentColor,
    required Color textColor,
    required Color secondaryTextColor,
    double? cardWidth, // Add optional cardWidth
  }) {
    return GestureDetector( // Wrap in GestureDetector to make it tappable
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(courseId: course.id), // Navigate to CourseDetailScreen
          ),
        );
      },
      child: SizedBox( // Wrap card content in SizedBox to control width
        width: cardWidth, // Apply the width
        child: Container(
          // Remove padding from the main container, apply it to text section
          // padding: const EdgeInsets.all(12), 
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            // Optional: Add a subtle shadow if desired
             boxShadow: [
               BoxShadow(
                 color: Colors.black.withOpacity(0.1),
                 blurRadius: 4,
                 offset: const Offset(0, 2),
               ),
             ],
          ),
          child: ClipRRect( // Clip the contents to the rounded corners
             borderRadius: BorderRadius.circular(16),
             child: Column( // Change Row to Column
                crossAxisAlignment: CrossAxisAlignment.start, // Align text left
                children: [
                  // Image container at the top
                  AspectRatio( // Use AspectRatio for image sizing
                    aspectRatio: 3 / 2, // Changed aspect ratio to 3:2
                    child: Stack(
                      fit: StackFit.expand, // Make stack fill the AspectRatio
                      children: [
                        // Image using FadeInImage
                         FadeInImage.memoryNetwork(
                           placeholder: kTransparentImage,
                           image: course.thumbnailUrl.isNotEmpty ? course.thumbnailUrl : course.imageUrl,
                           fit: BoxFit.cover,
                           imageErrorBuilder: (context, error, stackTrace) {
                             return Container(
                               color: Colors.grey[300],
                               child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                             );
                           },
                         ),
                        // Optional: Add gradient overlay or other elements over the image here
                      ],
                    ),
                  ),
                  // Text content below the image
                  Padding(
                    padding: const EdgeInsets.all(12), // Add padding around text
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title, // Use course title
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14, // Adjust font size if needed
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2, // Allow title to wrap to 2 lines
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // Display duration or other relevant info
                          '${course.lessonsList.length} lessons • ${course.durationMinutes} min',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12, // Slightly smaller subtitle font
                          ),
                          maxLines: 1, // Keep subtitle to 1 line
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ),
        ), // End of Container
      ),
    );
  }
} 