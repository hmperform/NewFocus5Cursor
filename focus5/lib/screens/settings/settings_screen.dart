import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore access
import 'admin_management_screen.dart'; // Import the admin management screen
import '../../services/user_permissions_service.dart'; // For checking user permissions

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  bool _downloadOverWifi = true;
  
  // Controllers for admin inputs
  final TextEditingController _xpAmountController = TextEditingController();
  final TextEditingController _targetLevelController = TextEditingController();
  
  // Controller for university code entry
  final TextEditingController _universityCodeController = TextEditingController();
  
  // Firestore instance for university code validation
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // For checking current user role
  final UserPermissionsService _permissionsService = UserPermissionsService();
  
  // Loading state
  bool _isLoading = false;
  String _statusMessage = '';

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
  void dispose() {
    _xpAmountController.dispose();
    _targetLevelController.dispose();
    _universityCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final userProvider = Provider.of<UserProvider>(context); // Listen for user changes
    final bool isAdmin = userProvider.user?.isAdmin ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                if (_statusMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(_statusMessage),
                  ),
              ],
            ),
          )
        : ListView(
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
            
            // University/Club Code Section (for all users)
            _buildSectionHeader('University / Club Account'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Enter a code to join a university or club account',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            
            // Show current university if user belongs to one
            if (userProvider.user?.universityCode != null && userProvider.user!.universityCode!.isNotEmpty)
              ListTile(
                title: const Text('Current Organization'),
                subtitle: Text(userProvider.user?.university ?? 'Unknown'),
                trailing: TextButton(
                  onPressed: () {
                    // Show confirmation dialog to leave current university
                    _showLeaveUniversityDialog(userProvider);
                  },
                  child: const Text('Leave'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            
            // University code entry field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _universityCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Code',
                        hintText: 'e.g. TEAM2023',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  ElevatedButton(
                    onPressed: () => _validateAndJoinUniversity(userProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    ),
                    child: const Text('Join'),
                  ),
                ],
              ),
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
            
            // --- Admin Tools Section (conditionally shown) ---
            if (isAdmin)
              _buildAdminToolsSection(context, userProvider),
              
            // --- Admin Management Section (conditionally shown) ---
            if (isAdmin)
              _buildAdminManagementSection(),
            
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
  
  // Validate and join university with provided code
  Future<void> _validateAndJoinUniversity(UserProvider userProvider) async {
    final String code = _universityCodeController.text.trim();
    
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a code')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Validating code...';
    });
    
    try {
      // Check if university exists with this code
      final universityDoc = await _firestore.collection('universities').doc(code).get();
      
      if (!universityDoc.exists) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid university/club code')),
        );
        return;
      }
      
      // Get university data
      final universityData = universityDoc.data() as Map<String, dynamic>;
      final universityName = universityData['name'] as String;
      
      // Update user's university
      final currentUser = userProvider.user;
      if (currentUser != null) {
        // Update user document in Firestore
        await _firestore.collection('users').doc(currentUser.id).update({
          'university': universityName,
          'universityCode': code,
        });
        
        // Increment university's user count
        await _firestore.collection('universities').doc(code).update({
          'currentUserCount': FieldValue.increment(1)
        });
        
        // Update local user data
        await userProvider.refreshUser();
        
        setState(() {
          _isLoading = false;
          _statusMessage = '';
          _universityCodeController.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined $universityName')),
        );
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user information')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  
  // Show dialog to confirm leaving university
  void _showLeaveUniversityDialog(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Organization?'),
        content: const Text(
          'Are you sure you want to leave your current organization? You may lose access to organization-specific content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leaveCurrentUniversity(userProvider);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
  
  // Handle leaving university
  Future<void> _leaveCurrentUniversity(UserProvider userProvider) async {
    final currentUser = userProvider.user;
    if (currentUser == null || currentUser.universityCode == null || currentUser.universityCode!.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Leaving organization...';
    });
    
    try {
      final oldUniversityCode = currentUser.universityCode!;
      
      // Update user document in Firestore
      await _firestore.collection('users').doc(currentUser.id).update({
        'university': null,
        'universityCode': null,
      });
      
      // Decrement university's user count
      await _firestore.collection('universities').doc(oldUniversityCode).update({
        'currentUserCount': FieldValue.increment(-1)
      });
      
      // Update local user data
      await userProvider.refreshUser();
      
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully left organization')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
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
  
  // --- Admin Management Section ---
  Widget _buildAdminManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Admin Management'),
        ListTile(
          title: const Text('University Admin Management'),
          subtitle: const Text('Manage university accounts and admins'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminManagementScreen(),
              ),
            );
          },
        ),
        const Divider(),
      ],
    );
  }
  
  // --- Build Admin Tools section ---
  Widget _buildAdminToolsSection(BuildContext context, UserProvider userProvider) {
    final accentColor = Provider.of<ThemeProvider>(context).accentColor;
    final userId = userProvider.user?.id ?? ''; // For safety

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Admin Tools'),
        // --- Add XP ---
        ListTile(
          title: const Text('Add XP'),
          subtitle: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _xpAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Enter XP amount',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                child: const Text('Add', style: TextStyle(color: Colors.black)),
                onPressed: () async {
                  final amount = int.tryParse(_xpAmountController.text);
                  if (amount != null && amount > 0 && userId.isNotEmpty) {
                    final success = await userProvider.adminAddXp(amount);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Added $amount XP' : 'Failed to add XP')),
                    );
                    _xpAmountController.clear();
                    FocusScope.of(context).unfocus(); // Dismiss keyboard
                  }
                },
              ),
            ],
          ),
        ),
        // --- Set Level ---
        ListTile(
          title: const Text('Set Level'),
          subtitle: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetLevelController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Enter target level',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                child: const Text('Set', style: TextStyle(color: Colors.black)),
                onPressed: () async {
                  final level = int.tryParse(_targetLevelController.text);
                  if (level != null && level > 0 && userId.isNotEmpty) {
                    final success = await userProvider.adminSetLevel(level);
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Level set to $level' : 'Failed to set level')),
                    );
                    _targetLevelController.clear();
                     FocusScope.of(context).unfocus(); // Dismiss keyboard
                  }
                },
              ),
            ],
          ),
        ),
        // --- Increment Streak ---
        ListTile(
          title: const Text('Increment Streak'),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            child: const Text('+1 Day', style: TextStyle(color: Colors.black)),
            onPressed: () async {
              if (userId.isNotEmpty) {
                final success = await userProvider.adminIncrementStreak();
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Streak incremented' : 'Failed to increment streak')),
                );
              }
            },
          ),
        ),
         // --- Reset Streak ---
        ListTile(
          title: const Text('Reset Streak'),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]), // Warning color
            child: const Text('Reset'),
            onPressed: () async {
              if (userId.isNotEmpty) {
                 // Confirmation Dialog
                 showDialog(
                   context: context,
                   builder: (context) => AlertDialog(
                     title: const Text('Confirm Reset Streak'),
                     content: const Text('Are you sure you want to reset the streak to 0 and clear the last completion date?'),
                     actions: [
                       TextButton(
                         onPressed: () => Navigator.pop(context),
                         child: const Text('Cancel'),
                       ),
                       TextButton(
                         style: TextButton.styleFrom(foregroundColor: Colors.red),
                         onPressed: () async {
                           Navigator.pop(context); // Close dialog
                           final success = await userProvider.adminResetStreak();
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(success ? 'Streak Reset' : 'Failed to reset streak')),
                           );
                         },
                         child: const Text('Reset'),
                       ),
                     ],
                   ),
                 );
              }
            },
          ),
        ),
        const Divider(),
      ],
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