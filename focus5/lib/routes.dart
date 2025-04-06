import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/main_navigation_screen.dart';
import 'screens/coaches/coaches_list_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const SplashScreen(),
  '/onboarding': (context) => const OnboardingScreen(),
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/forgot_password': (context) => const ForgotPasswordScreen(),
  '/home': (context) => const MainNavigationScreen(),
  '/coaches': (context) => const CoachesListScreen(),
  '/profile_setup': (context) => const ProfileSetupScreen(fromOnboarding: true),
}; 