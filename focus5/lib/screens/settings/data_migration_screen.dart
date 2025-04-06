import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:focus5/providers/content_provider.dart';
import 'package:focus5/data/dummy_data.dart';
import 'package:focus5/utils/ui_utils.dart';

class DataMigrationScreen extends StatefulWidget {
  static const routeName = '/data-migration';

  const DataMigrationScreen({Key? key}) : super(key: key);

  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  bool _isLoading = false;
  String _statusMessage = 'Ready to migrate data.';
  double _progress = 0.0;

  Future<void> _migrateAllData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting data migration...';
      _progress = 0.05;
    });

    try {
      // Migrate courses
      await _migrateCourses();
      setState(() {
        _statusMessage = 'Courses migrated successfully.';
        _progress = 0.3;
      });

      // Migrate audio modules
      await _migrateAudioModules();
      setState(() {
        _statusMessage = 'Audio modules migrated successfully.';
        _progress = 0.5;
      });

      // Migrate articles
      await _migrateArticles();
      setState(() {
        _statusMessage = 'Articles migrated successfully.';
        _progress = 0.7;
      });

      // Migrate coaches
      await _migrateCoaches();
      setState(() {
        _statusMessage = 'Coaches migrated successfully.';
        _progress = 0.9;
      });

      // Migration complete
      setState(() {
        _statusMessage = 'All data migrated successfully! You can now use the app with Firebase.';
        _progress = 1.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during migration: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _migrateCourses() async {
    final courses = DummyData.dummyCourses;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    
    // Create courses collection
    final coursesCollection = db.collection('courses');
    
    for (final course in courses) {
      final courseDoc = coursesCollection.doc(course.id);
      batch.set(courseDoc, {
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
        'universityExclusive': course.universityExclusive,
        'universityAccess': course.universityAccess,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Create modules subcollection for each course
      final modulesCollection = courseDoc.collection('modules');
      
      for (final module in course.modules) {
        final moduleDoc = modulesCollection.doc(module.id);
        batch.set(moduleDoc, {
          'id': module.id,
          'title': module.title,
          'description': module.description,
          'type': module.type.toString().split('.').last,
          'videoUrl': module.videoUrl,
          'audioUrl': module.audioUrl,
          'textContent': module.textContent,
          'durationMinutes': module.durationMinutes,
          'sortOrder': module.sortOrder,
          'thumbnailUrl': module.thumbnailUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    
    // Commit the batch
    await batch.commit();
  }

  Future<void> _migrateAudioModules() async {
    final audioModules = DummyData.dummyAudioModules;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    
    // Create audio_modules collection
    final audioCollection = db.collection('audio_modules');
    
    for (final audio in audioModules) {
      final audioDoc = audioCollection.doc(audio.id);
      batch.set(audioDoc, {
        'id': audio.id,
        'title': audio.title,
        'description': audio.description,
        'category': audio.category,
        'imageUrl': audio.imageUrl,
        'audioUrl': audio.audioUrl,
        'durationMinutes': audio.durationMinutes,
        'creatorId': audio.creatorId,
        'creatorName': audio.creatorName,
        'datePublished': audio.datePublished.toIso8601String(),
        'focusAreas': audio.focusAreas,
        'xpReward': audio.xpReward,
        'universityExclusive': audio.universityExclusive,
        'universityAccess': audio.universityAccess,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    // Commit the batch
    await batch.commit();
  }

  Future<void> _migrateArticles() async {
    final articles = DummyData.dummyArticles;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    
    // Create articles collection
    final articlesCollection = db.collection('articles');
    
    for (final article in articles) {
      final articleDoc = articlesCollection.doc(article.id);
      batch.set(articleDoc, {
        'id': article.id,
        'title': article.title,
        'authorId': article.authorId,
        'authorName': article.authorName,
        'authorImageUrl': article.authorImageUrl,
        'content': article.content,
        'thumbnailUrl': article.thumbnailUrl,
        'publishedDate': article.publishedDate.toIso8601String(),
        'tags': article.tags,
        'readTimeMinutes': article.readTimeMinutes,
        'focusAreas': article.focusAreas,
        'universityExclusive': article.universityExclusive,
        'universityAccess': article.universityAccess ?? [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    // Commit the batch
    await batch.commit();
  }

  Future<void> _migrateCoaches() async {
    final coaches = DummyData.dummyCoaches;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    
    // Create coaches collection
    final coachesCollection = db.collection('coaches');
    
    for (final coach in coaches) {
      final coachDoc = coachesCollection.doc(coach['id'] as String);
      batch.set(coachDoc, {
        'id': coach['id'],
        'name': coach['name'],
        'title': coach['title'],
        'bio': coach['bio'],
        'imageUrl': coach['imageUrl'],
        'rating': coach['rating'],
        'reviewCount': coach['reviewCount'],
        'specialization': coach['specialization'],
        'experience': coach['experience'],
        'courses': coach['courses'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    // Commit the batch
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final accentColor = themeProvider.accentColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Data Migration',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information Card
            Card(
              elevation: 2,
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Firebase Data Migration',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This tool will migrate all dummy data to your Firebase database. '
                      'Use this only for development and testing purposes. '
                      'Make sure you have configured Firebase correctly before proceeding.',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Data to be migrated:',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDataItem(
                      icon: Icons.video_library,
                      title: 'Courses & Modules',
                      description: '${DummyData.dummyCourses.length} courses with multiple modules',
                      textColor: textColor,
                      accentColor: accentColor,
                    ),
                    _buildDataItem(
                      icon: Icons.headphones,
                      title: 'Audio Modules',
                      description: '${DummyData.dummyAudioModules.length} audio modules',
                      textColor: textColor,
                      accentColor: accentColor,
                    ),
                    _buildDataItem(
                      icon: Icons.article,
                      title: 'Articles',
                      description: '${DummyData.dummyArticles.length} articles',
                      textColor: textColor,
                      accentColor: accentColor,
                    ),
                    _buildDataItem(
                      icon: Icons.person,
                      title: 'Coaches',
                      description: '${DummyData.dummyCoaches.length} coaches',
                      textColor: textColor,
                      accentColor: accentColor,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status and Progress
            if (_isLoading || _progress > 0) ...[
              Text(
                'Migration Status:',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontStyle: _isLoading ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Action Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _migrateAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: themeProvider.accentTextColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(_isLoading ? Icons.hourglass_top : Icons.upload),
                label: Text(
                  _isLoading ? 'Migrating...' : 'Migrate All Data',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 