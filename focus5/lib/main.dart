import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/audio_player_screen.dart';
import 'screens/home/journal_entry_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/content_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/journal_provider.dart';
import 'widgets/mini_player.dart';
import 'constants/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
  
  // TODO: Initialize Firebase when ready
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ContentProvider()),
        ChangeNotifierProvider(create: (context) => AudioProvider()),
        ChangeNotifierProxyProvider<AuthProvider, JournalProvider>(
          create: (context) => JournalProvider('user123'), // Default user ID
          update: (context, authProvider, previous) =>
            authProvider.isAuthenticated && authProvider.currentUser != null
              ? JournalProvider(authProvider.currentUser!.id)
              : JournalProvider('guest'),
        ),
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
    final ThemeData appTheme = ThemeData(
      // Base theme on dark mode
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      // Main color scheme with neon green primary
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB4FF00), // Neon green
        secondary: Color(0xFFB4FF00),
        background: Color(0xFF121212),
        surface: Color(0xFF1E1E1E),
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      
      // Custom card theme with dark background
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      
      // Text themes
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
      
      // Custom button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB4FF00),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // Custom input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB4FF00), width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A1A),
        selectedItemColor: Color(0xFFB4FF00),
        unselectedItemColor: Colors.grey,
        selectedIconTheme: IconThemeData(size: 28),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
    
    return MaterialApp(
      title: 'Focus 5',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
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
        '/journal_entry': (context) => const JournalEntryScreen(),
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
