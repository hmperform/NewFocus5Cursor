import 'package:flutter/material.dart';

// This file is deprecated and should not be used.
// Use the CoachProfileScreen from the coach directory instead.
class CoachProfileScreen extends StatelessWidget {
  final dynamic coach;
  
  const CoachProfileScreen({Key? key, required this.coach}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show an error UI indicating this screen is deprecated
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error: Deprecated Screen'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 80),
              const SizedBox(height: 16),
              const Text(
                'This coach profile screen is deprecated',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please update your import to use:\nimport \'../coach/coach_profile_screen.dart\'',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}