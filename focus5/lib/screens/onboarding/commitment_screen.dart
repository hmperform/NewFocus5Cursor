import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../home/home_screen.dart';

class CommitmentScreen extends StatefulWidget {
  final String userName;
  
  const CommitmentScreen({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  State<CommitmentScreen> createState() => _CommitmentScreenState();
}

class _CommitmentScreenState extends State<CommitmentScreen> with SingleTickerProviderStateMixin {
  bool _isCommitting = false;
  bool _isCommitmentComplete = false;
  double _commitmentProgress = 0.0;
  late AnimationController _progressController;
  
  // For confetti animation
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
      setState(() {
        _commitmentProgress = _progressController.value;
      });
      if (_progressController.value == 1.0 && !_isCommitmentComplete) {
        _completeCommitment();
      }
    });
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
  
  void _startCommitment() {
    if (_isCommitting) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _isCommitting = true;
    });
    
    _progressController.forward(from: 0.0);
  }
  
  void _cancelCommitment() {
    if (!_isCommitting) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _isCommitting = false;
    });
    
    _progressController.stop();
    _progressController.reset();
  }
  
  void _completeCommitment() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isCommitmentComplete = true;
    });
    
    // Play confetti
    _confettiController.play();
    
    // Navigate to home screen after a delay
    Future.delayed(const Duration(seconds: 3), () {
      _navigateToHome();
    });
  }
  
  void _navigateToHome() async {
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);
    
    if (!mounted) return;
    
    // Navigate to home screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
      (route) => false, // Remove all previous routes
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Animate(
                    effects: [
                      FadeEffect(duration: 800.ms),
                      SlideEffect(
                        begin: const Offset(0, -50),
                        end: const Offset(0, 0),
                        duration: 800.ms,
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey ${widget.userName}!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Are you ready to commit to improving your mental game?',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Commitment Button
                  Animate(
                    effects: [
                      FadeEffect(duration: 800.ms, delay: 400.ms),
                      SlideEffect(
                        begin: const Offset(0, 50),
                        end: const Offset(0, 0),
                        duration: 800.ms,
                        delay: 400.ms,
                      ),
                    ],
                    child: Center(
                      child: Column(
                        children: [
                          // Commitment Button
                          if (!_isCommitmentComplete)
                            GestureDetector(
                              onLongPress: _isCommitting ? null : _startCommitment,
                              onLongPressEnd: (_) => _cancelCommitment(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isCommitting
                                      ? const Color(0xFFB4FF00).withOpacity(0.3)
                                      : const Color(0xFF2A2A2A),
                                  border: Border.all(
                                    color: _isCommitting
                                        ? const Color(0xFFB4FF00)
                                        : Colors.white24,
                                    width: 3,
                                  ),
                                  boxShadow: _isCommitting
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFB4FF00).withOpacity(0.5),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          )
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: _isCommitting
                                      ? const Text(
                                          'Hold...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.touch_app,
                                              color: Colors.white70,
                                              size: 40,
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'HOLD TO\nCOMMIT',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            )
                          else
                            // Success message when commitment is complete
                            Animate(
                              effects: const [
                                ScaleEffect(
                                  begin: Offset(0.5, 0.5),
                                  end: Offset(1, 1),
                                  duration: Duration(milliseconds: 600),
                                  curve: Curves.elasticOut,
                                ),
                              ],
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFB4FF00),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFB4FF00).withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    )
                                  ],
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        color: Colors.black,
                                        size: 60,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'COMMITTED!',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 24),
                          
                          // Progress indicator
                          if (_isCommitting && !_isCommitmentComplete)
                            SizedBox(
                              width: 240,
                              child: LinearProgressIndicator(
                                value: _commitmentProgress,
                                backgroundColor: Colors.white10,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFB4FF00),
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          
                          if (_isCommitmentComplete)
                            Animate(
                              effects: const [
                                FadeEffect(duration: Duration(milliseconds: 800), delay: Duration(milliseconds: 500)),
                              ],
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32.0),
                                child: Text(
                                  'Congratulations! You\'re ready to start your mental performance journey.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Instructions
                  if (!_isCommitmentComplete)
                    Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 800), delay: Duration(milliseconds: 800)),
                      ],
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'Hold the button to commit to your mental training program.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2, // straight down
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 10,
              gravity: 0.2,
              particleDrag: 0.05,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Color(0xFFB4FF00),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 