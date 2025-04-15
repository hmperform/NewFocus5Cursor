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
    // Short delay for splash visibility
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool navigationHandled = false;
    
    // Listen to status changes to wait for data loading
    // Using a listener is more robust than a simple await here
    void listener() {
      if (!mounted || navigationHandled) return; // Check mounted status inside listener and if already navigated

      final currentStatus = authProvider.status;
      final isReady = authProvider.isAuthenticatedAndReady; // Use the new flag

      print("SplashScreen Listener: Auth Status: $currentStatus, IsReady: $isReady, IsFirstLaunch: ${widget.isFirstLaunch}");

      // Check conditions for navigation *only when status is not authenticating*
      if (currentStatus != AuthStatus.authenticating && currentStatus != AuthStatus.initial) {
        // Mark navigation as handled to prevent multiple navigations
        navigationHandled = true;
        authProvider.removeListener(listener); // Remove listener once decided

        if (widget.isFirstLaunch) {
           print("SplashScreen: Navigating to Onboarding (First Launch)");
          Navigator.of(context).pushReplacementNamed('/onboarding');
        } else if (isReady) { // Navigate to home ONLY if authenticated AND data is ready
           print("SplashScreen: Navigating to Home (Authenticated & Ready)");
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (currentStatus == AuthStatus.unauthenticated || currentStatus == AuthStatus.error) {
           print("SplashScreen: Navigating to Login (Unauthenticated or Error)");
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
           // Should ideally not happen if isReady logic is correct, but fallback to login
           print("SplashScreen: Fallback - Navigating to Login (State: $currentStatus, Ready: $isReady)");
           Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    }

    authProvider.addListener(listener);

    // Initial check - This triggers the process, the listener handles the navigation result
    print("SplashScreen: Triggering initial authProvider.checkAuthStatus()...");
    await authProvider.checkAuthStatus();
    // The listener added above will handle the navigation once checkAuthStatus and subsequent loadUserData complete.
    print("SplashScreen: Initial checkAuthStatus() completed. Waiting for listener callback...");
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
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading logo: $error');
                      return Icon(
                        Icons.fitness_center,
                        size: 80,
                        color: accentColor,
                      );
                    },
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