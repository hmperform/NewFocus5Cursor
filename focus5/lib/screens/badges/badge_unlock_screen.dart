import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/content_models.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';

class BadgeUnlockScreen extends StatefulWidget {
  final AppBadge badge;

  const BadgeUnlockScreen({Key? key, required this.badge}) : super(key: key);

  @override
  _BadgeUnlockScreenState createState() => _BadgeUnlockScreenState();
}

class _BadgeUnlockScreenState extends State<BadgeUnlockScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _confettiController.play();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut, // Bouncy effect
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut), // Fade in later
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = textColor.withOpacity(0.7);

    // Log the image URLs
    debugPrint('[BadgeUnlockScreen] Received badge: ${widget.badge.name}');
    debugPrint('[BadgeUnlockScreen] badgeImage URL: ${widget.badge.badgeImage}');
    debugPrint('[BadgeUnlockScreen] imageUrl URL: ${widget.badge.imageUrl}');
    final imageUrlToLoad = widget.badge.badgeImage ?? widget.badge.imageUrl ?? '';
    debugPrint('[BadgeUnlockScreen] Attempting to load URL: $imageUrlToLoad');

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.9),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              gravity: 0.3,
              emissionFrequency: 0.05,
              maxBlastForce: 20,
              minBlastForce: 10,
              colors: [
                accentColor,
                Colors.yellow,
                Colors.lightBlue,
                Colors.lightGreen,
                Colors.pinkAccent,
              ],
              createParticlePath: (size) {
                final path = Path();
                path.addOval(Rect.fromCircle(center: Offset.zero, radius: Random().nextDouble() * 5 + 5));
                return path;
              },
            ),
          ),

          // Content Column
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Hero(
                    tag: 'badge_${widget.badge.id}', // Match tag from list/detail
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: imageUrlToLoad.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrlToLoad,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(color: accentColor.withOpacity(0.5)),
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint('[BadgeUnlockScreen] Error loading image $url: $error');
                                return Icon(Icons.error_outline, color: Colors.red.withOpacity(0.7), size: 60);
                              },
                            )
                          : Icon(
                              Icons.emoji_events,
                              size: 80,
                              color: accentColor.withOpacity(0.7)
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'BADGE UNLOCKED!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    widget.badge.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    widget.badge.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                 FadeTransition(
                   opacity: _fadeAnimation,
                   child: Text(
                     '+${widget.badge.xpValue} XP',
                     style: TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                       color: accentColor,
                     ),
                   ),
                 ),
                const SizedBox(height: 50),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('AWESOME!', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 