import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color accent = Color(0xFFFF9800);
  
  // Background colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color darkBackground = Color(0xFF121212);
  
  // Card colors
  static const Color lightCardBackground = Colors.white;
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  
  // Gray shades
  static const Color lightGray = Color(0xFFEEEEEE);
  static const Color darkGray = Color(0xFF757575);
  
  // Text colors
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color darkTextPrimary = Colors.white;
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF29B6F6);
  
  // Helper method to get appropriate color based on brightness
  static Color getColorForBrightness(Brightness brightness, Color lightColor, Color darkColor) {
    return brightness == Brightness.dark ? darkColor : lightColor;
  }
} 