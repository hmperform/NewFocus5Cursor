import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:provider/provider.dart';
import '../more/games_screen.dart';
import '../more/journal_screen.dart';
import '../more/settings_screen.dart';
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
                  _buildCategoryCard(
                    'Journal',
                    Colors.purple[600]!,
                    Icons.book,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JournalScreen()),
                    ),
                  ),
                  _buildCategoryCard(
                    'Mental Games',
                    Colors.blue[600]!,
                    Icons.gamepad,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GamesScreen()),
                    ),
                  ),
                  _buildCategoryCard(
                    'Meditate',
                    Colors.orange[600]!,
                    Icons.self_improvement,
                    () {},
                  ),
                  _buildCategoryCard(
                    'Sleep',
                    Colors.deepPurple[600]!,
                    Icons.nightlight_round,
                    () {},
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

              // Content Database section
              Container(
                width: double.infinity,
                height: 100,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.green[500],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 16,
                      top: 20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.book,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Content Database',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom spacing
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background design elements
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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