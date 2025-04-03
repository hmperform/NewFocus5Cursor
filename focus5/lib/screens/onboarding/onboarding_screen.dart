import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../constants/dummy_data.dart';
import '../auth/signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isIndividual = true;
  String? _selectedSport;
  final List<String> _selectedFocusAreas = [];
  bool _isCommitted = false;
  double _commitmentProgress = 0.0;
  
  final List<Map<String, dynamic>> _onboardingSteps = [
    {
      'title': 'Choose from 80+ weekly options',
      'description': 'Daily training exercises to build your mental game',
      'image': 'assets/images/onboarding/welcome.png',
    },
    {
      'title': 'Audio sessions from pro coaches',
      'description': 'Train with elite mental performance coaches every day',
      'image': 'assets/images/onboarding/audio.png',
    },
    {
      'title': 'Master your mindset',
      'description': 'Build confidence, reduce anxiety, and perform at your peak',
      'image': 'assets/images/onboarding/courses.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SignupCommitmentScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_first_launch', false);
                      
                      if (!mounted) return;
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'LOG IN',
                      style: TextStyle(
                        color: Color(0xFFB4FF00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingSteps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final step = _onboardingSteps[index];
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Image placeholder (in a real app, use actual images)
                          Container(
                            height: MediaQuery.of(context).size.width * 0.8,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 40),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                'https://picsum.photos/500/500?random=${index+10}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    index == 0 ? Icons.sports : 
                                    index == 1 ? Icons.headphones : 
                                    Icons.psychology,
                                    size: 80,
                                    color: const Color(0xFFB4FF00),
                                  );
                                },
                              ),
                            ),
                          ),
                          Text(
                            step['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            step['description'],
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingSteps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                      ? const Color(0xFFB4FF00) 
                      : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB4FF00),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage < _onboardingSteps.length - 1 ? 'NEXT' : 'GET STARTED',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupCommitmentScreen extends StatefulWidget {
  const SignupCommitmentScreen({Key? key}) : super(key: key);

  @override
  State<SignupCommitmentScreen> createState() => _SignupCommitmentScreenState();
}

class _SignupCommitmentScreenState extends State<SignupCommitmentScreen> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  double _commitmentProgress = 0.0;
  bool _isComplete = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<Color?> _colorAnimation;
  
  // Track the long press status
  DateTime? _pressStartTime;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
      ..addListener(() {
        setState(() {
          _commitmentProgress = _progressAnimation.value;
        });
      });
    
    _colorAnimation = ColorTween(
      begin: const Color(0xFF1E1E1E),
      end: const Color(0xFFB4FF00),
    ).animate(_animationController);
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isComplete = true;
        });
        
        // Delay to show completion before navigating
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateToSignup();
        });
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _startCommitment() {
    setState(() {
      _isPressed = true;
      _pressStartTime = DateTime.now();
    });
    _animationController.forward();
  }
  
  void _cancelCommitment() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reset();
  }
  
  void _navigateToSignup() async {
    // Save that first launch is complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacementNamed('/signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          AnimatedOpacity(
                            opacity: _isComplete ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: const Text(
                              "LET'S GET TO WORK!",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!_isComplete)
                            const Text(
                              "Make a commitment to your mental training",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 24),
                          if (!_isComplete)
                            const Text(
                              "Hold the thumbprint below for 5 seconds to commit to your transformation",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 40),
                          if (!_isComplete)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: constraints.maxWidth * 0.9,
                              height: availableHeight * 0.25,
                              decoration: BoxDecoration(
                                color: _colorAnimation.value ?? const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onLongPressStart: (_) => _startCommitment(),
                                    onLongPressEnd: (_) => _cancelCommitment(),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A2A),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            spreadRadius: 1,
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.fingerprint,
                                        size: 60,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_isPressed)
                                    SizedBox(
                                      width: 200,
                                      child: LinearProgressIndicator(
                                        value: _commitmentProgress,
                                        backgroundColor: const Color(0xFF2A2A2A),
                                        color: const Color(0xFFB4FF00),
                                        minHeight: 8,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Hold to commit",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 40),
                          if (!_isComplete)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _navigateToSignup,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFB4FF00), width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Skip",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB4FF00),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }
} 