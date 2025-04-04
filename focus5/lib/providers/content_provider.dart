import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/content_models.dart';
import '../constants/dummy_data.dart';

class ContentProvider with ChangeNotifier {
  List<Course> _courses = [];
  List<DailyAudio> _audioModules = [];
  List<Article> _articles = [];
  List<Map<String, dynamic>> _coaches = [];
  DailyAudio? _todayAudio;
  String? _universityCode;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Course> get courses => _courses;
  List<DailyAudio> get audioModules => _audioModules;
  List<Article> get articles => _articles;
  List<Map<String, dynamic>> get coaches => _coaches;
  DailyAudio? get todayAudio => _todayAudio;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize content, optionally filtering by university code
  Future<void> initContent(String? universityCode) async {
    _isLoading = true;
    _errorMessage = null;
    _universityCode = universityCode;
    notifyListeners();

    try {
      // In a real app, this would fetch from API
      // Use a shorter delay to improve loading time
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Immediately load data from DummyData
      _courses = DummyData.dummyCourses;
      _audioModules = DummyData.dummyAudioModules;
      _articles = DummyData.dummyArticles;
      _coaches = DummyData.dummyCoaches;
      
      // Set today's audio
      _todayAudio = _audioModules.isNotEmpty 
        ? _audioModules.firstWhere(
            (audio) => audio.datePublished.day == DateTime.now().day,
            orElse: () => _audioModules.first,
          )
        : null;
      
      // Filter content based on university access if applicable
      if (universityCode != null) {
        _courses = _courses.where((course) => 
          !course.universityExclusive || 
          (course.universityAccess?.contains(universityCode) ?? false)
        ).toList();
        
        _audioModules = _audioModules.where((audio) => 
          !audio.universityExclusive || 
          (audio.universityAccess?.contains(universityCode) ?? false)
        ).toList();
        
        _articles = _articles.where((article) => 
          !article.universityExclusive || 
          (article.universityAccess?.contains(universityCode) ?? false)
        ).toList();
      }
      
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
    return Future.value(); // Explicitly complete the Future
  }

  Future<void> loadCourses() async {
    try {
      // In a real app, fetch from backend with proper filtering
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
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load courses';
      notifyListeners();
    }
  }
  
  Future<void> loadAudioModules() async {
    try {
      // In a real app, fetch from backend with proper filtering
      _audioModules = DummyData.dummyAudioModules.where((audio) {
        // If audio is not university exclusive, it's available to everyone
        if (!audio.universityExclusive) return true;
        
        // If audio is university exclusive, check if user has access
        if (_universityCode != null && 
            audio.universityAccess != null && 
            audio.universityAccess!.contains(_universityCode)) {
          return true;
        }
        
        return false;
      }).toList();
      
      // Set today's audio
      _todayAudio = _audioModules.firstWhere(
        (audio) => audio.datePublished.day == DateTime.now().day,
        orElse: () => _audioModules.first, // Fallback to the first one if no match
      );
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load audio modules';
      notifyListeners();
    }
  }
  
  Future<void> loadArticles() async {
    try {
      // In a real app, fetch from backend with proper filtering
      _articles = DummyData.dummyArticles.where((article) {
        // If article is not university exclusive, it's available to everyone
        if (!article.universityExclusive) return true;
        
        // If article is university exclusive, check if user has access
        if (_universityCode != null && 
            article.universityAccess != null && 
            article.universityAccess!.contains(_universityCode)) {
          return true;
        }
        
        return false;
      }).toList();
      
      // Make sure we have articles
      if (_articles.isEmpty) {
        _articles = DummyData.dummyArticles;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load articles';
      notifyListeners();
    }
  }
  
  Future<void> loadCoaches() async {
    try {
      // In a real app, fetch from backend with proper filtering
      // For now, we'll just use the dummy data directly
      _coaches = DummyData.dummyCoaches;
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load coaches';
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
  Course? getCourseById(String courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }
  
  // Method to get today's audio
  Future<void> refreshTodayAudio() async {
    try {
      _todayAudio = _audioModules.firstWhere(
        (audio) => audio.datePublished.day == DateTime.now().day,
        orElse: () => _audioModules.first,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load today\'s audio';
      notifyListeners();
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
             audio.focusAreas.any((area) => area.toLowerCase().contains(lowerQuery));
    }).toList();
  }
  
  // Method to get all daily audio modules
  List<DailyAudio> getDailyAudio() {
    return _audioModules;
  }

  // Method to get a specific audio module
  DailyAudio? getAudioById(String audioId) {
    try {
      return _audioModules.firstWhere((audio) => audio.id == audioId);
    } catch (e) {
      return null;
    }
  }
  
  // Methods to get coaches
  
  List<Map<String, dynamic>> getAllCoaches() {
    return _coaches;
  }
  
  List<Map<String, dynamic>> searchCoaches(String query) {
    if (query.isEmpty) return _coaches;
    
    final lowerQuery = query.toLowerCase();
    return _coaches.where((coach) {
      return coach['name'].toString().toLowerCase().contains(lowerQuery) ||
             coach['bio'].toString().toLowerCase().contains(lowerQuery) ||
             coach['specialization'].toString().toLowerCase().contains(lowerQuery);
    }).toList();
  }
  
  // Method to get a specific coach
  Map<String, dynamic>? getCoachById(String coachId) {
    try {
      return _coaches.firstWhere((coach) => coach['id'] == coachId);
    } catch (e) {
      return null;
    }
  }

  // Get article by ID
  Article? getArticleById(String id) {
    try {
      return _articles.firstWhere((article) => article.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get articles by author ID
  List<Article> getArticlesByAuthor(String authorId) {
    return _articles.where((article) => article.authorId == authorId).toList();
  }
  
  // Get articles by tag
  List<Article> getArticlesByTag(String tag) {
    return _articles.where((article) => article.tags.contains(tag)).toList();
  }
  
  // Get articles by focus area
  List<Article> getArticlesByFocusArea(String focusArea) {
    return _articles.where((article) => article.focusAreas.contains(focusArea)).toList();
  }
  
  // Get featured articles (newest ones)
  List<Article> getFeaturedArticles({int limit = 5}) {
    final articles = List<Article>.from(_articles);
    articles.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
    return articles.take(limit).toList();
  }

  // Synchronous method to load courses immediately
  void loadCoursesSync() {
    _courses = DummyData.dummyCourses;
    
    // Filter based on university access if needed
    if (_universityCode != null) {
      _courses = _courses.where((course) => 
        !course.universityExclusive || 
        (course.universityAccess?.contains(_universityCode) ?? false)
      ).toList();
    }
  }
} 