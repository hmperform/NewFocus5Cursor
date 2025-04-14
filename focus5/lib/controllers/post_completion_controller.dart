import 'package:flutter/material.dart';
import 'package:focus5/models/content_models.dart';

class PostCompletionController extends ChangeNotifier {
  final DailyAudio module;
  int currentScreenIndex = 0;
  final List<String> screenTypes = [];
  Map<String, dynamic> userResponses = {};
  
  PostCompletionController(this.module) {
    final screens = module.postCompletionScreens;
    if (screens != null && screens['screenschosen'] != null) {
      screenTypes.addAll(List<String>.from(screens['screenschosen']));
    }
  }
  
  bool get hasNextScreen => currentScreenIndex < screenTypes.length - 1;
  
  void nextScreen() {
    if (hasNextScreen) {
      currentScreenIndex++;
      notifyListeners();
    }
  }
  
  // Method to go to the previous screen
  void goBack() {
     if (currentScreenIndex > 0) {
       currentScreenIndex--;
       notifyListeners();
     }
  }
  
  String get currentScreenType => screenTypes[currentScreenIndex];
  
  int get totalScreens => screenTypes.length;
  
  double get progressPercentage => (currentScreenIndex + 1) / totalScreens;
  
  void saveResponse(String response) {
    userResponses[currentScreenType] = response;
    notifyListeners();
  }
} 