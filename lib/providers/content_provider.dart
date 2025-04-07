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
  DailyAudio? _todayAudio;
  Lesson? _dailyLesson;
  Map<String, dynamic>? _dailyLessonAssignment;
  String? _universityCode;
  bool _isLoading = false;
  String? _errorMessage;
  List<Lesson> _lessons = [];
  
  final FirebaseContentService _contentService = FirebaseContentService();

  // Getters
  List<Course> get courses => _courses;
  List<DailyAudio> get audioModules => _audioModules;
  List<Article> get articles => _articles;
  DailyAudio? get todayAudio => _todayAudio;
  Lesson? get dailyLesson => _dailyLesson;
  Map<String, dynamic>? get dailyLessonAssignment => _dailyLessonAssignment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Lesson> get allLessons => _lessons;

  // For backward compatibility
  Lesson? get dailyModule => _dailyLesson;
  Map<String, dynamic>? get dailyModuleAssignment => _dailyLessonAssignment;

  List<String> get focusAreas => ['Mental Toughness', 'Confidence', 'Focus', 'Resilience', 'Motivation'];

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
        // Fix module organization first to ensure consistency
        await _contentService.fixModuleOrganization();
        
        // Load courses from Firebase
        await loadCourses();
        
        // Load audio modules from Firebase
        await loadAudioModules();
        
        // Load daily lesson assignment
        await loadDailyLesson();
        
        // Load articles from Firebase
        await loadArticles();
        
        // Populate _lessons after loading courses
        _lessons = _courses.expand((course) => course.lessonsList).toList();
        
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
      
      _courses = await _contentService.getCourses(universityCode: _universityCode);
      
      if (_courses.isEmpty) {
        debugPrint('No courses found in Firebase. This could be due to missing data or permissions.');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load courses: ${e.toString()}';
      debugPrint('Error loading courses: $e');
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
  
  Future<void> loadArticles() async {
    try {
      _articles = await _contentService.getArticles(universityCode: _universityCode);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load articles: ${e.toString()}';
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
    return _courses.where((course) => course.featured).toList();
  }

  // Helper methods
  List<Lesson>? getLessonsForCourse(String courseId) {
    if (_courses.isEmpty) {
       debugPrint("getLessonsForCourse called before courses loaded.");
       return null;
    }
    try {
      final course = _courses.firstWhere(
        (c) => c.id == courseId,
        orElse: () => Course.empty(),
      );
      return course.id.isNotEmpty ? course.lessonsList : null;
    } catch (e) {
      debugPrint("Error finding course $courseId: $e");
      return null;
    }
  }

  // For backward compatibility
  List<Lesson> getModules() {
    return _contentService.loadModules('') as List<Lesson>;
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
               audio.focusAreas.any((category) => category.toLowerCase().contains(lowerQuery));
      }).toList();
    } else {
      List<Lesson> filteredLessons = [];
      for (final course in _courses) {
        filteredLessons.addAll(course.lessonsList.where((lesson) {
          return lesson.title.toLowerCase().contains(lowerQuery) ||
                 lesson.description.toLowerCase().contains(lowerQuery);
        }));
      }
      return filteredLessons;
    }
  }
  
  // Method to get media (audio/video) by coach
  List<dynamic>? getMediaByCoach(String coachId, String mediaType) {
    try {
      if (mediaType == 'audio') {
        return _audioModules.where((audio) => audio.creatorId == coachId).toList();
      } else {
        // For videos, look in lessons within courses
        List<Lesson> coachLessons = [];
        for (final course in _courses) {
          if (course.creatorId == coachId) {
            coachLessons.addAll(course.lessonsList.where((lesson) => lesson.type == LessonType.video));
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
} 