import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';  // Add this import for ImageFilter
import '../../models/chat_models.dart';
import '../../providers/chat_provider.dart';
import 'package:flutter/rendering.dart';
import 'widgets/content_sharing_screen.dart';
import '../../main.dart'; // Import main.dart to access navigatorKey
// Import providers needed for fetching content
import '../../providers/content_provider.dart'; 
import '../../providers/audio_provider.dart'; 
import '../../models/content_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  bool _hasAttemptedLoad = false;
  final String _componentId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('ChatScreen[$_componentId]: Initializing');
    
    // Debug specific coach
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).debugCoachInfo('coach-001');
    });
    
    _loadMessages();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This method gets called when the component is inserted into the tree
    // or when the dependencies change (like Provider updates)
    debugPrint('ChatScreen $_componentId: didChangeDependencies called for chat ${widget.chatId}');
  }
  
  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('ChatScreen $_componentId: didUpdateWidget called for chat ${widget.chatId}');
    
    // If the chat ID changed, reload messages
    if (oldWidget.chatId != widget.chatId) {
      debugPrint('ChatScreen $_componentId: Chat ID changed from ${oldWidget.chatId} to ${widget.chatId}');
      _loadMessages();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('ChatScreen $_componentId: App lifecycle changed to $state');
    
    // When app comes back to foreground, refresh messages
    if (state == AppLifecycleState.resumed && _isInitialized) {
      debugPrint('ChatScreen $_componentId: App resumed, refreshing messages');
      // Use a gentler refresh that doesn't clear existing messages
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadMessages(widget.chatId);
    }
  }

  Future<void> _loadMessages() async {
    if (_hasAttemptedLoad) {
      debugPrint('ChatScreen $_componentId: Already attempted to load messages, skipping');
      return;
    }
    
    _hasAttemptedLoad = true;
    
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      // Check if we already have messages
      final existingMessages = chatProvider.getMessagesForChat(widget.chatId);
      if (existingMessages.isNotEmpty) {
        debugPrint('ChatScreen $_componentId: Already have ${existingMessages.length} messages, just marking as read');
        await chatProvider.markChatAsRead(widget.chatId);
        
        if (mounted && !_isInitialized) {
          setState(() {
            _isInitialized = true;
          });
        }
        return;
      }
      
      // Check if this chat exists in the provider
      final existingChat = chatProvider.chats.any((c) => c.id == widget.chatId);
      if (!existingChat) {
        debugPrint('ChatScreen $_componentId: Chat ${widget.chatId} not found in provider, this might need special handling');
      } else {
        debugPrint('ChatScreen $_componentId: Chat ${widget.chatId} found in provider');
      }
      
      // Mark chat as read first
      await chatProvider.markChatAsRead(widget.chatId);
      
      // Force a message refresh to ensure we see latest messages
      debugPrint('ChatScreen $_componentId: Loading messages for chat: ${widget.chatId}');
      await chatProvider.loadMessages(widget.chatId);
      
      // Wait a moment to let Firestore queries complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if we got any messages
      final messages = chatProvider.getMessagesForChat(widget.chatId);
      debugPrint('ChatScreen $_componentId: Loaded ${messages.length} messages for chat: ${widget.chatId}');
      
      // If we didn't get any messages, try one more time with a longer delay
      if (messages.isEmpty) {
        debugPrint('ChatScreen $_componentId: No messages found, trying one more time...');
        await Future.delayed(const Duration(seconds: 1));
        await chatProvider.resetAndReloadMessages(widget.chatId);
        
        final retryMessages = chatProvider.getMessagesForChat(widget.chatId);
        debugPrint('ChatScreen $_componentId: After retry, found ${retryMessages.length} messages for chat: ${widget.chatId}');
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('ChatScreen $_componentId Error: Failed to initialize chat: $e');
      debugPrint('ChatScreen $_componentId Error: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Still mark as initialized to show error state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    debugPrint('ChatScreen $_componentId: Disposing for chat ${widget.chatId}');
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final content = _messageController.text.trim();
    _messageController.clear();
    
    try {
      debugPrint('ChatScreen: Preparing to send message: "$content" to chat: ${widget.chatId}');
      debugPrint('ChatScreen: Is widget mounted? ${mounted}');
      
      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending message...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      debugPrint('ChatScreen: Calling ChatProvider.sendMessage()');
      await Provider.of<ChatProvider>(context, listen: false).sendMessage(
        widget.chatId,
        content,
      );
      
      debugPrint('ChatScreen: Message sent successfully, now scrolling to bottom');
      
      // Scroll to bottom after sending message
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          debugPrint('ChatScreen: Scrolling to bottom of chat');
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          debugPrint('ChatScreen: Cannot scroll, _scrollController has no clients');
        }
      });
      
      // Success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent!'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Enhanced error logging
      debugPrint('>>> CHAT SCREEN ERROR: Failed to send message in chat ${widget.chatId}. Error: $e'); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: ${e.toString()}'),
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
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final chat = chatProvider.chats.firstWhere(
              (chat) => chat.id == widget.chatId,
              orElse: () => Chat(
                id: '',
                participantIds: [],
                lastMessageText: '',
                lastMessageTime: DateTime.now(),
                lastMessageSenderId: '',
                hasUnreadMessages: false,
                isGroupChat: false,
              ),
            );
            
            debugPrint('ChatScreen: Chat header for ${widget.chatId}, chat found: ${chat.id.isNotEmpty}');
            if (chat.id.isEmpty) {
              debugPrint('ChatScreen: Chat ${widget.chatId} not found in chats list, checking directly in Firestore');
              // Try to reload the chat data
              Future.microtask(() => chatProvider.resetAndReloadMessages(widget.chatId));
              return const Text('Loading...');
            }
            
            if (chat.isGroupChat) {
              return Text(chat.groupName ?? 'Group Chat');
            } else {
              // Find the other user in a 1:1 chat
              final otherUserId = chat.participantIds.firstWhere(
                (id) => id != chatProvider.currentUserId,
                orElse: () => '',
              );
              
              debugPrint('ChatScreen $_componentId: Other user ID: $otherUserId');
              if (otherUserId.isEmpty) {
                return const Text('Chat');
              }
              
              return FutureBuilder<ChatUser?>(
                future: chatProvider.getUserDetails(otherUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading...');
                  }
                  
                  final user = snapshot.data;
                  if (user == null) {
                    // Try one more check for a coach-user mapping
                    if (otherUserId.startsWith('coach-')) {
                      return Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person), radius: 16),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Coach')),
                        ],
                      );
                    }
                    return const Text('Chat');
                  }
                  
                  return Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        child: user.avatarUrl.isEmpty
                            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                            : null,
                        radius: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              user.status == UserStatus.online
                                  ? 'Online'
                                  : user.status == UserStatus.away
                                      ? 'Away'
                                      : 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                color: user.status == UserStatus.online
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show chat info/settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat info coming soon')),
              );
            },
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final messages = chatProvider.getMessagesForChat(widget.chatId);
                      debugPrint('ChatScreen $_componentId: Rendering ${messages.length} messages for chat: ${widget.chatId}');
                      
                      // Print first and last message for debugging
                      if (messages.isNotEmpty) {
                        final firstMsg = messages.first;
                        final lastMsg = messages.last;
                        debugPrint('ChatScreen $_componentId: First message: ${firstMsg.id} - ${firstMsg.content.substring(0, firstMsg.content.length > 20 ? 20 : firstMsg.content.length)} from ${firstMsg.senderId}');
                        debugPrint('ChatScreen $_componentId: Last message: ${lastMsg.id} - ${lastMsg.content.substring(0, lastMsg.content.length > 20 ? 20 : lastMsg.content.length)} from ${lastMsg.senderId}');
                      }
                      
                      if (messages.isEmpty) {
                        // Check if we have a chat in the provider
                        final chatExists = chatProvider.chats.any((c) => c.id == widget.chatId);
                        if (!chatExists) {
                          debugPrint('ChatScreen $_componentId: Chat ${widget.chatId} not found in provider. Forcing a reload.');
                          // Try to force a reload
                          Future.microtask(() {
                            chatProvider.resetAndReloadMessages(widget.chatId);
                          });
                          
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading chat...'),
                              ],
                            ),
                          );
                        }
                        
                        // Add manual refresh button for empty chats
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No messages yet. Start the conversation!',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isInitialized = false;
                                    _hasAttemptedLoad = false;
                                  });
                                  // Try to force reload messages
                                  Future.delayed(const Duration(milliseconds: 100), () async {
                                    await _loadMessages();
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reload messages'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // Show refresh indicator and message list together
                      return Stack(
                        children: [
                          // The actual message list
                          ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.senderId == chatProvider.currentUserId;
                              
                              // Scroll to bottom when new messages arrive if we're at the last item
                              if (index == messages.length - 1) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (_scrollController.hasClients) {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
                              }
                              
                              return FutureBuilder<ChatUser?>(
                                future: chatProvider.getUserDetails(message.senderId),
                                builder: (context, snapshot) {
                                  String displayName = 'Loading...';
                                  String? avatarUrl;
                                  bool isNameLoading = snapshot.connectionState == ConnectionState.waiting;
                                  
                                  // Get user details from snapshot or fallback to ID-based display
                                  if (snapshot.hasData && snapshot.data != null) {
                                    final user = snapshot.data!;
                                    if (message.senderId.startsWith('coach-')) {
                                      // For coaches, use "Coach" followed by their name
                                      displayName = 'Coach ${user.name}';
                                    } else {
                                      // For regular users, use their fullName
                                      displayName = user.fullName ?? user.name;
                                    }
                                    avatarUrl = user.avatarUrl;
                                  } else if (snapshot.connectionState == ConnectionState.done) {
                                    // If we're done loading but no data, use the ID as fallback
                                    if (message.senderId.startsWith('coach-')) {
                                      // For coach IDs, show a nicer format
                                      displayName = 'Coach ${message.senderId.replaceAll('coach-', '')}';
                                    } else {
                                      // For regular users, use a truncated ID
                                      displayName = message.senderId.length > 8
                                          ? 'User ${message.senderId.substring(0, 8)}...'
                                          : 'User ${message.senderId}';
                                    }
                                  }
                                  
                                  // Log user info loading for debugging
                                  if (isNameLoading) {
                                    debugPrint('ChatScreen $_componentId: Loading user details for sender: ${message.senderId}');
                                  } else {
                                    debugPrint('ChatScreen $_componentId: Displaying name "$displayName" for sender: ${message.senderId}');
                                  }
                                  
                                  // Shortened avatar rendering
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: isMe 
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isMe) ...[
                                          CircleAvatar(
                                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                                ? NetworkImage(avatarUrl)
                                                : null,
                                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                                ? Text(
                                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                                    style: TextStyle(
                                                      color: isNameLoading ? Colors.grey : Colors.white,
                                                    ),
                                                  )
                                                : null,
                                            radius: 16,
                                            backgroundColor: isNameLoading ? Colors.grey[300] : null,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        
                                        // Rest of the message UI remains the same...
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: isMe
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                            children: [
                                              if (!isMe)
                                                Text(
                                                  displayName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: isNameLoading ? Colors.grey[400] : Colors.grey[700],
                                                    fontStyle: isNameLoading ? FontStyle.italic : FontStyle.normal,
                                                  ),
                                                ),
                                              GestureDetector(
                                                onLongPress: () => _showReactionMenu(context, message),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isMe ? Colors.blue : Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      if (message.sharedContent != null) ...[
                                                        // Shared content card
                                                        Container(
                                                          margin: const EdgeInsets.only(bottom: 8),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.circular(12),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.black.withOpacity(0.1),
                                                                blurRadius: 4,
                                                                offset: const Offset(0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(12),
                                                            child: Material(
                                                              color: Colors.transparent,
                                                              child: InkWell(
                                                                onTap: () {
                                                                  _openSharedContent(message.sharedContent!);
                                                                },
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    if (message.sharedContent!.thumbnailUrl != null &&
                                                                        message.sharedContent!.thumbnailUrl!.isNotEmpty)
                                                                      Image.network(
                                                                        message.sharedContent!.thumbnailUrl!,
                                                                        height: 100,
                                                                        width: double.infinity,
                                                                        fit: BoxFit.cover,
                                                                        errorBuilder: (context, error, stackTrace) {
                                                                          return Container(
                                                                            height: 100,
                                                                            color: Colors.grey.shade300,
                                                                            child: Center(
                                                                              child: Icon(
                                                                                message.sharedContent!.contentType == 'course'
                                                                                    ? Icons.school
                                                                                    : message.sharedContent!.contentType == 'module'
                                                                                        ? Icons.headphones
                                                                                        : Icons.article,
                                                                                size: 32,
                                                                                color: Colors.grey.shade700,
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                      ),
                                                                    Padding(
                                                                      padding: const EdgeInsets.all(8),
                                                                      child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              Icon(
                                                                                message.sharedContent!.contentType == 'course'
                                                                                    ? Icons.school
                                                                                    : message.sharedContent!.contentType == 'module'
                                                                                        ? Icons.headphones
                                                                                        : Icons.article,
                                                                                size: 16,
                                                                                color: Colors.grey.shade700,
                                                                              ),
                                                                              const SizedBox(width: 8),
                                                                              Text(
                                                                                message.sharedContent!.contentType.toUpperCase(),
                                                                                style: TextStyle(
                                                                                  fontSize: 12,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: Colors.grey.shade700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          const SizedBox(height: 6),
                                                                          Text(
                                                                            message.sharedContent!.title,
                                                                            style: const TextStyle(
                                                                              fontSize: 14,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Colors.black,
                                                                            ),
                                                                            maxLines: 2,
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                          const SizedBox(height: 4),
                                                                          Text(
                                                                            message.sharedContent!.description,
                                                                            style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: Colors.grey.shade800,
                                                                            ),
                                                                            maxLines: 2,
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                      // Regular message text
                                                      if (message.content.isNotEmpty)
                                                        Text(
                                                    message.content,
                                                    style: TextStyle(
                                                      color: isMe ? Colors.white : Colors.black,
                                                    ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Message timestamp and read state
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _formatTime(message.timestamp),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  if (isMe) ...[
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      message.isRead 
                                                          ? Icons.done_all
                                                          : Icons.done,
                                                      size: 12,
                                                      color: message.isRead 
                                                          ? Colors.blue
                                                          : Colors.grey,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              // Display reactions if there are any
                                              if (message.reactions != null && message.reactions!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Wrap(
                                                    spacing: 4,
                                                    children: message.reactions!.entries.map((entry) {
                                                      return GestureDetector(
                                                        onTap: () => _toggleReaction(message.id, entry.key),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: entry.value.contains(chatProvider.currentUserId)
                                                                ? Colors.blue.withOpacity(0.2)
                                                                : Colors.grey.shade200,
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(entry.key),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                entry.value.length.toString(),
                                                                style: const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.grey,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        
                                        if (isMe) const SizedBox(width: 8),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          
                          // Pull to refresh capability for manual refresh
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () async {
                                  // Show loading indicator
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Refreshing messages...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                  
                                  await chatProvider.loadMessages(widget.chatId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh, size: 16, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text('Pull to refresh', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                // Message input bar with glassmorphic effect
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          children: [
                            // Attachment button
                            IconButton(
                              icon: Icon(
                                Icons.attach_file,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Attachments coming soon!'),
                                  ),
                                );
                              },
                            ),
                            // Share Content button for admins and coaches
                            Consumer<ChatProvider>(
                              builder: (context, chatProvider, child) {
                                // Only show for admins and coaches
                                if (chatProvider.isAdmin || chatProvider.isCoach) {
                                  return IconButton(
                                    icon: Icon(
                                      Icons.share,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: () {
                                      _showContentSharingDialog(context);
                                    },
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                            // Message text field
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                onSubmitted: (text) => _sendMessage(),
                              ),
                            ),
                            // Send button
                            IconButton(
                              icon: Icon(
                                Icons.send,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  void _showReactionMenu(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'React to message',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  '👍', '❤️', '😂', '😮', '😥', '🔥', '👏', '🎯'
                ].map((emoji) => InkWell(
                  onTap: () {
                    _toggleReaction(message.id, emoji);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _toggleReaction(String messageId, String reaction) async {
    try {
      await Provider.of<ChatProvider>(context, listen: false)
          .addReactionToMessage(widget.chatId, messageId, reaction);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding reaction: ${e.toString()}')),
        );
      }
    }
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  // Method to open shared content - now async to fetch data
  Future<void> _openSharedContent(SharedContent sharedContent) async {
    final contentType = sharedContent.contentType;
    final contentId = sharedContent.contentId;
    final navigator = navigatorKey.currentState; // Use global navigator

    if (navigator == null) {
      debugPrint('Error: navigatorKey.currentState is null!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigation error: Could not get navigator state.')),
        );
      }
      return;
    }

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    try {
      debugPrint('Opening shared content: $contentType with ID: $contentId');

      // Different fetching and navigation based on content type
      switch (contentType) {
        case 'course':
          // TODO: Implement fetching course details if needed
          // Assuming CourseDetailScreen takes courseId and fetches itself
          navigator.pop(); // Dismiss loading dialog
          navigator.pushNamed('/course-details', arguments: contentId);
          break;
          
        case 'module':
          // Fetch DailyAudio data
          // Assuming AudioProvider or similar can fetch by ID
          // Note: Providers might not be directly accessible here if ChatScreen doesn't provide them.
          // We might need to fetch directly from Firestore or refactor provider access.
          // For now, let's assume a direct Firestore fetch for simplicity.
          final doc = await FirebaseFirestore.instance.collection('daily_audio').doc(contentId).get();
          if (!doc.exists || doc.data() == null) {
             throw Exception('Audio module not found');
          }
          final audioData = doc.data()!;
          audioData['id'] = doc.id; // Add ID for fromJson
          final dailyAudio = DailyAudio.fromJson(audioData);

          // Dismiss loading dialog
          navigator.pop(); 
          
          // Navigate to MediaPlayerScreen with fetched data
          // Convert DailyAudio to MediaItem or pass required fields
          navigator.pushNamed('/media_player', arguments: { 
             // TODO: Verify MediaPlayerScreen arguments. Does it take DailyAudio directly? 
             // Or does it need a MediaItem? Or individual fields?
             // Passing individual fields for now based on constructor:
            'title': dailyAudio.title,
            'subtitle': dailyAudio.category, // Or assemble from focusAreas
            'mediaUrl': dailyAudio.audioUrl,
            'mediaType': MediaType.audio,
            'imageUrl': dailyAudio.thumbnail,
            // 'mediaItem': MediaItem.fromDailyAudio(dailyAudio), // Option if it takes MediaItem
          });
          break;
          
        case 'article':
          // Fetch Article data
          final articleDoc = await FirebaseFirestore.instance.collection('articles').doc(contentId).get();
           if (!articleDoc.exists || articleDoc.data() == null) {
             throw Exception('Article not found');
          }
          final articleData = articleDoc.data()!;
          articleData['id'] = articleDoc.id; // Add ID for fromJson
          final article = Article.fromJson(articleData);
          
          navigator.pop(); // Dismiss loading dialog
          
          // Navigate with required data for ArticleDetailScreen
          navigator.pushNamed('/article-details', arguments: { // Pass arguments as map
            'title': article.title,
            'imageUrl': article.thumbnail,
            'content': article.content,
            'metadata': {
              'authorName': article.authorName,
            },
          });
          break;
          
        default:
          navigator.pop(); // Dismiss loading dialog
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cannot open content of type: $contentType')),
            );
          }
      }
    } catch (e) {
      debugPrint('Error opening shared content: $e');
      navigator.pop(); // Dismiss loading dialog on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading content: $e')),
        );
      }
    }
  }
  
  // Show dialog for selecting content to share
  void _showContentSharingDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ContentSharingScreen(
        chatId: widget.chatId,
      ),
    );
  }
} 