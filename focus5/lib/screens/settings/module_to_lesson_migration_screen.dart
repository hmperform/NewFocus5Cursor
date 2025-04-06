import 'package:flutter/material.dart';
import 'package:focus5/utils/migrate_modules_to_lessons.dart';
import 'package:url_launcher/url_launcher.dart';

class ModuleToLessonMigrationScreen extends StatefulWidget {
  const ModuleToLessonMigrationScreen({Key? key}) : super(key: key);

  @override
  State<ModuleToLessonMigrationScreen> createState() => _ModuleToLessonMigrationScreenState();
}

class _ModuleToLessonMigrationScreenState extends State<ModuleToLessonMigrationScreen> {
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
      _logs.clear();
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

  void _openFirebaseConsole() async {
    final Uri url = Uri.parse('https://console.firebase.google.com/project/focus-5-app/firestore/data/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _log('Could not open Firebase Console. Please navigate to it manually.');
    }
  }

  void _createFirebaseIndex() async {
    final Uri url = Uri.parse('https://console.firebase.google.com/v1/r/project/focus-5-app/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mb2N1cy01LWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbGVzc29ucy9pbmRleGVzL18QARoMCghjb3Vyc2VJZBABGg0KCXNvcnRPcmRlchABGgwKCF9fbmFtZV9fEAE');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _log('Could not open Firebase Index creation page. Please navigate to it manually.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modules to Lessons Migration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              margin: EdgeInsets.only(bottom: 24.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Migration Tool',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This tool will migrate your data from the "modules" collection to the "lessons" collection. '
                      'Follow these steps:\n\n'
                      '1. Click "Run Migration" to copy all modules to lessons\n'
                      '2. Click "Create Index" to set up the required Firestore index\n'
                      '3. Verify the data in Firestore to ensure everything migrated correctly\n'
                      '4. Finally, you can delete the original modules collection if needed',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ElevatedButton.icon(
                  onPressed: _isMigrating ? null : _runMigration,
                  icon: const Icon(Icons.sync),
                  label: _isMigrating
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Migrating...'),
                          ],
                        )
                      : const Text('Run Migration'),
                ),
                
                ElevatedButton.icon(
                  onPressed: _isMigrating ? null : _createFirebaseIndex,
                  icon: const Icon(Icons.rule),
                  label: const Text('Create Index'),
                ),
                
                ElevatedButton.icon(
                  onPressed: _isMigrating ? null : _openFirebaseConsole,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Firestore'),
                ),
                
                ElevatedButton.icon(
                  onPressed: _isMigrating || !_migrationComplete
                      ? null
                      : _deleteModulesCollection,
                  icon: const Icon(Icons.delete_forever),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  label: const Text('Delete Modules Collection'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Migration Logs:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs yet. Run migration to see logs.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0,
                          ),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
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