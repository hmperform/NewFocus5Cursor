import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String PREF_KEY = 'is_dark_mode';
  
  late bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;
  
  // Theme mode for MaterialApp
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  // Current accent color based on theme
  Color get accentColor => _isDarkMode ? AppColors.accentDark : AppColors.accentLight;
  
  // Current accent text color based on theme
  Color get accentTextColor => _isDarkMode ? Colors.black : Colors.white;
  
  // Secondary text color (used for hints, subtitles, etc.)
  Color get secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.black87;
  
  // Background color based on theme
  Color get backgroundColor => _isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;
  
  // Text color based on theme
  Color get textColor => _isDarkMode ? Colors.white : Colors.black;
  
  // Surface color based on theme
  Color get surfaceColor => _isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;

  ThemeProvider() {
    _isDarkMode = true; // Default to dark mode initially
    loadThemePreference(); // Load saved preference
  }
  
  // Synchronous access for initial setup
  bool getThemeSync() {
    return _isDarkMode;
  }

  Future<void> loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use null-aware operator to default to true (dark mode) if not set
      _isDarkMode = prefs.getBool(PREF_KEY) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      // Keep default dark mode in case of error
      _isDarkMode = true;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PREF_KEY, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
  
  // Set theme explicitly
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(PREF_KEY, _isDarkMode);
      } catch (e) {
        debugPrint('Error saving theme preference: $e');
      }
    }
  }
} 