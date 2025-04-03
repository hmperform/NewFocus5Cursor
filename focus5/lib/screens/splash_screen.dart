import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/theme.dart';
import 'auth/login_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const SplashScreen({Key? key, required this.isFirstLaunch}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for a short delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Get the auth provider and check the authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
    
    if (!mounted) return;
    
    // Navigate to the appropriate screen based on authentication status and whether it's the first launch
    if (widget.isFirstLaunch) {
      // First launch, go to onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else if (authProvider.isAuthenticated) {
      // User is authenticated, go to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // User is not authenticated, go to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Use the appropriate accent color based on theme mode
    final Color accentColor = themeProvider.isDarkMode
        ? AppColors.accentDark
        : AppColors.accentLight;
    
    // Use appropriate contrasting text color based on theme mode
    final Color textColor = themeProvider.isDarkMode ? Colors.black : Colors.white;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor,
              accentColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/logos/just_focus5_head.png',
                    fit: BoxFit.contain,
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(delay: 200.ms, duration: 500.ms),
              
              const SizedBox(height: 24),
              
              // App name
              Text(
                "FOCUS 5",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 2,
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms),
              
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                "Mental Training for Athletes",
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              )
              .animate()
              .fadeIn(delay: 500.ms, duration: 600.ms),
              
              const Spacer(),
              
              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              )
              .animate()
              .fadeIn(delay: 800.ms, duration: 500.ms),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
} 