import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_permissions_service.dart';
import '../settings/firebase_setup_screen.dart';
import '../settings/data_migration_screen.dart';
import '../settings/admin_management_screen.dart';
import '../settings/module_to_lesson_migration_screen.dart';

class SettingsScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ... (existing code)

  @override
  Widget build(BuildContext context) {
    // ... (existing code)

    return Scaffold(
      // ... (existing code)

      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... (existing code)

            // About section
            _buildSectionHeader(context, 'About'),
            const SizedBox(height: 8),
            _buildSettingCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              icon: Icons.info,
              title: 'About Focus 5',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Show about dialog
              },
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              icon: Icons.help,
              title: 'Help & Support',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to help screen
              },
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Show privacy policy
              },
            ),
            
            const SizedBox(height: 24),
            
            // Modules to Lessons Migration - Added as a separate section
            _buildSectionHeader(context, 'Data Management'),
            const SizedBox(height: 8),
            _buildSettingCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              icon: Icons.swap_horiz,
              title: 'Modules to Lessons Migration',
              subtitle: 'Migrate modules to lessons collection',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/module_to_lesson_migration');
              },
            ),
            
            const SizedBox(height: 24),
            
            // Developer section (only in debug mode)
            _buildSectionHeader(context, 'Developer'),
            const SizedBox(height: 8),
            _buildSettingCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              icon: Icons.storage,
              title: 'Data Migration',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/data_migration');
              },
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              icon: Icons.cloud,
              title: 'Firebase Setup',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/firebase_setup');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    // ... (existing code)
  }

  Widget _buildSettingCard(
      BuildContext context, Color cardColor, Color textColor, IconData icon, String title,
      String subtitle, Icon trailingIcon, VoidCallback onTap) {
    // ... (existing code)
  }
} 