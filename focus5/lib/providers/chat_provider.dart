import 'package:flutter/material.dart';
import '../models/chat_models.dart';

class ChatProvider with ChangeNotifier {
  // Dummy data for chats and users
  final List<ChatUser> _users = [
    ChatUser(
      id: 'coach1',
      name: 'Coach Sarah',
      avatarUrl: 'https://picsum.photos/200/200?random=1',
      status: UserStatus.online,
      role: 'coach',
      specialization: 'Mental Performance',
    ),
    ChatUser(
      id: 'coach2',
      name: 'Coach Mike',
      avatarUrl: 'https://picsum.photos/200/200?random=2',
      status: UserStatus.away,
      role: 'coach',
      specialization: 'Leadership Development',
    ),
    ChatUser(
      id: 'coach3',
      name: 'Coach Emma',
      avatarUrl: 'https://picsum.photos/200/200?random=3',
      status: UserStatus.offline,
      role: 'coach',
      specialization: 'Sports Psychology',
    ),
    ChatUser(
      id: 'current_user',
      name: 'You',
      avatarUrl: 'https://picsum.photos/200/200?random=4',
      status: UserStatus.online,
      role: 'athlete',
      specialization: '',
    ),
  ];

  final List<Chat> _chats = [
    Chat(
      id: 'team_chat',
      participantIds: ['coach1', 'coach2', 'coach3', 'current_user'],
      lastMessageText: 'Great practice today everyone!',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
      lastMessageSenderId: 'coach1',
      hasUnreadMessages: true,
      isGroupChat: true,
      groupName: 'Team Chat',
      groupAvatarUrl: 'https://picsum.photos/200/200?random=5',
    ),
    Chat(
      id: 'coach1_chat',
      participantIds: ['coach1', 'current_user'],
      lastMessageText: 'Your form is improving!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      lastMessageSenderId: 'coach1',
      hasUnreadMessages: false,
      isGroupChat: false,
    ),
    Chat(
      id: 'coach2_chat',
      participantIds: ['coach2', 'current_user'],
      lastMessageText: 'See you at training tomorrow',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      lastMessageSenderId: 'coach2',
      hasUnreadMessages: true,
      isGroupChat: false,
    ),
  ];

  final Map<String, List<ChatMessage>> _messages = {
    'team_chat': [
      ChatMessage(
        id: '1',
        senderId: 'coach1',
        content: 'Great practice today everyone!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
        reactions: {'👍': ['coach2', 'coach3'], '🎯': ['current_user']},
      ),
    ],
    'coach1_chat': [
      ChatMessage(
        id: '1',
        senderId: 'coach1',
        content: 'Your form is improving!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
        reactions: {'🔥': ['current_user']},
      ),
    ],
    'coach2_chat': [
      ChatMessage(
        id: '1',
        senderId: 'coach2',
        content: 'See you at training tomorrow',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
    ],
  };

  // Getters
  List<Chat> get chats => _chats;
  List<ChatUser> get users => _users;
  
  // Methods
  List<ChatMessage> getMessagesForChat(String chatId) {
    return _messages[chatId] ?? [];
  }

  ChatUser? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  void sendMessage(String chatId, String content) {
    final newMessage = ChatMessage(
      id: DateTime.now().toString(),
      senderId: 'current_user',
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
    );

    if (_messages.containsKey(chatId)) {
      _messages[chatId]!.add(newMessage);
    } else {
      _messages[chatId] = [newMessage];
    }

    // Update last message in chat
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final updatedChat = Chat(
        id: _chats[chatIndex].id,
        participantIds: _chats[chatIndex].participantIds,
        isGroupChat: _chats[chatIndex].isGroupChat,
        groupName: _chats[chatIndex].groupName,
        groupAvatarUrl: _chats[chatIndex].groupAvatarUrl,
        lastMessageTime: newMessage.timestamp,
        lastMessageText: newMessage.content,
        lastMessageSenderId: newMessage.senderId,
        hasUnreadMessages: false,
      );
      _chats[chatIndex] = updatedChat;
    }

    notifyListeners();
  }

  void markChatAsRead(String chatId) {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final updatedChat = Chat(
        id: _chats[chatIndex].id,
        participantIds: _chats[chatIndex].participantIds,
        isGroupChat: _chats[chatIndex].isGroupChat,
        groupName: _chats[chatIndex].groupName,
        groupAvatarUrl: _chats[chatIndex].groupAvatarUrl,
        lastMessageTime: _chats[chatIndex].lastMessageTime,
        lastMessageText: _chats[chatIndex].lastMessageText,
        lastMessageSenderId: _chats[chatIndex].lastMessageSenderId,
        hasUnreadMessages: false,
      );
      _chats[chatIndex] = updatedChat;
      notifyListeners();
    }
  }
  
  void addReactionToMessage(String chatId, String messageId, String reaction) {
    if (_messages.containsKey(chatId)) {
      final messageIndex = _messages[chatId]!.indexWhere((message) => message.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[chatId]![messageIndex];
        final Map<String, List<String>> newReactions = {...message.reactions ?? {}};
        
        if (newReactions.containsKey(reaction)) {
          if (newReactions[reaction]!.contains('current_user')) {
            newReactions[reaction]!.remove('current_user');
            if (newReactions[reaction]!.isEmpty) {
              newReactions.remove(reaction);
            }
          } else {
            newReactions[reaction]!.add('current_user');
          }
        } else {
          newReactions[reaction] = ['current_user'];
        }
        
        final updatedMessage = ChatMessage(
          id: message.id,
          senderId: message.senderId,
          content: message.content,
          timestamp: message.timestamp,
          isRead: message.isRead,
          reactions: newReactions,
        );
        
        _messages[chatId]![messageIndex] = updatedMessage;
        notifyListeners();
      }
    }
  }
} 