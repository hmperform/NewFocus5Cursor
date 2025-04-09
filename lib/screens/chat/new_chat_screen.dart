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
  String _searchQuery = '';
  List<ChatUser> _searchResults = [];
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    
    if (_searchQuery.length >= 2) {
      _performSearch();
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }
  
  Future<void> _performSearch() async {
    if (_searchQuery.length < 2) return;
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await Provider.of<ChatProvider>(context, listen: false)
          .searchUsers(_searchQuery);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $e')),
      );
    }
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
    if (!user.isCoach || !user.hasCoachProfile) return;
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final coachDetails = await chatProvider.getCoachDetails(user.userId);
    
    if (coachDetails != null && mounted) {
      Navigator.pushNamed(context, '/coach', arguments: user.coachId);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final isAdminOrCoach = chatProvider.isAdmin || chatProvider.isCoach;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
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
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_searchQuery.length < 2)
            const Expanded(
              child: Center(
                child: Text('Type at least 2 characters to search'),
              ),
            )
          else if (_searchResults.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No users found'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final canChat = chatProvider.canStartChatWith(user);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: user.profileImageUrl == null
                          ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(user.name)),
                        if (user.isCoach)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Coach',
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                      ],
                    ),
                    subtitle: _buildUserStatus(user),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user.isCoach && user.hasCoachProfile)
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
                              : 'You can only chat with coaches',
                        ),
                      ],
                    ),
                    onTap: canChat ? () => _startChat(user) : null,
                    enabled: canChat,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildUserStatus(ChatUser user) {
    if (user.isOnline) {
      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text('Online'),
        ],
      );
    } else if (user.lastSeen != null) {
      return Text('Last seen ${_formatLastSeen(user.lastSeen!)}');
    } else {
      return const Text('Offline');
    }
  }
  
  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
} 