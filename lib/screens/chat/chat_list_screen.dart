import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewChatScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (chatProvider.chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewChatScreen()),
                      );
                    },
                    child: const Text('Start a new chat'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: chatProvider.chats.length,
            itemBuilder: (context, index) {
              final chat = chatProvider.chats[index];
              return ChatListTile(chat: chat);
            },
          );
        },
      ),
    );
  }
}

class ChatListTile extends StatelessWidget {
  final Chat chat;
  
  const ChatListTile({Key? key, required this.chat}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUserId = chatProvider.currentUserId;
    
    // Get other participant ID for 1:1 chats
    String? otherUserId;
    if (!chat.isGroupChat && chat.participantIds.length == 2) {
      otherUserId = chat.participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
    }
    
    return FutureBuilder<ChatUser?>(
      future: otherUserId != null ? chatProvider.getUserDetails(otherUserId) : null,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = chat.isGroupChat 
            ? chat.groupName ?? 'Group Chat'
            : user?.name ?? 'Loading...';
        final avatarUrl = chat.isGroupChat
            ? chat.groupAvatarUrl
            : user?.profileImageUrl;
        
        return ListTile(
          leading: GestureDetector(
            onTap: () => _handleAvatarTap(context, user),
            child: CircleAvatar(
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null 
                  ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?')
                  : null,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: chat.hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (user?.isCoach == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(left: 4),
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
          ),
          subtitle: Text(
            chat.lastMessageText.isEmpty ? 'No messages yet' : chat.lastMessageText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: chat.hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(chat.lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: chat.hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (chat.hasUnreadMessages)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatId: chat.id),
              ),
            );
          },
        );
      },
    );
  }
  
  void _handleAvatarTap(BuildContext context, ChatUser? user) async {
    if (user == null || !user.isCoach || !user.hasCoachProfile) return;
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final coachDetails = await chatProvider.getCoachDetails(user.userId);
    
    if (coachDetails != null && context.mounted) {
      Navigator.pushNamed(context, '/coach', arguments: user.coachId);
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
} 