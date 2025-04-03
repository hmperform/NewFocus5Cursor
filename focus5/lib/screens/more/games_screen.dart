import 'package:flutter/material.dart';
import 'concentration_grid_game.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // App color scheme
    final backgroundColor = Colors.black;
    final cardBackgroundColor = const Color(0xFF1A1A1A);
    final accentColor = const Color(0xFFB4FF00);

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
        title: const Text(
          'Mental Training Games',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                color: Colors.grey[300],
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
                      const Text(
                        'Daily Challenge',
                        style: TextStyle(
                          color: Colors.white,
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
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String difficulty,
    required String timeEstimate,
    required Color accentColor,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game icon header
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  if (!isAvailable)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Game details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          difficulty,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        timeEstimate,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
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