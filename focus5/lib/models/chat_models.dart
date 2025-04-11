import 'package:flutter/material.dart';

enum UserStatus {
  online,
  away,
  offline
}

class ChatUser {
  final String id;
  final String name;
  final String fullName;
  final String avatarUrl;
  final UserStatus status;
  final String role;
  final String specialization;

  ChatUser({
    required this.id,
    required this.name,
    required this.fullName,
    required this.avatarUrl,
    required this.status,
    required this.role,
    required this.specialization,
  });
}

class ChatUserData {
  final String id;
  final String name;
  final String userName;
  final String fullName;
  final String imageUrl;
  final String role;
  final String specialization;
  final String status;
  final String? coachId;

  ChatUserData({
    required this.id,
    required this.name,
    required this.userName,
    required this.fullName,
    required this.imageUrl,
    required this.role,
    this.specialization = '',
    required this.status,
    this.coachId,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, List<String>>? reactions;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.reactions,
  });
}

class Chat {
  final String id;
  final List<String> participantIds;
  final String lastMessageText;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final bool hasUnreadMessages;
  final bool isGroupChat;
  final String? groupName;
  final String? groupAvatarUrl;

  Chat({
    required this.id,
    required this.participantIds,
    required this.lastMessageText,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.hasUnreadMessages,
    required this.isGroupChat,
    this.groupName,
    this.groupAvatarUrl,
  });
} 