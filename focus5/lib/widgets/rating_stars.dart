import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final bool showEmptyStars;

  const RatingStars({
    Key? key,
    required this.rating,
    this.size = 20.0,
    this.color = Colors.amber,
    this.showEmptyStars = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          // Full star
          return Icon(
            Icons.star,
            color: color,
            size: size,
          );
        } else if (index == rating.floor() && rating - rating.floor() > 0) {
          // Partial star
          return Icon(
            Icons.star_half,
            color: color,
            size: size,
          );
        } else if (showEmptyStars) {
          // Empty star
          return Icon(
            Icons.star_border,
            color: color,
            size: size,
          );
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }
} 