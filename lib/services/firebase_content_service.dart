import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/content_models.dart';

// In the createCourse method, update to create modules as a subcollection

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
    
    // Create all lessons as a subcollection of the course
    for (var lesson in course.lessonsList) {
      final lessonRef = courseRef.collection('lessons').doc(lesson.id);
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

// Add this new utility method to check and fix module organization

Future<void> fixModuleOrganization() async {
  try {
    debugPrint('Starting module organization check and fix...');
    
    // Get all courses
    final coursesSnapshot = await _firestore.collection('courses').get();
    
    for (var courseDoc in coursesSnapshot.docs) {
      final courseId = courseDoc.id;
      debugPrint('Checking modules for course: $courseId');
      
      // Check for modules in the top-level modules collection with this courseId
      final topLevelModulesSnapshot = await _firestore
          .collection('modules')
          .where('courseId', isEqualTo: courseId)
          .get();
          
      // Check the subcollection
      final subcollectionModulesSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .get();
          
      debugPrint('Found ${topLevelModulesSnapshot.docs.length} modules in top-level collection');
      debugPrint('Found ${subcollectionModulesSnapshot.docs.length} modules in subcollection');
      
      // If there are modules in the top-level collection but not in subcollection,
      // copy them to the subcollection
      if (topLevelModulesSnapshot.docs.isNotEmpty && 
          subcollectionModulesSnapshot.docs.isEmpty) {
        debugPrint('Moving modules to subcollection for course: $courseId');
        
        for (var moduleDoc in topLevelModulesSnapshot.docs) {
          final moduleData = moduleDoc.data();
          await _firestore
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleDoc.id)
              .set(moduleData);
              
          debugPrint('Moved module ${moduleDoc.id} to subcollection');
        }
      }
      
      // If there are modules in the subcollection but not in top-level collection,
      // copy them to the top-level collection for compatibility
      if (subcollectionModulesSnapshot.docs.isNotEmpty && 
          topLevelModulesSnapshot.docs.isEmpty) {
        debugPrint('Creating top-level modules for compatibility for course: $courseId');
        
        for (var moduleDoc in subcollectionModulesSnapshot.docs) {
          final moduleData = moduleDoc.data();
          await _firestore
              .collection('modules')
              .doc(moduleDoc.id)
              .set(moduleData);
              
          debugPrint('Created top-level module ${moduleDoc.id}');
        }
      }
    }
    
    debugPrint('Module organization check and fix completed');
  } catch (e) {
    debugPrint('Error fixing module organization: $e');
  }
}

// Add a new method to create a Firestore index
Future<void> createModulesIndex() async {
  try {
    debugPrint('Creating modules index is recommended.');
    debugPrint('Please visit:');
    debugPrint('https://console.firebase.google.com/v1/r/project/focus-5-app/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mb2N1cy01LWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbW9kdWxlcy9pbmRleGVzL18QARoMCghjb3Vyc2VJZBABGg0KCXNvcnRPcmRlchABGgwKCF9fbmFtZV9fEAE');
    
    // We can't create indexes programmatically, this is just a reminder for the user
    return;
  } catch (e) {
    debugPrint('Error providing index information: $e');
  }
}

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
        
        // Ensure all values in the data map are appropriate types (handle DocumentReference)
        data = _sanitizeDocumentData(data);
        
        debugPrint('Loading lessons for course: ${doc.id} - ${data['title']}');
        
        // Get lessons from the course's lessons subcollection
        List<Lesson> lessons = [];
        
        try {
          QuerySnapshot lessonsSnapshot = await _firestore
              .collection('courses')
              .doc(doc.id)
              .collection('lessons')
              .orderBy('sortOrder')
              .get();
              
          debugPrint('Found ${lessonsSnapshot.docs.length} lessons for course ${doc.id}');
          
          if (lessonsSnapshot.docs.isNotEmpty) {
            lessons = lessonsSnapshot.docs.map((lessonDoc) {
              Map<String, dynamic> lessonData = lessonDoc.data() as Map<String, dynamic>;
              // Sanitize the lesson data
              lessonData = _sanitizeDocumentData(lessonData);
              return Lesson.fromJson(lessonData);
            }).toList();
          }
        } catch (lessonsError) {
          debugPrint('Error loading lessons for course ${doc.id}: $lessonsError');
        }
        
        // If no lessons in new structure, try the old module subcollection for backward compatibility
        if (lessons.isEmpty) {
          try {
            debugPrint('No lessons found in lessons subcollection, trying modules subcollection');
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
                // Sanitize the module data
                moduleData = _sanitizeDocumentData(moduleData);
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
    
    debugPrint('Successfully loaded ${courses.length} courses with their modules');
    return courses;
  } catch (e) {
    debugPrint('Error getting courses: $e');
    
    // Check if it's a Firestore index error and provide more helpful message
    if (e.toString().contains('failed-precondition') && e.toString().contains('index')) {
      debugPrint('This appears to be an index error. You may need to create an index in Firebase Console');
      debugPrint('Make sure you have created the necessary composite index for the modules or lessons collection');
      debugPrint('The index should be on: courseId (ascending) and sortOrder (ascending)');
      
      // Call our index creation helper
      await createModulesIndex();
    }
    
    // Still return empty list to not break the app
    return [];
  }
}

// Get a specific course by ID
Future<Course?> getCourseById(String courseId) async {
  try {
    debugPrint('Loading course by ID: $courseId');
    final doc = await _firestore.collection('courses').doc(courseId).get();
    if (!doc.exists) {
      debugPrint('Course with ID $courseId does not exist');
      return null;
    }
    
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // Sanitize data
    data = _sanitizeDocumentData(data);
    
    debugPrint('Found course: ${data['title']}');
    
    // Get lessons for this course
    try {
      debugPrint('Loading lessons for course: $courseId');
      QuerySnapshot lessonsSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('lessons')
          .orderBy('sortOrder')
          .get();
          
      debugPrint('Found ${lessonsSnapshot.docs.length} lessons for course $courseId');
      
      List<Lesson> lessons = lessonsSnapshot.docs.map((lessonDoc) {
        Map<String, dynamic> lessonData = lessonDoc.data() as Map<String, dynamic>;
        // Sanitize lesson data
        lessonData = _sanitizeDocumentData(lessonData);
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
          // Sanitize module data
          moduleData = _sanitizeDocumentData(moduleData);
          
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
      } catch (e) {
        debugPrint('Error loading modules from subcollection: $e');
        return null;
      }
    }
  } catch (e) {
    debugPrint('Error loading course by ID: $e');
    return null;
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
    } else {
      return item;
    }
  }).toList();
} 