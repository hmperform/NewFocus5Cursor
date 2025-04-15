import 'package:flutter/material.dart';

/// A class that provides consistent access to app icons across the application
class AppIcons {
  /// Returns the focus point icon as an Image widget with preserved colors
  static Widget getFocusPointIcon({
    double? width,
    double? height,
    Color? color,
  }) {
    // For colored version that preserves the image's original colors
    if (color == null) {
      return Image.asset(
        'assets/icons/focuspointicon-removebg-preview.png',
        width: width ?? 24.0,
        height: height ?? 24.0,
        fit: BoxFit.contain,
      );
    } 
    // For silhouette version when color is explicitly provided
    else {
      return Image.asset(
        'assets/icons/focuspointicon-removebg-preview.png',
        width: width ?? 24.0,
        height: height ?? 24.0,
        color: color,
        fit: BoxFit.contain,
      );
    }
  }
  
  /// Returns a custom widget for Focus Points display
  static Widget getCustomFocusPointWidget({
    required String value,
    double size = 40.0,
    Color backgroundColor = Colors.grey,
    Color textColor = Colors.white,
    bool showLabel = true,
    TextStyle? labelStyle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          SizedBox(height: 4),
          Text(
            'Focus Points',
            style: labelStyle ?? TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
  
  /// Returns the focus point icon as a widget with optional label
  static Widget getFocusPointIconWithLabel({
    required String label,
    double? iconSize,
    TextStyle? textStyle,
    Color? iconColor,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    double spacing = 4.0,
  }) {
    return Row(
      mainAxisSize: mainAxisSize,
      children: [
        getFocusPointIcon(
          width: iconSize,
          height: iconSize,
          color: iconColor,
        ),
        SizedBox(width: spacing),
        Text(
          label,
          style: textStyle,
        ),
      ],
    );
  }
} 