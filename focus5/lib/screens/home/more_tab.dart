import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:provider/provider.dart';
import '../more/games_screen.dart';
import '../more/journal_screen.dart';
import '../media/media_library_screen.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
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

              // Featured programs section
              _buildSection(
                context: context,
                title: 'Nutrition & Recovery',
                subtitle: '18 sessions • <10 min a day',
                imageUrl: 'https://picsum.photos/70/70?random=1',
                backgroundColor: cardBackgroundColor,
                accentColor: accentColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),

              const SizedBox(height: 16),

              _buildSection(
                context: context,
                title: 'Managing Stress',
                subtitle: '20 sessions • 10 min a day',
                imageUrl: 'https://picsum.photos/70/70?random=2',
                backgroundColor: cardBackgroundColor,
                accentColor: accentColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),

              const SizedBox(height: 32),

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

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imageUrl,
    required Color backgroundColor,
    required Color accentColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Show icon placeholder if image fails to load
                      return Container(
                        width: 70,
                        height: 70,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Icon(
                          title.contains('Nutrition') ? Icons.fitness_center : Icons.spa,
                          color: secondaryTextColor,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Icon(
                  Icons.star,
                  color: Provider.of<ThemeProvider>(context).accentTextColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 