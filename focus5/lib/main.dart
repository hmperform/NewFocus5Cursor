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
import 'utils/migrate_modules_to_lessons.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/content_provider.dart';
import 'providers/media_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/coach_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/audio_module_provider.dart';
import 'widgets/basic_mini_player.dart';
import 'constants/theme.dart';
import 'services/basic_video_service.dart';
import 'services/initialize_database.dart';
import 'screens/coaches/coaches_list_screen.dart';
import 'screens/badges/all_badges_screen.dart';
import 'providers/audio_provider.dart';

// Add global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
  
  // Initialize theme provider early to avoid flash of wrong theme
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreference();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize database with default data
  final dbService = InitializeDatabaseService();
  await dbService.initializeDatabase();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ContentProvider()),
        ChangeNotifierProvider(create: (context) => MediaProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => JournalProvider('default_user')),
        ChangeNotifierProvider(create: (context) => BasicVideoService()),
        ChangeNotifierProvider(create: (context) => CoachProvider()),
        ChangeNotifierProvider(create: (context) => BadgeProvider()),
        ChangeNotifierProxyProvider<UserProvider, AudioModuleProvider>(
          create: (context) => AudioModuleProvider(Provider.of<UserProvider>(context, listen: false)),
          update: (context, userProvider, previousAudioProvider) => 
              AudioModuleProvider(userProvider),
        ),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: Focus5App(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class Focus5App extends StatelessWidget {
  final bool isFirstLaunch;
  
  const Focus5App({Key? key, required this.isFirstLaunch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Focus 5',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primarySwatch: AppColors.accentLightSwatch,
        primaryColor: AppColors.accentLight,
        colorScheme: ColorScheme.light(
          primary: AppColors.accentLight,
          secondary: AppColors.accentLight,
          background: AppColors.backgroundLight,
          surface: AppColors.surfaceLight,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: AppColors.textPrimaryLight,
          onSurface: AppColors.textPrimaryLight,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: AppTheme.lightTheme.textTheme,
        cardTheme: AppTheme.lightTheme.cardTheme,
        appBarTheme: AppTheme.lightTheme.appBarTheme,
        iconTheme: AppTheme.lightTheme.iconTheme,
        inputDecorationTheme: AppTheme.lightTheme.inputDecorationTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: AppColors.accentDarkSwatch,
        primaryColor: AppColors.accentDark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accentDark,
          secondary: AppColors.accentDark,
          background: AppColors.backgroundDark,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: AppColors.textPrimaryDark,
          onSurface: AppColors.textPrimaryDark,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: AppTheme.darkTheme.textTheme,
        cardTheme: AppTheme.darkTheme.cardTheme,
        appBarTheme: AppTheme.darkTheme.appBarTheme,
        iconTheme: AppTheme.darkTheme.iconTheme,
        inputDecorationTheme: AppTheme.darkTheme.inputDecorationTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentDark,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BasicMiniPlayer(),
            ),
          ],
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(isFirstLaunch: isFirstLaunch),
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
        '/all_badges': (context) => const AllBadgesScreen(),
        '/module_to_lesson_migration': (context) => const ModulesToLessonsMigrationScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/media_player') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => MediaPlayerScreen(
              title: args['title'],
              subtitle: args['subtitle'],
              mediaUrl: args['mediaUrl'],
              mediaType: args['mediaType'],
              imageUrl: args['imageUrl'],
              mediaItem: args['mediaItem'],
            ),
          );
        }
        
        if (settings.name == '/mental_fitness_results') {
          final args = settings.arguments as Map<String, dynamic>? ?? {
            'goals': <String>[],
            'personalityType': 'Balanced',
            'stressScore': 0.5,
            'pressureResponse': '',
            'learningPreferences': <String>[],
          };
          
          return MaterialPageRoute(
            builder: (context) => MentalFitnessResults(
              goals: args['goals'] as List<String>,
              customGoal: args['customGoal'] as String?,
              personalityType: args['personalityType'] as String,
              stressScore: args['stressScore'] as double,
              pressureResponse: args['pressureResponse'] as String,
              learningPreferences: args['learningPreferences'] as List<String>,
            ),
          );
        }
        
        return null;
      },
    );
  }
}
