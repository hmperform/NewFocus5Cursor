import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/content_models.dart';

class FirebaseContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Courses
  
  // Get all courses (filtered by university access if applicable)
  Future<List<Course>> getCourses({String? universityCode}) async {
    try {
      debugPrint('Loading courses from Firebase...');
      QuerySnapshot coursesSnapshot = await _firestore.collection('courses').get();
      debugPrint('Found ${coursesSnapshot.docs.length} courses in Firebase');
      
      // Get all courses first
      List<Course> courses = [];
      for (var doc in coursesSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          debugPrint('Loading lessons for course: ${doc.id} - ${data['title']}');
          
          // First try to get lessons from the top-level lessons collection
          List<Lesson> lessons = [];
          
          try {
            QuerySnapshot lessonsSnapshot = await _firestore
                .collection('lessons')
                .where('courseId', isEqualTo: doc.id)
                .orderBy('sortOrder')
                .get();
                
            debugPrint('Found ${lessonsSnapshot.docs.length} lessons for course ${doc.id}');
            
            if (lessonsSnapshot.docs.isNotEmpty) {
              lessons = lessonsSnapshot.docs.map((lessonDoc) {
                Map<String, dynamic> lessonData = lessonDoc.data() as Map<String, dynamic>;
                return Lesson.fromJson(lessonData);
              }).toList();
            }
          } catch (lessonsError) {
            debugPrint('Error loading lessons for course ${doc.id}: $lessonsError');
          }
          
          // If no lessons in top-level collection, try the subcollection for backward compatibility
          if (lessons.isEmpty) {
            try {
              debugPrint('No lessons found in top-level collection, trying subcollection');
              QuerySnapshot moduleSnapshot = await _firestore
                  .collection('courses')
                  .doc(doc.id)
                  .collection('modules')
                  .orderBy('sortOrder')
                  .get();
                  
              debugPrint('Found ${moduleSnapshot.docs.length} modules in subcollection for course ${doc.id}');
              
              if (moduleSnapshot.docs.isNotEmpty) {
                lessons = moduleSnapshot.docs.map((moduleDoc) {
                  Map<String, dynamic> moduleData = moduleDoc.data() as Map<String, dynamic>;
                  // Ensure courseId is included
                  if (!moduleData.containsKey('courseId')) {
                    moduleData['courseId'] = doc.id;
                  }
                  return Lesson.fromJson(moduleData);
                }).toList();
              }
            } catch (subcollectionError) {
              debugPrint('Error loading subcollection modules for course ${doc.id}: $subcollectionError');
            }
          }
          
          // Create course with lessons
          courses.add(Course(
            id: doc.id,
            title: data['title'] ?? 'Untitled Course',
            description: data['description'] ?? 'No description available',
            imageUrl: data['imageUrl'] ?? data['thumbnailUrl'] ?? 'https://via.placeholder.com/400',
            thumbnailUrl: data['thumbnailUrl'] ?? 'https://via.placeholder.com/400',
            creatorId: data['creatorId'] ?? '',
            creatorName: data['creatorName'] ?? 'Unknown Creator',
            creatorImageUrl: data['creatorImageUrl'] ?? '',
            tags: List<String>.from(data['tags'] ?? []),
            focusAreas: List<String>.from(data['focusAreas'] ?? []),
            durationMinutes: data['durationMinutes'] ?? 0,
            duration: data['durationMinutes'] ?? 0,
            xpReward: data['xpReward'] ?? 0,
            lessonsList: lessons,
            featured: data['featured'] ?? false,
            premium: data['premium'] ?? false,
            createdAt: data['createdAt'] != null 
                ? (data['createdAt'] is Timestamp 
                   ? (data['createdAt'] as Timestamp).toDate() 
                   : DateTime.parse(data['createdAt'] as String))
                : DateTime.now(),
            universityExclusive: data['universityExclusive'] ?? false,
            universityAccess: data['universityAccess'] != null 
                ? List<String>.from(data['universityAccess']) 
                : null,
          ));
        } catch (courseError) {
          debugPrint('Error loading lessons for course ${doc.id}: $courseError');
        }
      }
      
      // Filter courses based on university access if needed
      if (universityCode != null) {
        courses = courses.where((course) {
          // If not university exclusive, everyone can access
          if (!course.universityExclusive) return true;
          
          // If university exclusive, check access
          return course.universityAccess?.contains(universityCode) ?? false;
        }).toList();
      }
      
      debugPrint('Successfully loaded ${courses.length} courses with their lessons');
      return courses;
    } catch (e) {
      debugPrint('Error getting courses: $e');
      
      // Check if it's a Firestore index error and provide more helpful message
      if (e.toString().contains('failed-precondition') && e.toString().contains('index')) {
        debugPrint('This appears to be an index error. You may need to create an index in Firebase Console');
        debugPrint('Make sure you have created the necessary composite index for the lessons collection');
        debugPrint('The index should be on: courseId (ascending) and sortOrder (ascending)');
        
        // Call our index creation helper
        await createLessonsIndex();
      }
      
      // Still return empty list to not break the app
      return [];
    }
  }
  
  // Get a course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      debugPrint('Loading course by ID: $courseId');
      final doc = await _firestore.collection('courses').doc(courseId).get();
      if (!doc.exists) {
        debugPrint('Course with ID $courseId does not exist');
        return null;
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      debugPrint('Found course: ${data['title']}');
      
      // Get lessons for this course
      try {
        debugPrint('Loading lessons for course: $courseId');
        QuerySnapshot lessonsSnapshot = await _firestore
            .collection('lessons')
            .where('courseId', isEqualTo: courseId)
            .orderBy('sortOrder')
            .get();
            
        debugPrint('Found ${lessonsSnapshot.docs.length} lessons for course $courseId');
        
        List<Lesson> lessons = lessonsSnapshot.docs.map((lessonDoc) {
          Map<String, dynamic> lessonData = lessonDoc.data() as Map<String, dynamic>;
          return Lesson.fromJson(lessonData);
        }).toList();
        
        return Course(
          id: doc.id,
          title: data['title'] ?? 'Untitled Course',
          description: data['description'] ?? 'No description available',
          imageUrl: data['imageUrl'] ?? data['thumbnailUrl'] ?? 'https://via.placeholder.com/400',
          thumbnailUrl: data['thumbnailUrl'] ?? 'https://via.placeholder.com/400',
          creatorId: data['creatorId'] ?? '',
          creatorName: data['creatorName'] ?? 'Unknown Creator',
          creatorImageUrl: data['creatorImageUrl'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          focusAreas: List<String>.from(data['focusAreas'] ?? []),
          durationMinutes: data['durationMinutes'] ?? 0,
          duration: data['durationMinutes'] ?? 0,
          xpReward: data['xpReward'] ?? 0,
          lessonsList: lessons,
          featured: data['featured'] ?? false,
          premium: data['premium'] ?? false,
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] is Timestamp 
                 ? (data['createdAt'] as Timestamp).toDate() 
                 : DateTime.parse(data['createdAt'] as String))
              : DateTime.now(),
          universityExclusive: data['universityExclusive'] ?? false,
          universityAccess: data['universityAccess'] != null 
              ? List<String>.from(data['universityAccess']) 
              : null,
        );
      } catch (lessonsError) {
        debugPrint('Error loading lessons for course $courseId: $lessonsError');
        
        // If there was an error loading lessons, try to get modules from the subcollection
        try {
          debugPrint('Trying to load modules from subcollection for course: $courseId');
          QuerySnapshot modulesSnapshot = await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .get();
              
          debugPrint('Found ${modulesSnapshot.docs.length} modules in subcollection');
          
          List<Lesson> lessons = modulesSnapshot.docs.map((moduleDoc) {
            Map<String, dynamic> moduleData = moduleDoc.data() as Map<String, dynamic>;
            if (!moduleData.containsKey('courseId')) {
              moduleData['courseId'] = courseId;
            }
            return Lesson.fromJson(moduleData);
          }).toList();
          
          return Course(
            id: doc.id,
            title: data['title'] ?? 'Untitled Course',
            description: data['description'] ?? 'No description available',
            imageUrl: data['imageUrl'] ?? data['thumbnailUrl'] ?? 'https://via.placeholder.com/400',
            thumbnailUrl: data['thumbnailUrl'] ?? 'https://via.placeholder.com/400',
            creatorId: data['creatorId'] ?? '',
            creatorName: data['creatorName'] ?? 'Unknown Creator',
            creatorImageUrl: data['creatorImageUrl'] ?? '',
            tags: List<String>.from(data['tags'] ?? []),
            focusAreas: List<String>.from(data['focusAreas'] ?? []),
            durationMinutes: data['durationMinutes'] ?? 0,
            duration: data['durationMinutes'] ?? 0,
            xpReward: data['xpReward'] ?? 0,
            lessonsList: lessons,
            featured: data['featured'] ?? false,
            premium: data['premium'] ?? false,
            createdAt: data['createdAt'] != null 
                ? (data['createdAt'] is Timestamp 
                   ? (data['createdAt'] as Timestamp).toDate() 
                   : DateTime.parse(data['createdAt'] as String))
                : DateTime.now(),
            universityExclusive: data['universityExclusive'] ?? false,
            universityAccess: data['universityAccess'] != null 
                ? List<String>.from(data['universityAccess']) 
                : null,
          );
        } catch (subcollectionError) {
          debugPrint('Error loading modules from subcollection: $subcollectionError');
        }
        
        // Return course without lessons if all loading attempts failed
        return Course(
          id: doc.id,
          title: data['title'] ?? 'Untitled Course',
          description: data['description'] ?? 'No description available',
          imageUrl: data['imageUrl'] ?? data['thumbnailUrl'] ?? 'https://via.placeholder.com/400',
          thumbnailUrl: data['thumbnailUrl'] ?? 'https://via.placeholder.com/400',
          creatorId: data['creatorId'] ?? '',
          creatorName: data['creatorName'] ?? 'Unknown Creator',
          creatorImageUrl: data['creatorImageUrl'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          focusAreas: List<String>.from(data['focusAreas'] ?? []),
          durationMinutes: data['durationMinutes'] ?? 0,
          duration: data['durationMinutes'] ?? 0,
          xpReward: data['xpReward'] ?? 0,
          lessonsList: [],
          featured: data['featured'] ?? false,
          premium: data['premium'] ?? false,
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] is Timestamp 
                 ? (data['createdAt'] as Timestamp).toDate() 
                 : DateTime.parse(data['createdAt'] as String))
              : DateTime.now(),
          universityExclusive: data['universityExclusive'] ?? false,
          universityAccess: data['universityAccess'] != null 
              ? List<String>.from(data['universityAccess']) 
              : null,
        );
      }
    } catch (e) {
      debugPrint('Error getting course by ID: $e');
      
      // Check if it's a Firestore index error and provide more helpful message
      if (e.toString().contains('failed-precondition') && e.toString().contains('index')) {
        debugPrint('This appears to be an index error. You may need to create an index in Firebase Console');
        debugPrint('Make sure you have created the necessary composite index for the lessons collection');
        debugPrint('The index should be on: courseId (ascending) and sortOrder (ascending)');
        
        // Call our index creation helper
        await createLessonsIndex();
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
          'courseId': course.id,
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
  Future<List<DailyAudio>> getDailyAudios({String? universityCode}) async {
    try {
      QuerySnapshot audioSnapshot = await _firestore.collection('daily_audio').get();
      
      List<DailyAudio> audioItems = audioSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return DailyAudio(
          id: doc.id,
          title: data['title'],
          description: data['description'],
          audioUrl: data['audioUrl'],
          imageUrl: data['imageUrl'],
          creatorId: data['creatorId'],
          creatorName: data['creatorName'],
          durationMinutes: data['durationMinutes'],
          focusAreas: List<String>.from(data['focusAreas']),
          xpReward: data['xpReward'],
          datePublished: DateTime.parse(data['datePublished']),
          universityExclusive: data['universityExclusive'],
          universityAccess: data['universityAccess'] != null 
              ? List<String>.from(data['universityAccess']) 
              : null,
          category: data['category'],
        );
      }).toList();
      
      // Filter based on university access if needed
      if (universityCode != null) {
        audioItems = audioItems.where((audio) {
          if (!audio.universityExclusive) return true;
          return audio.universityAccess?.contains(universityCode) ?? false;
        }).toList();
      }
      
      return audioItems;
    } catch (e) {
      debugPrint('Error getting daily audio: $e');
      return [];
    }
  }
  
  // Create daily audio item
  Future<String?> createDailyAudio(DailyAudio audio) async {
    try {
      final audioRef = _firestore.collection('daily_audio').doc(audio.id);
      
      final audioData = {
        'id': audio.id,
        'title': audio.title,
        'description': audio.description,
        'audioUrl': audio.audioUrl,
        'imageUrl': audio.imageUrl,
        'creatorId': audio.creatorId,
        'creatorName': audio.creatorName,
        'durationMinutes': audio.durationMinutes,
        'focusAreas': audio.focusAreas,
        'xpReward': audio.xpReward,
        'datePublished': audio.datePublished.toIso8601String(),
        'universityExclusive': audio.universityExclusive,
        'universityAccess': audio.universityAccess,
        'category': audio.category,
      };
      
      await audioRef.set(audioData);
      return audio.id;
    } catch (e) {
      debugPrint('Error creating daily audio: $e');
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
  
  // Get all articles
  Future<List<Article>> getArticles({String? universityCode}) async {
    try {
      QuerySnapshot articleSnapshot = await _firestore.collection('articles').get();
      
      List<Article> articles = articleSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Article(
          id: doc.id,
          title: data['title'],
          content: data['content'],
          thumbnailUrl: data['thumbnailUrl'] ?? '',
          authorId: data['authorId'],
          authorName: data['authorName'],
          authorImageUrl: data['authorImageUrl'] ?? '',
          publishedDate: data['publishedDate'] != null 
              ? DateTime.parse(data['publishedDate']) 
              : DateTime.now(),
          readTimeMinutes: data['readTimeMinutes'] ?? 3,
          tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
          focusAreas: data['focusAreas'] != null 
              ? List<String>.from(data['focusAreas']) 
              : [],
          universityExclusive: data['universityExclusive'] ?? false,
          universityAccess: data['universityAccess'] != null 
              ? List<String>.from(data['universityAccess']) 
              : null,
        );
      }).toList();
      
      // Filter based on university access if needed
      if (universityCode != null) {
        articles = articles.where((article) {
          if (!article.universityExclusive) return true;
          return article.universityAccess?.contains(universityCode) ?? false;
        }).toList();
      }
      
      // Sort by published date (newest first)
      articles.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
      
      return articles;
    } catch (e) {
      debugPrint('Error getting articles: $e');
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
            .where('courseId', isEqualTo: courseId)
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
} 