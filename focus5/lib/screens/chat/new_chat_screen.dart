import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_models.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<ChatUserData> _users = [];
  bool _debugMode = true; // Toggle this to show/hide debug information
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Setup tabs based on user role
    _setupTabs();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadUsers();
  }

  void _setupTabs() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final isAdmin = chatProvider.isAdmin;
    final isCoach = chatProvider.isCoach;
    
    // Show All Users tab only to admins and coaches
    final int tabCount = (isAdmin || isCoach) ? 2 : 1;
    
    if (_debugMode) {
      debugPrint('Setting up tabs: isAdmin=$isAdmin, isCoach=$isCoach, tabCount=$tabCount');
    }
    
    _tabController = TabController(
      length: tabCount,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Load users from Firestore
  Future<void> _loadUsers() async {
    if (_currentUserId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'You need to be logged in to start a chat';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      if (_debugMode) {
        debugPrint('🔍 Loading users for chat, current user ID: $_currentUserId');
      }
      
      // Get coaches with valid userIds
      final coachDocs = await _firestore.collection('coaches').get();
      
      // Store valid coaches in this list
      final coaches = <ChatUserData>[];
      
      // Log debug info
      if (_debugMode) {
        debugPrint('🧠 Found ${coachDocs.docs.length} coaches in the coaches collection');
      }
      
      for (final doc in coachDocs.docs) {
        final data = doc.data();
        
        // Check for direct userId field
        String? userId = data['userId'] as String?;
        
        // If userId is not available, try to extract from associatedUser
        if (userId == null && data['associatedUser'] != null) {
          // Handle either map or DocumentReference
          if (data['associatedUser'] is Map) {
            userId = data['associatedUser']['id'] as String?;
          } else {
            // For DocumentReference type
            try {
              // First try to get the path segments
              final associatedUser = data['associatedUser'];
              if (associatedUser != null) {
                if (_debugMode) {
                  debugPrint('Associated user type: ${associatedUser.runtimeType}');
                }
                
                // Check if it's a DocumentReference
                if (associatedUser.toString().contains('DocumentReference')) {
                  // Extract ID from the path
                  final path = associatedUser.toString();
                  final pathSegments = path.split('/');
                  if (pathSegments.isNotEmpty) {
                    userId = pathSegments.last.replaceAll(')', '');
                    if (_debugMode) {
                      debugPrint('Extracted userId from reference path: $userId');
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('Error extracting userId from associatedUser: $e');
            }
          }
        }
        
        // Only include coaches with valid userIds
        if (userId != null && userId.isNotEmpty) {
          // Verify the userId exists in users collection
          final userDoc = await _firestore.collection('users').doc(userId).get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() ?? {};
            // Prioritize user document's fullName for coach display if available
            final String displayName = userData['fullName'] ?? data['name'] ?? 'Unknown Coach';
            
            coaches.add(ChatUserData(
              id: userId,
              name: displayName,
              userName: userData['username'] ?? '',
              fullName: userData['fullName'] ?? displayName,
              imageUrl: data['imageUrl'] ?? '',
              role: 'coach',
              specialization: data['specialization'] ?? '',
              status: userData['status'] ?? 'offline',
              coachId: doc.id,
            ));
            
            if (_debugMode) {
              debugPrint('✅ Added coach: $displayName with userId: $userId');
            }
          } else if (_debugMode) {
            debugPrint('⚠️ Coach ${data['name']} has userId $userId but no matching user document');
          }
        } else if (_debugMode) {
          debugPrint('❌ Coach ${data['name'] ?? doc.id} has no valid userId or associatedUser.id reference');
          if (data['associatedUser'] != null) {
            debugPrint('associatedUser exists but could not extract ID: ${data['associatedUser']}');
          }
        }
      }
      
      // Get ALL users instead of filtering by role
      final userDocs = await _firestore
          .collection('users')
          .get(); // Removed the restrictive filter
      
      if (_debugMode) {
        debugPrint('👤 Found ${userDocs.docs.length} total users in the users collection');
      }
      
      final List<ChatUserData> regularUsers = [];
      
      for (final doc in userDocs.docs) {
        // Skip current user
        if (doc.id == _currentUserId) continue;
        
        final data = doc.data();
        final String email = (data['email'] ?? '').toString();
        final bool isAdmin = data['isAdmin'] == true || (email.isNotEmpty && email.endsWith('@hmperform.com'));
        final bool isCoach = data['isCoach'] == true;
        final String role = isAdmin ? 'admin' : (isCoach ? 'coach' : (data['role'] ?? 'user'));
        
        // Prioritize fullName over username or other name fields
        final String fullName = data['fullName'] ?? '';
        final String username = data['username'] ?? '';
        final String displayName = fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : (data['name'] ?? 'Unknown User'));
        
        if (_debugMode) {
          debugPrint('📄 Processing user: $displayName, ID: ${doc.id}, Role: $role, Email: $email');
        }
        
        regularUsers.add(ChatUserData(
          id: doc.id,
          name: displayName,
          userName: username,
          fullName: fullName,
          imageUrl: data['profileImage'] ?? data['profileImageUrl'] ?? '',
          role: role,
          specialization: '',
          status: data['status'] ?? 'offline',
        ));
      }
      
      // Combine coaches and users, ensuring no duplicates by ID
      final Set<String> addedUserIds = coaches.map((coach) => coach.id).toSet();
      final nonDuplicateUsers = regularUsers.where((user) => !addedUserIds.contains(user.id)).toList();
      
      setState(() {
        _users = [...coaches, ...nonDuplicateUsers];
        _isLoading = false;
      });
      
      if (_debugMode) {
        debugPrint('🔢 TOTAL USERS LOADED: ${_users.length}');
        debugPrint('🧠 Coaches: ${coaches.length}');
        debugPrint('👤 Non-coach users: ${nonDuplicateUsers.length}');
        
        // Print the first few users for debugging
        final int numToPrint = _users.length > 5 ? 5 : _users.length;
        for (int i = 0; i < numToPrint; i++) {
          debugPrint('User ${i+1}: ${_users[i].name} (${_users[i].id}) - Role: ${_users[i].role}');
          debugPrint('   Fullname: ${_users[i].fullName}, Username: ${_users[i].userName}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load users: ${e.toString()}';
      });
    }
  }

  // Get filtered users based on search query and current tab
  List<ChatUserData> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      // If on coaches tab (index 0), show only coaches regardless of user role
      if (_tabController.index == 0) {
        final coaches = _users.where((user) => user.role == 'coach').toList();
        if (_debugMode) {
          debugPrint('Showing ${coaches.length} coaches in Coaches tab');
        }
        return coaches;
      } 
      
      // If on all users tab (index 1), show everyone
      // Regular users should never reach here since they only have the coaches tab
      if (_debugMode) {
        debugPrint('Showing all ${_users.length} users in All Users tab');
      }
      return _users;
    }
    
    // Apply search filter
    List<ChatUserData> baseUsers;
    if (_tabController.index == 0) {
      // Coaches tab - only show coaches
      baseUsers = _users.where((user) => user.role == 'coach').toList();
    } else {
      // All users tab - show everyone
      baseUsers = _users;
    }
    
    // Filter by search query - check both name and username fields
    final filteredResults = baseUsers.where((user) {
      return user.name.toLowerCase().contains(_searchQuery) || 
             user.userName.toLowerCase().contains(_searchQuery) ||
             user.fullName.toLowerCase().contains(_searchQuery);
    }).toList();
    
    if (_debugMode) {
      final tabName = _tabController.index == 0 ? 'Coaches' : 'All Users';
      debugPrint('Search: Found ${filteredResults.length} results for "$_searchQuery" in $tabName tab');
    }
    
    return filteredResults;
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final canViewAllUsers = chatProvider.isAdmin || chatProvider.isCoach;
    
    if (_debugMode) {
      debugPrint('Building NewChatScreen: isAdmin=${chatProvider.isAdmin}, isCoach=${chatProvider.isCoach}, canViewAllUsers=$canViewAllUsers');
      debugPrint('Tab controller: length=${_tabController.length}, index=${_tabController.index}');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
        bottom: canViewAllUsers ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Coaches'),
            Tab(text: 'All Users'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          onTap: (index) {
            // Force setState to refresh the list with the new tab selection
            setState(() {});
            if (_debugMode) {
              debugPrint('Tab changed to: ${index == 0 ? "Coaches" : "All Users"}');
            }
          },
        ) : null,
        actions: [
          if (_debugMode)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers,
              tooltip: 'Reload Users',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          if (_debugMode && _currentUserId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Current User ID: $_currentUserId',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          if (!chatProvider.isAdmin && !chatProvider.isCoach)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'As a regular user, you can only start conversations with coaches.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadUsers,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : canViewAllUsers
                        ? TabBarView(
                            controller: _tabController,
                            children: [
                              // Coaches Tab
                              _buildUserList(showOnlyCoaches: true),
                              // All Users Tab
                              _buildUserList(showOnlyCoaches: false),
                            ],
                          )
                        : _buildUserList(showOnlyCoaches: true),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList({required bool showOnlyCoaches}) {
    final users = showOnlyCoaches
        ? _users.where((user) => user.role == 'coach').toList()
        : _filteredUsers;

    if (_debugMode) {
      final tabName = showOnlyCoaches ? "Coaches" : "All Users";
      debugPrint('Building $tabName list with ${users.length} users');
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showOnlyCoaches ? Icons.sports_kabaddi : Icons.people_alt_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              showOnlyCoaches 
                ? 'No coaches found' 
                : 'No users found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                },
                child: const Text('Clear Search'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user.imageUrl.isNotEmpty ? NetworkImage(user.imageUrl) : null,
              child: user.imageUrl.isEmpty
                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                  : null,
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.userName.isNotEmpty && user.userName != user.name && user.fullName != user.userName)
                  Text(
                    '@${user.userName}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: user.status == 'online' ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.status == 'online' ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: user.status == 'online' ? Colors.green : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.role.capitalize(),
                      style: TextStyle(
                        color: user.role == 'admin' 
                          ? Colors.purple 
                          : (user.role == 'coach' ? Colors.blue : Colors.black54),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: user.role == 'coach'
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Coach', style: TextStyle(color: Colors.blue)),
                  )
                : user.role == 'admin'
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Admin', style: TextStyle(color: Colors.purple)),
                      )
                    : null,
            onTap: () => _startChat(user),
          ),
        );
      },
    );
  }

  // Start a chat with a user
  void _startChat(ChatUserData user) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Check if the current user can chat with the selected user
    if (!chatProvider.isAdmin && !chatProvider.isCoach && user.role != 'coach') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As a regular user, you can only start conversations with coaches'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      if (_debugMode) {
        debugPrint('Attempting to create/find chat with user: ${user.name} (${user.id})');
      }
      
      // Create a new chat or get existing chat ID
      final chatId = await chatProvider.createNewChat(user.id);
      
      if (_debugMode) {
        debugPrint('Chat creation result: $chatId');
      }
      
      if (mounted && chatId != null) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Navigate to chat screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatId: chatId),
          ),
        );
      } else {
        // Handle error
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create chat')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating chat: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Helper class for user data
class ChatUserData {
  final String id;
  final String name;
  final String userName;
  final String fullName;
  final String imageUrl;
  final String role;
  final String specialization;
  final String status;
  final String? coachId;

  ChatUserData({
    required this.id,
    required this.name,
    required this.userName,
    required this.fullName,
    required this.imageUrl,
    required this.role,
    required this.specialization,
    required this.status,
    this.coachId,
  });
} 