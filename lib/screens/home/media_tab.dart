import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/media_provider.dart';
import '../../widgets/custom_button.dart';
import 'media_player_screen.dart';
import 'audio_player_screen.dart';

// Replace DummyData references with real data
final List<String> mediaCategories = [
  'Guided Meditations',
  'Breathing Exercises',
  'Visualization',
  'Mindfulness',
  'Performance Psychology',
  'Team Building',
  'Leadership',
  'Recovery'
];

// Replace debug prints with proper logging
void _logError(String message) {
  if (kDebugMode) {
    print('Error: $message');
  }
} 