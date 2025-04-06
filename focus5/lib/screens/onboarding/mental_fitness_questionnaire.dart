import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../providers/auth_provider.dart';
import 'profile_setup_screen.dart';

class MentalFitnessQuestionnaire extends StatefulWidget {
  const MentalFitnessQuestionnaire({Key? key}) : super(key: key);

  @override
  State<MentalFitnessQuestionnaire> createState() => _MentalFitnessQuestionnaireState();
}

class _MentalFitnessQuestionnaireState extends State<MentalFitnessQuestionnaire> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Simply navigate to the profile setup screen after a short delay
    _navigateToProfileSetup();
  }
  
  Future<void> _navigateToProfileSetup() async {
    // Add a small delay to show the transition screen
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Navigate to profile setup with the onboarding flag
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ProfileSetupScreen(fromOnboarding: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB4FF00)),
              ),
              const SizedBox(height: 24),
              const Text(
                "Setting up your profile...",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 