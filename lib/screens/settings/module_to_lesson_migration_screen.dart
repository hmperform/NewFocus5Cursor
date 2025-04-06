import 'package:flutter/material.dart';
import 'package:focus5/utils/migrate_modules_to_lessons.dart';

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
                      'Once complete, review the data in Firestore to ensure everything was transferred correctly. '
                      'After verification, you can delete the original modules collection.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            ElevatedButton(
              onPressed: _isMigrating ? null : _runMigration,
              child: _isMigrating
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
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isMigrating || !_migrationComplete
                  ? null
                  : _deleteModulesCollection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Modules Collection'),
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
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _logs.isEmpty
                  ? const Center(
                      child: Text('No logs yet. Run migration to see logs.'),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Text(_logs[index]),
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