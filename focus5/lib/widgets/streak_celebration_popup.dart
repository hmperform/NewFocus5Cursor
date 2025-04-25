import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// Rename to StreakCelebrationScreen to reflect full-screen nature
class StreakCelebrationScreen extends StatefulWidget {
  final int streakCount;

  const StreakCelebrationScreen({
    Key? key,
    required this.streakCount,
    // Remove onClose, handled by Navigator.pop
  }) : super(key: key);

  @override
  _StreakCelebrationScreenState createState() => _StreakCelebrationScreenState();
}

// Rename state class
class _StreakCelebrationScreenState extends State<StreakCelebrationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Keep entry animation
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // REMOVE Auto close Future.delayed
    // Future.delayed(const Duration(milliseconds: 3500), () { ... });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getStreakMessage() {
    if (widget.streakCount == 1) {
      return "You've started a streak!";
    } else if (widget.streakCount <= 3) {
      return "Keep it up!";
    } else if (widget.streakCount <= 7) {
      return "You're on fire!";
    } else if (widget.streakCount <= 14) {
      return "Impressive streak!";
    } else if (widget.streakCount <= 30) {
      return "Amazing dedication!";
    } else {
      return "Legendary streak!";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Scaffold for full-screen structure
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              // Remove Dialog, use Container directly within Scaffold body
              child: Container(
                // Expand to fill screen
                constraints: const BoxConstraints.expand(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                // Remove decoration for background - use Scaffold default
                // decoration: BoxDecoration(
                //   gradient: LinearGradient(
                //     begin: Alignment.topLeft,
                //     end: Alignment.bottomRight,
                //     colors: [
                //       Colors.grey[800]!, // Darker grey
                //       Colors.grey[600]!, // Medium grey
                //       Colors.grey[400]!, // Lighter grey
                //     ],
                //   ),
                // ),
                // Center content vertically and horizontally
                child: Center(
                  child: SingleChildScrollView( // Allow scrolling if content overflows
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                      mainAxisSize: MainAxisSize.min, // Prevent excessive height
                      children: [
                        const Text(
                          '🔥 Streak Bonus! 🔥',
                          style: TextStyle(
                            fontSize: 28, // Adjusted size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24), // Adjusted spacing
                        SizedBox(
                          height: 200, // Increased size
                          width: 200,
                          // Load Lottie from local asset
                          child: Lottie.asset(
                            'assets/lottie/Animation - 1745514163995.lottie',
                            fit: BoxFit.contain,
                            // Add errorBuilder for fallback
                            errorBuilder: (context, error, stackTrace) {
                              print("Error loading Lottie asset: $error"); // Log the error
                              // Fallback: Display a large flame emoji
                              return const Center(
                                child: Text(
                                  '🔥',
                                  style: TextStyle(
                                    fontSize: 150, // Adjust size as needed
                                    color: Colors.orangeAccent, // Use an orange color
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24), // Adjusted spacing
                        Text(
                          '${widget.streakCount} day streak',
                          style: const TextStyle(
                            fontSize: 36, // Adjusted size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54, // Softer shadow
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12), // Adjusted spacing
                        Text(
                          _getStreakMessage(),
                          style: const TextStyle(
                            fontSize: 20, // Adjusted size
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32), // Adjusted spacing
                        ElevatedButton(
                          // Update onPressed to pop the route
                          onPressed: () {
                            // Simply pop the current route
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey[800], // Match grey theme
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40, // Adjusted padding
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5, // Add some elevation
                          ),
                          child: const Text(
                            'Awesome!',
                            style: TextStyle(
                              fontSize: 20, // Adjusted size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Extension to show the streak celebration screen using a new route
extension StreakCelebrationExtension on BuildContext {
  Future<void> showStreakCelebration({required int streakCount}) async {
    // Use Navigator.push to show a full-screen route
    Navigator.of(this).push(
      MaterialPageRoute(
        // Make route non-dismissible by default (no barrierDismissible)
        fullscreenDialog: true, // Treat as a full-screen dialog appearance-wise
        builder: (context) => StreakCelebrationScreen(
          streakCount: streakCount,
        ),
      ),
    );
  }
} 