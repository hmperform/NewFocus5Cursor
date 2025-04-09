import 'package:flutter/material.dart';
import 'package:focus5/screens/admin/coach_admin_screen.dart'; // Assuming coach admin screen exists
import 'package:focus5/screens/settings/admin_management_screen.dart'; // Assuming this manages universities/permissions or similar
import 'package:focus5/screens/settings/data_migration_screen.dart'; // Assuming this exists
import 'package:focus5/screens/settings/firebase_setup_screen.dart'; // Assuming this exists
import 'package:focus5/screens/settings/explore_layout_screen.dart'; // Assuming this exists
import 'package:cloud_firestore/cloud_firestore.dart';

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
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Article Management'),
            subtitle: const Text('Manage article content'),
            onTap: () {
              // We'll create this screen next
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Article Management - Coming Soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_customize),
            title: const Text('Explore Screen Layout'),
            subtitle: const Text('Customize the order of sections on the explore tab'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExploreLayoutScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Migrate User Badges'),
            subtitle: const Text('Convert badge references to arrays in user documents'),
            onTap: () async {
              // Show confirmation dialog
              bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Migration'),
                  content: const Text(
                    'This will update all user documents that have badge references to use badge arrays instead. '
                    'This operation cannot be undone. Continue?'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ) ?? false;
              
              if (confirm) {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Beginning migration...'))
                );
                
                try {
                  // Get all user documents
                  final firestore = FirebaseFirestore.instance;
                  final snapshot = await firestore.collection('users').get();
                  
                  int updated = 0;
                  for (var doc in snapshot.docs) {
                    final data = doc.data();
                    if (data['badges'] != null && data['badges'] is Map) {
                      // If badges is a reference object with id and path
                      final badgeRef = data['badges'] as Map<String, dynamic>;
                      if (badgeRef.containsKey('id') && badgeRef.containsKey('path')) {
                        // Convert to array with a single badge
                        await firestore.collection('users').doc(doc.id).update({
                          'badges': [{
                            'id': badgeRef['id'],
                            'name': 'Badge',
                            'description': 'A badge from reference',
                            'imageUrl': '',
                            'earnedAt': FieldValue.serverTimestamp(),
                            'xpValue': 0,
                          }]
                        });
                        updated++;
                      }
                    }
                  }
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Migration complete. Updated $updated user documents.'))
                  );
                } catch (e) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'))
                  );
                }
              }
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