import 'package:flutter/foundation.dart';
import '../models/coach_model.dart';
import '../models/course_model.dart';
import '../services/coach_service.dart';

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
      _coachService.getCoaches().listen(
        (coaches) {
          _coaches = coaches;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Failed to load coaches: $error';
          debugPrint('Error loading coaches: $error');
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to load coaches: $e';
      debugPrint('Error in loadCoaches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get coach by ID
  Future<CoachModel?> getCoachById(String coachId) async {
    if (_isLoading) return null; // Avoid fetching if already loading
    
    _isLoading = true;
    _errorMessage = null;

    try {
      // Call the correct service method: getCoach
      final CoachModel? coach = await _coachService.getCoach(coachId);
      _isLoading = false;
      return coach;
    } catch (e) {
      _errorMessage = "Failed to get coach details: $e";
      _isLoading = false;
      notifyListeners(); // Notify listeners about the error
      return null;
    }
  }

  List<CoachModel> getCoachesBySpecialty(String specialty) {
    return _coaches.where((coach) => 
      coach.specialties.any((s) => s.toLowerCase().contains(specialty.toLowerCase()))
    ).toList();
  }
  
  Future<String?> createCoach(CoachModel coach) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final DocumentReference docRef = await _firestore.collection('coaches').add({
        'name': coach.name,
        'title': coach.title,
        'bio': coach.bio,
        'profileImageUrl': coach.profileImageUrl,
        'headerImageUrl': coach.headerImageUrl,
        'bookingUrl': coach.bookingUrl,
        'email': coach.email,
        'phoneNumber': coach.phoneNumber,
        'instagramUrl': coach.instagramUrl,
        'twitterUrl': coach.twitterUrl,
        'linkedinUrl': coach.linkedinUrl,
        'websiteUrl': coach.websiteUrl,
        'specialties': coach.specialties,
        'credentials': coach.credentials,
        'education': coach.education,
        'certifications': coach.certifications,
        'experience': coach.experience,
        'approach': coach.approach,
        'isVerified': coach.isVerified,
        'isActive': coach.isActive,
        'createdAt': Timestamp.fromDate(coach.createdAt),
        'updatedAt': Timestamp.fromDate(coach.updatedAt),
      });
      
      // Add new coach to local list
      _coaches.add(coach.copyWith(id: docRef.id));
      
      _isLoading = false;
      notifyListeners();
      
      return docRef.id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create coach: ${e.toString()}';
      debugPrint('Error creating coach: $e');
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> updateCoach(CoachModel coach) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('coaches').doc(coach.id).update({
        'name': coach.name,
        'title': coach.title,
        'bio': coach.bio,
        'profileImageUrl': coach.profileImageUrl,
        'headerImageUrl': coach.headerImageUrl,
        'bookingUrl': coach.bookingUrl,
        'email': coach.email,
        'phoneNumber': coach.phoneNumber,
        'instagramUrl': coach.instagramUrl,
        'twitterUrl': coach.twitterUrl,
        'linkedinUrl': coach.linkedinUrl,
        'websiteUrl': coach.websiteUrl,
        'specialties': coach.specialties,
        'credentials': coach.credentials,
        'education': coach.education,
        'certifications': coach.certifications,
        'experience': coach.experience,
        'approach': coach.approach,
        'isVerified': coach.isVerified,
        'isActive': coach.isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Update coach in local list
      final index = _coaches.indexWhere((c) => c.id == coach.id);
      if (index != -1) {
        _coaches[index] = coach;
      }
      
      _isLoading = false;
      notifyListeners();
      
      return true;
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
      
      await _firestore.collection('coaches').doc(coachId).delete();
      
      // Remove coach from local list
      _coaches.removeWhere((coach) => coach.id == coachId);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete coach: ${e.toString()}';
      debugPrint('Error deleting coach: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Helper method to sanitize Firestore document data
  Map<String, dynamic> _sanitizeDocumentData(Map<String, dynamic> data) {
    Map<String, dynamic> sanitizedData = {};
    
    data.forEach((key, value) {
      if (value is DocumentReference) {
        // Convert document references to string paths
        sanitizedData[key] = value.path;
      } else if (value is List) {
        // Handle lists containing document references
        sanitizedData[key] = _sanitizeList(value);
      } else if (value is Map) {
        // Handle nested maps
        sanitizedData[key] = _sanitizeDocumentData(Map<String, dynamic>.from(value));
      } else if (value is Timestamp) {
        // Convert Timestamp to DateTime
        sanitizedData[key] = (value as Timestamp).toDate();
      } else {
        // Keep other values as is
        sanitizedData[key] = value;
      }
    });
    
    return sanitizedData;
  }
  
  // Helper method to sanitize lists in Firestore data
  List _sanitizeList(List list) {
    return list.map((item) {
      if (item is DocumentReference) {
        return item.path;
      } else if (item is Map) {
        return _sanitizeDocumentData(Map<String, dynamic>.from(item));
      } else if (item is List) {
        return _sanitizeList(item);
      } else if (item is Timestamp) {
        return (item as Timestamp).toDate();
      } else {
        return item;
      }
    }).toList();
  }
} 