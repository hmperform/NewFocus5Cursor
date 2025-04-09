import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_models.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = true;
  final bool _debugMode = true;

  @override
  void initState() {
    super.initState();
    _initChatProvider();
    // Debug Trevor Conner's coach info
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).debugCoachInfo('coach-001');
    });
  }

  Future<void> _initChatProvider() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToNewChat(context),
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final chats = chatProvider.chats;
                
                if (_debugMode) {
                  debugPrint('Building chat list: ${chats.length} chats');
                }
                
                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.forum_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _navigateToNewChat(context),
                          child: const Text('Start a new chat'),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    
                    // Find other participant for 1:1 chats
                    final otherUserId = !chat.isGroupChat
                        ? chat.participantIds.firstWhere(
                            (id) => id != chatProvider.currentUserId,
                            orElse: () => '',
                          )
                        : '';
                    
                    return FutureBuilder<ChatUser?>(
                      future: otherUserId.isNotEmpty
                          ? chatProvider.getUserDetails(otherUserId)
                          : null,
                      builder: (context, snapshot) {
                        if (_debugMode && snapshot.connectionState == ConnectionState.waiting) {
                          debugPrint('Loading user details for: $otherUserId');
                        }
                        
                        if (_debugMode && snapshot.hasError) {
                          debugPrint('Error loading user details: ${snapshot.error}');
                        }
                        
                        if (_debugMode && snapshot.hasData) {
                          debugPrint('Loaded user details: ${snapshot.data?.name}');
                        }
                        
                        String name;
                        if (chat.isGroupChat) {
                          name = chat.groupName ?? 'Group Chat';
                        } else if (snapshot.connectionState == ConnectionState.waiting) {
                          name = 'Loading...';
                        } else if (snapshot.hasData && snapshot.data != null) {
                          name = snapshot.data!.name;
                        } else {
                          // Fallback to showing user ID if name can't be loaded
                          name = 'User $otherUserId';
                          
                          // Attempt to reload user details if we received null
                          if (snapshot.connectionState == ConnectionState.done && 
                              !snapshot.hasError && 
                              snapshot.data == null) {
                            // Force clear cache and reload
                            Future.microtask(() {
                              chatProvider.clearUserCache(otherUserId);
                              setState(() {});
                            });
                          }
                        }
                        
                        String? avatarUrl = chat.isGroupChat
                            ? chat.groupAvatarUrl
                            : snapshot.data?.avatarUrl;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: chat.hasUnreadMessages
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Text(
                                chat.lastMessageTime != null
                                    ? timeago.format(chat.lastMessageTime)
                                    : '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: chat.hasUnreadMessages
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.lastMessageText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: chat.hasUnreadMessages
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: chat.hasUnreadMessages
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              if (chat.hasUnreadMessages)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => _navigateToChat(context, chat.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  void _navigateToNewChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewChatScreen()),
    );
  }

  void _navigateToChat(BuildContext context, String chatId) {
    if (_debugMode) {
      debugPrint('Navigating to chat: $chatId');
    }
    
    // Force chat provider to reset and reload messages for this chat
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.resetAndReloadMessages(chatId);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chatId),
      ),
    ).then((_) {
      // Force refresh when returning to this screen
      if (_debugMode) {
        debugPrint('Returned from chat screen, refreshing chat list');
      }
      setState(() {});
    });
  }
} 