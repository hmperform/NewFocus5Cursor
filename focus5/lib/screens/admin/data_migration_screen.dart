import 'package:flutter/material.dart';
import '../../services/data_migration_service.dart';

class DataMigrationScreen extends StatefulWidget {
  const DataMigrationScreen({Key? key}) : super(key: key);

  @override
  _DataMigrationScreenState createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  final DataMigrationService _migrationService = DataMigrationService();
  final Map<String, bool> _migrationStatus = {
    'universities': false,
    'coaches': false,
    'courses': false,
    'audio': false,
    'articles': false,
    'all': false,
  };
  final Map<String, String> _migrationMessages = {};
  bool _isMigrating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Migration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Firebase Data Migration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use these tools to migrate your dummy data to Firebase.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildMigrationCard(
                    title: 'Migrate Universities',
                    description: 'Transfer university data to Firebase',
                    status: _migrationStatus['universities']!,
                    message: _migrationMessages['universities'],
                    onPressed: () => _migrateData('universities'),
                  ),
                  _buildMigrationCard(
                    title: 'Migrate Coaches',
                    description: 'Transfer coach profiles to Firebase',
                    status: _migrationStatus['coaches']!,
                    message: _migrationMessages['coaches'],
                    onPressed: () => _migrateData('coaches'),
                  ),
                  _buildMigrationCard(
                    title: 'Migrate Courses & Modules',
                    description: 'Transfer course content to Firebase',
                    status: _migrationStatus['courses']!,
                    message: _migrationMessages['courses'],
                    onPressed: () => _migrateData('courses'),
                  ),
                  _buildMigrationCard(
                    title: 'Migrate Daily Audio',
                    description: 'Transfer audio content to Firebase',
                    status: _migrationStatus['audio']!,
                    message: _migrationMessages['audio'],
                    onPressed: () => _migrateData('audio'),
                  ),
                  _buildMigrationCard(
                    title: 'Migrate Articles',
                    description: 'Transfer article content to Firebase',
                    status: _migrationStatus['articles']!,
                    message: _migrationMessages['articles'],
                    onPressed: () => _migrateData('articles'),
                  ),
                  const Divider(height: 32),
                  _buildMigrationCard(
                    title: 'Migrate All Data',
                    description: 'Transfer all content to Firebase at once',
                    status: _migrationStatus['all']!,
                    message: _migrationMessages['all'],
                    onPressed: () => _migrateData('all'),
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationCard({
    required String title,
    required String description,
    required bool status,
    String? message,
    required VoidCallback onPressed,
    bool isHighlighted = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isHighlighted ? 4 : 2,
      color: isHighlighted ? Colors.blue.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isHighlighted ? Colors.blue.shade800 : null,
                    ),
                  ),
                ),
                if (status)
                  const Icon(Icons.check_circle, color: Colors.green)
                else
                  const Icon(Icons.circle_outlined, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: status ? Colors.green : Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isMigrating ? null : onPressed,
              child: Text(_isMigrating ? 'Migrating...' : 'Migrate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _migrateData(String type) async {
    setState(() {
      _isMigrating = true;
      _migrationMessages[type] = 'Migration in progress...';
    });

    try {
      switch (type) {
        case 'universities':
          await _migrationService.migrateUniversities();
          break;
        case 'coaches':
          await _migrationService.migrateCoaches();
          break;
        case 'courses':
          await _migrationService.migrateCoursesAndLessons();
          break;
        case 'audio':
          await _migrationService.migrateDailyAudios();
          break;
        case 'articles':
          await _migrationService.migrateArticles();
          break;
        case 'all':
          await _migrationService.migrateAllData();
          // Update all statuses to true if all migration succeeds
          _migrationStatus.forEach((key, value) {
            _migrationStatus[key] = true;
          });
          _migrationMessages.forEach((key, value) {
            _migrationMessages[key] = 'Migration completed successfully!';
          });
          setState(() {});
          setState(() {
            _isMigrating = false;
            _migrationStatus[type] = true;
            _migrationMessages[type] = 'Migration completed successfully!';
          });
          return;
      }

      setState(() {
        _isMigrating = false;
        _migrationStatus[type] = true;
        _migrationMessages[type] = 'Migration completed successfully!';
      });
    } catch (e) {
      setState(() {
        _isMigrating = false;
        _migrationMessages[type] = 'Error: ${e.toString()}';
      });
    }
  }
} 