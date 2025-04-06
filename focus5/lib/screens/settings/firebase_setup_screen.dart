import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:focus5/services/firebase_config_service.dart';
import 'package:focus5/services/user_permissions_service.dart';

class FirebaseSetupScreen extends StatefulWidget {
  static const routeName = '/firebase-setup';

  const FirebaseSetupScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseSetupScreen> createState() => _FirebaseSetupScreenState();
}

class _FirebaseSetupScreenState extends State<FirebaseSetupScreen> {
  final FirebaseConfigService _configService = FirebaseConfigService();
  final UserPermissionsService _permissionsService = UserPermissionsService();
  bool _isLoading = false;
  String _statusMessage = 'Ready to configure Firebase.';
  bool _isAdmin = false;
  bool _isAnyAdmin = false;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    final isAppAdmin = await _permissionsService.isCurrentUserAppAdmin();
    final isAnyAdmin = await _permissionsService.isCurrentUserAnyAdmin();
    
    setState(() {
      _isAdmin = isAppAdmin;
      _isAnyAdmin = isAnyAdmin;
      _isLoading = false;
    });
  }

  Future<void> _setupCoachesCollection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up coaches collection...';
    });

    try {
      final success = await _configService.setupCoachesCollection();
      
      setState(() {
        _isLoading = false;
        _statusMessage = success 
            ? 'Coaches collection set up successfully!' 
            : 'Failed to set up coaches collection.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _showFirestoreRules() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Preparing Firestore security rules...';
    });

    try {
      await _configService.updateFirestoreSecurityRules();
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Firestore security rules prepared. Check the console output.';
      });
      
      _showRulesDialog(
        'Firestore Security Rules',
        '''
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions for role checking
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAppAdmin() {
      return isAuthenticated() && 
             exists(/databases/\$(database)/documents/users/\$(request.auth.uid)) &&
             get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.isAdmin == true;
    }
    
    function isUniversityAdmin(universityCode) {
      return isAuthenticated() && 
             exists(/databases/\$(database)/documents/universities/\$(universityCode)) &&
             request.auth.uid in get(/databases/\$(database)/documents/universities/\$(universityCode)).data.adminUserIds;
    }
    
    function getUserUniversityCode() {
      return get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.universityCode;
    }
    
    function isUserFromUniversity(universityCode) {
      return isAuthenticated() && 
             exists(/databases/\$(database)/documents/users/\$(request.auth.uid)) &&
             get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.universityCode == universityCode;
    }
    
    // User collection rules
    match /users/{userId} {
      // Users can read and update their own data
      allow read: if isAuthenticated() && (request.auth.uid == userId || isAppAdmin());
      
      // Users can update their own non-admin fields
      allow update: if isAuthenticated() && request.auth.uid == userId && 
                     (!request.resource.data.diff(resource.data).affectedKeys.hasAny(['isAdmin']));
      
      // App admins can read and write all user documents
      allow write: if isAppAdmin();
    }
    
    // More rules...
  }
}
'''
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _showStorageRules() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Preparing Storage security rules...';
    });

    try {
      await _configService.updateStorageSecurityRules();
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Storage security rules prepared. Check the console output.';
      });
      
      _showRulesDialog(
        'Firebase Storage Rules',
        '''
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Helper functions for role checking
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAppAdmin() {
      return request.auth != null &&
             exists(/databases/(default)/documents/users/\$(request.auth.uid)) &&
             get(/databases/(default)/documents/users/\$(request.auth.uid)).data.isAdmin == true;
    }
    
    // More rules...
  }
}
'''
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _makeCurrentUserAdmin() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Making current user an admin...';
    });

    try {
      final success = await _configService.makeCurrentUserAdmin();
      
      setState(() {
        _isLoading = false;
        _isAdmin = success;
        _isAnyAdmin = success;
        _statusMessage = success 
            ? 'Current user is now an admin!' 
            : 'Failed to make current user an admin.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  void _showRulesDialog(String title, String rules) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Container(
          width: double.maxFinite,
          height: 400,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SelectableText(
                  rules,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: rules));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rules copied to clipboard')),
              );
              Navigator.pop(context);
            },
            child: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
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
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Firebase Setup',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information card
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
                          'Firebase Setup',
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
                      'This tool helps you set up Firebase for coach profiles. '
                      'Use the buttons below to create collections and access security rules.',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isAnyAdmin ? Icons.verified_user : Icons.person,
                          color: _isAdmin ? Colors.green : (_isAnyAdmin ? Colors.orange : Colors.grey),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAdmin 
                              ? 'You have app admin privileges' 
                              : (_isAnyAdmin 
                                  ? 'You have university admin privileges' 
                                  : 'You do not have admin privileges'),
                          style: TextStyle(
                            color: _isAdmin 
                                ? Colors.green 
                                : (_isAnyAdmin ? Colors.orange : Colors.grey),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Collection Setup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              icon: Icons.person,
              text: 'Setup Coaches Collection',
              description: 'Creates the coaches collection in Firestore',
              onPressed: _setupCoachesCollection,
              accentColor: accentColor,
              textColor: textColor,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Security Rules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              icon: Icons.security,
              text: 'Firestore Security Rules',
              description: 'View and copy Firestore security rules',
              onPressed: _showFirestoreRules,
              accentColor: accentColor,
              textColor: textColor,
            ),
            
            const SizedBox(height: 12),
            
            _buildActionButton(
              icon: Icons.storage,
              text: 'Storage Security Rules',
              description: 'View and copy Firebase Storage security rules',
              onPressed: _showStorageRules,
              accentColor: accentColor,
              textColor: textColor,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Admin Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              icon: Icons.admin_panel_settings,
              text: 'Make Current User Admin',
              description: 'Grant admin privileges to your account (development only)',
              onPressed: _makeCurrentUserAdmin,
              accentColor: accentColor,
              textColor: textColor,
            ),
            
            const SizedBox(height: 12),
            
            _buildActionButton(
              icon: Icons.manage_accounts,
              text: 'Admin Management',
              description: 'Manage app and university admin users',
              onPressed: () {
                Navigator.of(context).pushNamed('/admin-management');
              },
              accentColor: accentColor,
              textColor: textColor,
            ),
            
            const SizedBox(height: 24),
            
            if (_isLoading || _statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(color: accentColor),
                ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontStyle: _isLoading ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required String description,
    required VoidCallback onPressed,
    required Color accentColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: textColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 