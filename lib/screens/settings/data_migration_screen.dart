import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:focus5/providers/content_provider.dart';
import 'package:focus5/utils/ui_utils.dart';
import 'package:focus5/services/firebase_content_service.dart';

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
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  // Method to migrate modules to lessons
  Future<void> _migrateModulesToLessons() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting modules to lessons migration...';
      _progress = 0.1;
      _logs.clear();
    });

    _addLog('Starting migration from course subcollection modules to top-level lessons...');
    
    try {
      final firestore = FirebaseFirestore.instance;
      
      // First check for course-001 which has modules as subcollection
      final courseRef = firestore.collection('courses').doc('course-001');
      final courseDoc = await courseRef.get();
      
      if (!courseDoc.exists) {
        _addLog('Course course-001 not found.');
        setState(() {
          _statusMessage = 'Course course-001 not found.';
          _progress = 1.0;
          _isLoading = false;
        });
        return;
      }
      
      _addLog('Found course: course-001');
      
      // Get modules subcollection for this course
      final modulesSnapshot = await courseRef.collection('modules').get();
      
      if (modulesSnapshot.docs.isEmpty) {
        _addLog('No modules found in subcollection for course-001.');
        setState(() {
          _statusMessage = 'No modules found in subcollection for course-001.';
          _progress = 1.0;
          _isLoading = false;
        });
        return;
      }
      
      _addLog('Found ${modulesSnapshot.docs.length} modules in subcollection for course-001.');
      setState(() {
        _progress = 0.3;
      });
      
      // Check if lessons collection already has data
      final lessonsSnapshot = await firestore.collection('lessons').limit(1).get();
      if (lessonsSnapshot.docs.isNotEmpty) {
        _addLog('Warning: Lessons collection already has data. Migration will add to existing data.');
      }
      
      // Create a batch operation
      int batchCount = 0;
      var batch = firestore.batch();
      int totalMigrated = 0;
      
      // Process each module in the subcollection
      for (var moduleDoc in modulesSnapshot.docs) {
        final moduleData = moduleDoc.data();
        
        // Make sure courseId is included in the data
        moduleData['courseId'] = 'course-001';
        
        // Create a document in the lessons collection with the same ID
        final lessonRef = firestore.collection('lessons').doc(moduleDoc.id);
        
        _addLog('Migrating module ${moduleDoc.id} to lessons collection');
        
        // Copy all data to the lessons collection
        batch.set(lessonRef, moduleData);
        batchCount++;
        totalMigrated++;
        
        // Commit batch when it reaches the limit
        if (batchCount >= 400) {
          _addLog('Committing batch of $batchCount documents...');
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
        }
      }
      
      setState(() {
        _progress = 0.7;
      });
      
      // Commit any remaining operations
      if (batchCount > 0) {
        _addLog('Committing final batch of $batchCount documents...');
        await batch.commit();
      }
      
      // Create index info
      _addLog('Note: Composite index for courseId and sortOrder should be created manually in Firebase Console.');
      _addLog('Index URL: https://console.firebase.google.com/v1/r/project/focus-5-app/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mb2N1cy01LWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbGVzc29ucy9pbmRleGVzL18QARoMCghjb3Vyc2VJZBABGg0KCXNvcnRPcmRlchABGgwKCF9fbmFtZV9fEAE');
      
      _addLog('Successfully migrated $totalMigrated modules to lessons collection.');
      _addLog('Note: The original modules subcollection is still intact.');
      
      setState(() {
        _statusMessage = 'Successfully migrated $totalMigrated modules to lessons.';
        _progress = 1.0;
        _isLoading = false;
      });
    } catch (e) {
      _addLog('Error during migration: $e');
      setState(() {
        _statusMessage = 'Error during migration: $e';
        _isLoading = false;
      });
    }
  }

  // Add this method to delete modules collection
  Future<void> _deleteModulesCollection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting modules collection...';
      _progress = 0.1;
    });

    _addLog('WARNING: Deleting the modules collection. This cannot be undone.');
    
    try {
      final firestore = FirebaseFirestore.instance;
      final modulesSnapshot = await firestore.collection('modules').get();
      
      int batchCount = 0;
      var batch = firestore.batch();
      int totalDeleted = 0;
      
      for (var doc in modulesSnapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;
        totalDeleted++;
        
        if (batchCount >= 400) {
          _addLog('Deleting batch of $batchCount documents...');
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
        }
      }
      
      if (batchCount > 0) {
        _addLog('Deleting final batch of $batchCount documents...');
        await batch.commit();
      }
      
      _addLog('Successfully deleted $totalDeleted documents from modules collection.');
      
      setState(() {
        _statusMessage = 'Successfully deleted modules collection.';
        _progress = 1.0;
        _isLoading = false;
      });
    } catch (e) {
      _addLog('Error deleting modules collection: $e');
      setState(() {
        _statusMessage = 'Error deleting modules collection: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fixModuleOrganization() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking and fixing module organization...';
      _progress = 0.2;
    });

    try {
      final firebaseContentService = FirebaseContentService();
      await firebaseContentService.fixModuleOrganization();
      
      setState(() {
        _statusMessage = 'Module organization fixed. All modules now exist in both subcollection and top-level format.';
        _progress = 1.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error fixing module organization: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _createModuleIndex() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating module index...';
      _progress = 0.5;
    });

    try {
      final firebaseContentService = FirebaseContentService();
      await firebaseContentService.createModulesIndex();
      
      setState(() {
        _statusMessage = 'Module index creation instructions provided. Please check the console log.';
        _progress = 1.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating module index: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showContentDetails(BuildContext context, String title, List<dynamic> items) {
    // Remove DummyData refs from here if any remain
  }

  Widget _buildContentSection(String title, IconData icon, List<dynamic> items) {
    // Ensure items are passed, not DummyData
    return Column(
      // ...
    );
  }

  @override
  Widget build(BuildContext context) {
    // Remove direct DummyData usage here
    // final courses = []; // DummyData.dummyCourses;
    // final audioModules = []; // DummyData.dummyAudioModules;
    // final articles = []; // DummyData.dummyArticles;
    // final coaches = []; // DummyData.dummyCoaches;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
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
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Migration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use these tools to migrate your data between collections or populate your Firebase database with sample data.',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Standard data population
                    ElevatedButton(
                      onPressed: _isLoading ? null : _migrateAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Populate Firebase with Sample Data',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Modules to Lessons Migration
                    ElevatedButton(
                      onPressed: _isLoading ? null : _migrateModulesToLessons,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Migrate Modules to Lessons',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Delete Modules Collection (only visible after migration)
                    if (_logs.isNotEmpty)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _deleteModulesCollection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_forever,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete Modules Collection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _fixModuleOrganization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sync_problem,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Fix Module Organization',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createModuleIndex,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.speed,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Create Module Index',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Progress status
            Text(
              'Status:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Migration logs
            if (_logs.isNotEmpty) ...[
              Text(
                'Migration Logs:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 