import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/mindset_assessment_screen.dart';
import 'screens/onboarding/sport_selection_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/onboarding/mental_fitness_questionnaire.dart';
import 'screens/onboarding/mental_fitness_results.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/media_player_screen.dart';
import 'screens/more/journal_entry_screen.dart';
import 'screens/more/journal_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'screens/settings/data_migration_screen.dart';
import 'screens/settings/firebase_setup_screen.dart';
import 'screens/settings/admin_management_screen.dart';
import 'screens/settings/module_to_lesson_migration_screen.dart';
import 'providers/auth_provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: SplashScreen(isFirstLaunch: false),
        routes: {
          '/': (context) => SplashScreen(isFirstLaunch: false),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/assessment': (context) => const MindsetAssessmentScreen(),
          '/sport_selection': (context) => const SportSelectionScreen(),
          '/profile_setup': (context) => const ProfileSetupScreen(),
          '/mental_fitness_questionnaire': (context) => const MentalFitnessQuestionnaire(),
          '/journal_entry': (context) => const JournalEntryScreen(),
          '/journal': (context) => const JournalScreen(),
          '/paywall': (context) => const PaywallScreen(),
          '/data_migration': (context) => const DataMigrationScreen(),
          '/firebase_setup': (context) => const FirebaseSetupScreen(),
          '/admin-management': (context) => const AdminManagementScreen(),
          '/coaches': (context) => const CoachesListScreen(),
          '/all_coaches': (context) => const AllCoachesScreen(),
          '/all_badges': (context) => const AllBadgesScreen(),
          '/module_to_lesson_migration': (context) => const ModuleToLessonMigrationScreen(),
        },
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
} 