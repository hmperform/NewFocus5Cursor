import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/content_provider.dart';
import '../../constants/theme.dart';
import '../../constants/sports.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/focus_area_chip.dart';

// Replace DummyData.focusAreas with real data from ContentProvider
final List<String> focusAreas = [
  'Mental Toughness',
  'Confidence',
  'Focus',
  'Resilience',
  'Motivation',
  'Anxiety Management',
  'Performance Under Pressure',
  'Team Dynamics',
  'Leadership',
  'Recovery'
]; 