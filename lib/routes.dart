import 'package:flutter/material.dart';
import '../screens/home/coaches_list_screen.dart';
import '../screens/home/course_detail_screen.dart';
import '../screens/home/lesson_detail_screen.dart';
import '../screens/home/coach_detail_screen.dart';
import '../screens/home/explore_tab.dart';
import '../screens/home/dashboard_tab.dart';
import '../screens/home/media_tab.dart';
import '../screens/home/article_detail_screen.dart';
import '../screens/home/audio_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/splash_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const SplashScreen(),
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/profile_setup': (context) => const ProfileSetupScreen(),
  '/dashboard': (context) => const DashboardTab(),
  '/explore': (context) => const ExploreTab(),
  '/media': (context) => const MediaTab(),
  '/coaches': (context) => const CoachesListScreen(),
  '/course': (context) => CourseDetailScreen(
        courseId: ModalRoute.of(context)!.settings.arguments as String,
      ),
  '/lesson': (context) => LessonDetailScreen(
        lessonId: ModalRoute.of(context)!.settings.arguments as String,
      ),
  '/coach': (context) => CoachDetailScreen(
        coachId: ModalRoute.of(context)!.settings.arguments as String,
      ),
  '/article': (context) => ArticleDetailScreen(
        articleId: ModalRoute.of(context)!.settings.arguments as String,
      ),
  '/audio': (context) => AudioDetailScreen(
        audioId: ModalRoute.of(context)!.settings.arguments as String,
      ),
  '/profile': (context) => const ProfileScreen(),
  '/settings': (context) => const SettingsScreen(),
}; 