import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_navigation_screen.dart';
import '../../providers/theme_provider.dart';

class CommitmentScreen extends StatefulWidget {
  final String userName;
  final bool isIndividual;
  final String universityCode;
  
  const CommitmentScreen({
    Key? key,
    required this.userName,
    required this.isIndividual,
    required this.universityCode,
  }) : super(key: key);

  @override
  State<CommitmentScreen> createState() => _CommitmentScreenState();
}

class _CommitmentScreenState extends State<CommitmentScreen> with SingleTickerProviderStateMixin {
  bool _isCommitting = false;
  bool _isCommitmentComplete = false;
  late AnimationController _progressController;
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
      if (_progressController.value == 1.0 && !_isCommitmentComplete) {
        _completeCommitment();
      }
    });
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
  
  void _startCommitment() {
    if (_isCommitting || _isCommitmentComplete) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _isCommitting = true;
    });
    _progressController.forward(from: 0.0);
  }
  
  void _cancelCommitment() {
    if (!_isCommitting || _isCommitmentComplete) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _isCommitting = false;
    });
    _progressController.stop();
    _progressController.reset();
  }
  
  void _completeCommitment() {
    if (_isCommitmentComplete) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isCommitmentComplete = true;
      _isCommitting = false;
    });
    
    _confettiController.play();
    
    Future.delayed(const Duration(seconds: 2), () {
      _navigateToMain();
    });
  }
  
  void _navigateToMain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
      (route) => false,
    );
  }

  void _skipCommitment() {
    _navigateToMain();
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Progress overlay
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: screenSize.height * _progressController.value,
                child: Container(
                  color: accentColor.withOpacity(0.1),
                ),
              );
            },
          ),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple
              ],
              gravity: 0.1,
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (!_isCommitmentComplete)
                    Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 800)),
                        SlideEffect(begin: Offset(0, -0.2), end: Offset.zero),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Make a commitment to your\nmental training',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Hold the thumbprint below for 5 seconds to\ncommit to your transformation',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // Fingerprint button
                  if (!_isCommitmentComplete)
                    GestureDetector(
                      onTapDown: (_) => _startCommitment(),
                      onTapUp: (_) => _cancelCommitment(),
                      onTapCancel: () => _cancelCommitment(),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCommitting ? accentColor.withOpacity(0.2) : Colors.grey[800],
                            ),
                            child: Icon(
                              Icons.fingerprint,
                              size: 50,
                              color: _isCommitting ? accentColor : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  if (!_isCommitmentComplete) ...[
                    const SizedBox(height: 24),
                    // Skip button
                    TextButton(
                      onPressed: _skipCommitment,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                  
                  if (_isCommitmentComplete)
                    Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 500)),
                        ScaleEffect(begin: Offset(0.8, 0.8), end: Offset(1,1)),
                      ],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: accentColor,
                            size: 100,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'COMMITMENT COMPLETE!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Get ready to level up.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 