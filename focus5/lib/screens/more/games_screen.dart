import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'concentration_grid_game.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.accentColor;

    final List<Map<String, dynamic>> games = [
      {
        'title': 'Concentration Grid',
        'description': 'Quickly find numbers in sequence from 0-99',
        'icon': Icons.grid_4x4,
        'color': Colors.blue[700],
        'difficulty': 'Medium',
        'timeEstimate': '1-5 min',
        'isAvailable': true,
        'navigate': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ConcentrationGridGame(),
            ),
          );
        },
      },
      {
        'title': 'Focus Trainer',
        'description': 'Improve your focus with timed challenges',
        'icon': Icons.center_focus_strong,
        'color': Colors.indigo[700],
        'difficulty': 'Medium',
        'timeEstimate': '5-10 min',
        'isAvailable': false,
      },
      {
        'title': 'Memory Match',
        'description': 'Enhance your memory through pattern matching',
        'icon': Icons.grid_view,
        'color': Colors.purple[700],
        'difficulty': 'Easy',
        'timeEstimate': '3-5 min',
        'isAvailable': false,
      },
      {
        'title': 'Reaction Timer',
        'description': 'Test and improve your reaction time',
        'icon': Icons.flash_on,
        'color': Colors.orange[700],
        'difficulty': 'Easy',
        'timeEstimate': '2-3 min',
        'isAvailable': false,
      },
      {
        'title': 'Decision Maker',
        'description': 'Practice making decisions under pressure',
        'icon': Icons.psychology,
        'color': Colors.teal[700],
        'difficulty': 'Hard',
        'timeEstimate': '10-15 min',
        'isAvailable': false,
      },
      {
        'title': 'Visualization Guide',
        'description': 'Interactive guided visualization exercises',
        'icon': Icons.visibility,
        'color': Colors.green[700],
        'difficulty': 'Medium',
        'timeEstimate': '8-12 min',
        'isAvailable': false,
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Mental Training Games',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Train your mental skills through these interactive games',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            
            // Games grid
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return _buildGameCard(
                  context: context,
                  title: game['title'],
                  description: game['description'],
                  icon: game['icon'],
                  color: game['color'],
                  difficulty: game['difficulty'],
                  timeEstimate: game['timeEstimate'],
                  accentColor: accentColor,
                  isAvailable: game['isAvailable'],
                  onTap: () {
                    if (game['isAvailable'] && game['navigate'] != null) {
                      game['navigate']();
                    } else {
                      // Show coming soon message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${game['title']} coming soon!'),
                          backgroundColor: game['color'],
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Daily Challenge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple[700]!,
                    Colors.deepPurple[900]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Daily Challenge',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete today\'s challenge to earn 50 XP and a streak bonus!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Go to concentration grid
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConcentrationGridGame(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'START CHALLENGE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color? color,
    required String difficulty,
    required String timeEstimate,
    required Color accentColor,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: color?.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeEstimate,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Soon',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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