import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:focus5/services/user_permissions_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManagementScreen extends StatefulWidget {
  static const routeName = '/admin-management';

  const AdminManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> with SingleTickerProviderStateMixin {
  final UserPermissionsService _permissionsService = UserPermissionsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late TabController _tabController;
  bool _isLoading = false;
  String _statusMessage = '';
  UserRole _currentUserRole = UserRole.user;
  
  // App admins tab
  List<Map<String, dynamic>> _appAdmins = [];
  
  // University admins tab
  List<Map<String, dynamic>> _universities = [];
  Map<String, List<Map<String, dynamic>>> _universityAdmins = {};
  
  // Selected university for adding admin
  String? _selectedUniversityCode;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading...';
    });
    
    try {
      // Get current user role
      _currentUserRole = await _permissionsService.getCurrentUserRole();
      
      // Load app admins
      if (_currentUserRole == UserRole.appAdmin) {
        _appAdmins = await _permissionsService.listAppAdmins();
      }
      
      // Load universities
      final querySnapshot = await _firestore.collection('universities').get();
      _universities = querySnapshot.docs.map((doc) => {
        'code': doc.id,
        'name': doc.data()['name'] ?? '',
        'domain': doc.data()['domain'] ?? '',
        'logoUrl': doc.data()['logoUrl'],
      }).toList();
      
      // If current user is university admin, filter to only show their university
      if (_currentUserRole == UserRole.universityAdmin) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
          final String? userUniversityCode = userDoc.data()?['universityCode'];
          
          if (userUniversityCode != null) {
            _universities = _universities.where((uni) => uni['code'] == userUniversityCode).toList();
            
            // Set the selected university
            _selectedUniversityCode = userUniversityCode;
          }
        }
      }
      
      // Load admins for each university
      for (var university in _universities) {
        final String code = university['code'];
        _universityAdmins[code] = await _permissionsService.listUniversityAdmins(code);
      }
      
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _showAddAppAdminDialog() async {
    final TextEditingController emailController = TextEditingController();
    String errorMessage = '';
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add App Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'User Email',
                  hintText: 'Enter user email address',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  setDialogState(() {
                    errorMessage = 'Please enter an email address';
                  });
                  return;
                }
                
                // Find user by email
                try {
                  final userQuery = await _firestore
                      .collection('users')
                      .where('email', isEqualTo: email)
                      .limit(1)
                      .get();
                  
                  if (userQuery.docs.isEmpty) {
                    setDialogState(() {
                      errorMessage = 'User not found';
                    });
                    return;
                  }
                  
                  final userId = userQuery.docs.first.id;
                  
                  // Make user an admin
                  final success = await _permissionsService.makeUserAppAdmin(userId);
                  
                  if (success) {
                    Navigator.pop(context);
                    _loadData(); // Refresh data
                  } else {
                    setDialogState(() {
                      errorMessage = 'Failed to add admin permissions';
                    });
                  }
                } catch (e) {
                  setDialogState(() {
                    errorMessage = 'Error: ${e.toString()}';
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddUniversityAdminDialog(String universityCode, String universityName) async {
    final TextEditingController emailController = TextEditingController();
    String errorMessage = '';
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Admin to $universityName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'User Email',
                  hintText: 'Enter user email address',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  setDialogState(() {
                    errorMessage = 'Please enter an email address';
                  });
                  return;
                }
                
                // Find user by email
                try {
                  final userQuery = await _firestore
                      .collection('users')
                      .where('email', isEqualTo: email)
                      .limit(1)
                      .get();
                  
                  if (userQuery.docs.isEmpty) {
                    setDialogState(() {
                      errorMessage = 'User not found';
                    });
                    return;
                  }
                  
                  final userId = userQuery.docs.first.id;
                  
                  // Make user a university admin
                  final success = await _permissionsService.makeUserUniversityAdmin(userId, universityCode);
                  
                  if (success) {
                    Navigator.pop(context);
                    _loadData(); // Refresh data
                  } else {
                    setDialogState(() {
                      errorMessage = 'Failed to add admin permissions';
                    });
                  }
                } catch (e) {
                  setDialogState(() {
                    errorMessage = 'Error: ${e.toString()}';
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateUniversityDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController codeController = TextEditingController();
    final TextEditingController domainController = TextEditingController();
    String? logoUrl;
    bool isUploading = false;
    String errorMessage = '';
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create University'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // University Logo Upload
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    setDialogState(() {
                      isUploading = true;
                    });
                    
                    try {
                      // Logic to select and upload image would go here
                      // For now, using a placeholder to demonstrate UI
                      await Future.delayed(const Duration(seconds: 1));
                      
                      // In a real implementation, this would be the URL returned from Firebase Storage
                      logoUrl = 'https://via.placeholder.com/150';
                      
                      setDialogState(() {
                        isUploading = false;
                      });
                    } catch (e) {
                      setDialogState(() {
                        isUploading = false;
                        errorMessage = 'Error uploading logo: ${e.toString()}';
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  logoUrl!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Upload Logo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'University Name',
                    hintText: 'e.g. State University',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'University Code',
                    hintText: 'e.g. STATE_UNIV',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9_]')),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: domainController,
                  decoration: const InputDecoration(
                    labelText: 'Email Domain',
                    hintText: 'e.g. stateuniv.edu',
                  ),
                  keyboardType: TextInputType.url,
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isUploading ? null : () async {
                final name = nameController.text.trim();
                final code = codeController.text.trim();
                final domain = domainController.text.trim();
                
                if (name.isEmpty || code.isEmpty || domain.isEmpty) {
                  setDialogState(() {
                    errorMessage = 'All fields are required';
                  });
                  return;
                }
                
                try {
                  final newCode = await _permissionsService.createUniversity(
                    name: name,
                    code: code,
                    domain: domain,
                    logoUrl: logoUrl,
                  );
                  
                  if (newCode != null) {
                    Navigator.pop(context);
                    _loadData(); // Refresh data
                  } else {
                    setDialogState(() {
                      errorMessage = 'Failed to create university';
                    });
                  }
                } catch (e) {
                  setDialogState(() {
                    errorMessage = 'Error: ${e.toString()}';
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeAppAdmin(String userId) async {
    final bool confirm = await _showConfirmDialog(
      'Remove Admin',
      'Are you sure you want to remove admin privileges from this user?'
    );
    
    if (confirm) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Removing admin privileges...';
      });
      
      try {
        final success = await _permissionsService.makeUserAppAdmin(userId, isAdmin: false);
        
        if (success) {
          _loadData(); // Refresh data
        } else {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Failed to remove admin privileges';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _removeUniversityAdmin(String userId, String universityCode) async {
    final bool confirm = await _showConfirmDialog(
      'Remove University Admin',
      'Are you sure you want to remove this user as a university admin?'
    );
    
    if (confirm) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Removing university admin privileges...';
      });
      
      try {
        final success = await _permissionsService.removeUserAsUniversityAdmin(userId, universityCode);
        
        if (success) {
          _loadData(); // Refresh data
        } else {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Failed to remove university admin privileges';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final accentColor = themeProvider.accentColor;
    
    // If user doesn't have admin privileges, show access denied
    if (_currentUserRole == UserRole.user && !_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          title: Text(
            'Admin Management',
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to access this page.',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Admin Management',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: textColor.withOpacity(0.7),
          tabs: [
            Tab(
              text: 'App Admins',
              icon: Icon(Icons.admin_panel_settings),
            ),
            Tab(
              text: 'University Admins',
              icon: Icon(Icons.school),
            ),
          ],
        ),
      ),
      floatingActionButton: _isLoading 
          ? null 
          : FloatingActionButton(
              backgroundColor: accentColor,
              onPressed: () {
                if (_tabController.index == 0 && _currentUserRole == UserRole.appAdmin) {
                  _showAddAppAdminDialog();
                } else if (_tabController.index == 1) {
                  if (_currentUserRole == UserRole.appAdmin) {
                    // App admin can create universities
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.person_add),
                            title: Text('Add University Admin'),
                            onTap: () {
                              Navigator.pop(context);
                              
                              if (_universities.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Select University'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _universities.length,
                                        itemBuilder: (context, index) {
                                          final university = _universities[index];
                                          return ListTile(
                                            title: Text(university['name']),
                                            subtitle: Text(university['code']),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _showAddUniversityAdminDialog(
                                                university['code'],
                                                university['name'],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('No universities available')),
                                );
                              }
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.add_business),
                            title: Text('Create University'),
                            onTap: () {
                              Navigator.pop(context);
                              _showCreateUniversityDialog();
                            },
                          ),
                        ],
                      ),
                    );
                  } else if (_currentUserRole == UserRole.universityAdmin && _selectedUniversityCode != null) {
                    // University admin can only add admins to their university
                    final university = _universities.firstWhere(
                      (uni) => uni['code'] == _selectedUniversityCode,
                      orElse: () => {'code': _selectedUniversityCode, 'name': 'Your University'},
                    );
                    
                    _showAddUniversityAdminDialog(
                      university['code'],
                      university['name'],
                    );
                  }
                }
              },
              child: Icon(Icons.add, color: Colors.white),
            ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // App Admins Tab
                _currentUserRole == UserRole.appAdmin
                    ? _buildAppAdminsTab(accentColor, textColor)
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Access Restricted',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Only app admins can manage app-wide permissions.',
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                
                // University Admins Tab
                _buildUniversityAdminsTab(accentColor, textColor),
              ],
            ),
    );
  }

  Widget _buildAppAdminsTab(Color accentColor, Color textColor) {
    if (_appAdmins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No App Admins Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add an app admin.',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appAdmins.length,
      itemBuilder: (context, index) {
        final admin = _appAdmins[index];
        final currentUser = FirebaseAuth.instance.currentUser;
        final isCurrentUser = currentUser != null && admin['userId'] == currentUser.uid;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: admin['profileImageUrl'] != null
                  ? NetworkImage(admin['profileImageUrl'])
                  : null,
              child: admin['profileImageUrl'] == null
                  ? Icon(Icons.person, color: Colors.white)
                  : null,
              backgroundColor: Colors.grey.shade700,
            ),
            title: Text(
              admin['fullName'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin['email'],
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                if (isCurrentUser)
                  Text(
                    'Current User',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: !isCurrentUser
                ? IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeAppAdmin(admin['userId']),
                    tooltip: 'Remove admin privileges',
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildUniversityAdminsTab(Color accentColor, Color textColor) {
    if (_universities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Universities Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create a university.',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _universities.length,
      itemBuilder: (context, index) {
        final university = _universities[index];
        final String code = university['code'];
        final List<Map<String, dynamic>> admins = _universityAdmins[code] ?? [];
        final currentUser = FirebaseAuth.instance.currentUser;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: university['logoUrl'] != null
                ? Image.network(
                    university['logoUrl'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  )
                : CircleAvatar(
                    child: Text(
                      university['name'].substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: accentColor,
                  ),
            title: Text(
              university['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            subtitle: Text(
              '${university['domain']} • ${admins.length} admin${admins.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            children: [
              if (admins.isEmpty)
                ListTile(
                  title: Text(
                    'No admins for this university',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ...admins.map((admin) {
                  final isCurrentUser = currentUser != null && admin['userId'] == currentUser.uid;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: admin['profileImageUrl'] != null
                          ? NetworkImage(admin['profileImageUrl'])
                          : null,
                      child: admin['profileImageUrl'] == null
                          ? Icon(Icons.person, color: Colors.white)
                          : null,
                      backgroundColor: Colors.grey.shade700,
                    ),
                    title: Text(
                      admin['fullName'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          admin['email'],
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        if (isCurrentUser)
                          Text(
                            'Current User',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: !isCurrentUser
                        ? IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeUniversityAdmin(admin['userId'], code),
                            tooltip: 'Remove university admin',
                          )
                        : null,
                  );
                }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
} 