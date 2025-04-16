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
  VoidCallback? _authListener;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    if (_authListener != null) {
      Provider.of<AuthProvider>(context, listen: false).removeListener(_authListener!);
    }
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool navigationHandled = false;
    
    _authListener = () {
      if (!mounted || navigationHandled) return;

      final currentStatus = authProvider.status;
      final isReady = authProvider.isAuthenticatedAndReady;

      print("[Listener] SplashScreen Listener: Auth Status: $currentStatus, IsReady: $isReady, IsFirstLaunch: ${widget.isFirstLaunch}");

      if (currentStatus != AuthStatus.authenticating && currentStatus != AuthStatus.initial) {
        _navigateToNextScreen(authProvider);
        navigationHandled = true;
      }
    };

    authProvider.addListener(_authListener!);

    print("SplashScreen: Triggering initial authProvider.checkAuthStatus()...");
    await authProvider.checkAuthStatus();
    print("SplashScreen: Initial checkAuthStatus() completed.");

    if (!mounted) return;
    final initialStatus = authProvider.status;
    print("SplashScreen: Status immediately after check: $initialStatus");
    if (initialStatus != AuthStatus.authenticating && initialStatus != AuthStatus.initial) {
        if (!navigationHandled) {
            print("SplashScreen: Navigating based on status after initial check.");
             _navigateToNextScreen(authProvider);
             navigationHandled = true;
        } else {
             print("SplashScreen: Navigation already handled by listener during initial check.");
        }
    } else {
         print("SplashScreen: Status still initial/authenticating after check. Waiting for listener...");
    }
  }

  void _navigateToNextScreen(AuthProvider authProvider) {
     if (_authListener != null) {
        authProvider.removeListener(_authListener!);
        _authListener = null;
     }
     
     final currentStatus = authProvider.status;
     final isReady = authProvider.isAuthenticatedAndReady;

     if (widget.isFirstLaunch) {
       print("SplashScreen: Navigating to Onboarding (First Launch)");
       Navigator.of(context).pushReplacementNamed('/onboarding');
     } else if (isReady) {
       print("SplashScreen: Navigating to Home (Authenticated & Ready)");
       Navigator.of(context).pushReplacementNamed('/home');
     } else if (currentStatus == AuthStatus.unauthenticated || currentStatus == AuthStatus.error) {
       print("SplashScreen: Navigating to Login (Unauthenticated or Error)");
       Navigator.of(context).pushReplacementNamed('/login');
     } else {
       print("SplashScreen: Fallback - Navigating to Login (State: $currentStatus, Ready: $isReady)");
       Navigator.of(context).pushReplacementNamed('/login');
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