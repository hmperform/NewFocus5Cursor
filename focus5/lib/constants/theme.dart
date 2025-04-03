import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color secondaryLight = Color(0xFFFF9800);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  
  // Dark theme colors
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color secondaryDark = Color(0xFFFFA726);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  
  // Common colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF29B6F6);
  
  // Custom app accent colors
  static const Color accentDark = Color(0xFFB4FF00);  // Neon green for dark mode
  static const Color accentLight = Color(0xFF268623); // Green for light mode
  
  // Material color swatches for the accent colors
  static final MaterialColor accentDarkSwatch = MaterialColor(
    0xFFB4FF00,
    <int, Color>{
      50: Color(0xFFF7FFCC),
      100: Color(0xFFEEFF99),
      200: Color(0xFFE3FF66),
      300: Color(0xFFD6FF33),
      400: Color(0xFFC9FF00),
      500: accentDark,
      600: Color(0xFF9FE600),
      700: Color(0xFF8ACC00),
      800: Color(0xFF75B300),
      900: Color(0xFF609900),
    },
  );
  
  static final MaterialColor accentLightSwatch = MaterialColor(
    0xFF268623,
    <int, Color>{
      50: Color(0xFFE8F5E9),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: accentLight,
      600: Color(0xFF227A1F),
      700: Color(0xFF1B691A),
      800: Color(0xFF155915),
      900: Color(0xFF0F480F),
    },
  );
  
  // Helper method to get the correct accent color based on brightness
  static Color getAccentColor(Brightness brightness) {
    return brightness == Brightness.dark ? accentDark : accentLight;
  }
  
  // Helper method to get the appropriate foreground color for accent buttons
  static Color getAccentTextColor(Brightness brightness) {
    return brightness == Brightness.dark ? Colors.black : Colors.white;
  }
  
  // Helper method to get the appropriate accent swatch based on brightness
  static MaterialColor getAccentSwatch(Brightness brightness) {
    return brightness == Brightness.dark ? accentDarkSwatch : accentLightSwatch;
  }
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
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
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.textPrimaryLight, fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: AppColors.textPrimaryLight, fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: AppColors.textPrimaryLight, fontSize: 24, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: AppColors.textPrimaryLight, fontSize: 22, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: AppColors.textPrimaryLight, fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: AppColors.textPrimaryLight, fontSize: 14, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.textPrimaryLight, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.accentLight,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: AppColors.primaryLight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.surfaceLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.textPrimaryLight,
      size: 24,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      background: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: AppColors.textPrimaryDark,
      onSurface: AppColors.textPrimaryDark,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.textPrimaryDark, fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: AppColors.textPrimaryDark, fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: AppColors.textPrimaryDark, fontSize: 24, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: AppColors.textPrimaryDark, fontSize: 22, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: AppColors.textPrimaryDark, fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: AppColors.textPrimaryDark, fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: AppColors.textPrimaryDark, fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: AppColors.textPrimaryDark, fontSize: 12, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: AppColors.textPrimaryDark, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.accentDark,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: AppColors.primaryDark),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.textPrimaryDark,
      size: 24,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
  );
} 