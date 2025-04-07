import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/coach_provider.dart';
import '../../services/data_migration_service.dart';

// Replace DummyData references with real data
final List<String> migrationTypes = [
  'Courses',
  'Modules',
  'Lessons',
  'Articles',
  'Videos',
  'Audio',
  'Coaches',
  'Users'
];

// Replace debug prints with proper logging
void _logError(String message) {
  if (kDebugMode) {
    print('Error: $message');
  }
} 