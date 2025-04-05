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
      QuerySnapshot coursesSnapshot = await _firestore.collection('courses').get();
      
      // Get all courses first
      List<Course> courses = [];
      for (var doc in coursesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Get modules for this course
        QuerySnapshot modulesSnapshot = await _firestore
            .collection('modules')
            .where('courseId', isEqualTo: doc.id)
            .orderBy('sortOrder')
            .get();
            
        List<Module> modules = modulesSnapshot.docs.map((moduleDoc) {
          Map<String, dynamic> moduleData = moduleDoc.data() as Map<String, dynamic>;
          return Module.fromJson(moduleData);
        }).toList();
        
        // Create course with modules
        courses.add(Course(
          id: doc.id,
          title: data['title'],
          description: data['description'],
          thumbnailUrl: data['thumbnailUrl'],
          creatorId: data['creatorId'],
          creatorName: data['creatorName'],
          creatorImageUrl: data['creatorImageUrl'],
          tags: List<String>.from(data['tags']),
          focusAreas: List<String>.from(data['focusAreas']),
          durationMinutes: data['durationMinutes'],
          xpReward: data['xpReward'],
          modules: modules,
          createdAt: DateTime.parse(data['createdAt']),
          universityExclusive: data['universityExclusive'],
          universityAccess: data['universityAccess'] != null 
              ? List<String>.from(data['universityAccess']) 
              : null,
        ));
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
      
      return courses;
    } catch (e) {
      debugPrint('Error getting courses: $e');
      return [];
    }
  }
  
  // Get a course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      if (!doc.exists) return null;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Get modules for this course
      QuerySnapshot modulesSnapshot = await _firestore
          .collection('modules')
          .where('courseId', isEqualTo: courseId)
          .orderBy('sortOrder')
          .get();
          
      List<Module> modules = modulesSnapshot.docs.map((moduleDoc) {
        Map<String, dynamic> moduleData = moduleDoc.data() as Map<String, dynamic>;
        return Module.fromJson(moduleData);
      }).toList();
      
      return Course(
        id: doc.id,
        title: data['title'],
        description: data['description'],
        thumbnailUrl: data['thumbnailUrl'],
        creatorId: data['creatorId'],
        creatorName: data['creatorName'],
        creatorImageUrl: data['creatorImageUrl'],
        tags: List<String>.from(data['tags']),
        focusAreas: List<String>.from(data['focusAreas']),
        durationMinutes: data['durationMinutes'],
        xpReward: data['xpReward'],
        modules: modules,
        createdAt: DateTime.parse(data['createdAt']),
        universityExclusive: data['universityExclusive'],
        universityAccess: data['universityAccess'] != null 
            ? List<String>.from(data['universityAccess']) 
            : null,
      );
    } catch (e) {
      debugPrint('Error getting course by ID: $e');
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
      
      // Create all modules for this course
      for (var module in course.modules) {
        final moduleRef = _firestore.collection('modules').doc(module.id);
        final moduleData = {
          'id': module.id,
          'courseId': course.id,
          'title': module.title,
          'description': module.description,
          'type': module.type.toString().split('.').last,
          'videoUrl': module.videoUrl,
          'audioUrl': module.audioUrl,
          'textContent': module.textContent,
          'durationMinutes': module.durationMinutes,
          'sortOrder': module.sortOrder,
          'thumbnailUrl': module.thumbnailUrl,
        };
        
        await moduleRef.set(moduleData);
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
  
  // User Module Assignment (daily modules)
  
  // Get today's module assignment for the current user
  Future<Map<String, dynamic>?> getTodayModuleAssignment() async {
    if (currentUserId == null) return null;
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final querySnapshot = await _firestore
          .collection('user_module_assignments')
          .where('userId', isEqualTo: currentUserId)
          .where('assignedDate', isGreaterThanOrEqualTo: today.toIso8601String())
          .where('assignedDate', isLessThan: tomorrow.toIso8601String())
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final assignmentData = querySnapshot.docs.first.data();
        
        // Get the module details
        final moduleDoc = await _firestore
            .collection('modules')
            .doc(assignmentData['moduleId'])
            .get();
        
        if (moduleDoc.exists) {
          return {
            'assignment': assignmentData,
            'module': moduleDoc.data(),
          };
        }
      }
      
      // No assignment yet for today, create one
      return await _assignNewModule();
    } catch (e) {
      debugPrint('Error getting today\'s module: $e');
      return null;
    }
  }
  
  // Mark a module as completed
  Future<bool> markModuleCompleted(String assignmentId) async {
    try {
      await _firestore
          .collection('user_module_assignments')
          .doc(assignmentId)
          .update({
            'completed': true,
            'completedDate': DateTime.now().toIso8601String(),
          });
      
      // Update user's completed modules list
      if (currentUserId != null) {
        final assignmentDoc = await _firestore
            .collection('user_module_assignments')
            .doc(assignmentId)
            .get();
        
        if (assignmentDoc.exists) {
          final moduleId = assignmentDoc.data()?['moduleId'];
          
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .update({
                'completedModules': FieldValue.arrayUnion([moduleId]),
              });
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error marking module completed: $e');
      return false;
    }
  }
  
  // Assign a new module to the user for today
  Future<Map<String, dynamic>?> _assignNewModule() async {
    if (currentUserId == null) return null;
    
    try {
      // Get list of modules the user has completed
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      List<String> completedModuleIds = [];
      if (userDoc.exists && userDoc.data()?['completedModules'] != null) {
        completedModuleIds = List<String>.from(userDoc.data()?['completedModules']);
      }
      
      // Get all available modules
      final modulesQuery = await _firestore
          .collection('modules')
          .get();
      
      // Filter out completed modules
      final availableModules = modulesQuery.docs
          .where((doc) => !completedModuleIds.contains(doc.id))
          .toList();
      
      // If there are no more modules, we can reuse completed ones
      final moduleDoc = availableModules.isNotEmpty
          ? availableModules.first
          : modulesQuery.docs.first;
      
      // Create a new assignment with UUID
      final assignmentId = const Uuid().v4();
      final assignmentData = {
        'id': assignmentId,
        'userId': currentUserId,
        'moduleId': moduleDoc.id,
        'assignedDate': DateTime.now().toIso8601String(),
        'completed': false,
        'completedDate': null,
      };
      
      // Save to Firestore
      await _firestore
          .collection('user_module_assignments')
          .doc(assignmentId)
          .set(assignmentData);
      
      return {
        'assignment': assignmentData,
        'module': moduleDoc.data(),
      };
    } catch (e) {
      debugPrint('Error assigning new module: $e');
      return null;
    }
  }
  
  // Get a user's module assignment history
  Future<List<Map<String, dynamic>>> getUserModuleHistory() async {
    if (currentUserId == null) return [];
    
    try {
      final querySnapshot = await _firestore
          .collection('user_module_assignments')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('assignedDate', descending: true)
          .get();
      
      List<Map<String, dynamic>> history = [];
      
      for (var doc in querySnapshot.docs) {
        final assignmentData = doc.data();
        
        // Get the module details
        final moduleDoc = await _firestore
            .collection('modules')
            .doc(assignmentData['moduleId'])
            .get();
        
        if (moduleDoc.exists) {
          history.add({
            'assignment': assignmentData,
            'module': moduleDoc.data(),
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
} 