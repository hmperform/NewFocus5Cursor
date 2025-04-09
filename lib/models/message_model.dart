import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final DocumentReference? chatRef;
  final String senderId;
  final DocumentReference? senderRef;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final List<Map<String, dynamic>>? reactions;
  final MessageType type;
  final String? mediaUrl;

  ChatMessage({
    required this.id,
    required this.chatId,
    this.chatRef,
    required this.senderId,
    this.senderRef,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.reactions,
    this.type = MessageType.text,
    this.mediaUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse reactions
    List<Map<String, dynamic>>? reactionsList;
    if (data['reactions'] != null && data['reactions'] is List) {
      reactionsList = List<Map<String, dynamic>>.from(data['reactions']);
    }
    
    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      chatRef: data['chatRef'],
      senderId: data['senderId'] ?? '',
      senderRef: data['senderRef'],
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] is Timestamp) 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      reactions: reactionsList,
      type: _parseMessageType(data['type']),
      mediaUrl: data['mediaUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'chatRef': chatRef,
      'senderId': senderId,
      'senderRef': senderRef,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'reactions': reactions ?? [],
      'type': type.toString().split('.').last,
      'mediaUrl': mediaUrl,
    };
  }
  
  static MessageType _parseMessageType(dynamic value) {
    if (value == null) return MessageType.text;
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'image': return MessageType.image;
        case 'video': return MessageType.video;
        case 'audio': return MessageType.audio;
        case 'file': return MessageType.file;
        default: return MessageType.text;
      }
    }
    return MessageType.text;
  }
}

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
} 