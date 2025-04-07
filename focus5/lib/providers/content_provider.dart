import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/content_models.dart';
import '../services/firebase_content_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContentProvider with ChangeNotifier {
  List<Course> _courses = [];
  List<DailyAudio> _audioModules = [];
  List<Article> _articles = [];
  List<Map<String, dynamic>> _coaches = [];
  DailyAudio? _todayAudio;
  Lesson? _dailyLesson;
  Map<String, dynamic>? _dailyLessonAssignment;
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
  Lesson? get dailyLesson => _dailyLesson;
  Map<String, dynamic>? get dailyLessonAssignment => _dailyLessonAssignment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // For backward compatibility
  Lesson? get dailyModule => _dailyLesson;
  Map<String, dynamic>? get dailyModuleAssignment => _dailyLessonAssignment;

  // Initialize content, optionally filtering by university code
  Future<void> initContent(String? universityCode) async {
    if (_isLoading) return; // Prevent multiple initializations
    
    _errorMessage = null;
    _universityCode = universityCode;
    
    // Use post-frame callback to avoid setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _isLoading = true;
      notifyListeners();
  
      try {
        // Load courses from Firebase
        await loadCourses();
        
        // Load audio modules from Firebase
        await loadAudioModules();
        
        // Load daily lesson assignment
        await loadDailyLesson();
        
        // Load articles from Firebase
        await loadArticles();
        
        _isLoading = false;
        _errorMessage = null;
      } catch (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load content: ${e.toString()}';
        debugPrint('Error in initContent: ${e.toString()}');
      }
      
      notifyListeners();
    });
  }

  Future<void> loadCourses() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final courses = await _contentService.getCourses();
      if (courses != null) {
        _courses = courses;
      } else {
        _courses = [];
      }
    } catch (e) {
      debugPrint('Error loading courses: $e');
      _courses = [];
    } finally {
      _isLoading = false;
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
  
  Future<void> loadDailyLesson() async {
    try {
      _dailyLessonAssignment = await _contentService.getTodayLessonAssignment();
      
      if (_dailyLessonAssignment != null && _dailyLessonAssignment!['lesson'] != null) {
        _dailyLesson = Lesson.fromJson(_dailyLessonAssignment!['lesson'] as Map<String, dynamic>);
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load daily lesson: ${e.toString()}';
      notifyListeners();
    }
  }
  
  Future<bool> markDailyLessonCompleted() async {
    if (_dailyLessonAssignment == null) return false;
    
    try {
      final assignmentId = _dailyLessonAssignment!['assignment']['id'];
      final result = await _contentService.markLessonCompleted(assignmentId);
      
      if (result) {
        // Update the local assignment state
        _dailyLessonAssignment!['assignment']['completed'] = true;
        _dailyLessonAssignment!['assignment']['completedDate'] = DateTime.now().toIso8601String();
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _errorMessage = 'Failed to mark lesson as completed: ${e.toString()}';
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
    if (_courses.isEmpty) {
      // Trigger async load if courses aren't loaded yet
      loadCourses();
      return [];
    }
    return _courses.where((course) => course.focusAreas.contains(focusArea)).toList();
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
      Course? localCourse;
      try {
        localCourse = _courses.firstWhere(
          (course) => course.id == courseId,
        );
        return localCourse;
      } catch (e) {
        // Course not found in local cache, fetch from Firebase
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
  
  // Article methods
  
  Future<void> loadArticles() async {
    if (_articles.isNotEmpty) return;
    
    try {
      _articles = await _contentService.getArticles(universityCode: _universityCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading articles: $e');
      _articles = [];
      notifyListeners();
    }
  }
  
  Article? getArticleById(String id) {
    try {
      return _articles.firstWhere((article) => article.id == id);
    } catch (e) {
      return null;
    }
  }
  
  List<Article> getArticlesByAuthor(String authorId) {
    return _articles.where((article) => article.authorId == authorId).toList();
  }
  
  List<Article> getArticlesByTag(String tag) {
    return _articles.where((article) => article.tags.contains(tag)).toList();
  }
  
  List<Article> getArticlesByFocusArea(String focusArea) {
    return _articles.where((article) => article.focusAreas.contains(focusArea)).toList();
  }
  
  List<Article> getFeaturedArticles({int limit = 5}) {
    final articles = List<Article>.from(_articles);
    articles.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
    return articles.take(limit).toList();
  }
  
  // Coach methods
  
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
  
  Map<String, dynamic>? getCoachById(String coachId) {
    try {
      return _coaches.firstWhere((coach) => coach['id'] == coachId);
    } catch (e) {
      return null;
    }
  }
  
  // Helper methods
  
  List<Lesson>? getLessonsForCourse(String courseId) {
    // Find the course, return null if not found
    Course? course;
    try {
      course = _courses.firstWhere((c) => c.id == courseId);
    } catch (e) {
      course = null; // Explicitly set course to null if not found
    }

    // Return the modules (lessons) if the course exists, otherwise null
    return course?.modules; // Use modules getter and null-safe operator
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

  /// Get featured courses
  List<Course> getFeaturedCourses() {
    return courses.where((course) => course.featured).toList();
  }

  // Method to get media (audio/video) by coach
  List<dynamic>? getMediaByCoach(String coachId, String mediaType) {
    try {
      if (mediaType == 'audio') {
        return _audioModules.where((audio) => audio.creatorId == coachId).toList();
      } else {
        // For videos, look in modules within courses
        List<Lesson> coachLessons = [];
        for (final course in _courses) {
          if (course.creatorId == coachId) {
            coachLessons.addAll(course.modules.where((lesson) => lesson.type == LessonType.video));
          }
        }
        return coachLessons;
      }
    } catch (e) {
      _errorMessage = 'Failed to get media by coach: ${e.toString()}';
      debugPrint('Error getting media by coach: $e');
      return [];
    }
  }

  // Method to get courses by coach
  List<Course>? getCoursesByCoach(String coachId) {
    try {
      return _courses.where((course) => course.creatorId == coachId).toList();
    } catch (e) {
      _errorMessage = 'Failed to get courses by coach: ${e.toString()}';
      debugPrint('Error getting courses by coach: $e');
      return [];
    }
  }
  
  // Method to load media content for the media library
  Future<void> loadMediaContent() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Load audio modules
      await loadAudioModules();
      
      // Load videos (modules from courses)
      await loadCourses();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load media content: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Getter for videos extracted from course modules
  List<Lesson> get videos {
    List<Lesson> allLessons = [];
    for (final course in _courses) {
      allLessons.addAll(course.lessonsList.where((lesson) => lesson.type == LessonType.video));
    }
    return allLessons;
  }
  
  // Getter for audios 
  List<DailyAudio> get audios => _audioModules;
  
  // Search for modules and audio content
  List<dynamic> searchMediaContent(String query, String mediaType) {
    if (query.isEmpty) {
      return mediaType == 'audio' ? audios : videos;
    }
    
    final lowerQuery = query.toLowerCase();
    
    if (mediaType == 'audio') {
      return _audioModules.where((audio) {
        return audio.title.toLowerCase().contains(lowerQuery) ||
               audio.description.toLowerCase().contains(lowerQuery) ||
               audio.creatorName.toLowerCase().contains(lowerQuery) ||
               audio.categories.any((category) => category.toLowerCase().contains(lowerQuery));
      }).toList();
    } else {
      List<Lesson> filteredLessons = [];
      for (final course in _courses) {
        filteredLessons.addAll(course.modules.where((lesson) {
          return lesson.title.toLowerCase().contains(lowerQuery) ||
                 lesson.description.toLowerCase().contains(lowerQuery) ||
                 lesson.categories.any((category) => category.toLowerCase().contains(lowerQuery));
        }));
      }
      return filteredLessons;
    }
  }
} 