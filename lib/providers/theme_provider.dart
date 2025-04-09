import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  Color _primaryColor = Colors.blue;
  Color _accentColor = Colors.amber;
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  Color get backgroundColor => _backgroundColor;
  Color get textColor => _textColor;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _backgroundColor = _isDarkMode ? Colors.grey[900]! : Colors.white;
    _textColor = _isDarkMode ? Colors.white : Colors.black;
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
  }

  ThemeData get themeData {
    return ThemeData(
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: MaterialColor(_primaryColor.value, {
          50: _primaryColor.withOpacity(0.1),
          100: _primaryColor.withOpacity(0.2),
          200: _primaryColor.withOpacity(0.3),
          300: _primaryColor.withOpacity(0.4),
          400: _primaryColor.withOpacity(0.5),
          500: _primaryColor.withOpacity(0.6),
          600: _primaryColor.withOpacity(0.7),
          700: _primaryColor.withOpacity(0.8),
          800: _primaryColor.withOpacity(0.9),
          900: _primaryColor,
        }),
        accentColor: _accentColor,
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: _backgroundColor,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: _textColor),
        bodyMedium: TextStyle(color: _textColor),
        bodySmall: TextStyle(color: _textColor),
      ),
    );
  }
} 