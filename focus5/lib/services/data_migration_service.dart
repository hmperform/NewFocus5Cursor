import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../constants/dummy_data.dart';
import '../models/content_models.dart';
import 'package:flutter/material.dart';

class DataMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Migrate Universities
  Future<void> migrateUniversities() async {
    try {
      // Check if any universities already exist
      final existingUniversities = await _firestore.collection('universities').limit(1).get();
      if (existingUniversities.docs.isNotEmpty) {
        debugPrint('Universities already exist, skipping migration');
        return;
      }
      
      // Create a batch operation for better performance
      final batch = _firestore.batch();
      
      // Add each university
      DummyData.universities.forEach((name, code) {
        final docRef = _firestore.collection('universities').doc();
        batch.set(docRef, {
          'name': name,
          'code': code,
          'domain': '${name.toLowerCase().replaceAll(' ', '')}.edu',
          'logoUrl': null,
          'primaryColor': '#1E88E5',
          'secondaryColor': '#64B5F6',
          'adminUserIds': [],
          'activeUntil': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'maxUsers': 100,
          'currentUserCount': 0,
        });
      });
      
      // Commit the batch
      await batch.commit();
      debugPrint('Successfully migrated ${DummyData.universities.length} universities');
    } catch (e) {
      debugPrint('Error migrating universities: $e');
    }
  }
  
  // Migrate courses to Firestore
  Future<void> migrateCourses() async {
    try {
      debugPrint('Starting migration of courses and lessons...');
      
      // Check if any courses already exist
      final existingCourses = await _firestore.collection('courses').limit(1).get();
      if (existingCourses.docs.isNotEmpty) {
        debugPrint('Courses already exist, skipping migration');
        return;
      }
      
      // Create a batch operation to make this faster and more reliable
      var batch = _firestore.batch();
      int batchCount = 0;
      
      // Process each course
      for (final course in DummyData.dummyCourses) {
        debugPrint('Processing course: ${course.title}');
        final courseRef = _firestore.collection('courses').doc(course.id);
        
        // Convert course to map for Firestore, excluding lessons
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
        
        // Add course to batch
        batch.set(courseRef, courseData);
        batchCount++;
        
        // Now process each lesson in the course
        for (final lesson in course.lessonsList) {
          final lessonRef = _firestore.collection('lessons').doc(lesson.id);
          
          // Convert lesson to map for Firestore
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
          
          // Add lesson to batch
          batch.set(lessonRef, lessonData);
          batchCount++;
          
          // Firestore batches have a limit of 500 operations
          if (batchCount >= 400) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
      }
      
      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }
      
      debugPrint('Successfully migrated ${DummyData.dummyCourses.length} courses and their lessons');
    } catch (e) {
      debugPrint('Error migrating courses and lessons: $e');
    }
  }
  
  // Migrate Daily Audio
  Future<void> migrateDailyAudios() async {
    try {
      // Check if any daily audios already exist
      final existingAudios = await _firestore.collection('daily_audio').limit(1).get();
      if (existingAudios.docs.isNotEmpty) {
        debugPrint('Daily audios already exist, skipping migration');
        return;
      }
      
      // Create a batch operation
      final batch = _firestore.batch();
      
      // Process each audio item
      for (final audio in DummyData.dummyAudioModules) {
        final audioRef = _firestore.collection('daily_audio').doc(audio.id);
        
        // Convert audio to map for Firestore
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
        
        // Add audio to batch
        batch.set(audioRef, audioData);
      }
      
      // Commit the batch
      await batch.commit();
      debugPrint('Successfully migrated ${DummyData.dummyAudioModules.length} daily audios');
    } catch (e) {
      debugPrint('Error migrating daily audios: $e');
    }
  }
  
  // Migrate Articles
  Future<void> migrateArticles() async {
    try {
      // Check if any articles already exist
      final existingArticles = await _firestore.collection('articles').limit(1).get();
      if (existingArticles.docs.isNotEmpty) {
        debugPrint('Articles already exist, skipping migration');
        return;
      }
      
      // Create a batch operation
      final batch = _firestore.batch();
      
      // Process each article
      for (final article in DummyData.dummyArticles) {
        final articleRef = _firestore.collection('articles').doc(article.id);
        
        // Convert article to map for Firestore
        final articleData = {
          'id': article.id,
          'title': article.title,
          'authorId': article.authorId,
          'authorName': article.authorName,
          'authorImageUrl': article.authorImageUrl,
          'content': article.content,
          'summary': article.summary,
          'thumbnailUrl': article.thumbnailUrl,
          'publishedDate': article.publishedDate.toIso8601String(),
          'tags': article.tags,
          'readTimeMinutes': article.readTimeMinutes,
          'focusAreas': article.focusAreas,
          'universityExclusive': article.universityExclusive,
          'universityAccess': article.universityAccess,
        };
        
        // Add article to batch
        batch.set(articleRef, articleData);
      }
      
      // Commit the batch
      await batch.commit();
      debugPrint('Successfully migrated ${DummyData.dummyArticles.length} articles');
    } catch (e) {
      debugPrint('Error migrating articles: $e');
    }
  }
  
  // Migrate Coaches
  Future<void> migrateCoaches() async {
    try {
      // Check if any coaches already exist
      final existingCoaches = await _firestore.collection('coaches').limit(1).get();
      if (existingCoaches.docs.isNotEmpty) {
        debugPrint('Coaches already exist, skipping migration');
        return;
      }
      
      // Create a batch operation
      final batch = _firestore.batch();
      
      // Process each coach
      for (final coach in DummyData.dummyCoaches) {
        final coachRef = _firestore.collection('coaches').doc(coach['id']);
        
        // Add coach to batch
        batch.set(coachRef, coach);
      }
      
      // Commit the batch
      await batch.commit();
      debugPrint('Successfully migrated ${DummyData.dummyCoaches.length} coaches');
    } catch (e) {
      debugPrint('Error migrating coaches: $e');
    }
  }
  
  // Migrate all data
  Future<void> migrateAllData() async {
    try {
      debugPrint('Starting data migration...');
      
      // Migrate in this order to ensure proper references
      await migrateUniversities();
      await migrateCoaches();
      await migrateCourses();
      await migrateDailyAudios();
      await migrateArticles();
      
      debugPrint('Data migration completed successfully');
    } catch (e) {
      debugPrint('Error during data migration: $e');
    }
  }
} 