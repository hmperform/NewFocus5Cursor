import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/content_models.dart';
import '../services/firebase_content_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Added getters for explore tab
  List<Course> get featuredCourses => _courses.where((course) => course.featured).toList();
  List<Course> get allCourses => _courses;

  // For backward compatibility
  Lesson? get dailyModule => _dailyLesson;
  Map<String, dynamic>? get dailyModuleAssignment => _dailyLessonAssignment;

  // Initialize content, optionally filtering by university code
  Future<void> initContent(String? universityCode) async {
    if (_isLoading) return; // Prevent multiple initializations
    
    // Set loading state immediately
    _isLoading = true;
    _errorMessage = null;
    _universityCode = universityCode;
    notifyListeners();

    try {
      // Directly await loading functions
      // Use Future.wait for potential parallelization if desired, or sequence them
      // Sequencing them might be safer if there are dependencies or to manage load
      await loadCourses(); 
      await loadAudioModules();
      await loadDailyLesson();
      await loadArticles();
      await loadCoaches();

      // All loading successful
      _isLoading = false;
      _errorMessage = null;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load initial content: ${e.toString()}';
      debugPrint('Error in initContent: ${e.toString()}');
    } finally {
      // Ensure loading is false and notify listeners regardless of success/failure
      if (_isLoading) { // Check in case error handling didn't set it
         _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> loadCourses() async {
    try {
      // Loading state managed by initContent
      List<Course> baseCourses = await _contentService.getCourses() ?? [];
      
      List<Course> coursesWithCoachImages = [];
      for (var course in baseCourses) {
        String? coachImageUrl;
        debugPrint("[Provider LoadCourses] Processing Course ID: ${course.id}, Creator ID: ${course.creatorId}");
        if (course.creatorId.isNotEmpty && course.creatorId != 'unknown_creator') {
          try {
            final coachDoc = await FirebaseFirestore.instance
                .collection('coaches')
                .doc(course.creatorId)
                .get();
            
            if (coachDoc.exists && coachDoc.data() != null) {
              final coachData = coachDoc.data() as Map<String, dynamic>; 
              // Look for 'profileImageUrl' or fallback to 'imageUrl'
              String? fetchedProfileUrl = coachData['profileImageUrl'] as String?;
              String? fetchedImageUrl = coachData['imageUrl'] as String?;
              coachImageUrl = fetchedProfileUrl ?? fetchedImageUrl;
              debugPrint("[Provider LoadCourses]   Fetched Coach ${course.creatorId}. profileImageUrl: $fetchedProfileUrl, imageUrl: $fetchedImageUrl. Assigned coachImageUrl: $coachImageUrl");
            } else {
               debugPrint("[Provider LoadCourses]   Coach document not found for creator ID: ${course.creatorId}");
               coachImageUrl = null;
            }
          } catch (e) {
            debugPrint("[Provider LoadCourses]   Error fetching coach profile for creator ${course.creatorId}: $e");
            coachImageUrl = null;
          }
        } else {
           debugPrint("[Provider LoadCourses]   Invalid or empty creatorId for course ${course.id}: \"${course.creatorId}\"");
           coachImageUrl = null;
        }
        // Use copyWith to add the fetched image URL (or null if fetch failed/invalid ID)
        coursesWithCoachImages.add(course.copyWith(coachProfileImageUrl: coachImageUrl));
      }
      
      _courses = coursesWithCoachImages;
      debugPrint("ContentProvider: Loaded ${_courses.length} courses with coach images attempted.");
      
    } catch (e) {
      debugPrint('Error loading courses: $e');
      _courses = []; // Reset courses on error
      throw Exception('Failed to load courses: $e'); // Re-throw to be caught by initContent
    }
  }
  
  Future<void> loadAudioModules() async {
    try {
      // Loading state managed by initContent
      _audioModules = await _contentService.fetchDailyAudios();
      
      // Sort by document ID
      _audioModules.sort((a, b) => a.id.compareTo(b.id));
      
      // Set today's audio based on total login days
      if (_audioModules.isNotEmpty) {
        // Get total login days from Firestore directly
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();
        
        final totalLoginDays = userDoc.data()?['totalLoginDays'] ?? 0;
        final moduleIndex = totalLoginDays > 0 ? (totalLoginDays - 1) % _audioModules.length : 0;
        _todayAudio = _audioModules[moduleIndex];
        print('\n🎵 ContentProvider: Selected audio module ${_todayAudio?.title} for day $totalLoginDays (index: $moduleIndex)');
      } else {
        _todayAudio = null;
        print('\n🎵 ContentProvider: No audio modules available');
      }
      
      // Don't notify here, initContent will notify at the end
      debugPrint("ContentProvider: Loaded ${_audioModules.length} audio modules.");
    } catch (e) {
      // Don't set _errorMessage or notify here
      throw Exception('Failed to load audio modules: $e'); // Re-throw
    }
  }
  
  Future<void> loadDailyLesson() async {
    try {
      // Loading state managed by initContent
      _dailyLessonAssignment = await _contentService.getTodayLessonAssignment();
      
      if (_dailyLessonAssignment != null && _dailyLessonAssignment!['lesson'] != null) {
        _dailyLesson = Lesson.fromJson(_dailyLessonAssignment!['lesson'] as Map<String, dynamic>);
      }
      
      // Don't notify here
      debugPrint("ContentProvider: Daily lesson loaded: ${_dailyLesson != null}");
    } catch (e) {
      print('\n🎵 ContentProvider Error loading daily lesson: $e');
      // Don't set _errorMessage or notify here
      // This might be less critical, so maybe don't re-throw?
      // For consistency, let's re-throw for now.
      throw Exception('Failed to load daily lesson: $e');
    }
  }
  
  Future<bool> markDailyLessonCompleted() async {
    if (_dailyLessonAssignment == null) return false;
    
    try {
      // This method modifies state independently, so it needs its own notifyListeners
      final assignmentId = _dailyLessonAssignment!['assignment']['id'];
      final result = await _contentService.markLessonCompleted(assignmentId);
      
      if (result) {
        // Update the local assignment state
        _dailyLessonAssignment!['assignment']['completed'] = true;
        _dailyLessonAssignment!['assignment']['completedDate'] = DateTime.now().toIso8601String();
        notifyListeners(); // Notify specifically for this change
      }
      
      return result;
    } catch (e) {
      _errorMessage = 'Failed to mark lesson as completed: ${e.toString()}'; // Okay to set error message here
      notifyListeners(); // Notify about the error
      return false;
    }
  }
  
  Future<void> refreshTodayAudio() async {
    try {
      _isLoading = true; // Manage loading for refresh specifically
      notifyListeners();
      await loadAudioModules();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load today\'s audio: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Methods to get filtered courses
  
  List<Course> getCoursesForCoach(String coachId) {
    return _courses.where((course) => course.creatorId == coachId).toList();
  }
  
  List<Course> getCoursesForFocusArea(String focusArea) {
    // Don't trigger load here, assume initContent handled it or is running
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
  
  List<String> selectedCategories = [];
  
  List<DailyAudio> searchAudioModules(String query, List<String> selectedCats) {
    final lowerQuery = query.toLowerCase();
    List<DailyAudio> results = _audioModules;
    
    if (query.isNotEmpty) {
      results = results.where((audio) =>
          audio.title.toLowerCase().contains(lowerQuery) ||
          audio.description.toLowerCase().contains(lowerQuery) ||
          audio.creatorName.id.toLowerCase().contains(lowerQuery) ||
          audio.focusAreas.any((area) => area.toLowerCase().contains(lowerQuery))
      ).toList();
    }
    
    if (selectedCats.isNotEmpty) {
      results = results.where((audio) =>
          audio.focusAreas.any((area) => selectedCats.contains(area.toLowerCase()))
      ).toList();
    }
    
    return results;
  }
  
  // Article methods
  
  Future<void> loadArticles() async {
    try {
      // Loading state managed by initContent
      List<Article> baseArticles = await _contentService.getArticles();
      
      // Fetch author details for each article
      List<Article> articlesWithAuthors = [];
      for (var article in baseArticles) {
        try {
          DocumentSnapshot authorDoc = await article.author.get();
          String authorName = 'Unknown Author'; // Default
          String? authorImageUrl;

          if (authorDoc.exists && authorDoc.data() != null) {
            // Safely access data
            final data = authorDoc.data() as Map<String, dynamic>; 
            authorName = data.containsKey('name') ? data['name'] as String? ?? 'Unknown Author' : 'Unknown Author';
            // Check for both possible image URL fields
            authorImageUrl = data.containsKey('profileImageUrl') 
                              ? data['profileImageUrl'] as String? 
                              : (data.containsKey('imageUrl') ? data['imageUrl'] as String? : null);
                              
            articlesWithAuthors.add(article.copyWithAuthorDetails(
              name: authorName,
              imageUrl: authorImageUrl,
            ));
          } else {
            // Author document doesn't exist or has no data
            articlesWithAuthors.add(article.copyWithAuthorDetails(name: authorName)); // Use default name
          }
        } catch (e) {
          // Error fetching specific author, add article with default/unknown author
          debugPrint('Error fetching/parsing author for article ${article.id}: $e');
          articlesWithAuthors.add(article.copyWithAuthorDetails(name: 'Unknown Author'));
        }
      }
      
      _articles = articlesWithAuthors;
      debugPrint("ContentProvider: Loaded ${_articles.length} articles with author details.");
      
    } catch (e) {
      debugPrint('Error loading articles: $e');
      _articles = [];
      throw Exception('Failed to load articles: $e'); // Re-throw
    }
  }
  
  Article? getArticleById(String id) {
    try {
      return _articles.firstWhere((article) => article.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Renamed and updated filtering logic
  List<Article> getArticlesByCoach(String coachId) {
    return _articles.where((article) => article.author.id == coachId).toList();
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

  // Method to get media (audio/video) by coach - REMOVED (Replaced by specific getters)
  // List<dynamic>? getMediaByCoach(String coachId, String mediaType) { ... }
  
  // Method to get Daily Audios by coach - Renamed and updated
  List<DailyAudio> getDailyAudiosByCoach(String coachId) {
    try {
       // Compare document IDs
      return _audioModules.where((audio) => audio.creatorId.id == coachId).toList();
    } catch (e) {
      _errorMessage = 'Failed to get daily audios by coach: ${e.toString()}';
      debugPrint('Error getting daily audios by coach: $e');
      return [];
    }
  }

  // Method to get courses by coach
  List<Course> getCoursesByCoach(String coachId) {
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
  
  // Method to search media content
  List<dynamic> searchMediaContent(String query, String mediaType) {
    if (query.isEmpty) {
      return mediaType == 'audio' ? audios : videos;
    }
    
    final lowerQuery = query.toLowerCase();
    
    if (mediaType == 'audio') {
      return searchAudioModules(query, selectedCategories);
    } else {
      List<Lesson> filteredLessons = [];
      for (final course in _courses) {
        filteredLessons.addAll(course.modules.where((lesson) {
          return lesson.title.toLowerCase().contains(lowerQuery) ||
                 (lesson.description?.toLowerCase() ?? '').contains(lowerQuery) ||
                 lesson.categories.any((category) => category.toLowerCase().contains(lowerQuery));
        }));
      }
      return filteredLessons;
    }
  }

  List<dynamic> searchMedia(String mediaType, String query) {
    final lowerQuery = query.toLowerCase();
    
    if (mediaType == 'audio') {
      return searchAudioModules(query, []);
    } else if (mediaType == 'lesson') {
      List<Lesson> filteredLessons = [];
      
      for (final course in _courses) {
        for (final lesson in course.modules) {
          if (lesson.title.toLowerCase().contains(lowerQuery) ||
              (lesson.description?.toLowerCase() ?? '').contains(lowerQuery) ||
              course.title.toLowerCase().contains(lowerQuery)) {
            filteredLessons.add(lesson);
          }
        }
      }
      
      return filteredLessons;
    } else {
      return _courses.where((course) {
        return course.title.toLowerCase().contains(lowerQuery) ||
               course.description.toLowerCase().contains(lowerQuery) ||
               course.creatorName.toLowerCase().contains(lowerQuery) ||
               course.focusAreas.any((area) => area.toLowerCase().contains(lowerQuery));
      }).toList();
    }
  }

  Future<void> loadCoaches() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('coaches').get();
      _coaches = snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure essential fields are present, provide defaults if necessary
        return {
          'id': doc.id, // Use the document ID as the coach ID
          'name': data['name']?.toString() ?? 'Unknown Coach',
          // Add other fields you might need, e.g., 'imageUrl'
          'imageUrl': data['imageUrl']?.toString() ?? '',
        };
      }).toList();
      debugPrint("ContentProvider: Loaded ${_coaches.length} coaches.");
    } catch (e) {
      debugPrint('Error loading coaches: $e');
      _coaches = []; // Reset on error
      throw Exception('Failed to load coaches: $e'); // Re-throw to be caught by initContent
    }
  }
} 