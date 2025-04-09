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

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<ChatUserData> _users = [];
  bool _debugMode = true; // Toggle this to show/hide debug information

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      // Get coaches with valid userIds
      final coachDocs = await _firestore.collection('coaches').get();
      
      // Store valid coaches in this list
      final coaches = <ChatUserData>[];
      
      // Log debug info
      if (_debugMode) {
        debugPrint('Found ${coachDocs.docs.length} coaches in the coaches collection');
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
            coaches.add(ChatUserData(
              id: userId,
              name: data['name'] ?? 'Unknown Coach',
              imageUrl: data['imageUrl'] ?? '',
              role: 'coach',
              specialization: data['specialization'] ?? '',
              status: userDoc.data()?['status'] ?? 'offline',
              coachId: doc.id,
            ));
            
            if (_debugMode) {
              debugPrint('Added coach: ${data['name']} with userId: $userId');
            }
          } else if (_debugMode) {
            debugPrint('Coach ${data['name']} has userId $userId but no matching user document');
          }
        } else if (_debugMode) {
          debugPrint('Coach ${data['name'] ?? doc.id} has no valid userId or associatedUser.id reference');
          if (data['associatedUser'] != null) {
            debugPrint('associatedUser exists but could not extract ID: ${data['associatedUser']}');
          }
        }
      }
      
      // Get regular users
      final userDocs = await _firestore
          .collection('users')
          .where('role', isNotEqualTo: 'admin') // Exclude admins
          .get();
      
      if (_debugMode) {
        debugPrint('Found ${userDocs.docs.length} non-admin users in the users collection');
      }
      
      final users = userDocs.docs
          .where((doc) => doc.id != _currentUserId) // Exclude current user
          .map((doc) {
            final data = doc.data();
            return ChatUserData(
              id: doc.id,
              name: data['name'] ?? 'Unknown User',
              imageUrl: data['profileImage'] ?? '',
              role: data['role'] ?? 'user',
              specialization: '',
              status: data['status'] ?? 'offline',
            );
          })
          .toList();
      
      setState(() {
        _users = [...coaches, ...users];
        _isLoading = false;
      });
      
      if (_debugMode) {
        debugPrint('Total users available for chat: ${_users.length}');
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load users: ${e.toString()}';
      });
    }
  }

  // Get filtered users based on search query
  List<ChatUserData> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    return _users.where((user) {
      return user.name.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
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
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No users found to chat with'
                                        : 'No users matching "$_searchQuery"',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (_searchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                      child: const Text('Clear Search'),
                                    ),
                                  ],
                                  if (_users.isEmpty) ...[
                                    const SizedBox(height: 24),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                                      child: Text(
                                        'When you have teammates or coaches in the system, '
                                        'you\'ll be able to start conversations with them here!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                                      child: Text(
                                        'Note: Coaches must have a valid userId field that links '
                                        'to a document in the users collection',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user.imageUrl.isNotEmpty
                                      ? NetworkImage(user.imageUrl)
                                      : null,
                                  child: user.imageUrl.isEmpty
                                      ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(user.name),
                                    ),
                                    if (_debugMode)
                                      Text(
                                        user.id.substring(0, 4),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: user.status == 'online'
                                            ? Colors.green
                                            : user.status == 'away'
                                                ? Colors.orange
                                                : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.status == 'online'
                                          ? 'Online'
                                          : user.status == 'away'
                                              ? 'Away'
                                              : 'Offline',
                                    ),
                                    if (user.role == 'coach') ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Coach',
                                          style: TextStyle(fontSize: 10, color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () => _startChat(user),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // Start a chat with a user
  void _startChat(ChatUserData user) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
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

// Helper class for user data
class ChatUserData {
  final String id;
  final String name;
  final String imageUrl;
  final String role;
  final String specialization;
  final String status;
  final String? coachId;

  ChatUserData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.role,
    required this.specialization,
    required this.status,
    this.coachId,
  });
} 