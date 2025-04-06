import 'package:flutter/material.dart';

class FocusAreaChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final double height;
  final EdgeInsetsGeometry? padding;
  final bool isSelected;

  const FocusAreaChip({
    Key? key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.height = 32.0,
    this.padding,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualBackgroundColor = backgroundColor ?? 
        (isSelected ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.surface);
    final actualTextColor = textColor ?? 
        (isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: actualBackgroundColor,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: actualTextColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
} 