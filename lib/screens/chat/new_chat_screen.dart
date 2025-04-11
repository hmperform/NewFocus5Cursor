import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  _NewChatScreenState createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Initial load for admins
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      if (!chatProvider.isCurrentUserLoading && chatProvider.isAdmin) {
         // Load all users if admin and search results are currently empty
         // Check searchResults length to avoid redundant calls if navigating back
         if (chatProvider.searchResults.isEmpty) {
            chatProvider.searchUsers(''); 
         }
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _startChat(ChatUser user) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Check if user can start this chat
    if (!chatProvider.canStartChatWith(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only start conversations with coaches'),
          backgroundColor: Colors.red,
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
      // Create or get existing chat
      final chatId = await chatProvider.createChat([user.userId]);
      
      // Hide loading indicator
      if (context.mounted) Navigator.pop(context);
      
      if (chatId != null && context.mounted) {
        // Navigate to chat screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatId: chatId),
          ),
        );
      } else {
        throw Exception('Failed to create chat');
      }
    } catch (e) {
      // Hide loading indicator
      if (context.mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }
  
  // Navigate to coach profile if user is a coach
  void _viewCoachProfile(ChatUser user) async {
    if (!user.isCoach || user.coachId == null) return; // Use coachId check
    
    // No need to fetch details again, just navigate if coachId exists
    Navigator.pushNamed(context, '/coach', arguments: user.coachId);
  }
  
  @override
  Widget build(BuildContext context) {
    // Use watch to rebuild when provider notifies listeners
    final chatProvider = context.watch<ChatProvider>(); 
    final isAdminOrCoach = chatProvider.isAdmin || chatProvider.isCoach;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
         actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Allow manual refresh, especially for admins to reload all users
              chatProvider.searchUsers(_searchController.text);
            },
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isAdminOrCoach && !chatProvider.isCurrentUserLoading)
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isAdminOrCoach ? 'Search all users...' : 'Search coaches...',
                prefixIcon: const Icon(Icons.search),
                 suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // Trigger search with empty query (loads all for admin)
                          chatProvider.searchUsers(''); 
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              textInputAction: TextInputAction.search,
              // Trigger search on every change
              onChanged: (query) {
                chatProvider.searchUsers(query);
              },
            ),
          ),
          Expanded(
            // Use provider state for loading and results
            child: chatProvider.isSearching 
                ? const Center(child: CircularProgressIndicator())
                : chatProvider.searchResults.isEmpty
                    ? Center(
                        child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(Icons.people_outline, size: 60, color: Colors.grey),
                             SizedBox(height: 16),
                             Text(
                               _searchController.text.isEmpty
                                  ? (chatProvider.isAdmin ? 'No users found' : 'Search for coaches')
                                  : 'No users matching "${_searchController.text}"',
                                textAlign: TextAlign.center,
                             ),
                             if (_searchController.text.isNotEmpty)
                               Padding(
                                 padding: const EdgeInsets.only(top: 16.0),
                                 child: ElevatedButton(
                                   onPressed: () {
                                      _searchController.clear();
                                      chatProvider.searchUsers(''); 
                                   },
                                   child: const Text('Clear Search'),
                                 ),
                               ),
                           ],
                        ),
                      )
                    : ListView.builder(
                        // Use provider state for item count and data
                        itemCount: chatProvider.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = chatProvider.searchResults[index];
                          final canChat = chatProvider.canStartChatWith(user);
                          
                          return ListTile(
                             leading: CircleAvatar(
                              // Handle potential null avatarUrl gracefully
                              backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(user.fullName.isNotEmpty ? user.fullName : user.name)), // Prefer fullName
                                if (user.isCoach)
                                   Padding(
                                     padding: const EdgeInsets.only(left: 8.0),
                                     child: Chip(
                                        label: Text('Coach'),
                                        labelStyle: TextStyle(fontSize: 10, color: Colors.blue.shade900),
                                        backgroundColor: Colors.blue.shade100,
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                   ),
                                 if (user.isAdmin) // Add Admin chip
                                   Padding(
                                     padding: const EdgeInsets.only(left: 8.0),
                                     child: Chip(
                                        label: Text('Admin'),
                                        labelStyle: TextStyle(fontSize: 10, color: Colors.purple.shade900),
                                        backgroundColor: Colors.purple.shade100,
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                   ),
                              ],
                            ),
                            subtitle: _buildUserStatus(user),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (user.isCoach && user.coachId != null)
                                  IconButton(
                                    icon: const Icon(Icons.person, color: Colors.blue),
                                    onPressed: () => _viewCoachProfile(user),
                                    tooltip: 'View coach profile',
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.chat),
                                  onPressed: canChat ? () => _startChat(user) : null,
                                  color: canChat ? Colors.blue : Colors.grey,
                                  tooltip: canChat 
                                      ? 'Start chat' 
                                      : (chatProvider.isAdmin ? 'Start chat' : 'You can only chat with coaches'), // Update tooltip for admin
                                ),
                              ],
                            ),
                            onTap: canChat ? () => _startChat(user) : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatus(ChatUser user) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (user.status) {
      case UserStatus.online:
        statusIcon = Icons.circle;
        statusColor = Colors.green;
        statusText = 'Online';
        break;
      case UserStatus.away:
        statusIcon = Icons.circle;
        statusColor = Colors.orange;
        statusText = 'Away';
        break;
      case UserStatus.offline:
      default:
        statusIcon = Icons.circle_outlined; // Or Icons.circle with grey
        statusColor = Colors.grey;
        statusText = 'Offline';
        break;
    }

    return Row(
      children: [
        Icon(statusIcon, size: 12, color: statusColor),
        const SizedBox(width: 4),
        Text(statusText, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
} 