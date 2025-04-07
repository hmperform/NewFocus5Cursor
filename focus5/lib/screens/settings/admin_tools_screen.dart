import 'package:flutter/material.dart';
import 'package:focus5/screens/admin/coach_admin_screen.dart'; // Assuming coach admin screen exists
import 'package:focus5/screens/settings/admin_management_screen.dart'; // Assuming this manages universities/permissions or similar
import 'package:focus5/screens/settings/data_migration_screen.dart'; // Assuming this exists
import 'package:focus5/screens/settings/firebase_setup_screen.dart'; // Assuming this exists

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({Key? key}) : super(key: key);

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Tools'),
        backgroundColor: Theme.of(context).colorScheme.surface, // Use theme color
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('User Management'),
            subtitle: const Text('Search, view, and manage users'),
            onTap: () {
              // TODO: Navigate to User Management Screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User Management - Not Implemented')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('University/Permissions Management'),
            subtitle: const Text('Manage universities and admin roles'),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const AdminManagementScreen()), // Navigate to existing screen if it covers this
               );
            },
          ),
           ListTile(
            leading: const Icon(Icons.supervisor_account_outlined), // Changed Icon
            title: const Text('Coach Management'),
            subtitle: const Text('Manage coach profiles'),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const CoachAdminScreen()),
               );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Data Migration'),
            subtitle: const Text('Run data migration scripts'),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const DataMigrationScreen()),
               );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Firebase Setup'),
            subtitle: const Text('Configure Firebase settings'),
            onTap: () {
              Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const FirebaseSetupScreen()),
               );
            },
          ),
        ],
      ),
    );
  }
} 