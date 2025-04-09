import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/message_model.dart';
import '../../../models/chat_model.dart';
import '../../../providers/chat_provider.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMyMessage;
  final bool showSenderInfo;
  
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMyMessage,
    this.showSenderInfo = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderInfo)
            FutureBuilder<ChatUser?>(
              future: Provider.of<ChatProvider>(context, listen: false)
                  .getUserDetails(message.senderId),
              builder: (context, snapshot) {
                final sender = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    sender?.name ?? 'User',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                );
              },
            ),
          Row(
            mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMyMessage)
                SizedBox(
                  width: 30,
                  child: FutureBuilder<ChatUser?>(
                    future: Provider.of<ChatProvider>(context, listen: false)
                        .getUserDetails(message.senderId),
                    builder: (context, snapshot) {
                      final sender = snapshot.data;
                      return CircleAvatar(
                        radius: 12,
                        backgroundImage: sender?.profileImageUrl != null
                            ? NetworkImage(sender!.profileImageUrl!)
                            : null,
                        child: sender?.profileImageUrl == null
                            ? Text(sender?.name.isNotEmpty == true ? sender!.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 10))
                            : null,
                      );
                    },
                  ),
                ),
              Flexible(
                child: Container(
                  margin: EdgeInsets.only(
                    left: isMyMessage ? 64 : 4,
                    right: isMyMessage ? 4 : 64,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? theme.primaryColor.withOpacity(0.8)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(context),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMyMessage ? 0 : 38,
              right: isMyMessage ? 8 : 0,
              top: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                if (isMyMessage) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.isRead ? Colors.blue : Colors.grey[600],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.mediaUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      heightFactor: 4,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            if (message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMyMessage ? Colors.white : null,
                  ),
                ),
              ),
          ],
        );
      
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isMyMessage ? Colors.white : Colors.blue,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMyMessage ? Colors.white : null,
                ),
              ),
            ),
          ],
        );
        
      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              color: isMyMessage ? Colors.white : Colors.blue,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Audio message',
                style: TextStyle(
                  color: isMyMessage ? Colors.white : null,
                ),
              ),
            ),
          ],
        );
        
      case MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.mediaUrl != null)
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      message.mediaUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            if (message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMyMessage ? Colors.white : null,
                  ),
                ),
              ),
          ],
        );
        
      case MessageType.text:
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMyMessage ? Colors.white : null,
          ),
        );
    }
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
} 