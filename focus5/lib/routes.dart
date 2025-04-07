import 'package:flutter/material.dart';
import 'package:focus5/models/coach_model.dart';
import '../screens/home/coaches_list_screen.dart';
import '../screens/home/course_detail_screen.dart';
// import '../screens/home/lesson_detail_screen.dart'; // Commented out
import '../screens/home/coach_detail_screen.dart';
import '../screens/home/explore_tab.dart';
import '../screens/home/dashboard_tab.dart';
import '../screens/home/media_tab.dart';
import '../screens/home/article_detail_screen.dart';
// import '../screens/home/audio_detail_screen.dart'; // Commented out
import '../screens/profile/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/home/coach_profile_screen.dart';
import '../screens/home/coach_sessions_screen.dart';
import '../screens/home/articles_list_screen.dart';
import '../screens/more/settings_screen.dart';
import '../screens/main_navigation_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const SplashScreen(isFirstLaunch: false),
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/onboarding': (context) => const OnboardingScreen(),
  '/profile-setup': (context) => const ProfileSetupScreen(),
  '/main': (context) => const MainNavigationScreen(),
  '/course-detail': (context) => CourseDetailScreen(
        courseId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['courseId'],
        course: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['course'],
      ),
  '/coaches': (context) => const CoachesListScreen(),
  '/explore': (context) => const ExploreTab(),
  '/media': (context) => const MediaTab(),
  '/dashboard': (context) => const DashboardTab(),
  '/profile': (context) => const ProfileScreen(),
  '/welcome': (context) => const WelcomeScreen(),
  '/coach-profile': (context) => CoachProfileScreen(
        coachId: ModalRoute.of(context)!.settings.arguments as String,
      ),
  '/coach-sessions': (context) => CoachSessionsScreen(
        coach: ModalRoute.of(context)!.settings.arguments as CoachModel,
      ),
  '/article-detail': (context) {
      final arguments = ModalRoute.of(context)!.settings.arguments;
      String articleId;
      if (arguments is Map<String, dynamic> && arguments.containsKey('articleId')) {
        articleId = arguments['articleId'] as String;
      } else if (arguments is String) {
        articleId = arguments;
      } else {
        throw Exception('ArticleDetailScreen requires an articleId argument');
      }
      return ArticleDetailScreen(articleId: articleId);
    },
  '/articles-list': (context) => ArticlesListScreen(
        tag: ModalRoute.of(context)!.settings.arguments as String?,
      ),
}; 