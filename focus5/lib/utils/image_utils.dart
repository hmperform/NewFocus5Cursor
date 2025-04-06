import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class ImageUtils {
  /// Loads a network image with proper error handling and fallbacks for web
  static Widget networkImageWithFallback({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Color? backgroundColor,
    Color? errorColor,
  }) {
    return FadeInImage.memoryNetwork(
      placeholder: kTransparentImage,
      image: imageUrl,
      width: width,
      height: height,
      fit: fit,
      imageErrorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: backgroundColor ?? Colors.grey[300],
          child: Center(
            child: Icon(
              Icons.image_not_supported,
              size: width * 0.3, // Proportional to the container
              color: errorColor ?? Colors.grey[600],
            ),
          ),
        );
      },
    );
  }

  /// Loads an avatar with a fallback for web
  static Widget avatarWithFallback({
    String? imageUrl,
    required double radius,
    String? name,
    Color? backgroundColor,
    Color? textColor,
  }) {
    // Only use NetworkImage and onBackgroundImageError when imageUrl is not null
    final NetworkImage? networkImage = 
        (imageUrl != null && imageUrl.isNotEmpty) 
            ? NetworkImage(imageUrl) 
            : null;
            
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      backgroundImage: networkImage,
      // Only provide onBackgroundImageError when we have a backgroundImage
      onBackgroundImageError: networkImage != null 
          ? (exception, stackTrace) {
              debugPrint('Failed to load avatar image: $exception');
            }
          : null,
      child: imageUrl == null || imageUrl.isEmpty 
          ? Text(
              name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.grey[800],
              ),
            ) 
          : null,
    );
  }
} 