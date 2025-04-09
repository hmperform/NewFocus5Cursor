import 'package:flutter/material.dart';
import 'package:focus5/screens/home/coaches_list_screen.dart';
import 'package:focus5/screens/home/course_detail_screen.dart';
import 'package:focus5/screens/home/lesson_detail_screen.dart';
import 'package:focus5/screens/home/coach_detail_screen.dart';
import 'package:focus5/screens/home/explore_tab.dart';
import 'package:focus5/screens/home/dashboard_tab.dart';
import 'package:focus5/screens/home/media_tab.dart';
import 'package:focus5/screens/home/article_detail_screen.dart';
import 'package:focus5/screens/home/audio_detail_screen.dart';
import 'package:focus5/screens/profile/profile_screen.dart';
import 'package:focus5/screens/settings/settings_screen.dart';
import 'package:focus5/screens/auth/login_screen.dart';
import 'package:focus5/screens/auth/signup_screen.dart';
import 'package:focus5/screens/onboarding/profile_setup_screen.dart';
import 'package:focus5/screens/splash_screen.dart';
import 'package:focus5/models/content_models.dart';

// Use named routes for simple navigation
final Map<String, WidgetBuilder> routes = {
  '/': (context) => const SplashScreen(),
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/profile_setup': (context) => const ProfileSetupScreen(),
  '/dashboard': (context) => const DashboardTab(),
  '/explore': (context) => const ExploreTab(),
  '/media': (context) => const MediaTab(),
  '/coaches': (context) => const CoachesListScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/settings': (context) => const SettingsScreen(),
};

// For routes with parameters, create a separate function that handles proper typing
// Instead of directly using these in the routes map
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/course':
      final String courseId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => CourseDetailScreen(courseId: courseId),
      );
      
    case '/lesson':
      final String lessonId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lessonId: lessonId),
      );
      
    case '/coach':
      final String coachId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => CoachDetailScreen(coachId: coachId),
      );
      
    case '/article':
      final String articleId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(articleId: articleId),
      );
      
    case '/audio':
      final String audioId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => AudioDetailScreen(audioId: audioId),
      );
    
    default:
      // Default case - fallback to home
      return MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      );
  }
} 