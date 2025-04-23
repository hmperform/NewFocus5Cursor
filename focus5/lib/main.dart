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
import 'screens/home/course_detail_screen.dart';
import 'screens/article/article_detail_screen.dart';
import 'models/content_models.dart';

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
        // UserProvider needs to be defined before AuthProvider depends on it
        ChangeNotifierProvider(create: (context) => UserProvider()),
        // AuthProvider now depends on UserProvider
        ChangeNotifierProxyProvider<UserProvider, AuthProvider>(
          create: (context) => AuthProvider(null), // Initial state with null provider
          update: (context, userProvider, previousAuthProvider) {
            // Return existing provider if it exists rather than creating a new one
            return previousAuthProvider ?? AuthProvider(userProvider);
          },
        ),
        ChangeNotifierProvider(create: (context) => ContentProvider()),
        ChangeNotifierProvider(create: (context) => MediaProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProxyProvider<AuthProvider, JournalProvider>(
          // Create a new JournalProvider with the default user
          create: (context) => JournalProvider('default_user'),
          // Update when auth state changes
          update: (context, authProvider, previousJournalProvider) {
            // Get current user ID or use default
            final userId = authProvider.currentUser?.id ?? 'default_user';
            
            // Always create a new provider when auth changes
            return JournalProvider(userId);
          },
        ),
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

class Focus5App extends StatefulWidget {
  final bool isFirstLaunch;
  
  const Focus5App({Key? key, required this.isFirstLaunch}) : super(key: key);

  @override
  State<Focus5App> createState() => _Focus5AppState();
}

class _Focus5AppState extends State<Focus5App> {
  @override
  void initState() {
    super.initState();
    _setupStreakTracking();
  }
  
  // Setup streak tracking to run on each app launch
  void _setupStreakTracking() {
    // Delay slightly to allow providers to initialize
    Future.delayed(const Duration(milliseconds: 500), () {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Listen for user changes to check streak status
      authProvider.addListener(() {
        final userId = authProvider.currentUser?.id;
        if (userId != null && userProvider.user != null) {
          // Check streak status when user logs in
          userProvider.checkAndUpdateStreakStatus(userId);
        }
      });
      
      // Initial streak check if user is already logged in
      if (authProvider.isLoggedIn && userProvider.user != null) {
        print('_setupStreakTracking: User is logged in. Checking streak status.');
        userProvider.checkAndUpdateStreakStatus(userProvider.user!.id);
        // --> Check for badges after initial login checks <--
        userProvider.checkAndAwardBadges(context);
      }
    });
  }

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
        '/': (context) => SplashScreen(isFirstLaunch: widget.isFirstLaunch),
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
        '/course-details': (context) {
          final courseId = ModalRoute.of(context)!.settings.arguments as String?;
          return courseId != null 
                 ? CourseDetailScreen(courseId: courseId)
                 : Scaffold(body: Center(child: Text('Error: Missing Course ID'))); 
        },
        '/article-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          if (args != null && 
              args.containsKey('title') && 
              args.containsKey('imageUrl')) {
            return ArticleDetailScreen(
              title: args['title'] as String,
              imageUrl: args['imageUrl'] as String,
              content: args['content'] as String?, // Content is optional
            );
          } else {
            // Handle missing or invalid arguments
             return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Error: Missing arguments for Article Details')));
          }
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/media_player' || settings.name == '/audio-player') {
          final args = settings.arguments;
          if (args is Map<String, dynamic> && args.containsKey('mediaUrl')) {
            return MaterialPageRoute(
              builder: (context) => MediaPlayerScreen(
                title: args['title'] as String? ?? 'Audio',
                subtitle: args['subtitle'] as String? ?? '',
                mediaUrl: args['mediaUrl'] as String,
                mediaType: args['mediaType'] as MediaType? ?? MediaType.audio,
                imageUrl: args['imageUrl'] as String?,
                mediaItem: args.containsKey('mediaItem') ? args['mediaItem'] as MediaItem? : null,
              ),
            );
          } else {
            // Handle incorrect arguments or other cases if needed
             debugPrint('Invalid arguments for /media_player or /audio-player: $args');
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Error: Invalid arguments for audio player')),
              ),
            );
          }
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
        
        // If route is not handled by `routes` or `onGenerateRoute`, show error page
        debugPrint('Route not found: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
      },
    );
  }
}
