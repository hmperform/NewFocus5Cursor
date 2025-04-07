import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../models/coach_model.dart';
import '../models/article_model.dart';
import '../models/media_model.dart';

// Replace DummyData references with real data
final List<String> migrationStatuses = [
  'Pending',
  'In Progress',
  'Completed',
  'Failed'
];

// Replace debug prints with proper logging
void _logError(String message) {
  if (kDebugMode) {
    print('Error: $message');
  }
} 