import '../../utils/migrate_modules_to_lessons.dart';
import '../../utils/firebase_indexes_helper.dart';

class AdminToolsScreen extends StatefulWidget {
  // ... (existing code)
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  // ... (existing code)

  @override
  Widget build(BuildContext context) {
    // ... (existing code)

    return Scaffold(
      // ... (existing code)

      body: Column(
        children: [
          // ... (existing code)

          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Migrate Modules to Lessons'),
            subtitle: const Text('Transfer data from modules to lessons collection'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ModulesToLessonsMigrationScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Firebase Indexes Helper'),
            subtitle: const Text('View and create required Firebase indexes'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FirebaseIndexesHelper(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 