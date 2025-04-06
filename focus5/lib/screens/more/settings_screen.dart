import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final accentColor = themeProvider.accentColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account section
            _buildSectionHeader(context, 'Account'),
            const SizedBox(height: 8),
            _buildSettingCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              icon: Icons.person,
              title: 'Account Information',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to account info screen
              },
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              icon: Icons.security,
              title: 'Security',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to security settings
              },
            ),
            
            const SizedBox(height: 24),
            
            // App Settings
            _buildSectionHeader(context, 'App Settings'),
            const SizedBox(height: 8),
            _buildSettingCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
                activeColor: accentColor,
              ),
              onTap: () {
                themeProvider.toggleTheme();
              },
            ),
            const SizedBox(height: 8),
            _buildSettingCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              icon: Icons.notifications,
              title: 'Notifications',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to notifications settings
              },
            ),
            
            const SizedBox(height: 24),
            
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
            
            const SizedBox(height: 24),
            
            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  Widget _buildSettingCard({
    required BuildContext context,
    required Color cardColor,
    required Color textColor,
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Log out user
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
} 