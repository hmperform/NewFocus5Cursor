import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/content_models.dart';

// Helper function to sanitize Firestore document data
Map<String, dynamic> _sanitizeDocumentData(Map<String, dynamic>? data) {
  data ??= {};
  data.removeWhere((k, v) => v == null);
  // Add more sanitization if needed (e.g., convert Timestamps)
  data.forEach((key, value) {
    if (value is Timestamp) {
      data![key] = value.toDate();
    } else if (value is List) {
      data![key] = _sanitizeList(value);
    } else if (value is Map) {
      data![key] = _sanitizeDocumentData(Map<String, dynamic>.from(value));
    }
  });
  return data;
}

List _sanitizeList(List list) {
  return list.map((item) {
    if (item is Timestamp) {
      return item.toDate();
    } else if (item is Map) {
      return _sanitizeDocumentData(Map<String, dynamic>.from(item));
    } else if (item is List) {
      return _sanitizeList(item);
    } else {
      return item;
    }
  }).toList();
}

class FirebaseContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Courses
  
  // Get all courses (filtered by university access if applicable)
  Future<List<Course>?> getCourses() async {
    try {
      if (kDebugMode) {
        debugPrint('Loading courses from Firebase...');
      }
      
      final coursesSnapshot = await _firestore.collection('courses').get();
      
      if (kDebugMode) {
        debugPrint('Found ${coursesSnapshot.docs.length} courses in Firebase');
      }

      final courses = <Course>[];
      for (var doc in coursesSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Correctly load lessons from the top-level 'lessons' collection
        // using multiple query approaches to handle different data formats
        try {
          // Try three different query approaches and combine results
          // 1. Query by courseId.id field (nested object format)
          final lessonsQueryByNestedId = await _firestore
              .collection('lessons') 
              .where('courseId.id', isEqualTo: doc.id) 
              .orderBy('sortOrder') 
              .get();
          
          // 2. Query by courseId as DocumentReference (reference format)
          final courseRef = _firestore.collection('courses').doc(doc.id);
          final lessonsQueryByRef = await _firestore
              .collection('lessons') 
              .where('courseId', isEqualTo: courseRef) 
              .get();
          
          // 3. Query by courseId as String (legacy string format)
          final lessonsQueryByString = await _firestore
              .collection('lessons') 
              .where('courseId', isEqualTo: doc.id) 
              .get();
          
          // Combine results, keeping lessons with unique IDs
          final Map<String, Map<String, dynamic>> uniqueLessons = {};
          
          // Process all query results to find unique lessons
          for (var snapshot in [lessonsQueryByNestedId, lessonsQueryByRef, lessonsQueryByString]) {
            for (var lessonDoc in snapshot.docs) {
              Map<String, dynamic> lessonData = lessonDoc.data();
              lessonData['id'] = lessonDoc.id;
              uniqueLessons[lessonDoc.id] = lessonData;
            }
          }
              
          if (kDebugMode) {
            debugPrint('Found ${uniqueLessons.length} unique lessons for course ${doc.id}');
          }
              
          data['lessons'] = uniqueLessons.values.toList();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error loading lessons for course ${doc.id}: $e');
          }
          data['lessons'] = [];
        }

        // Now call Course.fromJson with the course data including the fetched lessons
        courses.add(Course.fromJson(data));
      }

      if (kDebugMode) {
        debugPrint('Successfully loaded ${courses.length} courses with their lessons');
        for (var course in courses) {
          debugPrint('Course ${course.id} has ${course.lessonsList.length} lessons');
        }
      }
      return courses;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting courses: $e');
      }
      return null;
    }
  }
  
  // Get a course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      if (kDebugMode) {
        debugPrint('Loading course by ID: $courseId');
      }
      
      final doc = await _firestore.collection('courses').doc(courseId).get();
      
      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint('Course with ID $courseId does not exist');
        }
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      
      if (kDebugMode) {
        debugPrint('Found course: ${data['title']}');
      }

      // Correctly load lessons from the top-level 'lessons' collection using multiple query approaches
      try {
        // Try three different query approaches and combine results
        // 1. Query by courseId.id field (nested object format)
        final lessonsQueryByNestedId = await _firestore
            .collection('lessons') 
            .where('courseId.id', isEqualTo: courseId) 
            .orderBy('sortOrder') 
            .get();
        
        // 2. Query by courseId as DocumentReference (reference format)
        final courseRef = _firestore.collection('courses').doc(courseId);
        final lessonsQueryByRef = await _firestore
            .collection('lessons') 
            .where('courseId', isEqualTo: courseRef) 
            .get();
        
        // 3. Query by courseId as String (legacy string format)
        final lessonsQueryByString = await _firestore
            .collection('lessons') 
            .where('courseId', isEqualTo: courseId) 
            .get();
        
        // Combine results, keeping lessons with unique IDs
        final Map<String, Map<String, dynamic>> uniqueLessons = {};
        
        // Process all query results to find unique lessons
        for (var snapshot in [lessonsQueryByNestedId, lessonsQueryByRef, lessonsQueryByString]) {
          for (var lessonDoc in snapshot.docs) {
            Map<String, dynamic> lessonData = lessonDoc.data();
            lessonData['id'] = lessonDoc.id;
            uniqueLessons[lessonDoc.id] = lessonData;
          }
        }
            
        if (kDebugMode) {
          debugPrint('Found ${uniqueLessons.length} unique lessons for course $courseId');
        }
            
        data['lessons'] = uniqueLessons.values.toList();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error loading lessons for course $courseId: $e');
        }
        data['lessons'] = [];
      }

      return Course.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading course by ID: $e');
      }
      return null;
    }
  }
  
  // Create a new course
  Future<String?> createCourse(Course course) async {
    try {
      // Create a document reference with the course ID
      final courseRef = _firestore.collection('courses').doc(course.id);
      
      // Convert the course to a map for Firestore
      final courseData = {
        'id': course.id,
        'title': course.title,
        'description': course.description,
        'imageUrl': course.imageUrl,
        'thumbnailUrl': course.thumbnailUrl,
        'creatorId': course.creatorId,
        'creatorName': course.creatorName,
        'creatorImageUrl': course.creatorImageUrl,
        'tags': course.tags,
        'focusAreas': course.focusAreas,
        'durationMinutes': course.durationMinutes,
        'xpReward': course.xpReward,
        'createdAt': course.createdAt.toIso8601String(),
        'universityExclusive': course.universityExclusive,
        'universityAccess': course.universityAccess,
      };
      
      // Create the course document
      await courseRef.set(courseData);
      
      // Create all lessons for this course
      for (var lesson in course.lessonsList) {
        final lessonRef = _firestore.collection('lessons').doc(lesson.id);
        final lessonData = {
          'id': lesson.id,
          'courseId': {
            'id': course.id,
            'path': 'courses/${course.id}'
          }, // Store as nested object for consistency
          'title': lesson.title,
          'description': lesson.description,
          'type': lesson.type.toString().split('.').last,
          'videoUrl': lesson.videoUrl,
          'audioUrl': lesson.audioUrl,
          'textContent': lesson.textContent,
          'durationMinutes': lesson.durationMinutes,
          'sortOrder': lesson.sortOrder,
          'thumbnailUrl': lesson.thumbnailUrl,
        };
        
        await lessonRef.set(lessonData);
      }
      
      return course.id;
    } catch (e) {
      debugPrint('Error creating course: $e');
      return null;
    }
  }
  
  // Daily Audio Media
  
  // Get all daily audio/media items
  Future<List<DailyAudio>> fetchDailyAudios() async {
    try {
      final snapshot = await _firestore
          .collection('audio_modules')
          .orderBy('datePublished')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Convert any Firestore types as needed
        return DailyAudio.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching daily audios: $e');
      return [];
    }
  }
  
  // Create daily audio item
  Future<String?> createDailyAudio(DailyAudio audio) async {
    try {
      final docRef = await _firestore.collection('audio_modules').add({
        'title': audio.title,
        'description': audio.description,
        'audioUrl': audio.audioUrl,
        'thumbnail': audio.thumbnail, // Use thumbnail instead of imageUrl
        'slideshow1': audio.slideshow1,
        'slideshow2': audio.slideshow2,
        'slideshow3': audio.slideshow3,
        'creatorId': {
          'id': audio.creatorId.id,
          'path': 'coaches'
        },
        'creatorName': {
          'id': audio.creatorName.id,
          'path': 'coaches'
        },
        'focusAreas': audio.focusAreas, // Use focusAreas instead of category
        'durationMinutes': audio.durationMinutes,
        'xpReward': audio.xpReward,
        'universityExclusive': audio.universityExclusive,
        'universityAccess': audio.universityAccess != null 
            ? {'id': audio.universityAccess!.id, 'path': 'universities'}
            : null,
        'createdAt': FieldValue.serverTimestamp(),
        'datePublished': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating daily audio: $e');
      return null;
    }
  }
  
  // User Lesson Assignment (daily lessons)
  
  // Get today's lesson assignment for the current user
  Future<Map<String, dynamic>?> getTodayLessonAssignment() async {
    if (currentUserId == null) return null;
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final querySnapshot = await _firestore
          .collection('user_lesson_assignments')
          .where('userId', isEqualTo: currentUserId)
          .where('assignedDate', isGreaterThanOrEqualTo: today.toIso8601String())
          .where('assignedDate', isLessThan: tomorrow.toIso8601String())
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final assignmentData = querySnapshot.docs.first.data();
        
        // Get the lesson details
        final lessonDoc = await _firestore
            .collection('lessons')
            .doc(assignmentData['lessonId'])
            .get();
        
        if (lessonDoc.exists) {
          return {
            'assignment': assignmentData,
            'lesson': lessonDoc.data(),
          };
        }
      }
      
      // No assignment yet for today, create one
      return await _assignNewLesson();
    } catch (e) {
      debugPrint('Error getting today\'s lesson: $e');
      return null;
    }
  }
  
  // Mark a lesson as completed
  Future<bool> markLessonCompleted(String assignmentId) async {
    try {
      await _firestore
          .collection('user_lesson_assignments')
          .doc(assignmentId)
          .update({
            'completed': true,
            'completedDate': DateTime.now().toIso8601String(),
          });
      
      // Update user's completed lessons list
      if (currentUserId != null) {
        final assignmentDoc = await _firestore
            .collection('user_lesson_assignments')
            .doc(assignmentId)
            .get();
        
        if (assignmentDoc.exists) {
          final lessonId = assignmentDoc.data()?['lessonId'];
          
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .update({
                'completedLessons': FieldValue.arrayUnion([lessonId]),
              });
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error marking lesson completed: $e');
      return false;
    }
  }
  
  // For backward compatibility
  Future<Map<String, dynamic>?> getTodayModuleAssignment() => getTodayLessonAssignment();
  
  Future<bool> markModuleCompleted(String assignmentId) => markLessonCompleted(assignmentId);
  
  // Assign a new lesson to the user for today
  Future<Map<String, dynamic>?> _assignNewLesson() async {
    if (currentUserId == null) return null;
    
    try {
      // Get list of lessons the user has completed
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      List<String> completedLessonIds = [];
      if (userDoc.exists && userDoc.data()?['completedLessons'] != null) {
        completedLessonIds = List<String>.from(userDoc.data()?['completedLessons']);
      }
      
      // Get all available lessons
      final lessonsQuery = await _firestore
          .collection('lessons')
          .get();
      
      // Filter out completed lessons
      final availableLessons = lessonsQuery.docs
          .where((doc) => !completedLessonIds.contains(doc.id))
          .toList();
      
      // If there are no more lessons, we can reuse completed ones
      final lessonDoc = availableLessons.isNotEmpty
          ? availableLessons.first
          : lessonsQuery.docs.first;
      
      // Create a new assignment with UUID
      final assignmentId = const Uuid().v4();
      final assignmentData = {
        'id': assignmentId,
        'userId': currentUserId,
        'lessonId': lessonDoc.id,
        'assignedDate': DateTime.now().toIso8601String(),
        'completed': false,
        'completedDate': null,
      };
      
      // Save to Firestore
      await _firestore
          .collection('user_lesson_assignments')
          .doc(assignmentId)
          .set(assignmentData);
      
      return {
        'assignment': assignmentData,
        'lesson': lessonDoc.data(),
      };
    } catch (e) {
      debugPrint('Error assigning new lesson: $e');
      return null;
    }
  }
  
  // Get a user's lesson assignment history
  Future<List<Map<String, dynamic>>> getUserLessonHistory() async {
    if (currentUserId == null) return [];
    
    try {
      final querySnapshot = await _firestore
          .collection('user_lesson_assignments')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('assignedDate', descending: true)
          .get();
      
      List<Map<String, dynamic>> history = [];
      
      for (var doc in querySnapshot.docs) {
        final assignmentData = doc.data();
        
        // Get the lesson details
        final lessonDoc = await _firestore
            .collection('lessons')
            .doc(assignmentData['lessonId'])
            .get();
        
        if (lessonDoc.exists) {
          history.add({
            'assignment': assignmentData,
            'lesson': lessonDoc.data(),
          });
        }
      }
      
      return history;
    } catch (e) {
      debugPrint('Error getting assignment history: $e');
      return [];
    }
  }
  
  // Universities
  
  // Add a university
  Future<String?> addUniversity(String name, String code, String domain) async {
    try {
      final universityData = {
        'name': name,
        'code': code,
        'domain': domain,
        'logoUrl': null,
        'primaryColor': '#1E88E5',
        'secondaryColor': '#64B5F6',
        'adminUserIds': [],
        'activeUntil': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'maxUsers': 100,
        'currentUserCount': 0,
      };
      
      final docRef = await _firestore.collection('universities').add(universityData);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding university: $e');
      return null;
    }
  }
  
  // Get all coaches (Helper for getArticles)
  Future<Map<String, Coach>> _getAllCoachesMap() async {
    try {
      final coachesSnapshot = await _firestore.collection('coaches').get();
      final Map<String, Coach> coachMap = {};
      for (var doc in coachesSnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          coachMap[doc.id] = Coach.fromJson(data);
        } catch (e) {
          debugPrint("Error parsing coach ${doc.id}: $e");
          // Skip this coach if parsing fails
        }
      }
      return coachMap;
    } catch (e) {
      debugPrint("Error fetching all coaches: $e");
      return {}; // Return empty map on error
    }
  }

  // Get all articles
  Future<List<Article>> getArticles({String? universityCode}) async {
    try {
      debugPrint('Fetching articles from Firestore...');
      final QuerySnapshot snapshot = await _firestore.collection('articles').get();
      debugPrint('Found ${snapshot.docs.length} raw articles in Firestore');

      // Fetch all coaches first to avoid repeated lookups
      final Map<String, Coach> coachesMap = await _getAllCoachesMap();
      debugPrint('Fetched ${coachesMap.length} coaches for author lookup');

      final List<Article> articles = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>; 
          // No need to sanitize here if Article.fromJson handles types correctly
          data['id'] = doc.id;
          
          debugPrint('Parsing article: ${data['title'] ?? '[No Title]'}');
          // Parse the basic article data
          Article article = Article.fromJson(data); 

          // Get the author details from the coaches map
          Coach? authorCoach = coachesMap[article.author.id];
          debugPrint('  Article ID: ${article.id}, Author Ref ID: ${article.author.id}'); // Log IDs

          if (authorCoach != null) {
             debugPrint('  Found author: ${authorCoach.fullName}, Image: ${authorCoach.profileImageUrl}. Updating article object...'); // Log details
             // Create enriched article object with author details
             article = article.copyWithAuthorDetails(
               name: authorCoach.fullName, // Use fullName from Coach model
               imageUrl: authorCoach.profileImageUrl, // Use profileImageUrl from Coach model
             );
          } else {
             debugPrint('  Warning: Could not find author coach with ID: ${article.author.id} for article ${article.id}'); // Log missing coach
             // Optionally set default/placeholder author details if needed
             // article = article.copyWithAuthorDetails(name: 'Unknown Author', imageUrl: '');
          }
          articles.add(article);
        } catch (e) {
           debugPrint("Error processing article ${doc.id}: $e");
           // Skip this article if parsing/processing fails
        }
      }
      debugPrint('Successfully processed ${articles.length} articles');
      
      // Filter based on university access if needed
      if (universityCode != null) {
        final filteredArticles = articles.where((article) {
          if (!article.universityExclusive) return true;
          // Ensure universityAccess list contains strings for comparison
          final accessList = article.universityAccess?.map((e) => e.toString()).toList() ?? [];
          return accessList.contains(universityCode);
        }).toList();
        debugPrint('Filtered to ${filteredArticles.length} articles for university $universityCode');
        return filteredArticles;
      }
      
      return articles;
    } catch (e) {
      debugPrint('Error in getArticles: $e');
      return [];
    }
  }
  
  // Add a new method to create a Firestore index for the lessons collection
  Future<void> createLessonsIndex() async {
    try {
      debugPrint('Creating lessons index is recommended.');
      debugPrint('Please visit:');
      debugPrint('https://console.firebase.google.com/v1/r/project/focus-5-app/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mb2N1cy01LWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbGVzc29ucy9pbmRleGVzL18QARoMCghjb3Vyc2VJZBABGg0KCXNvcnRPcmRlchABGgwKCF9fbmFtZV9fEAE');
      
      // We can't create indexes programmatically, this is just a reminder for the user
      return;
    } catch (e) {
      debugPrint('Error providing index information: $e');
    }
  }
  
  Future<void> fixModuleOrganization() async {
    try {
      debugPrint('Starting module organization check and fix...');
      
      // Get all courses
      final coursesSnapshot = await _firestore.collection('courses').get();
      
      for (var courseDoc in coursesSnapshot.docs) {
        final courseId = courseDoc.id;
        debugPrint('Checking modules and lessons for course: $courseId');
        
        // Check for modules in the subcollection
        final subcollectionModulesSnapshot = await _firestore
            .collection('courses')
            .doc(courseId)
            .collection('modules')
            .get();
        
        // Check for lessons in the top-level collection
        final topLevelLessonsSnapshot = await _firestore
            .collection('lessons')
            .where('courseId.id', isEqualTo: courseId)
            .get();
            
        debugPrint('Found ${subcollectionModulesSnapshot.docs.length} modules in subcollection');
        debugPrint('Found ${topLevelLessonsSnapshot.docs.length} lessons in top-level collection');
        
        // If there are modules in the subcollection but not in lessons collection,
        // copy them to the lessons collection
        if (subcollectionModulesSnapshot.docs.isNotEmpty && 
            topLevelLessonsSnapshot.docs.isEmpty) {
          debugPrint('Creating lessons from modules subcollection for course: $courseId');
          
          for (var moduleDoc in subcollectionModulesSnapshot.docs) {
            final moduleData = moduleDoc.data();
            
            // Make sure courseId is included
            if (!moduleData.containsKey('courseId')) {
              moduleData['courseId'] = courseId;
            }
            
            await _firestore
                .collection('lessons')
                .doc(moduleDoc.id)
                .set(moduleData);
                
            debugPrint('Created lesson ${moduleDoc.id} from module');
          }
        }
        
        // If there are lessons in the top-level collection but not in modules subcollection,
        // we leave this as is, since we're migrating from modules to lessons
      }
      
      debugPrint('Module/lesson organization check and fix completed');
    } catch (e) {
      debugPrint('Error fixing module/lesson organization: $e');
    }
  }

  // Load modules for a specific course
  Future<List<Lesson>> loadModules(String courseId) async {
    try {
      debugPrint('Loading modules for course: $courseId');
      
      // First try to load from the lessons collection (new approach)
      try {
        QuerySnapshot lessonsSnapshot = await _firestore
            .collection('lessons')
            .where('courseId.id', isEqualTo: courseId)
            .orderBy('sortOrder')
            .get();
            
        debugPrint('Found ${lessonsSnapshot.docs.length} lessons for course $courseId');
        
        if (lessonsSnapshot.docs.isNotEmpty) {
          return lessonsSnapshot.docs.map((lessonDoc) {
            Map<String, dynamic> lessonData = lessonDoc.data() as Map<String, dynamic>;
            // Sanitize the lesson data
            lessonData = _sanitizeDocumentData(lessonData);
            
            // Ensure courseId is included
            if (!lessonData.containsKey('courseId')) {
              lessonData['courseId'] = courseId;
            }
            
            return Lesson.fromJson(lessonData);
          }).toList();
        }
      } catch (e) {
        debugPrint('Error loading lessons for course $courseId: $e');
      }
      
      // If that fails, try the old approach with modules collection as fallback
      try {
        QuerySnapshot modulesSnapshot = await _firestore
            .collection('modules')
            .where('courseId.id', isEqualTo: courseId)
            .orderBy('sortOrder')
            .get();
            
        debugPrint('Found ${modulesSnapshot.docs.length} modules in modules collection for course $courseId');
        
        if (modulesSnapshot.docs.isNotEmpty) {
          return modulesSnapshot.docs.map((moduleDoc) {
            Map<String, dynamic> moduleData = moduleDoc.data() as Map<String, dynamic>;
            // Sanitize the module data
            moduleData = _sanitizeDocumentData(moduleData);
            
            // Ensure courseId is included
            if (!moduleData.containsKey('courseId')) {
              moduleData['courseId'] = courseId;
            }
            
            return Lesson.fromJson(moduleData);
          }).toList();
        }
      } catch (e) {
        debugPrint('Error loading modules for course $courseId: $e');
      }
      
      // Finally try the subcollection approach
      try {
        QuerySnapshot subcollectionSnapshot = await _firestore
            .collection('courses')
            .doc(courseId)
            .collection('lessons')
            .orderBy('sortOrder')
            .get();
            
        debugPrint('Found ${subcollectionSnapshot.docs.length} lessons in subcollection for course $courseId');
        
        if (subcollectionSnapshot.docs.isNotEmpty) {
          return subcollectionSnapshot.docs.map((lessonDoc) {
            Map<String, dynamic> lessonData = lessonDoc.data() as Map<String, dynamic>;
            // Sanitize the lesson data
            lessonData = _sanitizeDocumentData(lessonData);
            
            // Ensure courseId is included
            if (!lessonData.containsKey('courseId')) {
              lessonData['courseId'] = courseId;
            }
            
            return Lesson.fromJson(lessonData);
          }).toList();
        }
      } catch (e) {
        debugPrint('Error loading lessons subcollection for course $courseId: $e');
      }
      
      // If all approaches failed, return an empty list
      return [];
    } catch (e) {
      debugPrint('Error loading modules for course $courseId: $e');
      return [];
    }
  }
} 