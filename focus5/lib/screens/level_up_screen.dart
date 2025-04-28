import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart'; // Add confetti for celebration
import 'dart:math';

class LevelUpScreen extends StatefulWidget {
  final int newLevel;

  const LevelUpScreen({Key? key, required this.newLevel}) : super(key: key);

  @override
  _LevelUpScreenState createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (similar to existing completion screen)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.6),
                  theme.colorScheme.background,
                  theme.colorScheme.secondaryContainer.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Confetti Cannon
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30, // Number of confetti particles
              gravity: 0.1, // How fast confetti falls
              emissionFrequency: 0.05, // How often confetti emits
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Color(0xFFB4FF00) // Accent color
              ],
              // createParticlePath: drawStar, // Optional custom shape
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Color(0xFFB4FF00), // Accent color
                  size: screenSize.width * 0.3,
                ),
                const SizedBox(height: 24),
                Text(
                  'Level Up!',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "You've reached Level ${widget.newLevel}!",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // Simply pop the current screen (LevelUpScreen)
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB4FF00), // Accent color
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Optional: Custom confetti shape
  // Path drawStar(Size size) {
  //   // Method to convert degree to radians
  //   double degToRad(double deg) => deg * (pi / 180.0);

  //   const numberOfPoints = 5;
  //   final halfWidth = size.width / 2;
  //   final externalRadius = halfWidth;
  //   final internalRadius = halfWidth / 2.5;
  //   final degreesPerPoint = 360 / numberOfPoints;
  //   final halfDegreesPerPoint = degreesPerPoint / 2;
  //   final path = Path();
  //   final fullAngle = degToRad(360);
  //   path.moveTo(size.width, halfWidth);

  //   for (double step = 0; step < fullAngle; step += degToRad(degreesPerPoint)) {
  //     path.lineTo(halfWidth + externalRadius * cos(step),
  //         halfWidth + externalRadius * sin(step));
  //     path.lineTo(halfWidth + internalRadius * cos(step + degToRad(halfDegreesPerPoint)),
  //         halfWidth + internalRadius * sin(step + degToRad(halfDegreesPerPoint)));
  //   }
  //   path.close();
  //   return path;
  // }
} 