import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coach_model.dart';

class CoachProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CoachModel> _coaches = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CoachModel> get coaches => _coaches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCoaches() async {
    try {
      _isLoading = true;
      notifyListeners();

      final QuerySnapshot coachesSnapshot = await _firestore.collection('coaches').get();
      
      _coaches = coachesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Sanitize data to handle document references
        data = _sanitizeDocumentData(data);
        return CoachModel.fromJson({...data, 'id': doc.id});
      }).toList();
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load coaches: ${e.toString()}';
      debugPrint('Error loading coaches: $e');
      notifyListeners();
    }
  }
  
  Future<CoachModel?> getCoachById(String coachId) async {
    try {
      // Check if we have already loaded this coach
      final existingCoach = _coaches.firstWhere(
        (coach) => coach.id == coachId,
        orElse: () => CoachModel(
          id: '',
          name: '',
          title: '',
          bio: '',
          profileImageUrl: '',
          headerImageUrl: '',
          bookingUrl: '',
          specialties: [],
          credentials: [],
          isVerified: false, 
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      if (existingCoach.id.isNotEmpty) {
        return existingCoach;
      }
      
      // Load from Firestore
      final DocumentSnapshot coachDoc = await _firestore.collection('coaches').doc(coachId).get();
      
      if (!coachDoc.exists) {
        return null;
      }
      
      Map<String, dynamic> data = coachDoc.data() as Map<String, dynamic>;
      // Sanitize data to handle document references
      data = _sanitizeDocumentData(data);
      
      return CoachModel.fromJson({...data, 'id': coachDoc.id});
    } catch (e) {
      _errorMessage = 'Failed to get coach: ${e.toString()}';
      debugPrint('Error getting coach: $e');
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