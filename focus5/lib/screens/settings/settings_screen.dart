import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  bool _downloadOverWifi = true;
  
  @override
  void initState() {
    super.initState();
    // Initialize with current theme state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _isDarkMode = themeProvider.isDarkMode;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme throughout app'),
            value: _isDarkMode,
            activeColor: accentColor,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              themeProvider.toggleTheme();
            },
          ),
          
          const Divider(),
          
          // Notifications Section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications for new content'),
            value: _notificationsEnabled,
            activeColor: accentColor,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              // Implementation would go here
            },
          ),
          
          const Divider(),
          
          // Data Usage Section
          _buildSectionHeader('Data Usage'),
          SwitchListTile(
            title: const Text('Download Over Wi-Fi Only'),
            subtitle: const Text('Save mobile data by downloading only on Wi-Fi'),
            value: _downloadOverWifi,
            activeColor: accentColor,
            onChanged: (value) {
              setState(() {
                _downloadOverWifi = value;
              });
              // Implementation would go here
            },
          ),
          
          const Divider(),
          
          // Account Section
          _buildSectionHeader('Account'),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              
              // Get the user's email from UserProvider instead of AuthProvider
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final email = userProvider.user?.email ?? user?.email ?? 'user@example.com';
              
              return ListTile(
                title: const Text('Email Address'),
                subtitle: Text(email),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  // Open email edit dialog
                },
              );
            },
          ),
          ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to password change screen
            },
          ),
          ListTile(
            title: const Text('Delete Account'),
            textColor: Colors.red,
            onTap: () {
              // Show confirmation dialog
              _showDeleteAccountDialog();
            },
          ),
          
          const Divider(),
          
          // Sign Out Option
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                // Navigator back to login or home page happens automatically
              },
              child: const Text('Sign Out'),
            ),
          ),
          
          // App Info
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2023 Focus 5. All rights reserved.',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete account logic would go here
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 