import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart'; // Import SchedulerBinding
import '../models/coach_model.dart';
import '../services/coach_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachProvider with ChangeNotifier {
  final CoachService _coachService = CoachService();
  List<Coach> _coaches = [];
  Coach? _selectedCoach;
  bool _isLoading = false;
  String? _errorMessage;

  // Helper method to safely notify listeners
  void _safeNotifyListeners() {
    // Use addPostFrameCallback to ensure listeners are notified after the build phase
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) { // Check if there are still listeners
        notifyListeners();
      }
    });
  }

  // Getters
  List<Coach> get coaches => _coaches;
  Coach? get selectedCoach => _selectedCoach;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Methods
  void setSelectedCoach(Coach coach) {
    _selectedCoach = coach;
    _safeNotifyListeners();
  }

  void clearSelectedCoach() {
    _selectedCoach = null;
    _safeNotifyListeners();
  }

  // Load coaches
  Future<void> loadCoaches({bool activeOnly = true}) async {
    if (_isLoading) return; // Prevent concurrent loads
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners(); // Notify loading start safely

    try {
      _coaches = await _coachService.getCoaches(activeOnly: activeOnly);
    } catch (e) {
      _errorMessage = 'Failed to load coaches: $e';
      debugPrint('Error in loadCoaches: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners(); // Notify loading end safely
    }
  }

  // Get coach by ID
  Future<Coach?> getCoachById(String coachId) async {
    try {
      // First check if we already have this coach loaded
      Coach? localCoach = _coaches.firstWhere((c) => c.id == coachId, orElse: () => null as Coach);
      if (localCoach != null) {
        return localCoach;
      }
      
      // Fetch from service (no need to manage loading state here, handled by caller)
      final Coach? coach = await _coachService.getCoachById(coachId);
      
      return coach;
    } catch (e) {
      // Update error message safely, but don't change loading state
      final newErrorMessage = "Failed to get coach details: $e";
      if (_errorMessage != newErrorMessage) {
        _errorMessage = newErrorMessage;
        _safeNotifyListeners();
      }
      debugPrint('Error in getCoachById: $_errorMessage');
      return null;
    }
  }

  List<Coach> getCoachesBySpecialization(String specialization) {
    return _coaches.where((coach) => 
      coach.specialization.toLowerCase().contains(specialization.toLowerCase())
    ).toList();
  }
  
  Future<String?> createCoach(Coach coach) async {
    if (_isLoading) return null;
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();
    
    String? coachId;
    try {
      coachId = await _coachService.createCoach(coach);
      if (coachId != null) {
        _coaches.add(coach.copyWith(id: coachId));
      }
    } catch (e) {
      _errorMessage = 'Failed to create coach: ${e.toString()}';
      debugPrint('Error creating coach: $e');
      coachId = null; 
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
    return coachId;
  }
  
  Future<bool> updateCoach(Coach coach) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();
    
    bool success = false;
    try {
      success = await _coachService.updateCoach(coach);
      if (success) {
        final index = _coaches.indexWhere((c) => c.id == coach.id);
        if (index != -1) {
          _coaches[index] = coach;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to update coach: ${e.toString()}';
      debugPrint('Error updating coach: $e');
      success = false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
    return success;
  }
  
  Future<bool> deleteCoach(String coachId) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();
    
    bool success = false;
    try {
      success = await _coachService.deleteCoach(coachId);
      if (success) {
        _coaches.removeWhere((coach) => coach.id == coachId);
      }
    } catch (e) {
      _errorMessage = 'Failed to delete coach: ${e.toString()}';
      debugPrint('Error deleting coach: $e');
      success = false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
    return success;
  }
} 