import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/chat_models.dart';
import '../../models/user_model.dart';
import 'chat_detail_screen.dart';
import '../../utils/image_utils.dart';
import '../../widgets/common/empty_state_widget.dart';

class DMsTab extends StatefulWidget {
  const DMsTab({Key? key}) : super(key: key);

  @override
  State<DMsTab> createState() => _DMsTabState();
}

class _DMsTabState extends State<DMsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _isSearching = _searchQuery.isNotEmpty;
      });
    });
  }

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
    final unreadColor = accentColor.withOpacity(0.1);

    final filteredChats = chatProvider.chats.where((chat) {
      if (!_isSearching) return true;

      final otherUser = chatProvider.getUserById(
          chat.participantIds.firstWhere((id) => id != chatProvider.currentUserId,
              orElse: () => ''));

      if (!chat.isGroupChat && otherUser != null) {
        return otherUser.fullName.toLowerCase().contains(_searchQuery) ||
               chat.lastMessageText.toLowerCase().contains(_searchQuery);
      } else if (chat.isGroupChat && chat.groupName != null) {
        return chat.groupName!.toLowerCase().contains(_searchQuery) ||
               chat.lastMessageText.toLowerCase().contains(_searchQuery);
      }
      return false;
    }).toList();

    filteredChats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search messages',
                  hintStyle: TextStyle(color: secondaryTextColor),
                  prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  suffixIcon: _isSearching
                    ? IconButton(
                        icon: Icon(Icons.clear, color: secondaryTextColor),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                ),
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

          // Chat list or Empty State
          Expanded(
            child: filteredChats.isEmpty
                ? EmptyStateWidget(
                    iconData: Icons.chat_bubble_outline,
                    message: _isSearching
                        ? 'No results found for "$_searchQuery"'
                        : 'No conversations yet.
Start a chat with a coach!',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return _buildChatTile(
                        context: context,
                        chat: chat,
                        chatProvider: chatProvider,
                        themeProvider: themeProvider,
                        backgroundColor: surfaceColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        accentColor: accentColor,
                        unreadColor: unreadColor,
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
    required ThemeProvider themeProvider,
    required Color backgroundColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color accentColor,
    required Color unreadColor,
  }) {
    final currentUserId = chatProvider.currentUserId;
    User? otherUser;
    if (!chat.isGroupChat) {
       final otherParticipantId = chat.participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');
       if (otherParticipantId.isNotEmpty) {
         otherUser = chatProvider.getUserById(otherParticipantId);
       }
    }

    final bool isUnread = !chat.readBy.contains(currentUserId);

    DateTime? lastMessageDateTime;
    try {
      lastMessageDateTime = DateTime.tryParse(chat.lastMessageTime);
    } catch (e) {
      print("Error parsing lastMessageTime: ${chat.lastMessageTime} - $e");
      lastMessageDateTime = DateTime.tryParse(chat.createdAt);
    }
    final String timeAgoString = lastMessageDateTime != null
        ? timeago.format(lastMessageDateTime)
        : '';

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread ? unreadColor : backgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ImageUtils.avatarWithFallback(
                  imageUrl: chat.isGroupChat
                      ? chat.groupAvatarUrl
                      : otherUser?.profileImageUrl,
                  radius: 28,
                  name: chat.isGroupChat ? (chat.groupName ?? 'Group') : (otherUser?.fullName ?? 'User'),
                ),
                if (!chat.isGroupChat && otherUser?.isCoach == true)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: accentColor,
                        size: 16,
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
                  Text(
                    chat.isGroupChat ? (chat.groupName ?? 'Group') : (otherUser?.fullName ?? 'User'),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessageText,
                    style: TextStyle(
                      color: isUnread ? textColor : secondaryTextColor,
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Text(
                   timeAgoString,
                   style: TextStyle(
                     color: secondaryTextColor,
                     fontSize: 12,
                   ),
                 ),
                 if (isUnread) ...[
                   const SizedBox(height: 4),
                   Container(
                     width: 8,
                     height: 8,
                     decoration: BoxDecoration(
                       color: accentColor,
                       shape: BoxShape.circle,
                     ),
                   ),
                 ],
              ],
            ),
          ],
        ),
      ),
    );
  }
} 