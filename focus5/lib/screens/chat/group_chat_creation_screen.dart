import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_models.dart';
import 'chat_screen.dart';

class GroupChatCreationScreen extends StatefulWidget {
  const GroupChatCreationScreen({Key? key}) : super(key: key);

  @override
  State<GroupChatCreationScreen> createState() => _GroupChatCreationScreenState();
}

class _GroupChatCreationScreenState extends State<GroupChatCreationScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isCreatingChat = false;
  List<ChatUserData> _users = [];
  final Set<String> _selectedUserIds = {};
  final bool _debugMode = true;

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
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final users = await chatProvider.getAllUsers();
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
      
      if (_debugMode) {
        debugPrint('Loaded ${_users.length} users for group chat creation');
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ChatUserData> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    return _users.where((user) {
      return user.name.toLowerCase().contains(_searchQuery) || 
             user.userName.toLowerCase().contains(_searchQuery) ||
             user.fullName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _createGroupChat() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingChat = true;
    });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chatId = await chatProvider.createGroupChat(
        participantIds: _selectedUserIds.toList(),
        groupName: groupName,
      );

      if (_debugMode) {
        debugPrint('Created group chat: $chatId');
      }

      if (mounted) {
        // Hide loading indicator
        setState(() {
          _isCreatingChat = false;
        });

        if (chatId != null) {
          // Navigate to chat screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatId: chatId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create group chat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating group chat: $e');
      if (mounted) {
        setState(() {
          _isCreatingChat = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group Chat'),
      ),
      body: _isCreatingChat
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Users (${_selectedUserIds.length} selected)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_selectedUserIds.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedUserIds.clear();
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredUsers.isEmpty
                          ? const Center(
                              child: Text('No users found'),
                            )
                          : ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                final isSelected = _selectedUserIds.contains(user.id);
                                
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (_) => _toggleUserSelection(user.id),
                                  title: Text(
                                    user.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (user.userName.isNotEmpty && user.userName != user.name)
                                        Text(
                                          '@${user.userName}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      Text(
                                        user.role.capitalize(),
                                        style: TextStyle(
                                          color: user.role == 'admin' 
                                            ? Colors.purple 
                                            : (user.role == 'coach' ? Colors.blue : Colors.black54),
                                        ),
                                      ),
                                    ],
                                  ),
                                  secondary: CircleAvatar(
                                    backgroundImage: user.imageUrl.isNotEmpty 
                                        ? NetworkImage(user.imageUrl)
                                        : null,
                                    child: user.imageUrl.isEmpty
                                        ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                                        : null,
                                  ),
                                  activeColor: Colors.green,
                                  checkColor: Colors.white,
                                  controlAffinity: ListTileControlAffinity.leading,
                                );
                              },
                            ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _selectedUserIds.isEmpty || _groupNameController.text.trim().isEmpty
                        ? null 
                        : _createGroupChat,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(
                      'Create Group Chat with ${_selectedUserIds.length} Users',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 