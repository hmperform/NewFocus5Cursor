import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/content_models.dart';
import '../constants/dummy_data.dart';
import '../services/firebase_content_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContentProvider with ChangeNotifier {
  List<Course> _courses = [];
  List<DailyAudio> _audioModules = [];
  List<Article> _articles = [];
  List<Map<String, dynamic>> _coaches = [];
  DailyAudio? _todayAudio;
  Module? _dailyModule;
  Map<String, dynamic>? _dailyModuleAssignment;
  String? _universityCode;
  bool _isLoading = false;
  String? _errorMessage;
  
  final FirebaseContentService _contentService = FirebaseContentService();

  // Getters
  List<Course> get courses => _courses;
  List<DailyAudio> get audioModules => _audioModules;
  List<Article> get articles => _articles;
  List<Map<String, dynamic>> get coaches => _coaches;
  DailyAudio? get todayAudio => _todayAudio;
  Module? get dailyModule => _dailyModule;
  Map<String, dynamic>? get dailyModuleAssignment => _dailyModuleAssignment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize content, optionally filtering by university code
  Future<void> initContent(String? universityCode) async {
    _isLoading = true;
    _errorMessage = null;
    _universityCode = universityCode;
    notifyListeners();

    try {
      // Load courses from Firebase
      await loadCourses();
      
      // Load audio modules from Firebase
      await loadAudioModules();
      
      // Load daily module assignment
      await loadDailyModule();
      
      // For now, still use dummy data for articles and coaches
      _articles = DummyData.dummyArticles;
      _coaches = DummyData.dummyCoaches;
      
      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load content: ${e.toString()}';
      print('Error in initContent: ${e.toString()}');
      
      // In case of error, make sure we have at least some data
      if (_courses.isEmpty) _courses = DummyData.dummyCourses;
      if (_audioModules.isEmpty) _audioModules = DummyData.dummyAudioModules;
      if (_articles.isEmpty) _articles = DummyData.dummyArticles;
      if (_coaches.isEmpty) _coaches = DummyData.dummyCoaches;
    }
    
    notifyListeners();
  }

  Future<void> loadCourses() async {
    try {
      _courses = await _contentService.getCourses(universityCode: _universityCode);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load courses: ${e.toString()}';
      notifyListeners();
    }
  }
  
  Future<void> loadAudioModules() async {
    try {
      _audioModules = await _contentService.getDailyAudios(universityCode: _universityCode);
      
      // Set today's audio
      _todayAudio = _audioModules.isNotEmpty 
        ? _audioModules.firstWhere(
            (audio) => audio.datePublished.day == DateTime.now().day,
            orElse: () => _audioModules.first,
          )
        : null;
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load audio modules: ${e.toString()}';
      notifyListeners();
    }
  }
  
  Future<void> loadDailyModule() async {
    try {
      _dailyModuleAssignment = await _contentService.getTodayModuleAssignment();
      
      if (_dailyModuleAssignment != null && _dailyModuleAssignment!['module'] != null) {
        _dailyModule = Module.fromJson(_dailyModuleAssignment!['module'] as Map<String, dynamic>);
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load daily module: ${e.toString()}';
      notifyListeners();
    }
  }
  
  Future<bool> markDailyModuleCompleted() async {
    if (_dailyModuleAssignment == null) return false;
    
    try {
      final assignmentId = _dailyModuleAssignment!['assignment']['id'];
      final result = await _contentService.markModuleCompleted(assignmentId);
      
      if (result) {
        // Update the local assignment state
        _dailyModuleAssignment!['assignment']['completed'] = true;
        _dailyModuleAssignment!['assignment']['completedDate'] = DateTime.now().toIso8601String();
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _errorMessage = 'Failed to mark module as completed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  Future<void> refreshTodayAudio() async {
    try {
      await loadAudioModules();
    } catch (e) {
      _errorMessage = 'Failed to load today\'s audio: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Methods to get filtered courses
  
  List<Course> getCoursesForCoach(String coachId) {
    return _courses.where((course) => course.creatorId == coachId).toList();
  }
  
  List<Course> getCoursesForFocusArea(String focusArea) {
    // If we don't have courses loaded yet, load them
    if (_courses.isEmpty) {
      loadCoursesSync();
    }
    
    // More flexible matching - check if the focus area is contained in or contains any of the course's focus areas
    return _courses.where((course) {
      return course.focusAreas.any((area) => 
        area.toLowerCase().contains(focusArea.toLowerCase()) || 
        focusArea.toLowerCase().contains(area.toLowerCase())
      );
    }).toList();
  }
  
  List<Course> searchCourses(String query) {
    if (query.isEmpty) return _courses;
    
    final lowerQuery = query.toLowerCase();
    return _courses.where((course) {
      return course.title.toLowerCase().contains(lowerQuery) ||
             course.description.toLowerCase().contains(lowerQuery) ||
             course.creatorName.toLowerCase().contains(lowerQuery) ||
             course.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
             course.focusAreas.any((area) => area.toLowerCase().contains(lowerQuery));
    }).toList();
  }
  
  // Method to get a specific course
  Future<Course?> getCourseById(String courseId) async {
    try {
      // Check if the course is already loaded
      final localCourse = _courses.firstWhere(
        (course) => course.id == courseId,
        orElse: () => null as Course,
      );
      
      if (localCourse != null) {
        return localCourse;
      }
      
      // If not, fetch it from Firebase
      return await _contentService.getCourseById(courseId);
    } catch (e) {
      _errorMessage = 'Failed to get course: ${e.toString()}';
      return null;
    }
  }
  
  // Methods to get filtered audio modules
  
  List<DailyAudio> getAudioForCoach(String coachId) {
    return _audioModules.where((audio) => audio.creatorId == coachId).toList();
  }
  
  List<DailyAudio> getAudioForFocusArea(String focusArea) {
    return _audioModules.where((audio) => audio.focusAreas.contains(focusArea)).toList();
  }
  
  List<DailyAudio> searchAudioModules(String query) {
    if (query.isEmpty) return _audioModules;
    
    final lowerQuery = query.toLowerCase();
    return _audioModules.where((audio) {
      return audio.title.toLowerCase().contains(lowerQuery) ||
             audio.description.toLowerCase().contains(lowerQuery) ||
             audio.creatorName.toLowerCase().contains(lowerQuery) ||
             audio.category.toLowerCase().contains(lowerQuery) ||
             audio.focusAreas.any((area) => area.toLowerCase().contains(lowerQuery));
    }).toList();
  }
  
  // Helper methods
  
  void loadCoursesSync() {
    _courses = DummyData.dummyCourses.where((course) {
      // If course is not university exclusive, it's available to everyone
      if (!course.universityExclusive) return true;
      
      // If course is university exclusive, check if user has access
      if (_universityCode != null && 
          course.universityAccess != null && 
          course.universityAccess!.contains(_universityCode)) {
        return true;
      }
      
      return false;
    }).toList();
  }
  
  // Methods to create content (for admin purposes)
  
  Future<String?> createCourse(Course course) async {
    try {
      return await _contentService.createCourse(course);
    } catch (e) {
      _errorMessage = 'Failed to create course: ${e.toString()}';
      return null;
    }
  }
  
  Future<String?> createDailyAudio(DailyAudio audio) async {
    try {
      return await _contentService.createDailyAudio(audio);
    } catch (e) {
      _errorMessage = 'Failed to create daily audio: ${e.toString()}';
      return null;
    }
  }
} 