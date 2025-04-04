import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/mindset_assessment_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/audio_player_screen.dart';
import 'screens/more/journal_entry_screen.dart';
import 'screens/more/journal_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/content_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/chat_provider.dart';
import 'widgets/mini_player.dart';
import 'constants/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
  
  // Initialize theme provider early to avoid flash of wrong theme
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreference();
  
  // TODO: Initialize Firebase when ready
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ContentProvider()),
        ChangeNotifierProvider(create: (context) => AudioProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => JournalProvider('default_user')),
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
            Consumer<AudioProvider>(
              builder: (context, audioProvider, _) {
                return const MiniPlayer();
              },
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
        '/journal_entry': (context) => const JournalEntryScreen(),
        '/journal': (context) => const JournalScreen(),
        '/paywall': (context) => const PaywallScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/audio_player') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AudioPlayerScreen(
              title: args['title'],
              subtitle: args['subtitle'],
              audioUrl: args['audioUrl'],
              imageUrl: args['imageUrl'],
            ),
          );
        }
        return null;
      },
    );
  }
}
