import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/coaches/coaches_list_screen.dart';
import 'screens/badges/all_badges_screen.dart';
import 'screens/home/all_coaches_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/splash': (context) => const SplashScreen(),
  '/onboarding': (context) => const OnboardingScreen(),
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/home': (context) => const HomeScreen(),
  '/coaches': (context) => const CoachesListScreen(),
  '/all_coaches': (context) => const AllCoachesScreen(),
  '/all_badges': (context) => const AllBadgesScreen(),
  '/profile_setup': (context) => const ProfileSetupScreen(fromOnboarding: true),
}; 