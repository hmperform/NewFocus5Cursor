import 'package:flutter/foundation.dart';
import '../models/coach_model.dart';
import '../services/coach_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachProvider with ChangeNotifier {
  final CoachService _coachService = CoachService();
  List<Coach> _coaches = [];
  Coach? _selectedCoach;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Coach> get coaches => _coaches;
  Coach? get selectedCoach => _selectedCoach;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Methods
  void setSelectedCoach(Coach coach) {
    _selectedCoach = coach;
    notifyListeners();
  }

  void clearSelectedCoach() {
    _selectedCoach = null;
    notifyListeners();
  }

  // Load coaches
  Future<void> loadCoaches({bool activeOnly = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _coaches = await _coachService.getCoaches(activeOnly: activeOnly);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load coaches: $e';
      debugPrint('Error in loadCoaches: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get coach by ID
  Future<Coach?> getCoachById(String coachId) async {
    if (_isLoading) return null; // Avoid fetching if already loading
    
    try {
      // First check if we already have this coach loaded
      Coach? localCoach = _coaches.firstWhere((c) => c.id == coachId, orElse: () => null as Coach);
      if (localCoach != null) {
        return localCoach;
      }
      
      // If not found locally, fetch from service
      _isLoading = true;
      notifyListeners();
      
      final Coach? coach = await _coachService.getCoachById(coachId);
      
      _isLoading = false;
      notifyListeners();
      return coach;
    } catch (e) {
      _errorMessage = "Failed to get coach details: $e";
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  List<Coach> getCoachesBySpecialization(String specialization) {
    return _coaches.where((coach) => 
      coach.specialization.toLowerCase().contains(specialization.toLowerCase())
    ).toList();
  }
  
  Future<String?> createCoach(Coach coach) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final String? coachId = await _coachService.createCoach(coach);
      
      if (coachId != null) {
        // Add new coach to local list with the generated ID
        _coaches.add(coach.copyWith(id: coachId));
      }
      
      _isLoading = false;
      notifyListeners();
      
      return coachId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create coach: ${e.toString()}';
      debugPrint('Error creating coach: $e');
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> updateCoach(Coach coach) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final bool success = await _coachService.updateCoach(coach);
      
      if (success) {
        // Update coach in local list
        final index = _coaches.indexWhere((c) => c.id == coach.id);
        if (index != -1) {
          _coaches[index] = coach;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update coach: ${e.toString()}';
      debugPrint('Error updating coach: $e');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteCoach(String coachId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final bool success = await _coachService.deleteCoach(coachId);
      
      if (success) {
        // Remove coach from local list
        _coaches.removeWhere((coach) => coach.id == coachId);
      }
      
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete coach: ${e.toString()}';
      debugPrint('Error deleting coach: $e');
      notifyListeners();
      return false;
    }
  }
} 