import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/coach_model.dart';
import '../services/coach_service.dart';

class CoachProvider with ChangeNotifier {
  final CoachService _coachService = CoachService();
  
  List<CoachModel> _coaches = [];
  CoachModel? _selectedCoach;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CoachModel> get coaches => _coaches;
  CoachModel? get selectedCoach => _selectedCoach;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set selected coach
  void setSelectedCoach(CoachModel coach) {
    _selectedCoach = coach;
    notifyListeners();
  }

  // Clear selected coach
  void clearSelectedCoach() {
    _selectedCoach = null;
    notifyListeners();
  }

  // Load all coaches
  Future<void> loadCoaches({bool activeOnly = true}) async {
    _setLoading(true);
    _error = null;

    try {
      // Set up a stream subscription to the coaches collection
      _coachService.getCoaches(activeOnly: activeOnly).listen(
        (coaches) {
          _coaches = coaches;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _error = "Failed to load coaches: $error";
          _setLoading(false);
          notifyListeners();
        },
      );
    } catch (e) {
      _error = "Failed to load coaches: $e";
      _setLoading(false);
      notifyListeners();
    }
  }

  // Get coach by ID
  Future<CoachModel?> getCoachById(String coachId) async {
    _setLoading(true);
    _error = null;

    try {
      // Get coach data
      CoachModel? coach;
      await _coachService.getCoachById(coachId).first.then((value) {
        coach = value;
        if (value != null) {
          _selectedCoach = value;
        }
      });
      _setLoading(false);
      notifyListeners();
      return coach;
    } catch (e) {
      _error = "Failed to load coach: $e";
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  // Get coach's courses
  Future<List<Map<String, dynamic>>> getCoachCourses(String coachId) async {
    _setLoading(true);
    _error = null;

    try {
      final courses = await _coachService.getCoachCourses(coachId);
      _setLoading(false);
      return courses;
    } catch (e) {
      _error = "Failed to load coach courses: $e";
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  // Get coach's audio modules
  Future<List<Map<String, dynamic>>> getCoachAudioModules(String coachId) async {
    _setLoading(true);
    _error = null;

    try {
      final audioModules = await _coachService.getCoachAudioModules(coachId);
      _setLoading(false);
      return audioModules;
    } catch (e) {
      _error = "Failed to load coach audio modules: $e";
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  // Get coach's articles
  Future<List<Map<String, dynamic>>> getCoachArticles(String coachId) async {
    _setLoading(true);
    _error = null;

    try {
      final articles = await _coachService.getCoachArticles(coachId);
      _setLoading(false);
      return articles;
    } catch (e) {
      _error = "Failed to load coach articles: $e";
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  // Admin function: Create or update a coach
  Future<String?> createOrUpdateCoach({
    String? id,
    required String name,
    required String title,
    required String bio,
    File? profileImage,
    File? headerImage,
    String? existingProfileUrl,
    String? existingHeaderUrl,
    required String bookingUrl,
    String? email,
    String? phoneNumber,
    String? instagramUrl,
    String? twitterUrl,
    String? linkedinUrl,
    String? websiteUrl,
    required List<String> specialties,
    required List<String> credentials,
    required bool isVerified,
    required bool isActive,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final coachId = await _coachService.createOrUpdateCoach(
        id: id,
        name: name,
        title: title,
        bio: bio,
        profileImage: profileImage,
        headerImage: headerImage,
        existingProfileUrl: existingProfileUrl,
        existingHeaderUrl: existingHeaderUrl,
        bookingUrl: bookingUrl,
        email: email,
        phoneNumber: phoneNumber,
        instagramUrl: instagramUrl,
        twitterUrl: twitterUrl,
        linkedinUrl: linkedinUrl,
        websiteUrl: websiteUrl,
        specialties: specialties,
        credentials: credentials,
        isVerified: isVerified,
        isActive: isActive,
      );
      
      _setLoading(false);
      // Refresh coaches list after creating/updating a coach
      loadCoaches(activeOnly: false);
      return coachId;
    } catch (e) {
      _error = "Failed to save coach: $e";
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  // Admin function: Delete a coach
  Future<bool> deleteCoach(String coachId) async {
    _setLoading(true);
    _error = null;

    try {
      await _coachService.deleteCoach(coachId);
      _setLoading(false);
      // Refresh coaches list after deleting a coach
      loadCoaches(activeOnly: false);
      return true;
    } catch (e) {
      _error = "Failed to delete coach: $e";
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 