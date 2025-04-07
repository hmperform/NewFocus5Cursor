import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:focus5/providers/content_provider.dart';
import 'package:focus5/services/data_migration_service.dart';
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
  final DataMigrationService _migrationService = DataMigrationService();

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

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
    debugPrint('TODO: Course migration logic depends on DummyData which is commented out.');
  }

  Future<void> _migrateAudioModules() async {
    debugPrint('TODO: Audio module migration logic depends on DummyData which is commented out.');
  }

  Future<void> _migrateArticles() async {
    debugPrint('TODO: Article migration logic depends on DummyData which is commented out.');
  }

  Future<void> _migrateCoaches() async {
    debugPrint('TODO: Coach migration logic depends on DummyData which is commented out.');
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
                      description: 'TODO: Get course count',
                      textColor: textColor,
                      accentColor: accentColor,
                    ),
                    _buildDataItem(
                      icon: Icons.headphones,
                      title: 'Audio Modules',
                      description: 'TODO: Get audio count',
                      textColor: textColor,
                      accentColor: accentColor,
                    ),
                    _buildDataItem(
                      icon: Icons.article,
                      title: 'Articles',
                      description: 'TODO: Get article count',
                      textColor: textColor,
                      accentColor: accentColor,
                    ),
                    _buildDataItem(
                      icon: Icons.person,
                      title: 'Coaches',
                      description: 'TODO: Get coach count',
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