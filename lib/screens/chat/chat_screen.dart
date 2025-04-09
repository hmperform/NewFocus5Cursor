import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  
  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatProvider _chatProvider;
  bool _isLoading = true;
  Chat? _chat;
  ChatUser? _otherUser;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _loadChat();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _loadChat() {
    setState(() => _isLoading = true);
    
    // Select this chat to load its messages
    _chatProvider.selectChat(widget.chatId);
    
    setState(() => _isLoading = false);
  }
  
  void _navigateToCoachProfile(ChatUser? user) async {
    if (user == null || !user.isCoach || !user.hasCoachProfile) return;
    
    final coachDetails = await _chatProvider.getCoachDetails(user.userId);
    
    if (coachDetails != null && mounted) {
      Navigator.pushNamed(context, '/coach', arguments: user.coachId);
    }
  }
  
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _chatProvider.sendMessage(widget.chatId, message);
    _messageController.clear();
    
    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, provider, child) {
            final chat = provider.chats.firstWhere(
              (c) => c.id == widget.chatId,
              orElse: () => Chat(
                id: '',
                participantIds: [],
                lastMessageText: '',
                lastMessageTime: DateTime.now(),
                lastMessageSenderId: '',
                hasUnreadMessages: false,
              ),
            );
            
            if (chat.id.isEmpty) {
              return const Text('Chat');
            }
            
            final currentUserId = provider.currentUserId;
            
            // Get other participant for 1:1 chats
            if (!chat.isGroupChat && chat.participantIds.length == 2) {
              final otherUserId = chat.participantIds.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );
              
              if (otherUserId.isNotEmpty) {
                return FutureBuilder<ChatUser?>(
                  future: provider.getUserDetails(otherUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    
                    final user = snapshot.data;
                    _otherUser = user; // Store for later use
                    
                    return GestureDetector(
                      onTap: user?.isCoach == true ? () => _navigateToCoachProfile(user) : null,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: user?.profileImageUrl != null 
                                ? NetworkImage(user!.profileImageUrl!) 
                                : null,
                            child: user?.profileImageUrl == null
                                ? Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?')
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (user?.isCoach == true)
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Coach',
                                          style: TextStyle(fontSize: 10, color: Colors.blue),
                                        ),
                                      ),
                                      if (user?.isCoach == true)
                                        const Text(
                                          ' • Tap to view profile',
                                          style: TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            }
            
            // Group chat title
            return Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: chat.groupAvatarUrl != null
                      ? NetworkImage(chat.groupAvatarUrl!)
                      : null,
                  child: chat.groupAvatarUrl == null
                      ? const Icon(Icons.group, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chat.groupName ?? 'Group Chat',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          if (_otherUser?.isCoach == true)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => _navigateToCoachProfile(_otherUser),
              tooltip: 'View coach profile',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Show chat info/settings
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingMessages) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final messages = provider.messages[widget.chatId] ?? [];
          final currentUserId = provider.currentUserId;
          
          return Column(
            children: [
              // Messages list
              Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMyMessage = message.senderId == currentUserId;
                          
                          return MessageBubble(
                            message: message,
                            isMyMessage: isMyMessage,
                            showSenderInfo: !isMyMessage,
                          );
                        },
                      ),
              ),
              
              // Message input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () {
                        // TODO: Implement file attachment
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                        ),
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 