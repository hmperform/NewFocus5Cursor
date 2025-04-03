import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/chat_models.dart';
import 'chat_detail_screen.dart';
import '../../utils/image_utils.dart';

class DMsTab extends StatefulWidget {
  const DMsTab({Key? key}) : super(key: key);

  @override
  State<DMsTab> createState() => _DMsTabState();
}

class _DMsTabState extends State<DMsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment_outlined, color: textColor),
            onPressed: () {
              // TODO: Implement new message
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search messages',
                  hintStyle: TextStyle(color: secondaryTextColor),
                  prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          // Online coaches
          SizedBox(
            height: 100,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: chatProvider.users.length,
              itemBuilder: (context, index) {
                final user = chatProvider.users[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ImageUtils.avatarWithFallback(
                            imageUrl: user.avatarUrl,
                            radius: 30,
                            name: user.name,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.name.split(' ')[0],
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Chat list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chatProvider.chats.length,
              itemBuilder: (context, index) {
                final chat = chatProvider.chats[index];
                
                // Filter based on search query
                if (_searchQuery.isNotEmpty) {
                  final otherUser = chatProvider.getUserById(
                    chat.participantIds.firstWhere((id) => id != 'current_user', 
                    orElse: () => ''));
                  
                  if (!chat.isGroupChat && 
                      !otherUser!.name.toLowerCase().contains(_searchQuery) &&
                      !chat.lastMessageText.toLowerCase().contains(_searchQuery)) {
                    return const SizedBox.shrink();
                  }
                  
                  if (chat.isGroupChat && 
                      !chat.groupName!.toLowerCase().contains(_searchQuery) &&
                      !chat.lastMessageText.toLowerCase().contains(_searchQuery)) {
                    return const SizedBox.shrink();
                  }
                }

                return _buildChatTile(
                  context: context,
                  chat: chat,
                  chatProvider: chatProvider,
                  backgroundColor: surfaceColor,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  accentColor: accentColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile({
    required BuildContext context,
    required Chat chat,
    required ChatProvider chatProvider,
    required Color backgroundColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color accentColor,
  }) {
    final otherUser = chat.isGroupChat ? null : chatProvider.getUserById(
      chat.participantIds.firstWhere((id) => id != 'current_user'));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(chat: chat),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ImageUtils.avatarWithFallback(
                  imageUrl: chat.isGroupChat
                      ? chat.groupAvatarUrl ?? 'https://ui-avatars.com/api/?name=${chat.groupName}'
                      : otherUser?.avatarUrl ?? '',
                  radius: 28,
                  name: chat.isGroupChat ? chat.groupName : otherUser?.name ?? 'User',
                ),
                if (!chat.isGroupChat && otherUser != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: otherUser.status == UserStatus.online
                            ? Colors.green
                            : otherUser.status == UserStatus.away
                                ? Colors.orange
                                : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: backgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat.isGroupChat ? chat.groupName! : otherUser?.name ?? '',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: chat.hasUnreadMessages ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      Text(
                        timeago.format(chat.lastMessageTime, allowFromNow: true),
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessageText,
                          style: TextStyle(
                            color: chat.hasUnreadMessages ? textColor : secondaryTextColor,
                            fontSize: 14,
                            fontWeight: chat.hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.hasUnreadMessages)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 