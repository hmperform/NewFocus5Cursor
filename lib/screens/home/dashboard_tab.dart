import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/focus_area_chip.dart';
import 'course_detail_screen.dart';
import 'coach_detail_screen.dart';
import 'article_detail_screen.dart';
import 'audio_player_screen.dart';
import '../../widgets/course/course_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

// Replace debug prints with proper logging
void _logError(String message) {
  if (kDebugMode) {
    print('Error: $message');
  }
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  Widget build(BuildContext context) {
    // Use Consumers for providers where needed in build methods
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.star_outline,
            color: themeProvider.getTheme().colorScheme.onSurface,
            size: 28,
          ),
          onPressed: () {
            // TODO: Implement Focus Points action
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: themeProvider.getTheme().colorScheme.onSurface,
              size: 28,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildDailyStreakSection(context),
            const SizedBox(height: 24),
            _buildTodaysVideoSection(context),
            const SizedBox(height: 24),
            Consumer<ContentProvider>(
              builder: (context, contentProvider, _) =>
                  _buildFeaturedCoursesSection(contentProvider),
            ),
            Consumer<ContentProvider>(
              builder: (context, contentProvider, _) =>
                  _buildRecentMediaSection(contentProvider),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No daily content available today.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStreakSection(BuildContext context) {
    final days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Streak',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(days.length, (index) {
            bool isActive = index == 0;
            bool isCompleted = index == 0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive ? colorScheme.primary : colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: isActive ? Border.all(color: colorScheme.primary, width: 2) : null,
                  ),
                  child: Center(
                    child: Text(
                      days[index],
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 18,
                  )
                else
                  Container(height: 18),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTodaysVideoSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    const String title = 'Is All Self-Criticism Bad?';
    const String description = 'Learn essential techniques to manage self-criticism and build mental resilience';
    const String author = 'Morgan Taylor';
    const String duration = '5 min';
    const String xp = '30 XP';
    const String imageUrl = 'https://via.placeholder.com/350x150.png/2c2c2c/ffffff?text=Today%27s+Video';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today's Video',
           style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        )),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                      onPressed: () {
                        // TODO: Navigate to video player
                      },
                      iconSize: 40,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Chip(
                      label: Text(duration),
                      backgroundColor: Colors.black.withOpacity(0.6),
                      labelStyle: textTheme.labelSmall?.copyWith(color: Colors.white),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(author, style: textTheme.bodySmall),
                          ],
                        ),
                         Row(
                          children: [
                            Icon(Icons.star_border, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(xp, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
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
      ],
    );
  }

  Widget _buildRecentMediaSection(ContentProvider contentProvider) {
    final List<dynamic> recentMedia = [];

    if (recentMedia.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Recently Played',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recentMedia.length,
            itemBuilder: (context, index) {
              final item = recentMedia[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(8),
                  child: Text(item?.title ?? 'Media Item'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCoursesSection(ContentProvider contentProvider) {
    final courses = contentProvider.getFeaturedCourses();

    if (courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No featured courses available yet.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Courses',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return CourseCard(
                course: course,
                onTap: () {
                  Navigator.pushNamed(context, '/course', arguments: course.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// DO NOT DEFINE CourseCard or other classes here 