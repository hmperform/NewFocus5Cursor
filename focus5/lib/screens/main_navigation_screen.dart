import 'package:flutter/material.dart';
import 'home/home_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simply redirect to the HomeScreen
    return const HomeScreen();
  }
} 