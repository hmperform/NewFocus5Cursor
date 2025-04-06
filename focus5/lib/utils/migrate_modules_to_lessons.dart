import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class to migrate data from the 'modules' collection to the 'lessons' collection
class ModulesToLessonsMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Run the migration process
  Future<void> runMigration({required Function(String) logCallback}) async {
    logCallback('Starting migration from modules to lessons...');
    
    try {
      // Check if the course exists
      final courseRef = _firestore.collection('courses').doc('course-001');
      final courseDoc = await courseRef.get();
      
      if (!courseDoc.exists) {
        logCallback('Course course-001 not found.');
        return;
      }
      
      logCallback('Found course: course-001');
      
      // Get modules subcollection for this course
      final modulesSnapshot = await courseRef.collection('modules').get();
      
      if (modulesSnapshot.docs.isEmpty) {
        logCallback('No modules found in subcollection for course-001.');
        return;
      }
      
      logCallback('Found ${modulesSnapshot.docs.length} modules in subcollection for course-001.');
      
      // Check if lessons collection already has data
      final lessonsSnapshot = await _firestore.collection('lessons').limit(1).get();
      if (lessonsSnapshot.docs.isNotEmpty) {
        logCallback('Warning: Lessons collection already has data. Migration will add to existing data.');
      }
      
      // Create a batch operation
      int batchCount = 0;
      var batch = _firestore.batch();
      int totalMigrated = 0;
      
      // Process each module doc in the subcollection
      for (var moduleDoc in modulesSnapshot.docs) {
        final moduleData = moduleDoc.data();
        
        // Make sure courseId is included
        moduleData['courseId'] = 'course-001';
        
        final lessonRef = _firestore.collection('lessons').doc(moduleDoc.id);
        
        // Copy all data to the lessons collection
        batch.set(lessonRef, moduleData);
        batchCount++;
        totalMigrated++;
        
        // Commit batch when it reaches the limit
        if (batchCount >= 400) {
          logCallback('Committing batch of $batchCount documents...');
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }
      
      // Commit any remaining operations
      if (batchCount > 0) {
        logCallback('Committing final batch of $batchCount documents...');
        await batch.commit();
      }
      
      // Update index in Firebase
      logCallback('Creating index for lessons collection...');
      try {
        logCallback('Note: Composite index for courseId and sortOrder should be created manually in Firebase Console if needed.');
        logCallback('Index URL: https://console.firebase.google.com/v1/r/project/focus-5-app/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mb2N1cy01LWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbGVzc29ucy9pbmRleGVzL18QARoMCghjb3Vyc2VJZBABGg0KCXNvcnRPcmRlchABGgwKCF9fbmFtZV9fEAE');
      } catch (indexError) {
        logCallback('Warning: Could not create index automatically: $indexError');
        logCallback('You may need to create the index manually in the Firebase Console.');
      }
      
      logCallback('Successfully migrated $totalMigrated modules to lessons.');
      logCallback('Note: The original modules subcollection is still intact. You may want to keep it for compatibility.');
      
    } catch (e) {
      logCallback('Error during migration: $e');
    }
  }
  
  /// Helper to delete the modules collection after successful migration
  Future<void> deleteModulesCollection({required Function(String) logCallback}) async {
    logCallback('WARNING: About to delete the modules subcollection from course-001. This cannot be undone.');
    logCallback('Make sure you have verified the lessons collection is complete before proceeding.');
    
    try {
      final courseRef = _firestore.collection('courses').doc('course-001');
      final modulesSnapshot = await courseRef.collection('modules').get();
      
      if (modulesSnapshot.docs.isEmpty) {
        logCallback('No modules found in subcollection for course-001.');
        return;
      }
      
      int batchCount = 0;
      var batch = _firestore.batch();
      int totalDeleted = 0;
      
      for (var doc in modulesSnapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;
        totalDeleted++;
        
        if (batchCount >= 400) {
          logCallback('Deleting batch of $batchCount documents...');
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }
      
      if (batchCount > 0) {
        logCallback('Deleting final batch of $batchCount documents...');
        await batch.commit();
      }
      
      logCallback('Successfully deleted $totalDeleted modules from course-001 subcollection.');
    } catch (e) {
      logCallback('Error deleting modules subcollection: $e');
    }
  }
}

/// Widget for running the migration with UI
class ModulesToLessonsMigrationScreen extends StatefulWidget {
  const ModulesToLessonsMigrationScreen({Key? key}) : super(key: key);

  @override
  _ModulesToLessonsMigrationScreenState createState() => _ModulesToLessonsMigrationScreenState();
}

class _ModulesToLessonsMigrationScreenState extends State<ModulesToLessonsMigrationScreen> {
  final ModulesToLessonsMigration _migration = ModulesToLessonsMigration();
  final List<String> _logs = [];
  bool _isMigrating = false;
  bool _migrationComplete = false;
  
  void _log(String message) {
    setState(() {
      _logs.add(message);
    });
  }
  
  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
    });
    
    await _migration.runMigration(logCallback: _log);
    
    setState(() {
      _isMigrating = false;
      _migrationComplete = true;
    });
  }
  
  Future<void> _deleteModulesCollection() async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Are you sure you want to delete the modules collection? '
          'This action cannot be undone. Make sure you have verified '
          'the lessons collection is complete.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldDelete) {
      setState(() {
        _isMigrating = true;
      });
      
      await _migration.deleteModulesCollection(logCallback: _log);
      
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migrate Modules to Lessons'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This utility will migrate data from the "modules" collection to the "lessons" collection in Firestore.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isMigrating ? null : _runMigration,
                  child: const Text('Start Migration'),
                ),
                const SizedBox(width: 16),
                if (_migrationComplete)
                  ElevatedButton(
                    onPressed: _isMigrating ? null : _deleteModulesCollection,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete Original Collection'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Migration Log:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 