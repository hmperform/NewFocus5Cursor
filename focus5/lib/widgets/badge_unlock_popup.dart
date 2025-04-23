import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/content_models.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class BadgeUnlockPopup extends StatefulWidget {
  final AppBadge badge;

  const BadgeUnlockPopup({
    Key? key,
    required this.badge,
  }) : super(key: key);

  @override
  State<BadgeUnlockPopup> createState() => _BadgeUnlockPopupState();
}

class _BadgeUnlockPopupState extends State<BadgeUnlockPopup> with TickerProviderStateMixin {
  late AnimationController _lockController;
  late AnimationController _colorController;
  late AnimationController _shineController;
  late Animation<double> _scaleAnimation;
  
  bool _showLock = true;
  bool _isGrayscale = true;
  bool _showShine = false;

  @override
  void initState() {
    super.initState();

    // Play unlock sound
    _playUnlockSound();
    
    // Lock animation controller
    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Color transition controller
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Shine/gleam effect controller
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // Scale animation for the badge
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.elasticOut,
    ));
    
    // Sequence the animations
    _startAnimationSequence();
  }
  
  void _playUnlockSound() {
    // HapticFeedback can provide a physical response
    HapticFeedback.mediumImpact();
    
    // You could also play an audio file if needed
    // AudioService.playOneShot('unlock_sound.mp3');
  }
  
  Future<void> _startAnimationSequence() async {
    // Wait a moment before starting animations
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Start lock animation
    _lockController.forward();
    
    // After lock animation completes, hide it and show color transition
    _lockController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showLock = false;
          _isGrayscale = false;
        });
        
        // Start color transition
        _colorController.forward();
      }
    });
    
    // After color transition, show shine effect
    _colorController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showShine = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _lockController.dispose();
    _colorController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero, // Full screen dialog
      backgroundColor: Colors.black87,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge unlock title
            const Text(
              'BADGE UNLOCKED!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            
            // Badge with animations
            Stack(
              alignment: Alignment.center,
              children: [
                // Badge image with grayscale filter
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _isGrayscale 
                              ? null 
                              : [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  )
                                ],
                        ),
                        child: ColorFiltered(
                          colorFilter: _isGrayscale
                              ? const ColorFilter.matrix([
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ])
                              : const ColorFilter.matrix([
                                  1, 0, 0, 0, 0,
                                  0, 1, 0, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]),
                          child: ClipOval(
                            child: widget.badge.badgeImage != null
                                ? Image.network(
                                    widget.badge.badgeImage!,
                                    fit: BoxFit.cover,
                                    width: 200,
                                    height: 200,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.emoji_events,
                                          size: 100,
                                          color: Colors.amber,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.emoji_events,
                                      size: 100,
                                      color: Colors.amber,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Lock animation overlay
                if (_showLock)
                  Positioned.fill(
                    child: Lottie.asset(
                      'assets/lottie/lockanimation.json',
                      controller: _lockController,
                      fit: BoxFit.contain,
                    ),
                  ),
                
                // Shine/gleam effect
                if (_showShine)
                  AnimatedBuilder(
                    animation: _shineController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _shineController.value * 0.7,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.8),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.7],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Badge name
            Text(
              widget.badge.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Badge description/criteria
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.badge.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // XP reward
            Text(
              '+${widget.badge.xpValue} XP',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Exit button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'AWESOME!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 