import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore access
import 'admin_management_screen.dart'; // Import the admin management screen
import '../../services/user_permissions_service.dart'; // For checking user permissions
import 'admin_tools_screen.dart';
// Removed lines 11-16 which were causing import errors
// import 'account_settings_screen.dart';
// import 'notification_settings_screen.dart';
// import 'appearance_settings_screen.dart';
// import 'privacy_policy_screen.dart';
// import 'terms_of_service_screen.dart';
// import '../../widgets/common/custom_app_bar.dart'; // <<< Potential issue still
import '../../services/firebase_auth_service.dart'; // Correct path for auth service

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
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0, // Optional: match previous style if needed
        // automaticallyImplyLeading: false, // Set based on navigation needs
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
            
            // Account Section - REMOVED ListTiles for missing screens
            _buildSectionHeader('Account & Legal'), // Renamed slightly
            Consumer<AuthProvider>( // Kept Email display
              builder: (context, authProvider, _) {
                final user = authProvider.currentUser;
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final email = userProvider.user?.email ?? user?.email ?? 'user@example.com';
                
                return ListTile(
                  title: const Text('Email Address'),
                  subtitle: Text(email),
                  // Remove edit icon/onTap if AccountSettingsScreen is missing
                  // trailing: const Icon(Icons.edit),
                  // onTap: () { ... },
                );
              },
            ),
            // Removed Change Password ListTile - Add back if screen exists
            // ListTile(
            //   title: const Text('Change Password'),
            //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            //   onTap: () { ... },
            // ),
            ListTile( // Kept Delete Account
              title: const Text('Delete Account'),
              textColor: Colors.red,
              onTap: () {
                _showDeleteAccountDialog();
              },
            ),
            // Removed Privacy Policy ListTile - Add back if screen exists
            // ListTile(... Privacy Policy ...),
            // Removed Terms of Service ListTile - Add back if screen exists
            // ListTile(... Terms of Service ...),
            
            const Divider(),

            // ---- ADDED: Debug Button (Conditionally shown) ----
            if (userProvider.user?.isAdmin ?? false) ...[ 
              const Divider(),
               ListTile(
                leading: Icon(Icons.bug_report, color: Colors.orange),
                title: const Text('Debug: Test Daily Login Increment'),
                subtitle: const Text('Sets last active to yesterday & runs check'),
                onTap: () => _runLoginDayTest(context),
              ),
            ],
            // --------------------------
  
            // --- Admin Tools Section (conditionally shown) ---
            if (isAdmin)
              _buildAdminToolsSection(context, userProvider),
              
            // --- Admin Management Section (conditionally shown) ---
            if (isAdmin)
              _buildAdminManagementSection(),

            // --- Sign Out Button --- 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.redAccent, // Use a distinct color for sign out
                    minimumSize: const Size(double.infinity, 50), // Make button wider
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                  ),
                  onPressed: () async {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    final navigator = Navigator.of(context); // Capture navigator before async gap
                    try {
                      // Sign out using the correct logout() method
                      await authProvider.logout(); 
                      
                      // Clear local user data immediately (already done in logout, but good practice)
                      // userProvider.clearUserData(); 
                      
                      // Navigate to login screen and remove all previous routes
                      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                    } catch (e) {
                      // Show error message if sign out fails
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error signing out: $e')),
                        );
                      }
                    }
                  },
                ),
              ),            
            ),
            // --- End Sign Out Button ---            
            
            // App Info
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Version 1.0.0', // Consider making this dynamic
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '© 2024 Focus 5. All rights reserved.', // Update year maybe?
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
        // --- New Debug Button ---
        ListTile(
          leading: const Icon(Icons.bug_report, color: Colors.orange), // Add an icon
          title: const Text('Set Last Active to Yesterday'),
          subtitle: const Text('For testing totalLoginDays increment'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async { // Make onTap async
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final userId = authProvider.currentUser?.id;
        
            if (userId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not logged in'), backgroundColor: Colors.orange),
              );
              return;
            }
        
            setState(() {
              _isLoading = true; // Show loading indicator
              _statusMessage = 'Setting lastActive...';
            });
        
            try {
              final yesterday = DateTime.now().subtract(const Duration(days: 1));
              final yesterdayTimestamp = Timestamp.fromDate(yesterday);
        
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({'lastActive': yesterdayTimestamp});
        
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Successfully set lastActive to yesterday.'),
                  backgroundColor: Colors.green,
                ),
              );
              // Trigger user data refresh to reflect change locally if needed
              await Provider.of<UserProvider>(context, listen: false).loadUserData(userId);
              
              // Optionally, trigger the login info update check immediately after changing the date
              await Provider.of<UserProvider>(context, listen: false).updateUserLoginInfo();
              
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error setting lastActive: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            } finally {
               setState(() {
                 _isLoading = false; // Hide loading indicator
                 _statusMessage = '';
               });
            }
          },
        ),
         // --- End New Debug Button ---
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

  // Helper function for the debug button action
  Future<void> _runLoginDayTest(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not loaded.')),
      );
      return;
    }

    final userId = userProvider.user!.id;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final firestore = FirebaseFirestore.instance;

    try {
      print('DEBUG: Setting lastActive to yesterday for user $userId');
      // Update Firestore directly
      await firestore.collection('users').doc(userId).update({
        'lastActive': Timestamp.fromDate(yesterday),
      });

      // Optionally update local state if needed immediately, though updateUserLoginInfo should refresh it
      // userProvider.updateLocalUser(userProvider.user!.copyWith(lastActive: yesterday));

      print('DEBUG: Triggering updateUserLoginInfo manually...');
      // Trigger the logic that should increment totalLoginDays
      await userProvider.updateUserLoginInfo();

      print('DEBUG: Refreshing user data...');
      // Refetch user data to confirm the update - REMOVED forceRefresh
      await userProvider.loadUserData(userId);

      // Check if widget is still mounted before showing SnackBar
      if (!context.mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug Test Ran. New Total Days: ${userProvider.user?.totalLoginDays ?? 'N/A'}')),
      );
       print('DEBUG: Test finished. New Total Days: ${userProvider.user?.totalLoginDays}');

    } catch (e) {
      print('DEBUG: Error running login day test: $e');
       // Check if widget is still mounted before showing SnackBar
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug Test Error: $e')),
      );
    }
  }
} 