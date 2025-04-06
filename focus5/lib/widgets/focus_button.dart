import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FocusButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Widget child;

  const FocusButton({
    Key? key,
    required this.onPressed,
    this.backgroundColor,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onPressed!();
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: child,
    );
  }
} 