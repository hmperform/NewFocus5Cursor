import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/theme.dart';
import 'auth/login_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'home/home_screen.dart';
import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const SplashScreen({Key? key, required this.isFirstLaunch}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    
    _controller.forward();
    
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // Check streak status on app start
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Start loading user data
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      await userProvider.loadUserData(userId);
      // Check streak status after user data is loaded
      if (userProvider.user != null) {
        await userProvider.checkAndUpdateStreakStatus(userId);
      }
    }
    
    // Delay splash screen slightly for nicer animation
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    // Determine the next route
    String nextRoute;
    
    if (widget.isFirstLaunch) {
      nextRoute = '/onboarding';
    } else if (authProvider.isLoggedIn) {
      nextRoute = '/home';
    } else {
      nextRoute = '/login';
    }
    
    // Navigate to the determined route
    Navigator.of(context).pushReplacementNamed(nextRoute);
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
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Image.asset(
                    'assets/images/logos/just_focus5_head.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'FOCUS 5',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mental Performance App',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.9),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 